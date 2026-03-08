# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a tree-sitter grammar for ShellSpec (a BDD testing framework for POSIX shell scripts).
The grammar extends tree-sitter-bash to parse ShellSpec-specific constructs like
Describe/Context/It blocks, hooks, and directives.

## Development Commands

### Core Workflow

```bash
# Generate parser from grammar.js
npm run generate

# Run all tests (must be 100% passing)
npm test

# Combined generate + test workflow
npm run dev

# Watch mode for active development
npm run dev:watch

# Build the parser
npm run build

# Full rebuild (clean + generate + build)
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

The grammar extends `tree-sitter-bash` with 27 ShellSpec-specific rules:

**Block rules** (require `End` terminator):

1. `shellspec_describe_block` - Describe/fDescribe/xDescribe blocks
2. `shellspec_context_block` - Context/ExampleGroup blocks (with f/x variants)
3. `shellspec_it_block` - It/Example/Specify blocks (with f/x variants)
4. `shellspec_hook_block` - BeforeEach/AfterEach/BeforeAll/AfterAll/BeforeCall/AfterCall/BeforeRun/AfterRun
5. `shellspec_utility_block` - Parameters blocks (with :block/:value/:matrix/:dynamic variants)
6. `shellspec_data_block` - Data blocks with :raw/:expand modifiers, #| lines, pipe filters
7. `shellspec_mock_block` - Mock command blocks

**Statement rules** (single-line, no `End`):

1. `shellspec_hook_statement` - Before/After/BeforeEach/AfterEach/BeforeAll/AfterAll/BeforeCall/AfterCall/BeforeRun/AfterRun statements
2. `shellspec_directive_statement` - Include and conditional Skip if
3. `shellspec_when_statement` - When call/run evaluation statements
4. `shellspec_the_statement` - The subject should matcher expectations
5. `shellspec_assert_statement` - Assert function calls
6. `shellspec_path_statement` - Path/File/Dir statements
7. `shellspec_set_statement` - Set option statements
8. `shellspec_dump_statement` - Dump standalone
9. `shellspec_intercept_statement` - Intercept statements
10. `shellspec_todo_statement` - Todo standalone
11. `shellspec_pending_statement` - Pending standalone
12. `shellspec_skip_statement` - Skip standalone

**Directive rules** (% prefixed):

1. `shellspec_text_directive` - %text/%text:raw/%text:expand directives
2. `shellspec_const_directive` - %const and % directives
3. `shellspec_output_directive` - %puts/%putsn/%-/%= directives
4. `shellspec_preserve_directive` - %preserve directive
5. `shellspec_logger_directive` - %logger directive

**Helper rules** (used internally by other rules):

1. `shellspec_subject` - Subject words in The statements
2. `shellspec_matcher` - Matcher words in The statements
3. `shellspec_data_line_content` - Content after #| prefix

### Grammar Pattern

All blocks follow this structure:

```javascript
prec.right(1, seq(
  choice("BlockType", "fBlockType", "xBlockType"),
  field("description", choice($.string, $.raw_string, $.word)),
  repeat($._terminated_statement),
  "End"
))
```

### Conflict Management

The grammar has 6 total conflicts (minimized for performance):

- 3 inherited from bash grammar
- 3 ShellSpec-specific: `[$.command_name, $.shellspec_data_block]`, `[$.command_name, $.shellspec_hook_statement]`, and `[$.shellspec_hook_block]`

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
- **Verify spec files after grammar changes**: Corpus tests can pass while real spec files still
  have parse errors. Always run
  `for f in test/spec/*.sh; do tree-sitter parse "$f" 2>&1 | grep -c ERROR; done` after changes.

## Testing Requirements

### Quality Gates

- **Minimum tests**: 96 (currently 128 tests passing)
- **Success rate**: Must be 100% (no failing tests allowed)
- **Coverage**: All ShellSpec constructs must be tested
- **CI validation**: Tests run on Node 22 and 24

### Test Structure

Tests are organized in `test/corpus/`:

- `describe_blocks.txt` - Describe block variants
- `context_blocks.txt` - Context/ExampleGroup blocks
- `it_blocks.txt` - It/Example/Specify blocks
- `hook_blocks.txt` - Hook blocks and statements
- `utility_blocks.txt` - Parameters/Skip/Pending/Todo/Data blocks
- `nested_structures.txt` - Complex nesting scenarios
- `real_world_patterns.txt` - Official ShellSpec examples
- `when_the_assert.txt` - When/The/Assert evaluation and expectation statements
- `mock_blocks.txt` - Mock command blocks
- `shellspec_statements.txt` - Path/Set/Dump/Intercept statements
- `parameters_variants.txt` - Parameters :block/:value/:matrix/:dynamic variants
- `pending_skip_statements.txt` - Pending/Skip/Todo standalone statements
- `percent_directives.txt` - %text/%const/%puts/%preserve/%logger directives

### Test Format

Each test follows tree-sitter's corpus format:

```text
==================
Test name
==================

ShellSpec code here

---

(program
  (expected AST structure))
```

## Code Style

### EditorConfig Rules (MUST follow)

- **Indentation**: 2 spaces (no tabs, except Makefiles)
- **Line endings**: LF (Unix)
- **Charset**: UTF-8
- **Max line length**: 160 characters
- **Trailing whitespace**: Remove (except .md files)
- **Final newline**: Required

### JavaScript/Grammar Conventions

- Use JSDoc comments for file headers
- Include TypeScript reference for tree-sitter DSL: `/// <reference types="tree-sitter-cli/dsl" />`
- Prefix ShellSpec rules with `shellspec_`
- Use descriptive field names (e.g., `field("description", ...)`)
- Use `prec.right()` for right-associative block structures

## Development Workflow

### Making Grammar Changes

1. **Edit `grammar.js`** - Make your changes
2. **Generate parser** - `npm run generate`
3. **Test changes** - `npm test` (must be 100% passing)
4. **Lint code** - `npm run lint` (must pass)
5. **Build parser** - `npm run build`

### Adding New ShellSpec Constructs

1. Add the rule to `grammar.js` in the `rules` object
2. Extend `_statement_not_subshell` to include the new rule
3. Create comprehensive test cases in appropriate `test/corpus/*.txt` file
4. Verify no new conflicts introduced
5. Update README.md if adding user-facing features

### Debugging Parse Failures

```bash
# Parse a file and see where it fails
npx tree-sitter parse path/to/failing.shellspec

# View detailed AST
npx tree-sitter parse path/to/file.shellspec --debug

# Open web UI for interactive debugging
npm run web
```

## CI/CD Pipeline

### GitHub Actions

- **test.yml**: Runs tests on Node 22 and 24, validates parser generation
- **lint**: MegaLinter code quality checks
- **coverage**: Validates minimum 96 tests passing
- All checks must pass for PR merge

### Disabled Linters

The following linters are intentionally disabled in `.mega-linter.yml`:

- C_CLANG_FORMAT (generated code may not follow style)
- JSON_PRETTIER (causes problems)
- SPELL_LYCHEE/CSPELL (too many false positives)
- JAVASCRIPT_PRETTIER (not using Prettier)

## ShellSpec Language Support

### Block Types Supported

- **Describe**: `Describe`, `fDescribe`, `xDescribe`
- **Context**: `Context`, `ExampleGroup`, `fContext`, `xContext`
- **It**: `It`, `Example`, `Specify`, `fIt`, `fExample`, `fSpecify`, `xIt`, `xExample`, `xSpecify`
- **Hooks**: `BeforeEach`, `AfterEach`, `BeforeAll`, `AfterAll`, `BeforeCall`, `AfterCall`, `BeforeRun`, `AfterRun`
- **Utility**: `Parameters` (with `:block`/`:value`/`:matrix`/`:dynamic`), `Data` (with `:raw`/`:expand`)
- **Mock**: `Mock` command blocks

### Statement Types

- **Hook statements**: `Before func1 func2`, `After cleanup`, `BeforeRun setup`, `AfterRun cleanup`, etc.
- **Include**: `Include ./helper.sh`
- **Conditional Skip**: `Skip if "reason" condition` (supports `[ ... ]` test expressions)
- **When**: `When call func`, `When run command cmd`
- **The**: `The output should equal "expected"`
- **Assert**: `Assert function args`
- **Path/File/Dir**: `Path name="value"`, `File name="value"`, `Dir name="value"`
- **Set**: `Set option:value`
- **Dump**: `Dump` standalone
- **Intercept**: `Intercept name`
- **Todo/Pending/Skip**: Standalone statement variants

### Directive Types

- **%text**: `%text`, `%text:raw`, `%text:expand` with `#|` content lines
- **%const / %**: `%const NAME "value"`, `% NAME "value"`
- **%puts / %putsn / %- / %=**: Output directives
- **%preserve**: `%preserve VAR`
- **%logger**: `%logger "message"`

### Known Limitations

- `%` standalone shorthand may conflict with bash job control in edge cases
- `%text` with multiple `#|` lines may not work outside of block contexts
- Tagging (`Describe 'name' tag:value`) and `%` directives beyond the supported set
  (`%text`, `%const`, `%puts`, `%putsn`, `%preserve`, `%logger`) are not yet supported
- These are documented in README.md "Areas for Contribution"

## Important Notes

- **Never modify generated files** in `src/` directory (parser.c, grammar.json, node-types.json)
- **Always run tests** after grammar changes - failing tests block PRs
- **Follow EditorConfig** rules strictly - violations are blocking errors
- **Maintain 100% test pass rate** - CI enforces minimum 96 tests passing
- **Use system `tree-sitter`** for CLI commands — the `npx tree-sitter` binary may not work; fall back to the system-installed tree-sitter CLI
- The grammar extends bash, so all bash syntax remains valid

## Claude Code Automations

### Hooks (`.claude/hooks/`)

Hook scripts are in `.claude/hooks/`, invoked by `.claude/settings.json`:

- **`pre-edit-guard.sh`** (PreToolUse): Blocks edits to generated files
  (`src/parser.c`, `src/grammar.json`, `src/node-types.json`) and lock files
- **`post-edit-lint.sh`** (PostToolUse): Auto-regenerates parser after
  `grammar.js` edits, checks EditorConfig compliance, validates corpus format

### Skills (`.claude/skills/`)

| Skill | Invocation | Description |
| ----- | ---------- | ----------- |
| `/generate-and-test` | User | Generate parser, run tests, verify spec files |
| `/add-shellspec-rule` | User | Guided workflow to add a new grammar rule with tests |
| `/debug-parse-failure` | User | Diagnose ERROR nodes and trace to grammar rules |
| `/update-highlights` | User | Sync highlights.scm with all grammar keywords |
| `/validate-release` | User only | Full pre-release validation checklist |

### Agents (`.claude/agents/`)

- **grammar-validator**: Runs tests and spec file parsing, reports results without editing
