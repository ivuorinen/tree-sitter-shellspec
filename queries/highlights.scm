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
  "fExampleGroup"
  "fIt"
  "fExample"
  "fSpecify"
] @keyword.function.focused

; Skipped blocks (for temporarily disabling tests)
[
  "xDescribe"
  "xContext"
  "xExampleGroup"
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

; When/The/Assert keywords (core assertion DSL)
[
  "When"
  "The"
  "Assert"
] @keyword

; When evaluation type keywords
[
  "call"
  "run"
  "command"
  "script"
  "source"
] @keyword.operator

; The statement keywords
[
  "should"
  "not"
] @keyword.control

; Mock block keyword
[
  "Mock"
] @keyword.function

; Utility blocks
[
  "Data"
  "Data:raw"
  "Data:expand"
  "Parameters"
  "Parameters:block"
  "Parameters:value"
  "Parameters:matrix"
  "Parameters:dynamic"
] @keyword.function.data

; Skip/Pending/Todo keywords
[
  "Skip"
  "Pending"
  "Todo"
] @keyword.function.pending

; Statement keywords (Path/File/Dir, Set, Dump, Intercept)
[
  "Path"
  "File"
  "Dir"
  "Set"
  "Dump"
  "Intercept"
] @keyword

; Block terminator
[
  "End"
] @keyword.control

; Directives
[
  "Include"
] @keyword.directive

; % directives (text, const, output, preserve, logger)
[
  "%text"
  "%text:raw"
  "%text:expand"
  "%const"
  "%"
  "%puts"
  "%putsn"
  "%-"
  "%="
  "%preserve"
  "%logger"
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
