#!/usr/bin/env bash
set -e

echo "Running post-generation fixes..."

# Apply critical safety fixes that get overwritten during generation
echo "  - Applying critical safety fixes..."

# Fix 1: Buffer overflow prevention in parser.h
# The set_contains function needs a len==0 check to prevent accessing ranges[0]
# This fix gets overwritten every time tree-sitter generate runs
if ! grep -q "if (len == 0) return false;" src/tree_sitter/parser.h; then
  # Insert the safety check right after the function opening
  # Target: static inline bool set_contains(...) {
  # Insert: if (len == 0) return false;
  # Before: uint32_t index = 0;

  # Use perl for cross-platform compatibility (macOS and Linux)
  perl -i -pe '
    BEGIN { $in_func = 0; $done = 0; }
    if (/static inline bool set_contains/) { $in_func = 1; }
    if ($in_func && /^\s+uint32_t index = 0;/ && !$done) {
      print "  if (len == 0) return false;\n";
      $done = 1;
    }
    if (/^}/ && $in_func) { $in_func = 0; }
  ' src/tree_sitter/parser.h
  echo "    ✓ Applied buffer overflow fix to parser.h"
else
  echo "    ✓ Buffer overflow fix already present"
fi

echo "Post-generation fixes complete!"
