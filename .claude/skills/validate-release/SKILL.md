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

    Must be 100% passing. Report the total test count (must be >= 115, the threshold the CI coverage job enforces).

2. **Verify spec files parse cleanly** (`--quiet` exits non-zero on ERROR and MISSING nodes):

    ```bash
    failed_files=0
    for f in test/spec/*.sh; do
      if ! npx tree-sitter parse --quiet "$f" > /dev/null; then
        echo "PARSE ERRORS in $f"
        failed_files=$((failed_files + 1))
      fi
    done
    echo "Spec files with parse errors: $failed_files"
    ```

    Must be 0 files.

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
