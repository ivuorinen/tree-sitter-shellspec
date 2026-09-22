// tree-sitter-cli/dsl.d.ts declares its types as ambient globals — the file contains no
// top-level `export`, so `GrammarSchema` cannot be imported. The triple-slash reference is
// the only way to bring it into scope, which is the one case ts-standard's rule cannot cover.
/* eslint-disable-next-line @typescript-eslint/triple-slash-reference */
/// <reference types="tree-sitter-cli/dsl" />

// tree-sitter-bash ships no declarations for its grammar.js; type it as the grammar schema
// the tree-sitter DSL's `grammar()` returns, so grammar.js is type-checked against it.
//
// Style note: single quotes and no semicolons because ts-standard owns this file and its
// rules are not configurable. `types/` is in .prettierignore so Prettier (semi: true,
// singleQuote: false) does not fight it.
declare module 'tree-sitter-bash/grammar.js' {
  const grammar: GrammarSchema<string>
  export default grammar
}
