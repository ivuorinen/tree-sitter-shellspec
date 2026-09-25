#!/usr/bin/env python3
"""Fail when any manifest's version differs from the release version.

release-please bumps package.json and package-lock.json natively and five more
files through extra-files updaters that match by JSON/TOML path or by marker
comments. An updater that matches nothing leaves its file at the old version
without any error, and the registries would then get packages whose metadata
disagrees with the tag. The release workflow runs this before building anything,
so such a mismatch stops the release instead of publishing it.

Stdlib only (tomllib needs Python 3.11+), so it runs on a bare runner with no
install step.
"""

import json
import re
import sys
from pathlib import Path

import tomllib

NOT_FOUND = "<not found>"


def _match(pattern: str, text: str) -> str:
    """Return the first capture group, or NOT_FOUND.

    A missing field then shows up as a mismatch row instead of a traceback.
    """
    found = re.search(pattern, text, re.MULTILINE)
    return found.group(1) if found else NOT_FOUND


def read_versions(root: Path) -> dict[str, str]:
    """Read the version field of every manifest release-please maintains."""

    def text(name: str) -> str:
        return (root / name).read_text()

    lock = json.loads(text("package-lock.json"))
    return {
        "package.json": json.loads(text("package.json"))["version"],
        "package-lock.json": lock["version"],
        'package-lock.json packages[""]': lock["packages"][""]["version"],
        "tree-sitter.json": json.loads(text("tree-sitter.json"))["metadata"]["version"],
        "pyproject.toml": tomllib.loads(text("pyproject.toml"))["project"]["version"],
        "Cargo.toml": tomllib.loads(text("Cargo.toml"))["package"]["version"],
        # The project() call's VERSION argument; cmake_minimum_required(VERSION
        # ...) does not start a line, so it cannot match.
        "CMakeLists.txt": _match(r'^\s*VERSION "([^"]+)"\s*$', text("CMakeLists.txt")),
        # \S+$ rejects trailing whitespace, which make would keep in the value.
        "Makefile": _match(r"^VERSION := (\S+)$", text("Makefile")),
    }


def main(argv: list[str]) -> int:
    """Print one row per manifest; return 1 if any differs from argv[1]."""
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
