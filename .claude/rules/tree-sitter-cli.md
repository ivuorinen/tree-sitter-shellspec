# Tree-sitter CLI

The CLI version is pinned in `mise.toml`; run commands as `mise run <task>` (`mise tasks` lists them).
Never run `tree-sitter generate` directly in any form (bare, `npx`, `mise exec`): only `mise run generate` applies `scripts/post-generate.sh`.
