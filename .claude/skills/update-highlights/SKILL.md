---
name: update-highlights
description: Update highlights.scm to cover all grammar rules, detecting missing patterns
---

# Update Highlights

Ensure `queries/highlights.scm` has syntax highlighting patterns for all grammar rules.

## Steps

1. **Extract all ShellSpec keywords from grammar.js**: Find every string literal used as a keyword
    (Describe, It, When, The, etc.) and every rule name prefixed with `shellspec_`.

2. **Read current highlights.scm**: Check which keywords and rules already have highlight patterns.

3. **Identify gaps**: List any keywords or node types from grammar.js that are missing from highlights.scm.

4. **Add missing patterns** using the capture names already used in highlights.scm:
    - Example group and example keywords (Describe, Context, It, Mock) → `@keyword.function`
    - Focused (`f`) and skipped (`x`) variants → `@keyword.function.focused` / `@keyword.function.skipped`
    - Hook keywords (Before, AfterEach, etc.) → `@keyword.control.hook`
    - When/The/Assert and Path/Set/Dump/Intercept → `@keyword`
    - Evaluation types (call, run, command, script, source) → `@keyword.operator`
    - `should`, `not`, `End` and the `if` in `Skip if` → `@keyword.control`
    - Data and Parameters keywords → `@keyword.function.data`
    - Skip/Pending/Todo → `@keyword.function.pending`
    - Include and `%` directives → `@keyword.directive`

5. **Verify**:
    - Run `npx tree-sitter query queries/highlights.scm test/spec/01.very_simple_spec.sh` and confirm every
      changed keyword is captured.
    - Add or extend assertions in `test/highlight/` for every changed keyword, then run `npx tree-sitter test`
      (it runs the highlight tests too). All tests must pass.
