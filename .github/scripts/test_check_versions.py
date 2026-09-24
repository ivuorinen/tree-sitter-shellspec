"""Tests for check_versions.py.

Each test copies the manifests into a temp directory and reads the version they
currently carry, so a release bumping every manifest does not break the tests.
"""

import shutil
import subprocess  # nosec B404 - runs this repo's own script, never user input
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("check_versions.py")
REPO = Path(__file__).resolve().parents[2]
FILES = [
    "package.json",
    "package-lock.json",
    "tree-sitter.json",
    "pyproject.toml",
    "Cargo.toml",
    "CMakeLists.txt",
    "Makefile",
]


def run(version: str, root: Path) -> subprocess.CompletedProcess:
    """Run the script as the workflow does, so the exit code itself is tested."""
    # check=False: a non-zero exit is the behaviour under test, not an error.
    # nosec B603: argv is the interpreter, a fixed path and test-chosen strings.
    return subprocess.run(  # nosec B603
        [sys.executable, str(SCRIPT), version, str(root)],
        capture_output=True,
        text=True,
        check=False,
    )


class CheckVersionsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        for name in FILES:
            shutil.copy(REPO / name, self.tmp / name)
        self.current = (
            run("0.0.0", self.tmp).stdout.split("package.json", 1)[1].split()[0]
        )

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
        cargo.write_text(
            cargo.read_text().replace(
                f'version = "{self.current}"', 'version = "0.0.1"', 1
            )
        )
        result = run(self.current, self.tmp)
        self.assertEqual(result.returncode, 1)
        self.assertRegex(result.stdout, r"Cargo\.toml\s+0\.0\.1\s+MISMATCH")

    def test_makefile_trailing_whitespace_fails(self):
        # GNU make keeps the space before an inline comment in the value, so
        # "VERSION := 0.1.0 # marker" yields "0.1.0 " and breaks library names.
        makefile = self.tmp / "Makefile"
        makefile.write_text(
            makefile.read_text().replace(
                f"VERSION := {self.current}", f"VERSION := {self.current} # marker", 1
            )
        )
        self.assertEqual(run(self.current, self.tmp).returncode, 1)


if __name__ == "__main__":
    unittest.main()
