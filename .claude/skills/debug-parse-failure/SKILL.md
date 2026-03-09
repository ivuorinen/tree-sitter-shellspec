---
name: debug-parse-failure
description: Debug a ShellSpec parse failure by identifying ERROR nodes and tracing to grammar rules
---

# Debug Parse Failure

Diagnose why a ShellSpec file or snippet doesn't parse correctly.

## Arguments

- `file` (optional): Path to a file that fails to parse
- `snippet` (optional): Inline ShellSpec code to debug

## Steps

1. **Parse the file/snippet** and identify ERROR nodes:

    ```bash
    tree-sitter parse <file> 2>&1
    ```

    If debugging a snippet, write it to a temp file first.

2. **Locate ERROR nodes**: Look for `(ERROR)` in the AST output. Note:
    - The line/column where the error starts
    - What the parser expected vs. what it found
    - The surrounding AST context (what parsed successfully around it)

3. **Identify the grammar rule**: Based on the ShellSpec construct that failed:
    - Read the relevant rule in `grammar.js`
    - Check if the input matches the rule's expected pattern
    - Look for keyword mismatches, missing fields, or unexpected tokens

4. **Check common causes** (from Grammar Gotchas):
    - Is a compound keyword token interfering? (e.g., `"Data:raw"` as single token)
    - Is a precedence conflict causing the wrong rule to win?
    - Is a bash construct (like `[ ... ]` → `$.test_command`) not being recognized?
    - Is the construct inside a block that doesn't include it in `_terminated_statement`?

5. **Test a fix**:
    - Edit `grammar.js` with the proposed fix
    - Run `npm run generate && npm test` to verify no regressions
    - Re-parse the original file to confirm the fix works

6. **Verify broadly**: Run the full spec file check:

    ```bash
    for f in test/spec/*.sh; do
      errors=$(tree-sitter parse "$f" 2>&1 | grep -c ERROR || true)
      if [ "$errors" -gt 0 ]; then echo "ERRORS in $f: $errors"; fi
    done
    ```
