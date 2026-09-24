# Release Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans
> to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the token-based, tag-triggered `release.yml` with release-please plus OIDC trusted publishing to npm, PyPI and
crates.io, as designed in `docs/superpowers/specs/2026-09-22-release-automation-design.md`.

**Architecture:** One workflow, `.github/workflows/release.yml`. A `release-please` job (GitHub App token) maintains the release PR
and, on merge, tags `vX.Y.Z`. On a release, `verify` checks versions and CI, `build` packs the npm tarball and the Python sdist, and
three publish jobs in the `release` environment publish with `id-token: write` only. The `build` job also runs on every pull request.

**Tech Stack:** GitHub Actions, release-please 17 (action v5), npm 11 trusted publishing, `pypa/gh-action-pypi-publish`,
`rust-lang/crates-io-auth-action`, Python 3 stdlib for the version check, Renovate `packageRules`.

## Global Constraints

- Every file follows `.editorconfig`: 2-space indentation, LF, UTF-8, final newline, no trailing whitespace outside Markdown,
  at most 160 characters per line. An EditorConfig violation is a blocking error.
- Every action is pinned to a full commit SHA with the version in a trailing comment. Use exactly these pins:
  - `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1`
  - `actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0`
  - `actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0`
  - `actions/github-script@3a2844b7e9c422d3c10d287c895573f7108da1b3 # v9.0.0`
  - `actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1`
  - `actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1`
  - `actions/create-github-app-token@bcd2ba49218906704ab6c1aa796996da409d3eb1 # v3.2.0`
  - `googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7 # v5.0.0`
  - `pypa/gh-action-pypi-publish@dc37677b2e1c63e2034f94d8a5b11f265b73ba33 # v1.14.2`
  - `rust-lang/crates-io-auth-action@c6f97d42243bad5fab37ca0427f495c86d5b1a18 # v1.0.5`
- No long-lived registry token anywhere: no `NPM_TOKEN`, `PYPI_API_TOKEN` or `CARGO_REGISTRY_TOKEN` secret.
- Workflow-level `permissions: contents: read`; each job widens only what it needs. Publish jobs get `id-token: write` only.
- No dependency cache in any job of `release.yml`.
- Untrusted values reach `run:` blocks through `env:`, never through `${{ }}` inside the script.
- Tags are `vX.Y.Z` (`include-component-in-tag: false`).
- Two decisions differ from the spec's wording, both forced by facts found while planning; Task 5 corrects the spec:
  - PyPI gets the **sdist only**. `python -m build` produces `cp310-abi3-linux_x86_64.whl` because `setup.py` compiles the parser, and
    PyPI rejects plain `linux_x86_64` wheels. Wheels arrive with the deferred binary builds.
  - The GitHub App is identified by its **client ID** (`vars.RELEASE_APP_CLIENT_ID`): `create-github-app-token` v3 deprecates `app-id`.
- One test differs from the spec's method: the spec's "wrong version on a throwaway branch fails `verify`" is covered by Task 1's unit
  tests, which run the same script the `verify` job runs against a manifest set with one stale field.
- Use the pinned tree-sitter CLI only (`npx tree-sitter`, `npm run ...`), never a global `tree-sitter`.
- Commit messages follow Conventional Commits, as in `git log`.

## File Structure

| Path | Action | Responsibility |
| --- | --- | --- |
| `.github/scripts/check_versions.py` | Create | Compare every manifest's version to the release version; used by the `verify` job and locally |
| `.github/scripts/test_check_versions.py` | Create | Unit tests for the version check |
| `.gitignore` | Modify | Ignore `dist/`, `target/`, `Cargo.lock` produced by local packaging |
| `CMakeLists.txt` | Modify | release-please block markers around `VERSION` |
| `Makefile` | Modify | release-please block markers around `VERSION :=` |
| `release-please-config.json` | Create | release-please settings, changelog sections, extra-files |
| `.release-please-manifest.json` | Create | Current released version |
| `.github/renovate.json` | Modify | `deps:` / `deps!:` prefixes for runtime dependencies |
| `.github/workflows/release.yml` | Replace | release-please, verify, build, three publish jobs |
| `README.md`, `CONTRIBUTING.md`, `CLAUDE.md` | Modify | Install instructions, releasing guide, CI/CD summary |
| `docs/superpowers/specs/2026-09-22-release-automation-design.md` | Modify | Correct the sdist-only and client-ID points |

The version check lives under `.github/scripts/`, not `scripts/`: `scripts/` is in `package.json` `files` and ships in the npm package.

---

### Task 1: Version check script

**Files:**

- Create: `.github/scripts/check_versions.py`
- Create: `.github/scripts/test_check_versions.py`
- Modify: `.gitignore` (append at end)

**Interfaces:**

- Produces: `python3 .github/scripts/check_versions.py <version> [root]` — exits 0 when every field equals `<version>` (a leading `v`
  is stripped), exits 1 and prints a table otherwise. `read_versions(root: Path) -> dict[str, str]` maps a label to the version found,
  or `"<not found>"`. Task 4's `verify` job runs the CLI.

- [ ] **Step 1: Write the failing tests**

Create `.github/scripts/test_check_versions.py`:

```python
"""Tests for check_versions.py.

Each test builds a minimal copy of the eight version fields in a temp directory, so the
tests do not depend on the repository's current version and cannot be broken by a release.
"""

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("check_versions.py")
REPO = Path(__file__).resolve().parents[2]
FILES = ["package.json", "package-lock.json", "tree-sitter.json", "pyproject.toml", "Cargo.toml", "CMakeLists.txt", "Makefile"]


def run(version: str, root: Path) -> subprocess.CompletedProcess:
    """Run the script as the workflow does, so exit codes are tested, not just return values."""
    return subprocess.run([sys.executable, str(SCRIPT), version, str(root)], capture_output=True, text=True)


class CheckVersionsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        for name in FILES:
            shutil.copy(REPO / name, self.tmp / name)
        self.current = run("0.0.0", self.tmp).stdout.split("package.json", 1)[1].split()[0]

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def test_matching_version_passes(self):
        result = run(self.current, self.tmp)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_leading_v_is_accepted(self):
        self.assertEqual(run("v" + self.current, self.tmp).returncode, 0)

    def test_other_version_fails(self):
        result = run("99.0.0", self.tmp)
        self.assertEqual(result.returncode, 1)
        self.assertIn("MISMATCH", result.stdout)

    def test_one_stale_file_fails(self):
        cargo = self.tmp / "Cargo.toml"
        cargo.write_text(cargo.read_text().replace(f'version = "{self.current}"', 'version = "0.0.1"', 1))
        result = run(self.current, self.tmp)
        self.assertEqual(result.returncode, 1)
        self.assertRegex(result.stdout, r"Cargo\.toml\s+0\.0\.1\s+MISMATCH")

    def test_makefile_trailing_whitespace_fails(self):
        # GNU make keeps the space before an inline comment in the value, so
        # "VERSION := 0.1.0 # marker" yields "0.1.0 " and breaks library names.
        makefile = self.tmp / "Makefile"
        makefile.write_text(makefile.read_text().replace(f"VERSION := {self.current}", f"VERSION := {self.current} # marker", 1))
        self.assertEqual(run(self.current, self.tmp).returncode, 1)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s .github/scripts -v`
Expected: every test errors, because `check_versions.py` does not exist (`can't open file ... check_versions.py`, so `setUp` fails on the
missing `package.json` label).

- [ ] **Step 3: Write the script**

Create `.github/scripts/check_versions.py`:

```python
#!/usr/bin/env python3
"""Fail when any manifest's version differs from the release version.

release-please bumps package.json and package-lock.json natively and five more files through
extra-files updaters that match by JSON/TOML path or by marker comments. An updater that matches
nothing leaves its file at the old version without any error, and the registries would then get
packages whose metadata disagrees with the tag. The release workflow runs this before building
anything, so such a mismatch stops the release instead of publishing it.

Stdlib only (tomllib needs Python 3.11+), so it runs on a bare runner with no install step.
"""

import json
import re
import sys
import tomllib
from pathlib import Path

NOT_FOUND = "<not found>"


def _match(pattern: str, text: str) -> str:
    """Return the first capture group, or NOT_FOUND so a missing field reports instead of crashing."""
    found = re.search(pattern, text, re.MULTILINE)
    return found.group(1) if found else NOT_FOUND


def read_versions(root: Path) -> dict[str, str]:
    """Read the version field of every manifest release-please maintains."""
    lock = json.loads((root / "package-lock.json").read_text())
    return {
        "package.json": json.loads((root / "package.json").read_text())["version"],
        "package-lock.json": lock["version"],
        'package-lock.json packages[""]': lock["packages"][""]["version"],
        "tree-sitter.json": json.loads((root / "tree-sitter.json").read_text())["metadata"]["version"],
        "pyproject.toml": tomllib.loads((root / "pyproject.toml").read_text())["project"]["version"],
        "Cargo.toml": tomllib.loads((root / "Cargo.toml").read_text())["package"]["version"],
        # The project() call's VERSION argument; cmake_minimum_required(VERSION ...) is not at line start.
        "CMakeLists.txt": _match(r'^\s*VERSION "([^"]+)"\s*$', (root / "CMakeLists.txt").read_text()),
        # \S+$ rejects trailing whitespace, which make would keep in the value.
        "Makefile": _match(r"^VERSION := (\S+)$", (root / "Makefile").read_text()),
    }


def main(argv: list[str]) -> int:
    if len(argv) not in (2, 3):
        print("usage: check_versions.py <version> [root]", file=sys.stderr)
        return 2
    expected = argv[1].removeprefix("v")
    root = Path(argv[2]) if len(argv) == 3 else Path(__file__).resolve().parents[2]
    versions = read_versions(root)
    width = max(map(len, versions))
    failed = False
    for label, found in versions.items():
        status = "ok" if found == expected else "MISMATCH"
        failed |= status != "ok"
        print(f"{label:<{width}}  {found}  {status}")
    if failed:
        print(f"::error::manifest versions differ from the release version {expected}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
```

The tests read the current version from the `package.json` row of the script's own output, so the row label `package.json` must
stay first and exact.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s .github/scripts -v`
Expected: `Ran 5 tests` ... `OK`.

Then run it against the repository itself:
Run: `python3 .github/scripts/check_versions.py 0.1.0; echo rc=$?`
Expected: eight rows ending in `ok`, then `rc=0`.

- [ ] **Step 5: Ignore local packaging output**

Append to `.gitignore`:

```gitignore

# Packaging output. `python -m build` writes dist/, `cargo package` writes target/ and,
# because this crate is a library, generates a Cargo.lock that is not committed.
dist/
target/
Cargo.lock
```

- [ ] **Step 6: Lint and commit**

Run: `npx --no-install editorconfig-checker .github/scripts .gitignore && ruff check .github/scripts 2>/dev/null || true`
Expected: editorconfig-checker prints nothing. (ruff is optional; MegaLinter runs the Python linters in CI.)

```bash
git add .github/scripts/check_versions.py .github/scripts/test_check_versions.py .gitignore
git commit -m "ci(release): add a manifest version check for release runs"
```

---

### Task 2: release-please configuration and version markers

**Files:**

- Create: `release-please-config.json`
- Create: `.release-please-manifest.json`
- Modify: `CMakeLists.txt:3-4`
- Modify: `Makefile:3`

**Interfaces:**

- Consumes: `check_versions.py` (Task 1) to confirm the markers did not change any value.
- Produces: `release-please-config.json` and `.release-please-manifest.json` at the repository root, the default file names that
  `googleapis/release-please-action` and the `release-please` CLI read. Task 4 passes them explicitly as `config-file` and `manifest-file`.

- [ ] **Step 1: Add the CMake markers**

In `CMakeLists.txt`, change:

```cmake
project(tree-sitter-shellspec
        VERSION "0.1.0"
```

to:

```cmake
project(tree-sitter-shellspec
        # x-release-please-start-version
        VERSION "0.1.0"
        # x-release-please-end
```

- [ ] **Step 2: Add the Makefile markers**

In `Makefile`, change line 3 `VERSION := 0.1.0` to:

```makefile
# Block markers, not a trailing marker comment: make keeps the space before an inline
# comment in the value, which would turn VERSION into "0.1.0 " and break library names.
# x-release-please-start-version
VERSION := 0.1.0
# x-release-please-end
```

- [ ] **Step 3: Confirm the markers changed nothing**

Run: `python3 .github/scripts/check_versions.py 0.1.0; echo rc=$?`
Expected: all rows `ok`, `rc=0`.

Run: `make -n install >/dev/null; echo rc=$?`
Expected: `rc=0`. The marker lines are comments, so make must still parse the file.

Run: `cmake -S . -B /tmp/rp-cmake-check >/dev/null && grep -m1 CMAKE_PROJECT_VERSION: /tmp/rp-cmake-check/CMakeCache.txt; rm -rf /tmp/rp-cmake-check`
Expected: `CMAKE_PROJECT_VERSION:STATIC=0.1.0`. Skip this step and say so if `cmake` is not installed (`command -v cmake`).

- [ ] **Step 4: Create the release-please config**

Create `release-please-config.json`:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "node",
  "include-component-in-tag": false,
  "bump-minor-pre-major": true,
  "changelog-sections": [
    { "type": "feat", "section": "Features" },
    { "type": "fix", "section": "Bug Fixes" },
    { "type": "perf", "section": "Performance" },
    { "type": "deps", "section": "Dependencies" },
    { "type": "revert", "section": "Reverts", "hidden": true },
    { "type": "docs", "section": "Documentation", "hidden": true },
    { "type": "style", "section": "Styles", "hidden": true },
    { "type": "chore", "section": "Miscellaneous Chores", "hidden": true },
    { "type": "refactor", "section": "Code Refactoring", "hidden": true },
    { "type": "test", "section": "Tests", "hidden": true },
    { "type": "build", "section": "Build System", "hidden": true },
    { "type": "ci", "section": "Continuous Integration", "hidden": true }
  ],
  "packages": {
    ".": {
      "package-name": "@ivuorinen/tree-sitter-shellspec",
      "extra-files": [
        { "type": "json", "path": "tree-sitter.json", "jsonpath": "$.metadata.version" },
        { "type": "toml", "path": "pyproject.toml", "jsonpath": "$.project.version" },
        { "type": "toml", "path": "Cargo.toml", "jsonpath": "$.package.version" },
        { "type": "generic", "path": "CMakeLists.txt" },
        { "type": "generic", "path": "Makefile" }
      ]
    }
  }
}
```

The hidden types are listed explicitly: release-please starts a release for any commit whose type is not hidden, so an unlisted
`chore` could start one.

- [ ] **Step 5: Create the manifest**

Create `.release-please-manifest.json`:

```json
{ ".": "0.1.0" }
```

- [ ] **Step 6: Validate JSON and formatting**

Run: `python3 -m json.tool release-please-config.json >/dev/null && python3 -m json.tool .release-please-manifest.json >/dev/null && echo json-ok`
Expected: `json-ok`.

Run: `npx --no-install prettier --check release-please-config.json .release-please-manifest.json`
Run: `npx --no-install editorconfig-checker release-please-config.json .release-please-manifest.json CMakeLists.txt Makefile`
Expected: `All matched files use Prettier code style!` and no editorconfig output. If prettier reformats, run `npx --no-install prettier --write`
on the two files and re-check.

- [ ] **Step 7: Commit**

```bash
git add release-please-config.json .release-please-manifest.json CMakeLists.txt Makefile
git commit -m "ci(release): configure release-please and mark the CMake and Makefile versions"
```

- [ ] **Step 8: Dry-run release-please against a throwaway branch (needs the user's OK: it pushes a branch)**

release-please reads its config from the target branch on GitHub, so the dry run needs a pushed branch. Ask the user before pushing.

```bash
git switch -c tmp/release-please-dry-run
BOOT=$(git rev-parse HEAD)
python3 - "$BOOT" <<'EOF'
import json, sys
p = "release-please-config.json"
c = json.load(open(p))
c["bootstrap-sha"] = sys.argv[1]
json.dump(c, open(p, "w"), indent=2)
open(p, "a").write("\n")
EOF
git commit -qam "chore: dry-run bootstrap sha"
git commit -q --allow-empty -m "chore: hidden type must not release"
git push -q -u origin tmp/release-please-dry-run
npx --yes release-please@17.11.2 release-pr --token="$(gh auth token)" --repo-url=ivuorinen/tree-sitter-shellspec \
  --target-branch=tmp/release-please-dry-run --dry-run --debug 2>&1 | tail -20
```

Expected: no release PR would be opened (output says there are no user-facing commits / no pull requests). If it reports a PR, a
hidden type is releasable: stop and report.

```bash
git commit -q --allow-empty -m "deps: dry-run dependency entry"
git push -q
npx --yes release-please@17.11.2 release-pr --token="$(gh auth token)" --repo-url=ivuorinen/tree-sitter-shellspec \
  --target-branch=tmp/release-please-dry-run --dry-run --debug 2>&1 | tee /tmp/rp-dry-run.log | tail -40
grep -E '0\.1\.1|### Dependencies|dry-run dependency entry' /tmp/rp-dry-run.log
grep -E 'tree-sitter.json|pyproject.toml|Cargo.toml|CMakeLists.txt|Makefile|package-lock.json|package.json' /tmp/rp-dry-run.log | sort -u
```

Expected: the log names version `0.1.1`, a `### Dependencies` heading and the `dry-run dependency entry` line. The second grep should
list the seven files; if `--debug` does not print per-file updates, write that down in the task report — the `verify` job's version
check covers the files on the first real release.

- [ ] **Step 9: Remove the throwaway branch**

```bash
git switch feat/release-automation
git push -q origin --delete tmp/release-please-dry-run
git branch -D tmp/release-please-dry-run
rm -f /tmp/rp-dry-run.log
```

---

### Task 3: Renovate rule for runtime dependencies

**Files:**

- Modify: `.github/renovate.json` (append two entries to `packageRules`, after the existing two)

**Interfaces:**

- Consumes: the `deps` changelog type from Task 2's `release-please-config.json`.

- [ ] **Step 1: Add the rules**

Append these two objects to the end of the `packageRules` array in `.github/renovate.json`:

```json
    {
      "description": "Runtime deps change what users install, so they release as 'deps:' (Dependencies, patch). Keep last: last match wins.",
      "matchManagers": ["npm", "cargo", "pep621"],
      "matchDepTypes": ["dependencies", "peerDependencies", "project.dependencies", "project.optional-dependencies"],
      "matchUpdateTypes": ["minor", "patch", "pin", "digest"],
      "commitMessagePrefix": "deps: "
    },
    {
      "description": "A runtime dep major (e.g. tree-sitter-bash) can change parse trees: mark it breaking (minor bump below 1.0.0).",
      "matchManagers": ["npm", "cargo", "pep621"],
      "matchDepTypes": ["dependencies", "peerDependencies", "project.dependencies", "project.optional-dependencies"],
      "matchUpdateTypes": ["major"],
      "commitMessagePrefix": "deps!: "
    }
```

- [ ] **Step 2: Validate**

Run: `npx --yes --package renovate@latest -- renovate-config-validator --strict .github/renovate.json`
Expected: `Config validated successfully`. The first run downloads Renovate and takes a while.

Run: `npx --no-install prettier --check .github/renovate.json && npx --no-install editorconfig-checker .github/renovate.json`
Expected: prettier passes and editorconfig prints nothing. The `description` strings must stay under 160 characters per line after
prettier formatting; if editorconfig-checker reports a long line, shorten the description.

- [ ] **Step 3: Commit**

```bash
git add .github/renovate.json
git commit -m "chore(renovate): release runtime dependency updates as deps commits"
```

---

### Task 4: The release workflow

**Files:**

- Replace: `.github/workflows/release.yml` (whole file)

**Interfaces:**

- Consumes: `.github/scripts/check_versions.py <version>` (Task 1); `release-please-config.json` and `.release-please-manifest.json` (Task 2).
- Produces, for the bootstrap docs in Task 5: environments `release-please` (variable `RELEASE_APP_CLIENT_ID`, secret
  `RELEASE_APP_PRIVATE_KEY`) and `release`; workflow file name `release.yml`; artifacts `npm-package` and `python-sdist`.

- [ ] **Step 1: Replace the workflow**

Write `.github/workflows/release.yml`:

```yaml
---
# yaml-language-server: $schema=https://www.schemastore.org/github-workflow.json
# release-please keeps a release PR open on main. Merging it tags vX.Y.Z (the Go and Swift
# release) and creates the GitHub release; this run then verifies, builds, and — after one
# approval on the `release` environment — publishes to npm, PyPI and crates.io through OIDC
# trusted publishing. No registry token exists anywhere. The registries' trusted publishers
# name this file, so renaming it breaks publishing until they are updated.
name: Release

on:
  push:
    branches: [main]
  # The build job doubles as a packaging check on every pull request.
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false

permissions:
  contents: read

jobs:
  release-please:
    name: 🏷️ Release Please
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    timeout-minutes: 10
    # Holds the App credentials; the environment allows deployments from main only.
    environment: release-please
    permissions: {}
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
      version: ${{ steps.release.outputs.version }}

    steps:
      # A PR opened with GITHUB_TOKEN triggers no workflows, so the release PR would get no CI.
      # An App token does trigger them.
      - name: Create GitHub App token
        id: app-token
        uses: actions/create-github-app-token@bcd2ba49218906704ab6c1aa796996da409d3eb1 # v3.2.0
        with:
          client-id: ${{ vars.RELEASE_APP_CLIENT_ID }}
          private-key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
          permission-contents: write
          permission-pull-requests: write

      - name: Run release-please
        id: release
        uses: googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7 # v5.0.0
        with:
          token: ${{ steps.app-token.outputs.token }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json

  verify:
    name: 🔍 Verify Release
    needs: release-please
    if: needs.release-please.outputs.release_created == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 30
    permissions:
      contents: read # required to check out the tag
      actions: read # required to read test.yml run status

    steps:
      - name: Checkout Repository
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}
          persist-credentials: false

      - name: Check every manifest carries the release version
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: python3 .github/scripts/check_versions.py "$VERSION"

      - name: Audit production dependencies
        run: npm audit --package-lock-only --omit=dev --audit-level=high

      # test.yml starts on the same push as this run, so wait for it instead of failing on a
      # run that has not finished.
      - name: Wait for CI on the release commit
        uses: actions/github-script@3a2844b7e9c422d3c10d287c895573f7108da1b3 # v9.0.0
        with:
          script: |
            const { owner, repo } = context.repo;
            const { data: list } = await github.rest.actions.listRepoWorkflows({ owner, repo });
            const wf = list.workflows.find(w => w.path === '.github/workflows/test.yml');
            if (!wf) { core.setFailed('.github/workflows/test.yml not found'); return; }
            const deadline = Date.now() + 25 * 60 * 1000;
            for (;;) {
              const { data } = await github.rest.actions.listWorkflowRuns({
                owner, repo, workflow_id: wf.id, head_sha: context.sha, per_page: 1,
              });
              const run = data.workflow_runs[0];
              if (run && run.status === 'completed') {
                if (run.conclusion === 'success') core.info(`test.yml succeeded: ${run.html_url}`);
                else core.setFailed(`test.yml concluded ${run.conclusion}: ${run.html_url}`);
                return;
              }
              if (Date.now() > deadline) { core.setFailed('test.yml did not finish within 25 minutes'); return; }
              await new Promise(resolve => setTimeout(resolve, 30000));
            }

  build:
    name: 📦 Build Packages
    needs: [release-please, verify]
    # On a pull request both needed jobs are skipped; always() keeps that from skipping this one.
    if: always() && (github.event_name == 'pull_request' || needs.verify.result == 'success')
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read # required to check out the repository

    steps:
      - name: Checkout Repository
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          # Empty on pull requests, which checks out the PR as usual.
          ref: ${{ needs.release-please.outputs.tag_name }}
          persist-credentials: false

      # zizmor: ignore[cache-poisoning] no cache input is set, so nothing is restored
      - name: Setup Node.js 24
        uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
        with:
          node-version: 24

      # Packs the committed sources; test.yml fails when committed src/ differs from a fresh
      # generate, so no generate step and no dependency install run here.
      - name: Pack npm tarball
        run: npm pack --ignore-scripts

      - name: Setup Python
        uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        with:
          python-version: "3.12"

      # sdist only: setup.py compiles the parser, so a wheel built here is linux_x86_64,
      # which PyPI rejects. Platform wheels come with the binary builds.
      - name: Build Python sdist
        run: |
          python -m pip install build==1.6.1 twine==7.0.0
          python -m build --sdist
          python -m twine check --strict dist/*

      # Builds and verifies the crate; publish-crates runs cargo publish from the tag itself.
      - name: Package crate
        run: cargo package --locked

      - name: Upload npm tarball
        if: github.event_name == 'push'
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: npm-package
          path: "*.tgz"
          if-no-files-found: error

      - name: Upload Python sdist
        if: github.event_name == 'push'
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: python-sdist
          path: dist/
          if-no-files-found: error

  publish-npm:
    name: 🚀 Publish to npm
    needs: [release-please, build]
    if: needs.release-please.outputs.release_created == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 10
    environment: release
    permissions:
      id-token: write # required for npm trusted publishing (OIDC) and provenance

    steps:
      - name: Download npm tarball
        uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: npm-package
          path: pkg

      # zizmor: ignore[cache-poisoning] no cache input is set, so nothing is restored
      - name: Setup Node.js 24
        uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
        with:
          node-version: 24
          registry-url: "https://registry.npmjs.org"

      - name: Require npm 11.5.1 or newer
        run: |
          have="$(npm --version)"
          node -e '
            const [a, b, c] = process.argv[1].split(".").map(Number);
            process.exit(a > 11 || (a === 11 && (b > 5 || (b === 5 && c >= 1))) ? 0 : 1);
          ' "$have" || { echo "::error::npm $have is older than 11.5.1, which trusted publishing needs"; exit 1; }

      - name: Publish
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: |
          if npm view "@ivuorinen/tree-sitter-shellspec@$VERSION" version >/dev/null 2>&1; then
            echo "@ivuorinen/tree-sitter-shellspec@$VERSION is already on npm; skipping"
            exit 0
          fi
          tag=latest
          [[ "$VERSION" == *-* ]] && tag=next
          npm publish ./pkg/*.tgz --access public --tag "$tag"

  publish-pypi:
    name: 🐍 Publish to PyPI
    needs: [release-please, build]
    if: needs.release-please.outputs.release_created == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 10
    environment: release
    permissions:
      id-token: write # required for PyPI trusted publishing and attestations

    steps:
      - name: Download Python sdist
        uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: python-sdist
          path: dist

      - name: Check whether the version exists
        id: exists
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: |
          if curl -fsS -o /dev/null "https://pypi.org/pypi/tree-sitter-shellspec/$VERSION/json"; then
            echo "tree-sitter-shellspec $VERSION is already on PyPI; skipping"
            echo "found=true" >> "$GITHUB_OUTPUT"
          fi

      - name: Publish
        if: steps.exists.outputs.found != 'true'
        uses: pypa/gh-action-pypi-publish@dc37677b2e1c63e2034f94d8a5b11f265b73ba33 # v1.14.2
        with:
          packages-dir: dist/

  publish-crates:
    name: 🦀 Publish to crates.io
    needs: [release-please, build]
    if: needs.release-please.outputs.release_created == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 15
    environment: release
    permissions:
      contents: read # required to check out the tag
      id-token: write # required for crates.io trusted publishing

    steps:
      - name: Check whether the version exists
        id: exists
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: |
          # crates.io rejects API requests without a User-Agent.
          if curl -fsS -o /dev/null -A "tree-sitter-shellspec release (github.com/ivuorinen/tree-sitter-shellspec)" \
            "https://crates.io/api/v1/crates/tree-sitter-shellspec/$VERSION"; then
            echo "tree-sitter-shellspec $VERSION is already on crates.io; skipping"
            echo "found=true" >> "$GITHUB_OUTPUT"
          fi

      # Cargo cannot upload a prebuilt .crate, so publish from the tag itself.
      - name: Checkout Repository
        if: steps.exists.outputs.found != 'true'
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}
          persist-credentials: false

      - name: Get a short-lived crates.io token
        if: steps.exists.outputs.found != 'true'
        id: auth
        uses: rust-lang/crates-io-auth-action@c6f97d42243bad5fab37ca0427f495c86d5b1a18 # v1.0.5

      - name: Publish
        if: steps.exists.outputs.found != 'true'
        env:
          CARGO_REGISTRY_TOKEN: ${{ steps.auth.outputs.token }}
        run: cargo publish --locked
```

The `publish-*` jobs have no status function in `if:`, so GitHub adds an implicit `success()`: when `build` is skipped or fails they are
skipped too, even though `build` itself uses `always()`.

- [ ] **Step 2: Lint the workflow**

Run: `actionlint .github/workflows/release.yml; echo rc=$?`
Expected: `rc=0`.

Run: `command -v zizmor >/dev/null && zizmor --offline .github/workflows/release.yml || echo "zizmor not available locally; MegaLinter runs it on the PR"`
Expected: no findings, or the "not available" line. Fix any finding before continuing; do not add an ignore without a reason comment.

Run: `npx --no-install editorconfig-checker .github/workflows/release.yml && pre-commit run --files .github/workflows/release.yml`
Expected: editorconfig prints nothing; yamllint, actionlint and checkov hooks pass.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci(release): replace the token-based release with release-please and trusted publishing"
```

---

### Task 5: Documentation and spec corrections

**Files:**

- Modify: `README.md` (the "Using npm" subsection under "Installation", lines 27-33)
- Modify: `CONTRIBUTING.md` (Table of Contents; new "Releasing" section before "## Reporting Issues")
- Modify: `CLAUDE.md` ("## CI/CD Pipeline", lines 161-165)
- Modify: `docs/superpowers/specs/2026-09-22-release-automation-design.md`

**Interfaces:**

- Consumes: environment and variable names from Task 4: `release-please` (`RELEASE_APP_CLIENT_ID`, `RELEASE_APP_PRIVATE_KEY`), `release`.

- [ ] **Step 1: README install section**

Replace the "Using npm" subsection (heading through its code block) with:

````markdown
### Using npm

```bash
npm install @ivuorinen/tree-sitter-shellspec
```

### Using pip

```bash
pip install tree-sitter-shellspec
```

The PyPI package is a source distribution, so installing it compiles the parser and needs a C compiler.

### Using Cargo

```bash
cargo add tree-sitter-shellspec
```

### Using Go

```bash
go get github.com/ivuorinen/tree-sitter-shellspec
```
````

- [ ] **Step 2: CONTRIBUTING "Releasing" section**

Insert before `## Reporting Issues`:

```markdown
## Releasing

Releases are automated with [release-please](https://github.com/googleapis/release-please).

1. Merging to `main` updates an open release PR. It bumps the version in every manifest and adds the new entries to `CHANGELOG.md`.
    `feat`, `fix`, `perf` and `deps` commits appear in the changelog and cause a release; other types do not.
2. Merging the release PR tags `vX.Y.Z` and creates the GitHub release. The tag is the release for the Go module and the Swift package.
3. The release workflow then waits for approval on the `release` environment. After approval it publishes to npm, PyPI and
    crates.io with trusted publishing (OIDC). No registry token is stored anywhere.

Runtime dependency updates use the `deps:` type (`deps!:` for a major), so they release and appear under "Dependencies".
Renovate applies this prefix itself; use it for hand-made runtime dependency changes too.

### One-time setup

Done once, before the first release PR is merged:

1. Create a GitHub App installed on this repository only, with `Contents: write` and `Pull requests: write`. In the
    `release-please` environment (deployments from `main` only), store its client ID as the variable `RELEASE_APP_CLIENT_ID`
    and its private key as the secret `RELEASE_APP_PRIVATE_KEY`.
2. Create the `release` environment with the maintainer as a required reviewer and deployments from `main` only.
3. From a clean checkout, publish `0.1.0` by hand: `npm publish --access public` and `cargo publish`.
4. Add trusted publishers for repository `ivuorinen/tree-sitter-shellspec`, workflow `release.yml`, environment `release`:
    on npm and crates.io in the package settings, on PyPI as a pending publisher for `tree-sitter-shellspec`.
5. On npm, set publishing access to "Require two-factor authentication and disallow tokens".
6. Tag the commit from step 3 as `v0.1.0`, push the tag, and create a GitHub release for it. release-please counts versions from it.
```

Add `- [Releasing](#releasing)` to the Table of Contents, directly before the `Reporting Issues` entry, matching the existing entries'
format.

- [ ] **Step 3: CLAUDE.md CI/CD paragraph**

Append to the "## CI/CD Pipeline" paragraph, after the sentence ending ``listed in `.mega-linter.yml`.``:

```markdown
`release.yml` runs release-please on pushes to `main` and, when a release PR merges, verifies the manifest versions
(`.github/scripts/check_versions.py`), builds the npm tarball, Python sdist and crate, and publishes all three through OIDC trusted
publishing after approval on the `release` environment. Its build job also runs on pull requests as a packaging check.
```

- [ ] **Step 4: Correct the spec**

In `docs/superpowers/specs/2026-09-22-release-automation-design.md`:

- In "### build", replace the bullet `` `python -m build` produces the sdist and wheel, and `twine check --strict` validates their metadata. ``
  with two bullets:
  - `` `python -m build --sdist` produces the sdist, and `twine check --strict` validates its metadata. ``
  - `` No wheel is built: `setup.py` compiles the parser, so the wheel is `linux_x86_64`, which PyPI rejects. ``
- In "### publish-npm, publish-pypi, publish-crates", replace ``**PyPI:** downloads `dist/` and runs`` with
  ``**PyPI:** downloads the sdist into `dist/` and runs``.
- In "### release-please" and "## One-time bootstrap", replace "App ID" with "App client ID"
  (`create-github-app-token` v3 deprecates `app-id` in favour of `client-id`).
- In "### verify", replace the bullet that starts "Fails the run unless all seven version fields equal" so it starts
  ``Runs `.github/scripts/check_versions.py` and fails the run unless all seven version fields equal``.

- [ ] **Step 5: Lint and commit**

Run, with `SPEC=docs/superpowers/specs/2026-09-22-release-automation-design.md`:

```bash
npx --no-install markdownlint README.md CONTRIBUTING.md CLAUDE.md "$SPEC" --config .markdownlint.json
npx --no-install editorconfig-checker README.md CONTRIBUTING.md CLAUDE.md "$SPEC"
```

Expected: no output from either.

```bash
git add README.md CONTRIBUTING.md CLAUDE.md docs/superpowers/specs/2026-09-22-release-automation-design.md
git commit -m "docs: document the release process and install from each registry"
```

---

### Task 6: Pull request and CI check (needs the user's OK: pushes and opens a PR)

**Files:** none changed.

- [ ] **Step 1: Full local check**

Run: `npm test 2>&1 | tail -2 && python3 -m unittest discover -s .github/scripts && python3 .github/scripts/check_versions.py 0.1.0`
Expected: `failed parses: 0`, `OK`, and all version rows `ok`.

- [ ] **Step 2: Push and open the PR**

```bash
git push -u origin feat/release-automation
gh pr create --base main --title "ci(release): automate releases with release-please and trusted publishing" --body-file <file>
```

The PR body summarises the spec, lists the one-time setup from CONTRIBUTING "Releasing", and states the two spec corrections
(sdist only, client ID).

- [ ] **Step 3: Confirm the packaging check on the PR**

Run: `gh pr checks --watch`
Expected: `📦 Build Packages` passes (npm pack, sdist + twine check, cargo package), along with CI and MegaLinter. `🏷️ Release Please`,
`🔍 Verify Release` and the three publish jobs show as skipped.

---

## After merge (maintainer, by hand)

Not part of this plan's tasks: the one-time setup in CONTRIBUTING "Releasing" (GitHub App, environments, hand publish of `0.1.0`,
trusted publishers, `v0.1.0` tag). Until the `release-please` environment has the App credentials, the `release-please` job fails on
every push to `main`; do the setup promptly after merging.
