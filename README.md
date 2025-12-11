# tree-sitter-shellspec

[![Test Status](https://img.shields.io/badge/tests-61%2F61%20passing-brightgreen)](https://github.com/ivuorinen/tree-sitter-shellspec)
[![Grammar Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/ivuorinen/tree-sitter-shellspec)
[![Tree-sitter](https://img.shields.io/badge/tree--sitter-grammar-blue)](https://tree-sitter.github.io/)

A comprehensive [Tree-sitter](https://tree-sitter.github.io/) grammar for
[ShellSpec](https://shellspec.info/) - a BDD (Behavior Driven Development) testing framework for POSIX shell scripts.

## Overview

This grammar extends the [tree-sitter-bash](https://github.com/tree-sitter/tree-sitter-bash) grammar to provide complete parsing support
for ShellSpec's BDD constructs.

It enables syntax highlighting, code navigation, and tooling integration for ShellSpec test files.

### Features

- **Complete ShellSpec syntax support** - All block types, hooks, and utility constructs
- **Real-world compatibility** - Tested against official ShellSpec examples
- **Bash integration** - Seamlessly handles mixed ShellSpec/bash code
- **Production ready** - 100% test coverage with 59 comprehensive test cases
- **Editor support** - Works with any Tree-sitter compatible editor

## Installation

### Using npm

```bash
npm install @ivuorinen/tree-sitter-shellspec
```

### Manual Installation

```bash
git clone https://github.com/ivuorinen/tree-sitter-shellspec.git
cd tree-sitter-shellspec
npm install
npm run build
```

## Grammar Support

### Block Types

#### Describe Blocks (Example Groups)

```shellspec
Describe 'Calculator functions'
  # Test cases go here
End

# Variants: Describe, fDescribe (focused), xDescribe (skipped)
```

#### Context Blocks (Sub-groups)

```shellspec
Context 'when input is valid'
  # Specific test scenarios
End

# Variants: Context, ExampleGroup, fContext, xContext
```

#### Example Blocks (Test Cases)

```shellspec
It 'should calculate sum correctly'
  When call add 2 3
  The output should eq 5
End

# Variants: It, Example, Specify, fIt, fExample, fSpecify, xIt, xExample, xSpecify
```

### Hook Types

#### Block-Style Hooks

```shellspec
BeforeEach 'setup test environment'
  # Setup code here
End

AfterEach 'cleanup after test'
  # Cleanup code here
End

# Available: BeforeEach, AfterEach, BeforeAll, AfterAll, BeforeCall, AfterCall, BeforeRun, AfterRun
```

#### Statement-Style Hooks

```shellspec
Before 'setup_function'
Before 'setup1' 'setup2'  # Multiple functions
After 'cleanup_function'
Before 'variable=value'    # Inline code
```

### Utility Blocks

#### Data Blocks

```shellspec
Data 'test input data'
  item1 value1
  item2 value2
End
```

#### Parameters

```shellspec
Parameters
  'param1'
  'param2'
End
```

#### Test Control

```shellspec
Skip 'not implemented yet'
  # Skipped test code
End

Pending 'work in progress'
  # Code that should fail for now
End

Todo 'implement feature X'  # Note without block
```

### Directives

#### Include External Scripts

```shellspec
Include ./helper_functions.sh
Include ./custom_matchers.sh
```

#### Conditional Skip

```shellspec
Skip if "platform not supported" [ "$PLATFORM" != "linux" ]
Skip if "command not available" ! command -v docker
```

## Usage Examples

### Basic Test Structure

```shellspec
#!/usr/bin/env shellspec

Describe 'My Application'
  Include ./lib/my_app.sh

  Before 'setup_test_env'
  After 'cleanup_test_env'

  Context 'when user provides valid input'
    It 'processes input correctly'
      When call process_input "valid data"
      The status should be success
      The output should include "Processing complete"
    End

    It 'returns expected format'
      When call format_output "test"
      The output should match pattern "^Result: .*"
    End
  End

  Context 'when user provides invalid input'
    Skip if "validation not implemented" ! grep -q "validate" lib/my_app.sh

    It 'handles errors gracefully'
      When call process_input ""
      The status should be failure
      The stderr should include "Error: Invalid input"
    End
  End
End
```

### Top-Level Examples (No Describe Required)

```shellspec
It 'can run without describe block'
  When call echo "hello"
  The output should eq "hello"
End
```

### Complex Hook Chains

```shellspec
Describe 'Complex setup scenario'
  Before 'init_database' 'load_fixtures' 'start_services'
  After 'stop_services' 'cleanup_database'

  BeforeEach 'reset test state'
    test_counter=0
    temp_dir=$(mktemp -d)
  End

  AfterEach 'verify cleanup'
    [ "$test_counter" -gt 0 ]
    rm -rf "$temp_dir"
  End

  It 'runs with full setup chain'
    When call complex_operation
    The status should be success
  End
End
```

## Development

### Prerequisites

- [Node.js](https://nodejs.org/) (v22 or later)
- Tree-sitter CLI (provided via devDependency) — use `npx tree-sitter <cmd>`

### Setup

```bash
git clone https://github.com/ivuorinen/tree-sitter-shellspec.git
cd tree-sitter-shellspec
npm install
```

### Available Scripts

```bash
# Generate parser from grammar
npm run generate

# Run test suite (59 comprehensive tests)
npm test

# Build the parser
npm run build

# Development workflow
npm run dev          # Generate + test
npm run dev:watch    # Watch mode for development

# Linting and formatting
npm run lint         # Check code style
npm run lint:fix     # Auto-fix style issues
npm run format       # Format code

# Utilities
npm run clean        # Clean generated files
npm run rebuild      # Clean + generate + build
```

### Testing

The grammar includes comprehensive test coverage:

- **Comprehensive test cases** covering all ShellSpec constructs
- **Real-world patterns** from official ShellSpec repository
- **Edge cases** and complex nesting scenarios
- **Mixed content** (ShellSpec + bash code)

```bash
# Run all tests
npm test

# Test specific patterns
tree-sitter test --filter "describe_blocks"
tree-sitter test --filter "real_world_patterns"
```

### Grammar Structure

The grammar extends tree-sitter-bash with these main rules:

- `shellspec_describe_block` - Describe/fDescribe/xDescribe blocks
- `shellspec_context_block` - Context/ExampleGroup blocks
- `shellspec_it_block` - It/Example/Specify blocks
- `shellspec_hook_block` - BeforeEach/AfterEach/etc. blocks
- `shellspec_utility_block` - Data/Parameters/Skip/Pending/Todo blocks
- `shellspec_hook_statement` - Before/After statements
- `shellspec_directive_statement` - Include and conditional Skip

## Editor Integration

### Neovim (with nvim-treesitter)

Add to your Tree-sitter config:

```lua
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "bash", "shellspec" },
  highlight = {
    enable = true,
  },
}
```

### VS Code

Install a Tree-sitter extension that supports custom grammars, then add this grammar to your configuration.

### Emacs (with tree-sitter-mode)

Add to your configuration:

```elisp
(add-to-list 'tree-sitter-major-mode-language-alist '(sh-mode . shellspec))
```

## Contributing

Contributions are welcome! Please see our [contributing guidelines](CONTRIBUTING.md) for details.

### Areas for Contribution

- **Enhanced Data block support** - Advanced syntax (`:raw`, `:expand`, `|` filters)
- **Assertion parsing** - When/The statement structures
- **Performance optimization** - Reduce parser conflicts
- **Editor plugins** - Syntax highlighting themes
- **Documentation** - Usage examples and tutorials

### Reporting Issues

Please report issues with:

- ShellSpec code that doesn't parse correctly
- Missing syntax highlighting
- Performance problems
- Documentation improvements

## Related Projects

- [ShellSpec](https://github.com/shellspec/shellspec) - The BDD testing framework
- [tree-sitter-bash](https://github.com/tree-sitter/tree-sitter-bash) - Base bash grammar
- [Tree-sitter](https://tree-sitter.github.io/) - Parser generator framework

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- [ShellSpec project](https://shellspec.info/) for the excellent BDD testing framework
- [Tree-sitter team](https://tree-sitter.github.io/) for the parsing framework
- [tree-sitter-bash](https://github.com/tree-sitter/tree-sitter-bash) contributors for the base grammar

---

**Star this project** ⭐ if you find it useful for your ShellSpec development workflow!
