#!/usr/bin/env bash
# Pre-bash guard: blocks Bash commands that write to generated parser files.
#
# pre-edit-guard.sh only sees Edit/Write/NotebookEdit calls, so shell commands
# (`sed -i`, redirects, cp/mv/rm, a globally installed `tree-sitter generate`)
# could rewrite src/parser.c, src/grammar.json, src/node-types.json or
# src/tree_sitter/ unnoticed. During an audit a global CLI did exactly that: it
# regenerated those files with the wrong tree-sitter version and dropped the
# parser.h patch that scripts/post-generate.sh applies.
#
# Claude Code passes the command as JSON on stdin (tool_input.command). Only
# exit 2 blocks a PreToolUse call, so the guard exits 2 on a violation and on
# input it cannot parse (fail closed). Restoring committed files with
# `git checkout`/`git restore`, and the pinned `npm run generate` or
# `npx tree-sitter generate`, stay allowed.

set -euo pipefail

# The node program is single-quoted on purpose: its ${...} is JavaScript, not shell.
# shellcheck disable=SC2016
node -e '
let raw = "";
process.stdin.on("data", (chunk) => (raw += chunk)).on("end", () => {
  let command;
  try {
    command = JSON.parse(raw).tool_input?.command;
  } catch {
    command = undefined;
  }
  if (typeof command !== "string") {
    console.error("pre-bash-guard: could not read tool_input.command from hook input");
    process.exit(2);
  }
  const generatedPath = /(^|[^\w.-])src\/(parser\.c|grammar\.json|node-types\.json|tree_sitter\b)/;
  // Equivalent spellings of the same path defeat a literal match: src/"parser.c"
  // and src/./parser.c both name src/parser.c, in either quote style. Strip quote
  // characters and collapse /./ before matching so the checks see one canonical form.
  // This is normalisation, not Bash parsing: $VAR indirection still gets through,
  // and no regex can close that. The guard is a safety net for honest mistakes,
  // not a sandbox boundary.
  const normalize = (s) => s.replace(/["\x27]/g, "").replace(/(^|[^.])\.\//g, "$1");
  const reasons = new Set();
  for (const part of command.split(/&&|\|\||;|\n/)) {
    const segment = normalize(part.trim());
    if (/^git\s+(checkout|restore)\b/.test(segment)) continue;
    if (generatedPath.test(segment)) {
      // `>|` is the clobber-anyway redirect. The bar has to be matched explicitly:
      // \S* cannot consume it without also consuming the space that follows.
      if (/>{1,2}\|?\s*["\x27]?\S*src\/(parser\.c|grammar\.json|node-types\.json|tree_sitter\b)/.test(segment)) {
        reasons.add("redirects output into a generated file");
      } else if (/\b(sed|perl)\b.*\s-[a-zA-Z]*i/.test(segment)) {
        reasons.add("edits a generated file in place");
      } else if (/^(sudo\s+)?(cp|mv|rm|tee|truncate|install|dd|ln)\b/.test(segment) || /\|\s*tee\b/.test(segment)) {
        reasons.add("writes, moves or deletes a generated file");
      } else if (/^(sudo\s+)?(python3?|node|perl|ruby|awk|busybox)\b/.test(segment)) {
        // The path test already fired, so an interpreter naming a generated file is
        // a write until proven otherwise: a python3 -c or node -e one-liner opening
        // src/parser.c for writing matched no other reason and was allowed through.
        reasons.add("runs an interpreter that names a generated file");
      }
    }
    if (/(^|[\s(])tree-sitter\s+generate\b/.test(segment) && !/(npx\s+|node_modules\/\.bin\/)tree-sitter\s+generate\b/.test(segment)) {
      reasons.add("runs a global tree-sitter generate instead of the pinned CLI");
    }
  }
  if (reasons.size) {
    console.error(`BLOCKED: this command ${[...reasons].join("; ")}. Edit grammar.js and run npm run generate.`);
    process.exit(2);
  }
});
'
