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

3. **Verify real spec files parse without errors**:

    ```bash
    for f in test/spec/*.sh; do
      errors=$(tree-sitter parse "$f" 2>&1 | grep -c ERROR || true)
      if [ "$errors" -gt 0 ]; then
        echo "ERRORS in $f: $errors"
        tree-sitter parse "$f" 2>&1 | grep ERROR
      fi
    done
    ```

    Report any spec files with parse errors.

4. **Summary**: Report total corpus tests passed, and spec file parse status.
