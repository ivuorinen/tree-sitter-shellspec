#!/usr/bin/env bash
# Post-edit lint: regenerates the parser after grammar.js edits and checks
# EditorConfig and corpus format for the edited file.
#
# Claude Code passes hook input as JSON on stdin (tool_input.file_path, absolute);
# no environment variable carries the path. PostToolUse cannot undo the edit, and
# stdout of an exit-0 hook never reaches Claude, so every failure is written to
# stderr with exit 2, which Claude Code feeds back to the model. Nothing is
# swallowed with `|| true`: a silent failure here is how a broken grammar or a
# malformed corpus file slipped through before.

set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" || exit 2

file=$(node -e '
let s = "";
process.stdin.on("data", (d) => (s += d)).on("end", () => {
  const input = JSON.parse(s).tool_input || {};
  const path = input.file_path || input.notebook_path;
  if (!path) process.exit(3);
  process.stdout.write(path);
});
') || {
  echo "post-edit-lint: could not read tool_input.file_path from hook input" >&2
  exit 2
}

status=0

# Regenerate the parser after grammar.js changes so tests never run a stale parser.
case "$file" in
  */grammar.js)
    if ! out=$(npm run generate 2>&1); then
      printf 'post-edit-lint: npm run generate failed:\n%s\n' "$(printf '%s\n' "$out" | tail -20)" >&2
      status=2
    fi
    ;;
esac

# EditorConfig compliance for the edited file.
if ! out=$(npx editorconfig-checker "$file" 2>&1); then
  printf 'post-edit-lint: EditorConfig violations in %s:\n%s\n' "$file" "$out" >&2
  status=2
fi

# Corpus files need test headers (a line of '=') and an input/output separator (a line of '-').
case "$file" in
  */test/corpus/*.txt)
    if ! grep -q '^=\{3,\}$' "$file" || ! grep -q '^-\{3,\}$' "$file"; then
      echo "post-edit-lint: $file lacks a '===' header or '---' separator line" >&2
      status=2
    fi
    ;;
esac

exit "$status"
