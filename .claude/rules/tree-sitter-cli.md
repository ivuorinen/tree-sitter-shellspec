# Tree-sitter CLI

Use the pinned CLI through `npm run <script>` or `npx tree-sitter`.
Never run a globally installed `tree-sitter generate`: its version differs from the pinned devDependency and it skips `scripts/post-generate.sh`.
