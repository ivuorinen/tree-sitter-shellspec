---
paths:
  - "grammar.js"
  - "test/corpus/**"
---

# Grammar verification

After every change to `grammar.js` or `test/corpus/`, run `npm run generate` and then `npm test`.
Never leave a failing corpus test; the pass rate stays at 100%.
After every change to `grammar.js`, parse every real spec file and fix every ERROR or MISSING node it reports:

```bash
for f in test/spec/*.sh; do npx tree-sitter parse --quiet "$f" >/dev/null || echo "parse errors: $f"; done
```

`test/spec/` is a copy of ShellSpec's tutorial `examples/` and is the easy corpus.
Also parse the framework's own regression suite, which is where real usage lives —
CI does this at a pinned tag, and it is the corpus that surfaced eight parse failures
the tutorial files could not:

```bash
git clone --depth 1 --branch 0.28.1 https://github.com/shellspec/shellspec .tmp-shellspec
find .tmp-shellspec/spec .tmp-shellspec/examples -name '*.sh' \
  -exec sh -c 'npx tree-sitter parse --quiet "$1" >/dev/null || echo "parse errors: $1"' _ {} \;
```
