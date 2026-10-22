#!/usr/bin/env bash
#MISE description="Check src/scanner.c's TokenType enum against tree-sitter-bash"
# src/scanner.c is derived from tree-sitter-bash's scanner. Its TokenType enum must list
# the external tokens in the same order as the pinned tree-sitter-bash grammar.
# Whitespace is stripped because the local copy is re-indented to 2 spaces.
# Needs `mise run install` first: the reference copy comes from node_modules.
set -euo pipefail

enum_tokens() { sed -n '/^enum TokenType/,/^};/p' "$1" | tr -d ' \t'; }
diff <(enum_tokens node_modules/tree-sitter-bash/src/scanner.c) <(enum_tokens src/scanner.c)
