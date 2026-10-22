#!/usr/bin/env bash
#MISE description="Fail when src/ differs from the committed generator output"
# Run after `mise run generate`. Fails when grammar.js changed but the committed src/
# output was not regenerated, so CI never tests (or releases) a parser that differs from
# the committed one. `git status --porcelain`, not `git diff --exit-code`: diff only sees
# tracked files, so a generator that emits a *new* output under src/ would leave it
# untracked and the gate would pass while the build used an uncommitted file.
set -euo pipefail

changes=$(git status --porcelain -- src/)
if [ -n "$changes" ]; then
  echo "::error::src/ differs from the committed output; run 'mise run generate' and commit."
  printf '%s\n' "$changes"
  exit 1
fi
