#!/usr/bin/env bash
#MISE description="Test the Node binding against the tree-sitter runtime"
# The corpus tests run through the tree-sitter CLI's own runtime, so they cannot catch
# a binding whose declared runtime is too old for the grammar's ABI. This loads the
# grammar through the real Node runtime. Needs `mise run install` first: npm ci's
# node-gyp-build step compiles the addon this test loads.
#
# `tree-sitter` is declared as an OPTIONAL peerDependency, and npm refuses to add
# one to node_modules: `npm i --no-save tree-sitter` exits 0 and installs nothing,
# as do --legacy-peer-deps and --force. Installing into a separate prefix and
# symlinking it in is what actually works, and leaves package.json and
# package-lock.json untouched. The explicit resolve check is the point of the
# step: without it a silent no-op would leave the test below passing vacuously.
set -euo pipefail

prefix="$PWD/.temp/ts-runtime"
link=node_modules/tree-sitter

# --ignore-scripts: npm skips the runtime's node-gyp-build install script anyway (it is
# not covered by allowScripts, which only lists this package's own dependencies), and
# the runtime loads from the prebuilds it ships. The flag makes that explicit instead
# of leaving npm to warn about it.
npm i --ignore-scripts --prefix "$prefix" tree-sitter@^0.25
if [ ! -e "$link" ]; then
  ln -sfn "$prefix/node_modules/tree-sitter" "$link"
  # Removes only the link this run created, so a local node_modules stays as it was.
  trap 'rm -f "$link"' EXIT
fi
node -e "console.log('tree-sitter runtime', require('tree-sitter/package.json').version)" || {
  echo "::error::tree-sitter runtime is not resolvable; the Node binding test would pass without testing anything"
  exit 1
}

node --test bindings/node/binding_test.js
