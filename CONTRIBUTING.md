# Contributing to tree-sitter-shellspec

Thank you for your interest in contributing to tree-sitter-shellspec! This document provides guidelines and information for contributors.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Grammar Development](#grammar-development)
- [Testing](#testing)
- [Code Style](#code-style)
- [Submitting Changes](#submitting-changes)
- [Releasing](#releasing)
- [Reporting Issues](#reporting-issues)
- [Areas for Contribution](#areas-for-contribution)

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (v22 or later)
- Tree-sitter CLI (provided via devDependency) — use `npx tree-sitter <cmd>`
- A C/C++ compiler, `make` and Python 3 — `npm install` builds the Node binding with node-gyp
- [Git](https://git-scm.com/)
- Basic knowledge of [Tree-sitter grammars](https://tree-sitter.github.io/tree-sitter/creating-parsers)
- Familiarity with [ShellSpec](https://shellspec.info/) syntax

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:

```bash
git clone https://github.com/YOUR_USERNAME/tree-sitter-shellspec.git
cd tree-sitter-shellspec
```

1. Add the upstream repository:

```bash
git remote add upstream https://github.com/ivuorinen/tree-sitter-shellspec.git
```

## Development Setup

1. **Install dependencies:**

```bash
npm install
```

1. **Generate the grammar:**

```bash
npm run generate
```

1. **Run tests:**

```bash
npm test
```

1. **Build the parser:**

```bash
npm run build
```

### Development Workflow

Use the provided npm scripts for common development tasks:

```bash
# Development loop (generate + test)
npm run dev

# Clean and regenerate the parser
npm run rebuild

# Check code style
npm run lint
npm run lint:markdown
```

## Grammar Development

### Understanding the Grammar Structure

The grammar in `grammar.js` extends [tree-sitter-bash](https://github.com/tree-sitter/tree-sitter-bash) and adds ShellSpec-specific constructs:

- **Block types**: Describe, Context, ExampleGroup, It, Example, Specify (with focused/skipped variants), Mock
- **Hook statements**: Before, After, BeforeEach, AfterEach, BeforeAll, AfterAll, BeforeCall, AfterCall, BeforeRun, AfterRun
- **Utility blocks**: Parameters and Data blocks; `Parameters:value` single-line values
- **Statement types**: When/The/Assert, Skip/Pending/Todo, Include, Path/File/Dir, Set, Dump, Intercept
- **Directives**: Conditional `Skip if`, `%text`, `%const`, `%puts`/`%putsn`, `%preserve`, `%logger`

### Making Grammar Changes

1. **Edit `grammar.js`** with your changes
2. **Generate the parser:** `npm run generate`
3. **Test your changes:** `npm test`
4. **Add test cases** in `test/corpus/` for new functionality
5. **Update documentation** if needed

### Grammar Development Guidelines

- **Follow existing patterns** - Look at similar rules in the grammar
- **Use appropriate precedence** - Avoid conflicts with bash grammar
- **Test extensively** - Add comprehensive test cases
- **Document new syntax** - Update README.md with examples
- **Consider real-world usage** - Test with actual ShellSpec files

### Adding Test Cases

Create or update files in `test/corpus/`:

```text
================================================================================
Test Name
================================================================================

ShellSpec code here

--------------------------------------------------------------------------------

(expected_parse_tree
  structure_here)
```

**Test Organization:**

- `describe_blocks.txt` - Describe block variations
- `context_blocks.txt` - Context block variations
- `it_blocks.txt` - It/Example/Specify blocks
- `hook_blocks.txt` - Hook statements
- `utility_blocks.txt` - Data/Parameters/Skip/etc.
- `nested_structures.txt` - Complex nested patterns
- `real_world_patterns.txt` - Patterns from official examples

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Test specific patterns
npx tree-sitter test -i "describe_blocks"
npx tree-sitter test -i "real_world_patterns"

# Test with debug output
npx tree-sitter test --debug
```

### Test Coverage Requirements

- **All new grammar rules** must have test coverage
- **Existing tests** must continue to pass
- **Real-world examples** should be included when possible
- **Edge cases** should be tested

### Testing New Functionality

1. Add test cases before implementing
2. Run tests to see them fail
3. Implement the grammar changes
4. Run tests until they pass
5. Add additional edge case tests

## Code Style

### Grammar Style

- Use **consistent indentation** (2 spaces)
- Add **descriptive comments** for complex rules
- Use **meaningful rule names** (e.g., `shellspec_describe_block`)
- Group **related rules** together
- Follow **tree-sitter conventions**

### JavaScript Style

- Follow **Prettier** formatting
- Use **const** for immutable values
- Add **JSDoc comments** for exported functions
- Follow **Node.js best practices**

### Documentation Style

- Use **clear, concise language**
- Provide **practical examples**
- Keep **README.md** up to date
- Include **code comments** where needed

## Submitting Changes

### Before Submitting

1. **Ensure all tests pass:** `npm test`
2. **Check code style:** `npm run lint && npm run lint:editorconfig && npm run lint:markdown`
3. **Update documentation** if needed
4. **Test with real ShellSpec files** when possible
5. **Run the full development cycle:** `npm run rebuild`

### Pull Request Process

1. **Create a feature branch:**

```bash
git checkout -b feature/your-feature-name
```

1. **Make your changes** following the guidelines above

2. **Commit with clear messages:**

```bash
git commit -m "feat: add support for Data block modifiers

- Add :raw and :expand modifier support
- Update test cases for new syntax
- Add documentation examples"
```

1. **Push to your fork:**

```bash
git push origin feature/your-feature-name
```

1. **Create a Pull Request** with:

- Clear description of changes
- References to related issues
- Test results and coverage
- Breaking change notes (if any)

### Commit Message Guidelines

Use [Conventional Commits](https://conventionalcommits.org/):

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test additions or changes
- `refactor:` - Code refactoring
- `ci:` - CI workflow changes
- `build:` - Build tooling and parser generation changes
- `chore:` - Maintenance tasks
- `deps:` - Runtime dependency updates (these release; see [Releasing](#releasing))

## Releasing

Releases are automated with [release-please](https://github.com/googleapis/release-please).

1. Merging to `main` updates an open release PR. It bumps the version in every manifest and adds the new entries to `CHANGELOG.md`.
    `feat`, `fix`, `perf` and `deps` commits appear in the changelog and cause a release; other types do not.
2. Merging the release PR tags `vX.Y.Z` and creates the GitHub release. The tag is the release for the Go module and the Swift package.
3. The release workflow then waits for approval on the `release` environment. After approval it publishes to npm, PyPI and
    crates.io with trusted publishing (OIDC). No registry token is stored anywhere.

Runtime dependency updates use the `deps:` type (`deps!:` for a major), so they release and appear under "Dependencies".
Renovate applies this prefix itself; use it for hand-made runtime dependency changes too.

### One-time setup

Done once, before the first release PR is merged:

1. Create a GitHub App installed on this repository only, with `Contents: write` and `Pull requests: write`. In the
    `release-please` environment (deployments from `main` only), store its client ID as the variable `RELEASE_APP_CLIENT_ID`
    and its private key as the secret `RELEASE_APP_PRIVATE_KEY`.
2. Create the `release` environment with the maintainer as a required reviewer and deployments from `main` only.
3. From a clean checkout, publish `0.1.0` by hand: `npm publish --access public` and `cargo publish`.
4. Add trusted publishers for repository `ivuorinen/tree-sitter-shellspec`, workflow `release.yml`, environment `release`:
    on npm and crates.io in the package settings, on PyPI as a pending publisher for `tree-sitter-shellspec`.
5. On npm, set publishing access to "Require two-factor authentication and disallow tokens".
6. Tag the commit from step 3 as `v0.1.0`, push the tag, and create a GitHub release for it. release-please counts versions from it.

## Reporting Issues

### Bug Reports

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- ShellSpec code that doesn't parse correctly
- Expected vs actual behavior
- Environment information
- Tree-sitter parse output (if available)

### Feature Requests

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md) and include:

- ShellSpec syntax example
- Use case description
- Current behavior
- Links to ShellSpec documentation

### Grammar Issues

Use the [Grammar Issue template](.github/ISSUE_TEMPLATE/grammar_issue.md) for:

- Parsing errors
- Grammar conflicts
- Performance problems
- Integration issues

## Areas for Contribution

### High Priority

1. **Unsupported ShellSpec syntax**

- Tagging (`Describe "name" tag:value`)
- Additional `%` directives such as `%data`
- Concatenated arguments such as `--opt=$value` outside `Include` paths

1. **Performance optimization**

- Reduce parser conflicts
- Optimize grammar rules
- Improve parsing speed

### Medium Priority

1. **Editor integration**

- Neovim configuration examples
- VS Code extension support
- Emacs tree-sitter integration

1. **Tooling improvements**

- Syntax highlighting themes
- Language server features
- Code formatting rules

1. **Documentation**

- Usage tutorials
- Grammar development guide
- Editor setup instructions

### Low Priority

1. **Advanced features**

- ShellSpec custom matchers
- Configuration file parsing
- Metadata extraction

## Development Resources

### Useful Links

- [Tree-sitter Documentation](https://tree-sitter.github.io/tree-sitter/)
- [ShellSpec Documentation](https://shellspec.info/)
- [tree-sitter-bash Grammar](https://github.com/tree-sitter/tree-sitter-bash)
- [Tree-sitter Playground](https://tree-sitter.github.io/tree-sitter/playground)

### Learning Resources

- [Creating Tree-sitter Parsers](https://tree-sitter.github.io/tree-sitter/creating-parsers)
- [Grammar DSL Reference](https://tree-sitter.github.io/tree-sitter/creating-parsers#the-grammar-dsl)
- [Tree-sitter Conflicts](https://tree-sitter.github.io/tree-sitter/creating-parsers#conflicts)

## Getting Help

- **GitHub Discussions**: For questions and general discussion
- **Issues**: For bugs and feature requests
- **Pull Requests**: For code review and collaboration

## License

By contributing to tree-sitter-shellspec, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to tree-sitter-shellspec! 🎉
