; inherits: bash
; ShellSpec Syntax Highlighting
; Extends tree-sitter-bash highlighting. tree-sitter.json loads the bash queries first;
; nvim-treesitter-style consumers read the `inherits` line above.

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

; The optional `I` in `When I run` / `When I call`, scoped to the statement so a
; bash word `I` elsewhere keeps its own capture
(shellspec_when_statement
  modifier: "I" @keyword.operator)

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

; Statement keywords (Path/File/Dir, Set, Dump, Intercept, UseFD)
[
  "Path"
  "File"
  "Dir"
  "Set"
  "Dump"
  "Intercept"
  "UseFD"
] @keyword

; Block terminator
[
  "End"
] @keyword.control

; Directives
[
  "Include"
] @keyword.directive

; Conditional skip keyword (`Skip if`), scoped so bash `if` statements keep their own capture
(shellspec_directive_statement
  "if" @keyword.control)

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

; Data / %text line bodies. Bash heredoc bodies inherit @string from the bash
; queries, so `#|` content is treated the same way rather than left unhighlighted.
"#|" @punctuation.special

(shellspec_data_line_content) @string

; The statement subject and matcher slots
(shellspec_the_statement
  subject: (shellspec_subject) @variable.parameter
  matcher: (shellspec_matcher) @function.method)

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
