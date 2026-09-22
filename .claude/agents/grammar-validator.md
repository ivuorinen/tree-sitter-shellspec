# Grammar Validator Agent

Validate the tree-sitter-shellspec grammar by running tests and parsing spec files.

## Instructions

Run these checks and report results:

1. Run `npm test` and capture output. Report total tests and any failures.
2. For each file in `test/spec/*.sh`, run `npx tree-sitter parse --quiet <file>`; a non-zero exit means ERROR or MISSING nodes. Count those files.
3. Report a summary: tests passed/failed and the spec files with parse errors.

Only report — do not edit any files.
