package tree_sitter_shellspec_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_shellspec "github.com/ivuorinen/tree-sitter-shellspec/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_shellspec.Language())
	if language == nil {
		t.Errorf("Error loading Shellspec grammar")
	}
}
