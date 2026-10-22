---
paths:
  - "grammar.js"
  - "test/corpus/**"
---

# Grammar verification

After every change to `grammar.js` or `test/corpus/`, run `mise run generate` and then `mise run test`.
Never leave a failing corpus test; the pass rate stays at 100%.
After every change to `grammar.js`, parse every real spec file and fix every ERROR or MISSING node it reports.
`mise run test:spec` names each file with parse errors.

`test/spec/` is a copy of ShellSpec's tutorial `examples/` and is the easy corpus.
Also parse the framework's own regression suite with `mise run test:upstream`, which is where real usage lives —
CI does this at a pinned commit, and it is the corpus that surfaced eight parse failures
the tutorial files could not.
