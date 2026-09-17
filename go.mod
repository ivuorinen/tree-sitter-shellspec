module github.com/ivuorinen/tree-sitter-shellspec

go 1.22

toolchain go1.27.1

// v0.24.0 is the newest release and bundles the C library at ABI 14, but the generated
// parser targets ABI 15, so Parser.SetLanguage rejects this grammar. Bump this the
// moment go-tree-sitter ships an ABI 15 release. See README "Known Limitations".
require github.com/tree-sitter/go-tree-sitter v0.24.0
