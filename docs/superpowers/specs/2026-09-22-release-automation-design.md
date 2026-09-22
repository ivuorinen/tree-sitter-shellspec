# Release automation design

Date: 2026-09-22
Status: approved design, pending implementation plan

## Goal

Automate versioning, changelog and publishing for every package this repository ships:

- npm (`@ivuorinen/tree-sitter-shellspec`)
- PyPI (`tree-sitter-shellspec`)
- crates.io (`tree-sitter-shellspec`)
- Go module and Swift package, both released by a git tag alone

npm, PyPI and crates.io publish through OIDC trusted publishing. No long-lived registry token exists anywhere.
npm provenance and PyPI PEP 740 attestations are produced by that path.

## Current state

- `.github/workflows/release.yml` runs on a `v*.*.*` tag push or a manual dispatch. It publishes to npm with a
  long-lived `NPM_TOKEN` secret, then creates a GitHub release from hand-written notes.
- Nothing is published to any registry. The repository has no tags and no `CHANGELOG.md`.
- The version `0.1.0` appears in seven files: `package.json`, `package-lock.json`, `tree-sitter.json`,
  `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt` and `Makefile`.
- `test.yml` runs on push to `main` and on pull requests.

## Decisions

| Topic | Decision |
| --- | --- |
| Tool | release-please, manifest mode |
| Package contents | Source only now; the build stage is structured so binary builds can be added later |
| Publish gate | Merging the release PR, then one approval on the `release` GitHub environment |
| First npm and crates.io publish | By hand from the maintainer's machine; trusted publishers are added after it |
| First PyPI publish | CI, through a pending trusted publisher |
| CI on the release PR | GitHub App token, so the release PR triggers `test.yml` and `pr-lint.yml` |
| Changelog | Features, Bug Fixes, Performance, Dependencies |

## Architecture

One workflow, `.github/workflows/release.yml`, replaces the current file. It runs on every push to `main`, and
its `build` job also runs on pull requests.

```text
push to main
  └─ release-please          GitHub App token. Opens or updates the release PR; on merge,
      │                      tags vX.Y.Z and creates the GitHub release.
      │                      outputs: release_created, tag_name, version
      ▼  only when release_created == 'true'
    verify                   checks out the tag; all 7 manifests equal the version;
      │                      test.yml concluded success on the tag SHA; npm audit
      ▼
    build                    npm pack, python -m build, cargo package;
      │                      uploads the artifacts; no secrets, no id-token
      ▼
  ┌───┴──────────┬───────────────┐     environment: release (one approval)
  publish-npm    publish-pypi    publish-crates
```

The publish jobs share the `release` environment, so GitHub asks for approval once per run.
The Go module and Swift package need no job: the `vX.Y.Z` tag is their release.

Binary builds (npm prebuilds, Python wheels per platform) join later as extra `build` matrix jobs that upload
more artifacts. The publish jobs do not change when they are added.

## Version management

### `release-please-config.json`

- `release-type`: `node`, which updates `package.json` and `package-lock.json`.
- `include-component-in-tag`: `false`, giving `vX.Y.Z` tags for Go and SwiftPM.
- `bump-minor-pre-major`: `true`. Below 1.0.0 a breaking change bumps the minor version, and `feat` also bumps
  the minor version.
- `changelog-sections`: `feat` (Features), `fix` (Bug Fixes), `perf` (Performance), `deps` (Dependencies).
  Every other type is hidden and does not start a release.
- `extra-files`:

| File | Updater |
| --- | --- |
| `tree-sitter.json` | `json`, `jsonpath: $.metadata.version` |
| `pyproject.toml` | `toml`, `jsonpath: $.project.version` |
| `Cargo.toml` | `toml`, `jsonpath: $.package.version` |
| `CMakeLists.txt` | `generic`, with `# x-release-please-start-version` / `# x-release-please-end` around the `VERSION` line |
| `Makefile` | `generic`, with the same block markers around `VERSION :=` |

The Makefile must use block markers, not a trailing `# x-release-please-version` comment. GNU make keeps the
whitespace before an inline comment in the variable's value, so a trailing marker would set `VERSION` to
`0.1.0` followed by a space, and the shared-library file names built from it would break.

### `.release-please-manifest.json`

```json
{ ".": "0.1.0" }
```

### Runtime dependency commits

release-please groups changelog entries by commit type and ignores scope. Renovate writes every update as
`chore(deps)`, so a runtime dependency update would never start a release. A repository rule in
`.github/renovate.json` sets the prefix for runtime dependency types only:

- Matched dependency types: npm `dependencies` and `peerDependencies`, Cargo `dependencies`, and PEP 621
  `project.dependencies` and `project.optional-dependencies`.
- Minor, patch and digest updates use `commitMessagePrefix: "deps: "`.
- Major updates use `commitMessagePrefix: "deps!: "`. A new `tree-sitter-bash` major can change parse trees, so
  it is marked as breaking, which bumps the minor version while the version is below 1.0.0.

These rules go after the existing rules, because Renovate applies the last matching `packageRules` entry.
Dev dependencies, GitHub Actions and pre-commit hooks keep their `chore(...)` prefixes and do not release.

## Jobs

The workflow-level permission is `contents: read`. Each job asks only for what it needs.

### release-please

- Runs only on push to `main`.
- `environment: release-please`. That environment allows deployments from `main` only and holds the App ID as
  a variable and the App private key as a secret.
- `actions/create-github-app-token` mints a token limited to this repository, with `contents: write` and
  `pull-requests: write`. `googleapis/release-please-action` runs with that token.
- `GITHUB_TOKEN` gets no permissions (`permissions: {}`).
- Outputs: `release_created`, `tag_name`, `version`.

### verify

- Runs when `release_created == 'true'`.
- `permissions: contents: read, actions: read`.
- Checks out `tag_name` with `persist-credentials: false`.
- Fails the run unless all seven version fields equal `version`. This catches an `extra-files` updater that
  matched nothing.
- Fails unless the latest completed `test.yml` run for the tag SHA concluded `success`.
- Runs `npm audit --audit-level=high`.

### build

- Runs when `release_created == 'true'`, and on every pull request as a packaging check. On a push to `main`
  that creates no release, it does not run.
- `needs: [release-please, verify]` with
  `if: always() && (github.event_name == 'pull_request' || needs.verify.result == 'success')`. On a pull request
  both needed jobs are skipped, and `always()` keeps that from skipping `build` too.
- `permissions: contents: read`. No dependency cache: a cache written by a pull request run must not reach a
  published artifact.
- `npm ci --ignore-scripts`, then `npm rebuild tree-sitter-cli`, then `npm run generate`.
- `npm pack` produces the npm tarball.
- `python -m build` produces the sdist and wheel, and `twine check --strict` validates their metadata.
- `cargo package --locked` produces and verifies the `.crate`.
- On release runs, uploads the three outputs as workflow artifacts. Pull request runs build and check only.

### publish-npm, publish-pypi, publish-crates

Shared rules:

- `needs: [release-please, verify, build]`, runs only when `release_created == 'true'`.
- `environment: release`, with the maintainer as a required reviewer and deployments allowed from `main` only.
- `permissions: id-token: write` only.
- A job first asks its registry whether `version` is already published. If it is, the job logs a skip and
  passes. A re-run after a partial failure therefore publishes only what is missing, and the hand-published
  `0.1.0` is never uploaded twice.

Per registry:

- **npm:** `actions/setup-node` with Node 24, whose bundled npm 11.x meets the trusted publishing minimum of
  11.5.1. Downloads the tarball and runs `npm publish <tarball> --access public`, using the `next` dist-tag for a
  prerelease version. Provenance is generated automatically. The trusted publisher on npmjs.com names the
  workflow file `release.yml` and the environment `release`.
- **PyPI:** downloads `dist/` and runs `pypa/gh-action-pypi-publish`, which publishes with trusted publishing
  and attaches PEP 740 attestations by default. The pending publisher names `release.yml` and `release`.
- **crates.io:** `rust-lang/crates-io-auth-action` exchanges the OIDC token for a short-lived crates.io token.
  Cargo cannot upload a prebuilt `.crate` file, so this job checks out `tag_name` and runs
  `cargo publish --locked`. Cargo runs no install scripts, and the build script only compiles the bundled
  C sources. The trusted publisher names `release.yml` and `release`.

All actions are pinned to a full commit SHA with the version in a trailing comment, as in the rest of the
repository.

## Removed

- The tag-push and `workflow_dispatch` triggers of the current `release.yml`.
- The `NPM_TOKEN` secret and the `zizmor: ignore[use-trusted-publishing]` exemption.
- The hand-written release notes step. `CHANGELOG.md` and the release-please GitHub release replace it.

## One-time bootstrap (maintainer, by hand)

Done after the implementation PR merges, before the first release PR is merged:

1. Create a GitHub App owned by the maintainer, installed on this repository only, with `contents: write` and `pull-requests: write`.
    Store its App ID as a variable and its private key as a secret in the `release-please` environment.
2. Create the `release` environment: the maintainer as a required reviewer, deployments allowed from `main` only.
3. From a clean checkout of the merge commit, publish `0.1.0` by hand with `npm publish --access public` and `cargo publish`.
4. Add the trusted publishers: npm and crates.io on their package settings pages, PyPI as a pending publisher under the account's Publishing page.
    Each one names repository `ivuorinen/tree-sitter-shellspec`, workflow `release.yml` and environment `release`.
5. On npm, set publishing access to "Require two-factor authentication and disallow tokens".
6. Tag the commit from step 3 as `v0.1.0`, push the tag, and create a GitHub release for it.
    release-please calculates the next version from this tag; without it, the whole history counts as unreleased.

PyPI receives its first version from the first CI release, so its first version is the one after `0.1.0`.

## Testing

- `actionlint` and zizmor pass on the new workflow, with no zizmor ignores for registry tokens.
- A local `npx release-please release-pr --dry-run` against a branch with a test `deps:` commit produces a patch
  release PR that includes a Dependencies section and updates all seven version fields.
- The `build` job runs on the implementation PR itself and must pass: `npm pack`, `python -m build` with
  `twine check --strict`, and `cargo package --locked`.
- On a throwaway branch, one version field set to the wrong value makes the `verify` check fail.

## Documentation

- `README.md`: remove the note that the package is not published yet, and add `pip install` and `cargo add`
  lines.
- `CONTRIBUTING.md`: a "Releasing" section covering the release PR, the environment approval, the bootstrap
  steps, and the `deps:` rule for runtime dependencies.
- `CLAUDE.md`: update the CI/CD paragraph to describe the release workflow.

## Out of scope

- Binary builds (npm prebuilds, per-platform Python wheels). The `build` stage leaves room for them.
- Maven, WASM and any other registry.
- Signed tags for the Go module and Swift package.
