#!/usr/bin/env bash
#MISE description="Build and check the Python sdist"
# sdist only: setup.py compiles the parser, so a wheel built here is linux_x86_64,
# which PyPI rejects. Platform wheels come with the binary builds.
# A throwaway venv keeps the build tools out of the mise-managed Python.
set -euo pipefail

venv=.temp/venv-package
# setuptools writes this next to the package. npm does not apply .gitignore inside the
# `files` directories, so a leftover copy would end up in a local `npm pack`.
egg_info=bindings/python/tree_sitter_shellspec.egg-info

rm -rf "$venv" dist
trap 'rm -rf "$egg_info"' EXIT
python -m venv "$venv"
"$venv/bin/python" -m pip install --quiet build==1.6.1 twine==7.0.0
"$venv/bin/python" -m build --sdist
"$venv/bin/python" -m twine check --strict dist/*
