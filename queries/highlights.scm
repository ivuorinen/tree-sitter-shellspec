; ShellSpec Syntax Highlighting
; Extends tree-sitter-bash highlighting

; Block keywords (BDD test structure)
[
  "Describe"
  "Context"
  "ExampleGroup"
  "It"
  "Example"
  "Specify"
] @keyword.function

; Focused blocks (for running specific tests)
[
  "fDescribe"
  "fContext"
  "fIt"
  "fExample"
  "fSpecify"
] @keyword.function.focused

; Skipped blocks (for temporarily disabling tests)
[
  "xDescribe"
  "xContext"
  "xIt"
  "xExample"
  "xSpecify"
] @keyword.function.skipped

; Hook keywords
[
  "Before"
  "After"
  "BeforeAll"
  "AfterAll"
  "BeforeEach"
  "AfterEach"
  "BeforeRun"
  "AfterRun"
  "BeforeCall"
  "AfterCall"
] @keyword.control.hook

; Utility blocks
[
  "Data"
  "Parameters"
] @keyword.function.data

; Skip/Pending/Todo blocks
[
  "Skip"
  "Pending"
  "Todo"
] @keyword.function.pending

; Block terminator
[
  "End"
] @keyword.control

; Data block modifiers
[
  ":raw"
  ":expand"
  "#|"
] @keyword.modifier

; Directives
[
  "Include"
] @keyword.directive

; Comments (inherit from bash)
(comment) @comment

; Strings (inherit from bash)
(string) @string
(raw_string) @string

; Functions (inherit from bash)
(function_definition
  name: (word) @function)

; Variables (inherit from bash)
(variable_name) @variable

; Operators (inherit from bash)
[
  "&&"
  "||"
  "|"
  ";"
  "&"
] @operator
