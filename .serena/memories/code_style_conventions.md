# Code Style and Conventions

## EditorConfig Rules

All files follow `.editorconfig` specifications:

- **Charset**: UTF-8
- **Line endings**: LF (Unix style)
- **Indentation**: 2 spaces (no tabs except Makefiles)
- **Max line length**: 160 characters
- **Final newline**: Required
- **Trim trailing whitespace**: Yes (except .md files)

## JavaScript/Grammar Conventions

- Use 2-space indentation
- JSDoc comments for file headers
- TypeScript reference comments for tree-sitter DSL
- Semicolons and consistent formatting
- Descriptive field names in grammar rules

## Grammar Design Patterns

- Use `prec.right(1, seq(...))` for block structures
- Handle conflicts explicitly in the `conflicts` array
- Extend original bash rules with `choice(original, new_rules)`
- Use `field()` for semantic labeling of important parts
- Block patterns: `BlockType description statements End`

## File Organization

- `grammar.js`: Main grammar definition
- `src/`: Generated parser files (don't edit manually)
- Configuration files in root directory
- GitHub workflows in `.github/workflows/`

## Naming Conventions

- Snake_case for grammar rule names
- Descriptive names for block types and fields
- Prefix ShellSpec-specific rules with `shellspec_`
