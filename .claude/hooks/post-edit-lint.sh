#!/usr/bin/env bash
# Post-edit lint: regenerates parser, checks editorconfig, validates corpus.
# Used by Claude Code PostToolUse hook via settings.json.
# Expects $CLAUDE_FILE_PATH to be set by the hook runner.

set -uo pipefail

file="${CLAUDE_FILE_PATH:-}"

# Auto-regenerate parser after grammar.js changes
case "$file" in
  */grammar.js)
    npm run generate >/dev/null 2>&1 || true
    ;;
esac

# EditorConfig compliance check
npx editorconfig-checker "$file" 2>/dev/null || true

# Corpus format validation for test files
case "$file" in
  */test/corpus/*.txt)
    if ! grep -cq '==========' "$file" 2>/dev/null \
      || ! grep -cq '^---$' "$file" 2>/dev/null; then
      echo "WARNING: Corpus file may have invalid format"
    fi
    ;;
esac
