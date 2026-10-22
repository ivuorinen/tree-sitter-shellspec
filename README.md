# tree-sitter-shellspec

[![Tree-sitter](https://img.shields.io/badge/tree--sitter-grammar-blue)](https://tree-sitter.github.io/)

A [Tree-sitter](https://tree-sitter.github.io/) grammar for
[ShellSpec](https://shellspec.info/) - a BDD (Behavior Driven Development) testing framework for POSIX shell scripts.

## Overview

This grammar extends the [tree-sitter-bash](https://github.com/tree-sitter/tree-sitter-bash) grammar to parse
ShellSpec's BDD constructs.

It enables syntax highlighting, code navigation, and tooling integration for ShellSpec test files.

### Features

- **ShellSpec syntax support** - Example groups, examples, hooks, When/The/Assert, Data and Parameters, Mock blocks,
  and % directives (unsupported syntax is listed under [Areas for Contribution](#areas-for-contribution))
- **Real-world compatibility** - Both ShellSpec's tutorial examples (`test/spec/`) and its own
  regression suite (the upstream `spec/` and `examples/` trees, parsed in CI) are ERROR-free
- **Bash integration** - Seamlessly handles mixed ShellSpec/bash code
- **Tested** - Corpus tests cover each supported construct, and CI enforces a minimum test count
- **Editor support** - Works with any Tree-sitter compatible editor

## Installation

### Using npm

```bash
npm install @ivuorinen/tree-sitter-shellspec
```

### Using pip

```bash
pip install tree-sitter-shellspec
```

The PyPI package is a source distribution, so installing it compiles the parser and needs a C compiler.

### Using Cargo

```bash
cargo add tree-sitter-shellspec
```

### Using Go

```bash
go get github.com/ivuorinen/tree-sitter-shellspec@latest
```

### Manual Installation

```bash
git clone https://github.com/ivuorinen/tree-sitter-shellspec.git
cd tree-sitter-shellspec
mise install
mise run install
mise run build
```

To build and install the C library instead, run `make` and `make install`.

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

### Hooks

ShellSpec hooks are single-line statements that name the functions (or inline code) to run.

```shellspec
Before 'setup_function'
Before 'setup1' 'setup2'  # Multiple functions
After 'cleanup_function'
Before 'variable=value'    # Inline code

# Available: Before, After, BeforeEach, AfterEach, BeforeAll, AfterAll, BeforeCall, AfterCall, BeforeRun, AfterRun
```

### Utility Blocks

#### Data Blocks

```shellspec
Data            # Data:raw is the same; Data:expand expands variables
  #|item1 value1
  #|item2 value2
End

Data | tr 'a-z' 'A-Z'  # Pipe the lines through a filter
  #|item1
End

Data get_data arg1     # Function output as stdin (takes a filter too)
Data 'inline data'     # String as stdin
Data < input.txt       # File contents as stdin
```

#### Parameters

```shellspec
Parameters
  'param1'
  'param2'
End

Parameters:value 1 2 3  # Single-line values
```

#### Test Control

`Skip`, `Pending` and `Todo` are statements inside an example group or example, not blocks.

```shellspec
Describe 'feature X'
  It 'is not supported on this platform'
    Skip 'not implemented yet'
    When call feature_x
    The status should be success
  End

  It 'is expected to fail for now'
    Pending 'work in progress'
    When call feature_x
    The status should be success
  End

  Todo 'implement feature X'
End
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

### When/The/Assert (Core Assertion DSL)

```shellspec
It 'should calculate correctly'
  When call add 2 3
  The output should eq 5
End

It 'should handle errors'
  When run command invalid_cmd
  The status should be failure
  The stderr should not eq ""
End

It 'should validate the result'
  When call add 2 3
  Assert check_result
End
```

### Mock Blocks

```shellspec
Mock curl
  echo '{"status": "ok"}'
End
```

### % Directives

```shellspec
%const API_URL: "https://api.example.com"

%text
#|line one
#|line two

%text | tr 'a-z' 'A-Z'
#|hello world

%puts "output without newline"
%putsn "output with newline"
%preserve RESULT
%logger "debug info"
```

### Additional Statements

```shellspec
Path helper=./lib/helper.sh
Set 'errexit:on'
Dump
Intercept my_func
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

  reset_state() {
    test_counter=0
    temp_dir=$(mktemp -d)
  }

  verify_cleanup() {
    rm -rf "$temp_dir"
  }

  BeforeEach 'reset_state'
  AfterEach 'verify_cleanup'

  It 'runs with full setup chain'
    When call complex_operation
    The status should be success
  End
End
```

## Development

### Prerequisites

- [mise](https://mise.jdx.dev/) — `mise install` provides the pinned Node.js, Python, Rust, tree-sitter CLI and
  [prek](https://github.com/j178/prek) from `mise.toml`, and Go from `go.mod`
  [activated in your shell](https://mise.jdx.dev/getting-started.html#activate-mise) (`mise activate`), so `node`
  and `prek` are on `PATH` for direct commands
- A C/C++ compiler and `make` — `mise run install` builds the Node binding with node-gyp

### Setup

```bash
git clone https://github.com/ivuorinen/tree-sitter-shellspec.git
cd tree-sitter-shellspec
mise install
mise run install
```

### Available Tasks

Every command is a mise task, and CI runs the same tasks. `mise tasks` lists them all, including the CI
gates (`test:count`, `test:spec`, `test:upstream`, `test:bindings`). The `Makefile` remains the C-library
build and install entry point.

```bash
# Generate parser from grammar
mise run generate

# Run test suite
mise run test

# Build the parser
mise run build

# Development workflow
mise run dev          # Generate + test

# Linting and formatting
mise run lint                    # Check code style
mise run lint:editorconfig       # Check EditorConfig compliance
mise run format                  # Prettier on files changed since main (pretty-quick)
prek run markdownlint --all-files  # Lint and fix markdown

# Utilities
mise run clean        # Clean generated files
mise run rebuild      # Clean + generate
```

### Testing

The test suite includes:

- **Corpus test cases** for every supported ShellSpec construct
- **Real-world patterns** from the official ShellSpec repository
- **Edge cases** and complex nesting scenarios
- **Mixed content** (ShellSpec + bash code)

```bash
# Run all tests
mise run test

# Test specific patterns
mise run test --file-name describe_blocks.txt
mise run test --file-name real_world_patterns.txt
```

### Grammar Structure

The grammar extends tree-sitter-bash with 28 rules organized as follows:

**Block rules:**

- `shellspec_describe_block` - Describe/fDescribe/xDescribe blocks
- `shellspec_context_block` - Context/ExampleGroup blocks
- `shellspec_it_block` - It/Example/Specify blocks
- `shellspec_utility_block` - Parameters blocks
- `shellspec_data_block` - Data blocks with content types
- `shellspec_mock_block` - Mock command blocks

**Statement rules:**

- `shellspec_when_statement` - When call/run statements
- `shellspec_the_statement` - The subject should matcher assertions
- `shellspec_assert_statement` - Assert function assertions
- `shellspec_hook_statement` - Before/After statements
- `shellspec_directive_statement` - Include and conditional Skip
- `shellspec_parameters_value_statement` - Parameters:value single-line values
- `shellspec_path_statement` - Path alias declarations
- `shellspec_set_statement` - Set option directives
- `shellspec_dump_statement` - Dump debugging output
- `shellspec_intercept_statement` - Intercept function calls
- `shellspec_usefd_statement` - UseFD file-descriptor reservations
- `shellspec_todo_statement` - Todo markers
- `shellspec_pending_statement` - Pending markers
- `shellspec_skip_statement` - Skip markers

**Directive rules:**

- `shellspec_text_directive` - %text heredoc-style blocks
- `shellspec_const_directive` - %const variable declarations
- `shellspec_output_directive` - %puts/%putsn/%-/%= output directives
- `shellspec_preserve_directive` - %preserve variable preservation
- `shellspec_logger_directive` - %logger debug output

**Helper rules:**

- `shellspec_subject` - Subject expressions in The statements
- `shellspec_matcher` - Matcher expressions in The statements
- `shellspec_data_line_content` - Content lines in Data blocks

## Editor Integration

The grammar is not yet part of the nvim-treesitter or Emacs grammar registries, so editors need a manual parser
registration. ShellSpec spec files follow the `*_spec.sh` naming pattern.

### Neovim (with nvim-treesitter)

Register the parser (nvim-treesitter `master` API), map spec files to it, then run `:TSInstall shellspec`:

```lua
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.shellspec = {
  install_info = {
    url = "https://github.com/ivuorinen/tree-sitter-shellspec",
    files = { "src/parser.c", "src/scanner.c" },
    branch = "main",
  },
  filetype = "shellspec",
}

vim.filetype.add({ pattern = { [".*_spec%.sh"] = "shellspec" } })
```

Copy `queries/highlights.scm` to `~/.config/nvim/queries/shellspec/highlights.scm`. Its first line, `; inherits: bash`,
applies bash highlighting to the shell code around ShellSpec blocks.

### Emacs (with tree-sitter-mode)

Scope the grammar to spec files with a derived mode:

```elisp
(define-derived-mode shellspec-mode sh-mode "ShellSpec")
(add-to-list 'auto-mode-alist '("_spec\\.sh\\'" . shellspec-mode))
(add-to-list 'tree-sitter-major-mode-language-alist '(shellspec-mode . shellspec))
```

## Contributing

Contributions are welcome! Please see our [contributing guidelines](CONTRIBUTING.md) for details.

### Known Limitations

- **Every binding needs a runtime at ABI 15 or newer.** The generated parser targets
  tree-sitter ABI 15. Older runtimes reject it at `set_language` time, e.g.
  [go-tree-sitter](https://github.com/tree-sitter/go-tree-sitter) `v0.24.0` stops at
  ABI 14. Each binding's declared runtime floor (`go-tree-sitter v0.25.0`,
  `tree-sitter` `0.25` for Node and Python) already enforces this.

### Areas for Contribution

- **Tagging support** - `Describe "name" tag:value` syntax
- **Additional % directives** - `%data`, `%printf`, `%sleep` and other utility directives
- **Advanced subject/matcher semantics** - Ordinal references, compound modifiers in The statements
- **Editor plugins** - Syntax highlighting themes for various editors
- **Performance optimization** - Reduce parse time for large spec files

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

MIT License - see [LICENSE](LICENSE) file for details. Third-party notices are in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Acknowledgments

- [ShellSpec project](https://shellspec.info/) for the excellent BDD testing framework
- [Tree-sitter team](https://tree-sitter.github.io/) for the parsing framework
- [tree-sitter-bash](https://github.com/tree-sitter/tree-sitter-bash) contributors for the base grammar

---

**Star this project** ⭐ if you find it useful for your ShellSpec development workflow!
