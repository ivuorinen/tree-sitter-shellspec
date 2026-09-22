module github.com/ivuorinen/tree-sitter-shellspec

go 1.23

toolchain go1.27.1

// v0.25.0 is the first release whose bundled C library accepts ABI 15, which the
// generated parser targets; v0.24.0 stops at ABI 14 and Parser.SetLanguage rejects it.
require github.com/tree-sitter/go-tree-sitter v0.25.0

require github.com/mattn/go-pointer v0.0.1 // indirect
