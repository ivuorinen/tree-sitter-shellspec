; Vendored verbatim from tree-sitter-bash v0.25.1 queries/highlights.scm.
; Copyright (c) 2017 Max Brunsfeld, MIT License — see THIRD_PARTY_NOTICES.md.
;
; Vendored rather than referenced: tree-sitter.json resolves each `highlights` entry
; relative to its own directory, and npm hoists tree-sitter-bash to the consumer's
; top-level node_modules, so a package-local node_modules/tree-sitter-bash/... path
; does not exist in an installed copy. Re-copy this file when the tree-sitter-bash
; dependency is upgraded.

[
  (string)
  (raw_string)
  (heredoc_body)
  (heredoc_start)
] @string

(command_name) @function

(variable_name) @property

[
  "case"
  "do"
  "done"
  "elif"
  "else"
  "esac"
  "export"
  "fi"
  "for"
  "function"
  "if"
  "in"
  "select"
  "then"
  "unset"
  "until"
  "while"
] @keyword

(comment) @comment

(function_definition name: (word) @function)

(file_descriptor) @number

[
  (command_substitution)
  (process_substitution)
  (expansion)
]@embedded

[
  "$"
  "&&"
  ">"
  ">>"
  "<"
  "|"
] @operator

(
  (command (_) @constant)
  (#match? @constant "^-")
)
