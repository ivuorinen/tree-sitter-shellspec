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
    - Use `argument($)` for argument slots and `field()` for named parts (e.g., `field("description", argument($))`)

3. **Register in `_statement_not_subshell`**: Add the new rule to the choice array in `_statement_not_subshell`.

4. **Create corpus tests** in the appropriate `test/corpus/*.txt` file. Add at least 3 test cases: basic usage,
    every keyword variant, and one edge case. Follow the corpus format: `===` header, code, `---` separator,
    S-expression AST with field names.

5. **Update `queries/highlights.scm`**: Add highlighting patterns for any new keywords.

6. **Verify**:
    - Run `npm run generate` — check for new conflicts (minimize them)
    - Run `npm test` — all tests must pass
    - Run the spec file check (`--quiet` exits non-zero on ERROR and MISSING nodes):

      ```bash
      for f in test/spec/*.sh; do npx tree-sitter parse --quiet "$f" >/dev/null || echo "parse errors: $f"; done
      ```

7. **Update documentation**:
    - Update the rule count in CLAUDE.md
    - Update "Grammar Support" and the "Grammar Structure" rule list in README.md

## Grammar Gotchas (from CLAUDE.md)

- Use compound keywords such as `Data:raw` only in the alternatives that strictly need them — a compound token
  changes tokenization everywhere the keyword can appear
- `prec(N)` on simple alternatives can beat `prec.right(M)` on blocks at the initial ambiguity point
- `[ ... ]` is `$.test_command` in tree-sitter-bash, not literal bracket tokens
