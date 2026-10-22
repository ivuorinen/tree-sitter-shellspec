#!/usr/bin/env bash
#MISE description="Test the Node, Python and Go bindings"
#MISE depends=["test:bindings:node", "test:bindings:python", "test:bindings:go"]
# The binding tasks do the work; this task only groups them.
set -euo pipefail
