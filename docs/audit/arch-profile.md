# Architecture Profile

Generated: 2026-09-15

Detected: none
Confidence: none — manual review required

## Detected Patterns

No catalogued pattern matched with Medium or higher confidence.

Structural evidence examined:

- Single hand-written source of truth: `grammar.js`, which calls
  `grammar(bashGrammar, {...})` to inherit and extend `tree-sitter-bash/grammar`.
- Generated artifacts under `src/` (`parser.c`, `grammar.json`, `node-types.json`,
  `tree_sitter/*.h`) produced by `tree-sitter generate`, post-patched by
  `scripts/post-generate.sh`.
- One hand-maintained C file co-located with the generated output: `src/scanner.c`
  (external scanner copied from `tree-sitter-bash`).
- Editor query layer: `queries/highlights.scm`.
- Tests: `test/corpus/*.txt` (tree-sitter corpus format) and `test/spec/*.sh`
  (real-world ShellSpec files parsed for ERROR nodes).
- No `domain/`, `ports/`, `adapters/`, `use-cases/`, `services/`, `plugins/`,
  `features/`, `models/`/`views/`/`controllers/`, `commands/`/`queries/` (CQRS),
  or event directories exist. There is no import graph beyond the single
  `require("tree-sitter-bash/grammar")`.

## Detected Combination

none

## Inferred Structural Rules

none

## Ambiguities & Contradictions

- Grammar inheritance (`grammar(base, {...})`) superficially resembles Plugin /
  Extension (core + extension point), but there is no registry and no multiple
  extensions; confidence Low, below the threshold for inferring rules.
- The project's own conventions (CLAUDE.md) define a de-facto rule set that is
  not an architectural pattern: `src/` holds generated files that must not be
  hand-edited, yet `src/scanner.c` is hand-maintained and lives in that same
  directory. Any `arch` review should treat this as a declared convention, not a
  pattern-derived rule.
