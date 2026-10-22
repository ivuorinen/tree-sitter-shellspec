#!/usr/bin/env bash
#MISE description="Test the Python binding against the tree-sitter runtime"
# Builds the binding with pip and loads it through the py-tree-sitter runtime, which
# is what catches a declared runtime too old for the grammar's ABI. A throwaway venv
# keeps the install out of the mise-managed Python.
set -euo pipefail

venv=.temp/venv-bindings
# setuptools writes this next to the package. npm does not apply .gitignore inside the
# `files` directories, so a leftover copy would end up in a local `npm pack`.
egg_info=bindings/python/tree_sitter_shellspec.egg-info

rm -rf "$venv"
trap 'rm -rf "$egg_info"' EXIT
python -m venv "$venv"
"$venv/bin/python" -m pip install --quiet --upgrade pip
"$venv/bin/python" -m pip install --quiet '.[core]'
# importlib.metadata, not tree_sitter.__version__: py-tree-sitter only added that in
# 0.26.0, and pyproject.toml's tree-sitter~=0.25 also allows 0.25.x.
"$venv/bin/python" -c "from importlib.metadata import version; print('tree-sitter runtime', version('tree-sitter'))"
"$venv/bin/python" -m unittest discover -s bindings/python/tests -v
