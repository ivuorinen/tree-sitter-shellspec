#!/usr/bin/env bash
# Pre-edit guard: blocks Edit/Write calls that target generated or lock files.
#
# Claude Code passes hook input as JSON on stdin (tool_input.file_path is always
# absolute); it does not export the path as an environment variable. Only exit 2
# blocks a PreToolUse call, so the guard exits 2 on a protected path and also on
# input it cannot parse (fail closed). JSON is parsed with node because the
# project's npm scripts already require it; jq is not a declared prerequisite.

set -euo pipefail

file=$(node -e '
let s = "";
process.stdin.on("data", (d) => (s += d)).on("end", () => {
  const input = JSON.parse(s).tool_input || {};
  const path = input.file_path || input.notebook_path;
  if (!path) process.exit(3);
  process.stdout.write(path);
});
') || {
  echo "pre-edit-guard: could not read tool_input.file_path from hook input" >&2
  exit 2
}

case "$file" in
  */src/parser.c | */src/grammar.json | */src/node-types.json | */src/tree_sitter/*)
    echo "BLOCKED: $file is generated; edit grammar.js and run npm run generate" >&2
    exit 2
    ;;
  */package-lock.json)
    echo "BLOCKED: do not edit lock files directly; use npm commands" >&2
    exit 2
    ;;
esac
