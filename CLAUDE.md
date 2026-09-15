# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a tree-sitter grammar for ShellSpec (a BDD testing framework for POSIX shell scripts).
The grammar extends tree-sitter-bash to parse ShellSpec-specific constructs like
Describe/Context/It blocks, hooks, and directives.

Behavioral rules live in `.claude/rules/`: generated files, grammar verification, EditorConfig,
the pinned tree-sitter CLI, and grammar naming conventions.

## Development Commands

### Core Workflow

```bash
# Generate parser from grammar.js
npm run generate

# Run all tests
npm test

# Combined generate + test workflow
npm run dev

# Build the parser
npm run build

# Full rebuild (clean + generate)
npm run rebuild
```

### Testing

```bash
# Run all tests
npm test

# Test specific patterns (use tree-sitter CLI via npx)
npx tree-sitter test -i "describe_blocks"
npx tree-sitter test -i "real_world_patterns"

# Parse a specific file to test grammar
npx tree-sitter parse path/to/file.shellspec
```

### Code Quality

```bash
# Run all linters (MegaLinter)
npm run lint

# Fix markdown issues
npm run lint:markdown

# Run pre-commit hooks manually
npm run precommit
```

## Grammar Architecture

### Core Grammar Structure

The grammar extends `tree-sitter-bash` with 27 ShellSpec-specific rules (block, statement, `%` directive
and helper rules). README.md "Grammar Structure" lists every rule.

### Grammar Pattern

All blocks follow this structure. `argument($)` is the JS helper in grammar.js shared by every
argument slot (words, strings, numbers, `$var`, `${var}`, `$(cmd)`):

```javascript
prec.right(1, seq(
  choice("BlockType", "fBlockType", "xBlockType"),
  field("description", argument($)),
  repeat($._terminated_statement),
  "End"
))
```

### Conflict Management

The generated grammar has 7 conflicts:

- 6 inherited from tree-sitter-bash through `previous` (grammar.js does not re-declare them)
- 1 ShellSpec-specific: `[$.shellspec_utility_block]` (Parameters blocks enter the shared statement repeat directly after the keyword)

When adding new rules, minimize new conflicts. Test thoroughly with `npm test` after grammar changes.

### Grammar Gotchas

- **Compound keyword tokenization**: Adding `"Data:raw"` as a single keyword token in ANY variant
  forces the tokenizer to prefer it everywhere, breaking variants that expect `"Data"` `":"` `"raw"`
  as separate tokens. Only use compound keywords in variants where they're strictly required
  (e.g., pipe+#| variant).
- **Precedence at shift/reduce boundaries**: `prec(N)` on a simple alternative (e.g., `Data arg`)
  applies at reduce time. A block alternative's higher `prec.right(M)` only takes effect when `End`
  is matched. Adding even `prec(1)` to a simple variant can cause it to win over `prec.right(4)`
  blocks at the initial ambiguity point.
- **Bash test expressions**: `[ ... ]` parses as `$.test_command` in tree-sitter-bash, not as
  literal `[`/`]` tokens. Use `$.test_command` when grammar rules need to accept bracket
  test expressions.

### Known Limitations

- `%` standalone shorthand may conflict with bash job control in edge cases
- `%text` with multiple `#|` lines may not work outside of block contexts
- Tagging (`Describe 'name' tag:value`) and `%` directives beyond the supported set
  (`%text`, `%const`, `%puts`, `%putsn`, `%preserve`, `%logger`) are not yet supported
- These are documented in README.md "Areas for Contribution"

Supported ShellSpec syntax is documented in README.md "Grammar Support".

## Testing Requirements

### Quality Gates

- **Minimum tests**: 115, enforced by the CI coverage job (currently 134 tests passing)
- **Coverage**: All ShellSpec constructs must be tested
- **CI validation**: Tests run on Node 22 and 24

### Test Structure

Corpus tests live in `test/corpus/*.txt`, one file per construct family
(for example `describe_blocks.txt`, `when_the_assert.txt`, `percent_directives.txt`).
The corpus test format is described in CONTRIBUTING.md "Adding Test Cases".

## Code Style

### JavaScript/Grammar Conventions

- Use JSDoc comments for file headers
- Include TypeScript reference for tree-sitter DSL: `/// <reference types="tree-sitter-cli/dsl" />`
- Use descriptive field names (e.g., `field("description", ...)`)
- Use `prec.right()` for right-associative block structures

## Development Workflow

### Making Grammar Changes

1. **Edit `grammar.js`** - Make your changes
2. **Generate parser** - `npm run generate`
3. **Test changes** - `npm test`
4. **Lint code** - `npm run lint` (must pass)
5. **Build parser** - `npm run build`

### Adding New ShellSpec Constructs

1. Add the rule to `grammar.js` in the `rules` object
2. Extend `_statement_not_subshell` to include the new rule
3. Create comprehensive test cases in appropriate `test/corpus/*.txt` file
4. Verify no new conflicts introduced
5. Update README.md if adding user-facing features

### Debugging Parse Failures

Use the `/debug-parse-failure` skill.

## CI/CD Pipeline

Workflows live in `.github/workflows/`. `test.yml` regenerates the parser, fails when committed `src/` differs,
and runs the test suite on Node 22 and 24, the spec-file parse check and the coverage gate; `pr-lint.yml` runs
MegaLinter. Disabled linters and the reason for each are listed in `.mega-linter.yml`.

## Important Notes

- The grammar extends bash, so all bash syntax remains valid

## Claude Code Automations

### Hooks (`.claude/hooks/`)

Hook scripts are in `.claude/hooks/`, invoked by `.claude/settings.json`:

- **`pre-edit-guard.sh`** (PreToolUse on Edit/Write/NotebookEdit): Blocks edits to generated files
  (`src/parser.c`, `src/grammar.json`, `src/node-types.json`, `src/tree_sitter/`) and lock files
- **`pre-bash-guard.sh`** (PreToolUse on Bash): Blocks shell commands that write to those generated
  files or run a global `tree-sitter generate`
- **`post-edit-lint.sh`** (PostToolUse): Auto-regenerates parser after
  `grammar.js` edits, checks EditorConfig compliance, validates corpus format

### Skills and Agents

Project skills live in `.claude/skills/`; the `grammar-validator` agent in `.claude/agents/` runs the tests
and spec-file parsing without editing files.
