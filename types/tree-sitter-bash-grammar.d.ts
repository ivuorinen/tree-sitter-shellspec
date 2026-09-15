/// <reference types="tree-sitter-cli/dsl" />

// tree-sitter-bash ships no declarations for its grammar.js; type it as the grammar schema
// the tree-sitter DSL's `grammar()` returns, so grammar.js is type-checked against it.
declare module "tree-sitter-bash/grammar.js" {
  const grammar: GrammarSchema<string>;
  export default grammar;
}
