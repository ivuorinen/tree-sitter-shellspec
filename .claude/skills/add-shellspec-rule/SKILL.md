---
name: add-shellspec-rule
description: Add a new ShellSpec grammar rule with tests, following project conventions
---

# Add ShellSpec Rule

Follow these steps to add a new ShellSpec construct to the grammar:

## Arguments

- `rule_name` (required): Name of the ShellSpec construct (e.g., "Tag", "Filter")
- `type` (required): One of `block` (needs End terminator), `statement` (single-line), `directive` (% prefixed)

## Steps

1. **Research the construct** in ShellSpec documentation. Understand its syntax, variants, and where it appears in real spec files.

2. **Add the rule to `grammar.js`**:
    - Prefix the rule name with `shellspec_` (e.g., `shellspec_tag_statement`)
    - For blocks: use `prec.right()` with `seq(keyword, ..., repeat($._terminated_statement), "End")`
    - For statements: use `seq(keyword, ...args)`
    - For directives: use `seq("%" + name, ...args)`
    - Use `field()` for named parts (e.g., `field("description", ...)`)

3. **Register in `_statement_not_subshell`**: Add the new rule to the choice array in `_statement_not_subshell`.

4. **Create corpus tests** in the appropriate `test/corpus/*.txt` file:
    - Include basic usage, all variants, and edge cases
    - Follow the corpus format: `===` header, code, `---` separator, S-expression AST
    - Aim for 3-5 test cases minimum

5. **Update `queries/highlights.scm`**: Add highlighting patterns for any new keywords.

6. **Verify**:
    - Run `npm run generate` — check for new conflicts (minimize them)
    - Run `npm test` — all tests must pass
    - Run spec file check: `for f in test/spec/*.sh; do tree-sitter parse "$f" 2>&1 | grep -c ERROR; done`

7. **Update documentation**:
    - Update the rule list in CLAUDE.md
    - Update the ShellSpec Language Support section in README.md

## Grammar Gotchas (from CLAUDE.md)

- Don't use compound keyword tokens (e.g., `"Data:raw"`) — they force tokenizer behavior globally
- `prec(N)` on simple alternatives can beat `prec.right(M)` on blocks at the initial ambiguity point
- `[ ... ]` is `$.test_command` in tree-sitter-bash, not literal bracket tokens
