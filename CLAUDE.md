# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a tree-sitter grammar for ShellSpec (a BDD testing framework for POSIX shell scripts).
The grammar extends tree-sitter-bash to parse ShellSpec-specific constructs like
Describe/Context/It blocks, hooks, and directives.

Behavioral rules live in `.claude/rules/`: generated files, grammar verification, EditorConfig,
the pinned tree-sitter CLI, and grammar naming conventions.

## Development Commands

`mise.toml` pins the toolchain (node, python, rust, the tree-sitter CLI, prek; Go comes from `go.mod`) and
defines every command as a mise task. `mise tasks` lists them; multi-line tasks live in `.mise/tasks/`.
CI runs the same tasks. The `Makefile` is the C-library build/install entry point for packagers, not a
development command runner.

### Setup

```bash
mise install          # pinned toolchain; activate mise in the shell (`mise activate`):
                      # the .claude/hooks scripts call node and prek directly
mise run install      # npm ci: tree-sitter-bash for grammar.js, the Node addon
```

### Core Workflow

```bash
# Generate parser from grammar.js
mise run generate

# Run all tests
mise run test

# Combined generate + test workflow
mise run dev

# Build the parser
mise run build

# Full rebuild (clean + generate)
mise run rebuild
```

### Testing

```bash
# Run all tests
mise run test

# Run one corpus file (extra arguments go to `tree-sitter test`)
mise run test --file-name describe_blocks.txt
mise run test --file-name real_world_patterns.txt

# Parse a specific file to test grammar
mise run parse path/to/file.shellspec

# The CI gates
mise run test:count       # tests plus the minimum test count
mise run test:spec        # every test/spec/*.sh parses cleanly
mise run test:upstream    # the upstream ShellSpec suite parses cleanly
mise run test:bindings    # Node, Python and Go bindings load the grammar
```

### Code Quality

```bash
# Run all linters (MegaLinter)
mise run lint

# Fix markdown issues
prek run markdownlint --all-files

# Run all .pre-commit-config.yaml hooks manually
prek run --all-files
```

Use `prek` for hooks, not `pre-commit`; it reads the same `.pre-commit-config.yaml`.

## Grammar Architecture

### Core Grammar Structure

The grammar extends `tree-sitter-bash` with ShellSpec-specific block, statement, `%` directive
and helper rules. README.md "Grammar Structure" lists every rule.

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

`conflicts` in grammar.js inherits tree-sitter-bash's conflicts through `previous` (it does not re-declare them)
and appends the ShellSpec-specific ones, each with a comment giving its reason.

When adding new rules, minimize new conflicts. Test thoroughly with `mise run test` after grammar changes.

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

- **Minimum tests**: `mise run test:count` (run by `test.yml`) fails when the test count drops below its threshold
- **Coverage**: All ShellSpec constructs must be tested
- **CI validation**: Tests run on every Node version in the `test.yml` matrix

### Test Structure

Corpus tests live in `test/corpus/*.txt`, one file per construct family
(for example `describe_blocks.txt`, `when_the_assert.txt`, `percent_directives.txt`).
The corpus test format is described in CONTRIBUTING.md "Adding Test Cases".

## Code Style

### JavaScript/Grammar Conventions

- Use JSDoc comments for file headers
- Include TypeScript reference for tree-sitter DSL: `/// <reference types="tree-sitter-cli/dsl" />`
  (the `tree-sitter-cli` devDependency is kept for these types only; the CLI binary comes from mise. Its install
  script is denied in `allowScripts`, which npm 11+ honours; npm 10 (node 22) still runs it, harmlessly, since
  mise's CLI is first on `PATH`)
- Use descriptive field names (e.g., `field("description", ...)`)
- Use `prec.right()` for right-associative block structures

## Development Workflow

### Making Grammar Changes

1. **Edit `grammar.js`** - Make your changes
2. **Generate parser** - `mise run generate`
3. **Test changes** - `mise run test`
4. **Lint code** - `mise run lint` (must pass)
5. **Build parser** - `mise run build`

### Adding New ShellSpec Constructs

1. Add the rule to `grammar.js` in the `rules` object
2. Extend `_statement_not_subshell` to include the new rule
3. Create comprehensive test cases in appropriate `test/corpus/*.txt` file
4. Verify no new conflicts introduced
5. Update README.md if adding user-facing features

### Debugging Parse Failures

Use the `/debug-parse-failure` skill.

## CI/CD Pipeline

Workflows live in `.github/workflows/` and run mise tasks through `jdx/mise-action`. `test.yml` regenerates the parser,
fails when committed `src/` differs, and runs the test-count gate and the spec-file and upstream parse checks across its
Node version matrix, then the binding tests; `pr-lint.yml` runs MegaLinter. Disabled linters and the reason for each are listed in `.mega-linter.yml`.
`release.yml` runs release-please on pushes to `main` and, when a release PR merges, verifies the manifest versions
(`.github/scripts/check_versions.py`), builds the npm tarball, Python sdist and crate, and publishes all three through OIDC trusted
publishing after approval on the `release` environment. Its build job also runs on pull requests as a packaging check.

## Important Notes

- The grammar extends bash, so all bash syntax remains valid

## Claude Code Automations

### Hooks (`.claude/hooks/`)

Hook scripts are in `.claude/hooks/`, invoked by `.claude/settings.json`:

- **`pre-edit-guard.sh`** (PreToolUse on Edit/Write/NotebookEdit): Blocks edits to generated files
  (`src/parser.c`, `src/grammar.json`, `src/node-types.json`, `src/tree_sitter/`) and lock files
- **`pre-bash-guard.sh`** (PreToolUse on Bash): Blocks shell commands that write to those generated
  files or run `tree-sitter generate` directly (only `mise run generate` applies `scripts/post-generate.sh`)
- **`post-edit-lint.sh`** (PostToolUse): Auto-regenerates parser after
  `grammar.js` edits, checks EditorConfig compliance, validates corpus format

### Skills and Agents

Project skills live in `.claude/skills/`; the `grammar-validator` agent in `.claude/agents/` runs the tests
and spec-file parsing without editing files.
