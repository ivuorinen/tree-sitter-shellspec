#!/usr/bin/env bash
# Pre-edit guard: blocks edits to generated and locked files.
# Used by Claude Code PreToolUse hook via settings.json.
# Expects $CLAUDE_FILE_PATH to be set by the hook runner.

set -euo pipefail

case "${CLAUDE_FILE_PATH:-}" in
  */src/parser.c | */src/grammar.json | */src/node-types.json)
    echo "BLOCKED: Do not edit generated files in src/"
    exit 1
    ;;
  */package-lock.json)
    echo "BLOCKED: Do not edit lock files directly"
    exit 1
    ;;
esac
