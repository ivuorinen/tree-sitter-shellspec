# Suggested Commands

## Development Commands

### NPM Scripts (Preferred)

```bash
# Quick development cycle
npm run dev

# Generate parser from grammar
npm run generate
npm run build

# Run tests
npm test

# Interactive grammar testing
npm run web

# Clean and rebuild
npm run clean
npm run rebuild
```

### Tree-sitter Direct Commands

```bash
# Generate the parser from grammar.js
tree-sitter generate

# Test the grammar against test files
tree-sitter test

# Parse a specific file to debug
tree-sitter parse <file>

# Web UI for testing grammar
tree-sitter web-ui

# Clean generated files
rm -rf src/parser.c src/grammar.json src/node-types.json
```

### Linting and Formatting

```bash
# Comprehensive linting (preferred)
npm run lint

# Specific linters
npm run lint:yaml
npm run lint:markdown

# Run pre-commit hooks manually
npm run precommit

# Direct linter commands
yamllint .
markdownlint . --config .markdownlint.json --fix
shellcheck **/*.sh
```

### Git and Version Control

```bash
# Standard git workflow
git add .
git commit -m "message"
git push

# Pre-commit hooks run automatically on commit
```

## System Commands (Darwin/macOS)

- `ls` - list files
- `find` - find files/directories
- `grep` - search text patterns
- `cd` - change directory
- `pwd` - print working directory
- `which` - locate command

## Node.js/npm Commands

```bash
# Install dependencies
npm install

# Using nvm (available at /Users/ivuorinen/.local/share/nvm/nvm.sh)
nvm use
```

## Test Development

```bash
# Run specific test patterns (if needed)
tree-sitter test --debug

# Parse sample files for debugging
echo "Describe 'test' ... End" | tree-sitter parse
```
