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

4. **Add missing patterns** following the existing conventions in highlights.scm:
    - Block keywords (Describe, Context, It, etc.) → `@keyword`
    - Modifier prefixes (f, x) → `@attribute`
    - Hook keywords (BeforeEach, AfterAll, etc.) → `@keyword`
    - Statement keywords (When, The, Assert, etc.) → `@keyword`
    - Directive keywords (%text, %const, etc.) → `@function.macro`
    - String descriptions → `@string`
    - Matcher/subject words → `@variable.builtin` or `@function.builtin`
    - `End` keyword → `@keyword`

5. **Verify**: Run `tree-sitter test` to ensure highlights don't cause issues.
    Optionally test with `tree-sitter highlight test/spec/*.sh` if available.
