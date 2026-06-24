# Nitpicker Findings

Generated: 2026-06-24
Last validated: 2026-06-24

Scope: changed-files mode — branch `feat/upgrades` vs `origin/main` (PR #121).
Reviewed: `.github/workflows/*.yml`, `.mega-linter.yml`, `.pre-commit-config.yaml`, `package.json`.

## Summary

- Total: 7 | Open: 3 | Fixed: 3 | Invalid: 1

## Open Findings

### Medium

#### [NIT-03] Same pr-lint action granted contradictory permissions across workflows

Category: security
Area: .github/workflows/test.yml (job `lint`) vs .github/workflows/pr-lint.yml (job `Linter`)
Problem: The identical pinned action `ivuorinen/actions/pr-lint@8395dad…` is invoked with two
different permission sets. In `pr-lint.yml` it gets `statuses: write`, `contents: read`,
`packages: read`. In `test.yml` it gets `contents: read`, `issues: write`, `pull-requests: write`
— no `statuses: write`. The justification comments on both cannot both be accurate.
Evidence: pr-lint.yml:22-25 vs test.yml:158-161 (post-edit numbering).
Impact: At least one invocation is mis-scoped: either the `test.yml` `lint` job is missing
`statuses: write` it needs (lint status check fails to publish), or it holds `issues`/`pull-requests`
write it never uses (over-privilege). The comments document a requirement that is not verified.
Fix: Determine the action's actual required scopes (from its `action.yml`/docs) and apply the same
permission block in both call sites. Not auto-applied: the action is an external black box and
guessing risks breaking the status check.

### Low

#### [NIT-05] Redundant `token:` input on sync-labels checkout

Category: maintainability
Area: .github/workflows/sync-labels.yml:38
Problem: `token: ${{ secrets.GITHUB_TOKEN }}` restates the checkout action's default token, and is
paired with `persist-credentials: false`, so it has no effect — the credential is not persisted and
the value equals the default.
Evidence: sync-labels.yml:37-39.
Impact: Dead configuration; implies a non-default token is in use when it is not.
Fix: Remove the `token:` line, keeping `persist-credentials: false`.

#### [NIT-06] renovate-config-validator removed while renovate config still present

Category: maintainability
Area: .pre-commit-config.yaml (removed hook) / .github/renovate.json (still present)
Problem: This branch deletes the `renovatebot/pre-commit-hooks` `renovate-config-validator` hook,
but `.github/renovate.json` still exists. Local validation of the Renovate config is now gone.
Evidence: diff removes the hook block; `.github/renovate.json` present (extends
`github>ivuorinen/renovate-config`).
Impact: A malformed `.github/renovate.json` will no longer be caught pre-commit; only Renovate's own
server-side handling remains. Low impact because the file is a trivial `extends` shim.
Fix: Either restore the hook, or accept the reduced coverage intentionally and note it. Reported, not
auto-applied — removal may be deliberate (network/flaky hook).

## Fixed

### Pass 1 — 2026-06-24

#### [NIT-01] Release workflow_dispatch pushes a tag that mismatches the release tag

Fixed: 2026-06-24
Notes: On the `workflow_dispatch` path, "Create Tag" computed the tag from the raw input
(`git tag "${VERSION#v}"`), pushing an unprefixed tag (e.g. `1.0.0`) while "Create GitHub Release"
ran `gh release create "$VERSION"` with the validated, v-prefixed version (`v1.0.0`). Because the
input description tells users to enter `1.0.0`, the common path produced two divergent tags, and
`gh release create` would create the `v`-tag at the default branch HEAD rather than the pushed
commit. The intended convention is v-prefixed (`on.push.tags: v*.*.*`). Changed "Create Tag" to use
`needs.validate.outputs.version` and push that exact tag, so the pushed tag matches the release tag.
Verified with actionlint + yamllint.

#### [NIT-02] `test` job holds unused write permissions

Fixed: 2026-06-24
Notes: The `test` job's steps (checkout, setup-node, caches, `npm ci`, tree-sitter parse) never call
the issues, pull-requests, or actions APIs, yet it granted `issues: write`, `pull-requests: write`,
and `actions: read` with comments claiming "test tooling" needs them. Reduced to `contents: read`.

#### [NIT-04] `coverage` job holds unused write permissions

Fixed: 2026-06-24
Notes: The `coverage` job builds `coverage_report.md` but only `cat`s it — it never posts to issues
or PRs and never reads the Actions API. Removed unused `issues: write`, `pull-requests: write`, and
`actions: read`; reduced to `contents: read`.

## Invalid

### Pass 1 — 2026-06-24

#### [NIT-07] Re-enabling BASH_BASH_EXEC would fail the lint job

Notes: Initially suspected: this branch removes `BASH_BASH_EXEC` from `DISABLE_LINTERS`, and
`test/spec/*.sh` are non-executable. But `FILTER_REGEX_EXCLUDE` in `.mega-linter.yml` globally
excludes `test/spec`, and the only other `.sh` outside excluded paths
(`scripts/post-generate.sh`) is already executable. So the re-enabled linter has nothing to flag —
no defect.
