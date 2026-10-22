#!/usr/bin/env bash
#MISE description="Parse the upstream ShellSpec suite at a pinned commit"
# test/spec/ is a copy of ShellSpec's tutorial `examples/`, which exercises each
# construct in its simplest documented form. The framework's own regression suite
# is harder and is where real usage lives: it once had 8 failing files that the
# tutorial corpus could not surface (bracket test arguments, `When I run`,
# `Skip "reason" if`, `Include` with arguments, multi-argument `Data`, `<>`).
# Pinned to a commit on purpose — a moving ref, a tag included, would let an
# upstream push or retag turn this build red on its own.
set -euo pipefail

ref="${SHELLSPEC_REF:-90e48c950239f3b8a9fdfa3e869592872c77b981}" # 0.28.1
dir=.temp/shellspec

rm -rf "$dir"
trap 'rm -rf "$dir"' EXIT
git init --quiet "$dir"
git -C "$dir" fetch --quiet --depth 1 https://github.com/shellspec/shellspec "$ref"
git -C "$dir" checkout --quiet --detach FETCH_HEAD

failed=0
count=0
while IFS= read -r f; do
  count=$((count + 1))
  tree-sitter parse --quiet "$f" > /dev/null || { echo "❌ parse errors: $f"; failed=1; }
done < <(find "$dir/spec" "$dir/examples" -name '*.sh' | sort)
echo "parsed $count upstream files"
# find's failure is invisible inside the process substitution, so a changed upstream
# layout would otherwise pass with nothing parsed.
if [ "$count" -eq 0 ]; then
  echo "❌ no upstream spec files found in $dir/spec or $dir/examples"
  exit 1
fi
exit "$failed"
