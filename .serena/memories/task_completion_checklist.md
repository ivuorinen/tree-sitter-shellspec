# Task Completion Checklist

When completing any development task in this project, follow these steps:

## 1. Code Quality Checks

- [ ] Run `npm run generate` or `tree-sitter generate` to regenerate parser after grammar changes
- [ ] Run `npm test` or `tree-sitter test` if test files exist
- [ ] Check EditorConfig compliance (blocking errors)
- [ ] Fix any linting issues (considered blocking)

## 2. Linting and Formatting

- [ ] Run `npm run lint` or `npx mega-linter-runner` for comprehensive linting
- [ ] Fix all linting errors (NO linting issues are acceptable)
- [ ] Run `npm run precommit` or `pre-commit run --all-files` to verify pre-commit hooks pass
- [ ] Use autofixers before manual lint fixing

## 3. Specific Linters to Run

- [ ] `npm run lint:yaml` or `yamllint .` for YAML files
- [ ] `npm run lint:markdown` or `markdownlint . --config .markdownlint.json --fix` for Markdown
- [ ] `shellcheck` for any shell scripts

## 4. Development Workflow

- [ ] Use `npm run dev` for quick development cycles (generate + test)
- [ ] Use `npm run web` for interactive grammar testing
- [ ] Use `npm run rebuild` if encountering parser issues

## 5. Git Workflow

- [ ] Ensure you are in the project root directory
- [ ] Stage changes with `git add`
- [ ] Commit with descriptive message
- [ ] **NEVER** use `git commit --no-verify`
- [ ] **NEVER** commit automatically unless explicitly requested

## 6. Tree-sitter Specific

- [ ] Verify grammar generates without errors
- [ ] Test parsing of sample ShellSpec files if available
- [ ] Ensure conflicts are properly handled
- [ ] Check that new rules don't break existing bash parsing
- [ ] Run test suite and ensure reasonable pass rate (aim for >85%)

## 7. Testing

- [ ] Add tests to `test/corpus/` for new grammar features
- [ ] Ensure tests follow tree-sitter test format
- [ ] Verify test expectations match actual parser output
- [ ] Update test expectations if grammar behavior changes

## Important Notes

- EditorConfig violations are blocking errors
- All linting errors must be fixed before completion
- Use full paths when changing directories
- Use `nvm` for Node.js version management
- Never modify generated files in `src/` manually
- Current test suite has 53 tests with 87% pass rate (46/53)
