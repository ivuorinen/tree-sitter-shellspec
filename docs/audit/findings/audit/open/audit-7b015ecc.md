---
id: audit-7b015ecc
auditor: audit
severity: advisory
category: conventions
area: git history (2e62a33)
status: open
found: 2026-09-15
---

# malformed-convention: root commit "Initial commit" has no Conventional Commits type

## Problem

malformed-convention on the repository's root commit.

## Evidence

`git log --format=%s 2e62a33` → `Initial commit` (GitHub template commit); every other commit in the 136-commit range matches `type(scope)?!?: subject`.

## Impact

No version or changelog consequence (no release automation, pushed root commit); recorded for completeness.

## Fix

No change to pushed history; none required.
