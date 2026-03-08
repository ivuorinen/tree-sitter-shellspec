---
name: validate-release
description: Run full pre-release validation - tests, spec parsing, highlight coverage, build
disable-model-invocation: true
---

# Validate Release

Run comprehensive pre-release checks before tagging a release.

## Steps

1. **Run all corpus tests**:

    ```bash
    npm test
    ```

    Must be 100% passing. Report the total test count (must be >= 96).

2. **Verify spec files parse cleanly**:

    ```bash
    total_errors=0
    for f in test/spec/*.sh; do
      errors=$(tree-sitter parse "$f" 2>&1 | grep -c ERROR || true)
      if [ "$errors" -gt 0 ]; then
        echo "ERRORS in $f: $errors"
        total_errors=$((total_errors + errors))
      fi
    done
    echo "Total spec file errors: $total_errors"
    ```

    Must be 0 errors.

3. **Check highlight coverage**: Compare keywords in grammar.js against patterns in
    queries/highlights.scm. Report any uncovered keywords.

4. **Build the parser**:

    ```bash
    npm run build
    ```

    Must succeed without errors.

5. **Verify README accuracy**:
    - Count rules in grammar.js and compare to the number documented in README.md
    - Check that all block types, statement types, and directive types listed in README match grammar.js

6. **Check EditorConfig compliance**:

    ```bash
    npx editorconfig-checker
    ```

7. **Summary**: Report pass/fail for each check, with details on any failures. All checks must pass for release.
