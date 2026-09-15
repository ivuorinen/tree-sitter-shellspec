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
