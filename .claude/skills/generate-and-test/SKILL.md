---
name: generate-and-test
description: Generate parser from grammar.js, run all tests, and verify spec files parse cleanly
---

# Generate and Test

Run the full grammar validation workflow:

1. **Generate the parser** from grammar.js:

    ```bash
    npm run generate
    ```

    If generation fails, stop and report the error.

2. **Run all corpus tests**:

    ```bash
    npm test
    ```

    All tests must pass (100% success rate required). If any fail, report which tests failed.

3. **Verify real spec files parse without errors** (`--quiet` exits non-zero on ERROR and MISSING nodes; grepping for "ERROR" misses MISSING):

    ```bash
    for f in test/spec/*.sh; do
      if ! npx tree-sitter parse --quiet "$f" > /dev/null; then
        echo "PARSE ERRORS in $f"
        npx tree-sitter parse "$f" 2>&1 | grep -E 'ERROR|MISSING'
      fi
    done
    ```

    Report any spec files with parse errors.

4. **Summary**: Report total corpus tests passed, and spec file parse status.
