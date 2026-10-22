# mise consolidation design

Date: 2026-10-21
Status: approved design, pending implementation plan

## Goal

One file answers both "which tool versions does this repository use" and "how do I run X": `mise.toml` pins every
toolchain and defines every development command as a mise task. CI runs the same tasks, so a clean local
`mise run <task>` means the matching CI step passes.

## Current state

- Development commands are npm scripts in `package.json` (`generate`, `generate:only`, `test`, `parse`, `web`, `build`,
  `dev`, `lint`, `lint:editorconfig`, `format`, `clean`, `rebuild`). `install: node-gyp-build` is the npm lifecycle
  hook that consumers of the package run.
- The tree-sitter CLI is pinned as the `tree-sitter-cli` devDependency (resolved 0.27.1) and called through `npx`.
- `Makefile` is the `tree-sitter init` C-library scaffold: build, `install`, `uninstall`. release-please bumps its
  `VERSION` and `.github/scripts/check_versions.py` checks it.
- `pyproject.toml` and `setup.py` hold packaging metadata only (`requires-python >=3.10`). `go.mod` declares
  `toolchain go1.27.3`, which Renovate bumps.
- No version is pinned for node, python, rust or prek. CI picks node 22/24 and python 3.14 through `setup-*` actions,
  Go through `go-version-file: go.mod`, and rust from whatever the runner ships.
- `test.yml` holds about 150 lines of inline bash: scanner enum check, generated-`src/` gate, a heredoc sample parse,
  `test/spec` parse, upstream ShellSpec suite parse, binding tests, and a separate coverage job that reruns the tests to
  count them.
- About 40 references to `npm run …` and `npx tree-sitter` live in CLAUDE.md, README.md, CONTRIBUTING.md,
  `.claude/` hooks, rules, skills and agent, `.pre-commit-config.yaml` comments, and the grammar issue template.

## Decisions

| Topic           | Decision                                                                                                    |
|-----------------|-------------------------------------------------------------------------------------------------------------|
| Scope           | Local development and CI both run mise tasks                                                                |
| npm scripts     | Deleted, except the `install` lifecycle hook                                                                |
| tree-sitter CLI | mise tool (`aqua:tree-sitter/tree-sitter`); the devDependency stays for its DSL types only                  |
| Required checks | The `main` ruleset's "📊 Test Coverage" check is replaced by the maintainer when the job folds              |
| Task layout     | Short tasks inline in `mise.toml`; multi-line scripts as file tasks under `.mise/tasks/`                    |
| Go version      | Read from `go.mod`'s `toolchain` line, not duplicated in `mise.toml`                                        |
| Lockfile        | None (`lockfile = false`): mise-action's `--locked` install fails for the node 22 leg and every go.mod bump |
| Makefile        | Unchanged; it stays the C-library build and install interface                                               |

## Tools and settings

```toml
#:schema https://mise.jdx.dev/schema/mise.json
[settings]
idiomatic_version_file_enable_tools = ["go"]
lockfile = false

[tools]
node = "24.22.1"
python = "3.14.8"
rust = "1.99.0"
tree-sitter = "0.27.1"
prek = "0.5.6"
```

- Go: mise reads `toolchain goX.Y.Z` in `go.mod` as an exact version once `go` is in
  `idiomatic_version_file_enable_tools` (mise docs, "Go > Version files"). Only a patch-less `go X.Y` directive is a
  deprecated source; this `go.mod` has a `toolchain` line. The setting must be in the project file because CI has no
  global mise config.
- node: `test.yml`'s matrix overrides it with `MISE_NODE_VERSION` set to `22` and `24`, the same prefix pinning
  `setup-node` uses today. Every other job and every local run uses the exact pin.
- python: matches CI's current 3.14. `requires-python >=3.10` in `pyproject.toml` is the user-facing floor and does
  not change.
- rust: pins what `cargo package` and `cargo publish` build with in `release.yml`.
- mega-linter-runner: stays an `npx mega-linter-runner@10.1.0` call, now in the `lint` task. As an `npm:` tool, mise
  writes its full dependency graph to `.mise/locks/` (a 3000-line generated YAML file that yamllint fails on), and
  excluding it would take a lint-configuration change.
- Kept: the `tree-sitter-cli` devDependency, because `grammar.js` and `types/tree-sitter-bash-grammar.d.ts`
  reference its `dsl.d.ts` types (`tsconfig.json` `checkJs`, editors, MegaLinter's JS and TS linters). Its
  `allowScripts` entry becomes an explicit denial, so npm 11+ never runs its install script and never downloads a
  second CLI binary. npm 10 (the node 22 leg) ignores `allowScripts` and still downloads it, harmlessly: the binary
  on `PATH` comes from mise.
- Not added: swift, because no task or CI step runs it.
- Not changed: `Cargo.toml`'s `tree-sitter` dev-dependency (the runtime crate, not the CLI), `pyproject.toml`,
  `setup.py`, `go.mod`, `Makefile`.

## Tasks

### Inline in `mise.toml`

| Task                | Runs                                                             | Replaces                    |
|---------------------|------------------------------------------------------------------|-----------------------------|
| `install`           | `npm ci`                                                         | manual `npm ci`             |
| `generate`          | `tree-sitter generate && scripts/post-generate.sh`               | `npm run generate`          |
| `test`              | `tree-sitter test`                                               | `npm test`                  |
| `parse`             | `tree-sitter parse`                                              | `npm run parse`             |
| `web`               | `tree-sitter web-ui`                                             | `npm run web`               |
| `build`             | `tree-sitter build .`                                            | `npm run build`             |
| `dev`               | `generate`, then `test`                                          | `npm run dev`               |
| `clean`             | remove `src/parser.c`, `src/grammar.json`, `src/node-types.json` | `npm run clean`             |
| `rebuild`           | `clean`, then `generate`                                         | `npm run rebuild`           |
| `lint`              | `npx --yes mega-linter-runner@10.1.0`                            | `npm run lint`              |
| `lint:editorconfig` | `prek run editorconfig-checker --all-files`                      | `npm run lint:editorconfig` |
| `format`            | `prek run --stage manual --all-files pretty-quick-branch`        | `npm run format`            |
| `test:bindings:go`  | `go test -v ./bindings/go/`                                      | `test.yml` step             |
| `package:npm`       | `npm pack --ignore-scripts`                                      | `release.yml` step          |
| `package:crate`     | `cargo package`                                                  | `release.yml` step          |

Extra arguments reach the command, for example `mise run test -i describe_blocks` or `mise run parse file.sh`. The
implementation verifies that passthrough; where it does not hold for a task, that task declares a usage `arg`.

### File tasks under `.mise/tasks/`

Each is an executable bash script with a `#MISE description=` header. Its path sets its name, and mise drops the `.sh`
extension (`check/generated.sh` is `check:generated`). The extension is what makes MegaLinter, and so CI, shellcheck
them; prek's shellcheck hook covers them too.

| Task                   | Content, moved from                                                                                                           |
|------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| `check:scanner`        | `TokenType` enum diff of `src/scanner.c` against `node_modules/tree-sitter-bash` (`test.yml`)                                 |
| `check:generated`      | `git status --porcelain -- src/` gate (`test.yml`)                                                                            |
| `test:spec`            | parse every `test/spec/*.sh` with `--quiet` (`test.yml`)                                                                      |
| `test:upstream`        | upstream ShellSpec suite at the pinned `SHELLSPEC_REF` (`test.yml`)                                                           |
| `test:count`           | run the tests, enforce the 115-test floor and zero failures, print the report (also to `$GITHUB_STEP_SUMMARY`) (coverage job) |
| `test:bindings:node`   | install the tree-sitter runtime into a separate prefix, symlink it, verify it resolves, `node --test` (`test.yml`)            |
| `test:bindings:python` | `pip install '.[core]'` into a throwaway venv, print the runtime version, unittest (`test.yml`)                               |
| `test:bindings`        | depends on the three binding tasks                                                                                            |
| `package:python`       | install build 1.6.1 and twine 7.0.0 into a throwaway venv, build the sdist, `twine check --strict` (`release.yml`)            |

The coverage job's `GITHUB_OUTPUT` writes (`total-tests`, `passing-tests`, `coverage-percent`) are dropped: nothing in
`.github/` reads them.

Scratch output goes under `.temp/`, which `.gitignore` already covers: the upstream clone (`.temp/shellspec`) and the
throwaway venvs. `.gitignore` does not change.

### Removed

- `generate:only`: it skips `post-generate.sh`, and its output fails the CI `src/` gate.
- The "Test Parser with Sample Code" heredoc in `test.yml`: the corpus, `test:spec` and `test:upstream` already parse
  every construct it contains (Describe, Include, Before/After, Context, It, `When call`, The, `Skip if`).

## CI

### `test.yml`

- `test` job, node 22 and 24: checkout, `jdx/mise-action` with `MISE_NODE_VERSION: ${{ matrix.node-version }}`, then
  one step each for `mise run install`, `check:scanner`, `generate`, `check:generated`, `test:count`, `test:spec`,
  `test:upstream`. Separate steps keep the failing gate visible in the Actions UI.
- `coverage` job: removed; `test:count` in the `test` job replaces it.
- `bindings` job: checkout, `jdx/mise-action`, `mise run install`, `mise run test:bindings`. `setup-python` and
  `setup-go` are removed. The current `npm run build` step is dropped: it writes `shellspec.so`, which no binding
  loads. The Node binding loads the addon that `npm ci`'s `node-gyp-build` compiles, and the Python and Go bindings
  compile `src/` themselves.
- The `~/.npm` cache steps are dropped: without tree-sitter-cli, `npm ci` installs three small packages, and
  mise-action caches the toolchains.

### `release.yml`

- `build` job: `setup-node` and `setup-python` become `jdx/mise-action` with `cache: false`, then `mise run
  package:npm`, `package:python`, `package:crate`. The upload steps are unchanged.
- `publish-crates`: adds `jdx/mise-action` with `cache: false` so `cargo publish` uses the pinned rust.
- `cache: false` in both: release jobs follow the zizmor cache-poisoning rule already noted in this workflow.
- Unchanged: `verify` (stdlib `python3` and `npm audit` need no project toolchain), `publish-npm` (`setup-node`'s
  `registry-url` writes the `.npmrc` that OIDC publishing relies on, which mise-action does not), `publish-pypi`.

### Other workflows

- `pr-lint.yml`: unchanged.
- `codeql.yml`: unchanged; it invokes no npm script and no tree-sitter command.
- The mise version is pinned once per workflow as in gh-history: a workflow-level
  `MISE_VERSION` env with a `# renovate: datasource=github-releases depName=jdx/mise` comment, which the preset's
  `customManagers:githubActionsVersions` tracks, passed to each mise-action step as `version: ${{ env.MISE_VERSION }}`.

## Hooks, rules, skills, docs

- `.claude/hooks/pre-bash-guard.sh`: with mise active, `tree-sitter` on PATH is the pinned CLI, so the remaining
  hazard is skipping `post-generate.sh`. Any direct `tree-sitter generate` (bare, `npx`, `mise exec`) is blocked, and
  the message points to `mise run generate`. The `npx` and `node_modules/.bin` allowances are removed.
- `.claude/hooks/pre-edit-guard.sh`, `.claude/hooks/post-edit-lint.sh`: `npm run generate` becomes `mise run generate`.
- `.claude/rules/tree-sitter-cli.md`: rewritten. The CLI is pinned in `mise.toml`, commands run as `mise run <task>`,
  and `tree-sitter generate` is never run directly.
- `.claude/rules/grammar-verification.md`, the five skills under `.claude/skills/`, `.claude/agents/grammar-validator.md`,
  `.github/ISSUE_TEMPLATE/grammar_issue.md`: command references updated.
- CLAUDE.md, README.md, CONTRIBUTING.md: setup becomes `mise install` then `mise run install`. Command tables use
  `mise run …`, and `mise tasks` is named as the full list. One line notes that the Makefile remains the C-library
  build and install entry point.
- `.pre-commit-config.yaml`: comments naming `npm run format` and `npm run generate` are updated; hooks are unchanged.
- Not changed: `docs/superpowers/` (earlier specs and plans are historical records) and `docs/audit/`.

## Testing

- Run every task locally, including both `test:bindings` legs and the three `package:*` tasks. The `package:*` outputs
  must match what the current release steps produce: same tarball file list, sdist, and crate.
- `mise run lint` (MegaLinter) and `prek run --all-files`, fixed until clean.
- actionlint passes on the edited workflows.
- The pull request's CI is the final check: both node legs, bindings, and the release workflow's `build` job, which
  runs on pull requests.

## Out of scope

- New tests, or new CI coverage beyond what moves over (for example a Rust or Swift binding test).
- Changes to the Makefile, CMakeLists.txt, packaging metadata, or the publish steps' registry logic.
- Rewriting historical documents under `docs/superpowers/` and `docs/audit/`.
