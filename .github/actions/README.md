# Composite Actions

This directory contains reusable composite actions to reduce duplication across workflows.

## Available Actions

### setup-node

Sets up Node.js with caching and installs dependencies.

**Inputs:**

- `node-version` (optional): Node.js version, defaults to '24'
- `registry-url` (optional): NPM registry URL

**Usage:**

```yaml
- uses: ./.github/actions/setup-node
  with:
    node-version: 22
```

### setup-treesitter

Installs Tree-sitter CLI and generates the grammar.

**Usage:**

```yaml
- uses: ./.github/actions/setup-treesitter
```

### setup-dev

Complete development environment setup (combines setup-node + setup-treesitter).

**Inputs:**

- `node-version` (optional): Node.js version, defaults to '24'
- `registry-url` (optional): NPM registry URL
- `skip-checkout` (optional): Skip repository checkout, defaults to 'false'

**Usage:**

```yaml
- uses: ./.github/actions/setup-dev
  with:
    node-version: 24
    skip-checkout: 'true'
```

### test-grammar

Runs comprehensive grammar tests including parser validation.

**Inputs:**

- `skip-sample-test` (optional): Skip complex sample test, defaults to 'false'

**Usage:**

```yaml
- uses: ./.github/actions/test-grammar
  with:
    skip-sample-test: 'true'
```

### test-coverage

Analyzes test coverage and validates minimum requirements.

**Inputs:**

- `minimum-tests` (optional): Minimum tests required, defaults to '55'

**Outputs:**

- `total-tests`: Total number of tests found
- `passing-tests`: Number of passing tests
- `coverage-percent`: Test coverage percentage

**Usage:**

```yaml
- uses: ./.github/actions/test-coverage
  with:
    minimum-tests: 60
```

## Workflow Usage Examples

### Test Workflow (Simplified)

```yaml
jobs:
  test:
    steps:
      - uses: ./.github/actions/setup-dev
        with:
          node-version: ${{ matrix.node-version }}
      - uses: ./.github/actions/test-grammar
```

### Release Workflow (Simplified)

```yaml
jobs:
  test:
    steps:
      - uses: ./.github/actions/setup-dev
      - uses: ./.github/actions/test-grammar
        with:
          skip-sample-test: 'true'

  lint:
    steps:
      - uses: ./.github/actions/setup-node
      - uses: ivuorinen/actions/pr-lint@latest
```
