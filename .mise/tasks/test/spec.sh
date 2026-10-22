#!/usr/bin/env bash
#MISE description="Parse every real-world spec file in test/spec/"
# `tree-sitter parse --quiet` exits non-zero on ERROR and MISSING nodes alike; grepping
# the output for "ERROR" misses MISSING nodes.
set -euo pipefail

failed=0
for f in test/spec/*.sh; do
  tree-sitter parse --quiet "$f" > /dev/null || { echo "❌ parse errors: $f"; failed=1; }
done
exit "$failed"
