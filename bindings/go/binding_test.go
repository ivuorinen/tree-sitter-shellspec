package tree_sitter_shellspec_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_shellspec "github.com/ivuorinen/tree-sitter-shellspec/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_shellspec.Language())
	if language == nil {
		t.Fatal("Error loading Shellspec grammar")
	}
	// NewLanguage only wraps the pointer; the ABI check happens in SetLanguage, so a
	// runtime too old for the grammar passes the nil check above and fails only here.
	parser := tree_sitter.NewParser()
	defer parser.Close()
	if err := parser.SetLanguage(language); err != nil {
		t.Fatalf("Error setting Shellspec language: %v", err)
	}
}
