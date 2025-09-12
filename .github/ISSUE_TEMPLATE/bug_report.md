---
name: Bug report
about: Report a parsing issue or bug in tree-sitter-shellspec
title: "[BUG] "
labels: bug
assignees: ivuorinen
---

**Describe the bug**
A clear and concise description of the parsing issue or bug.

**ShellSpec code that doesn't parse correctly**
Please provide the ShellSpec code that causes the issue:

```shellspec
# Paste your ShellSpec code here
```

**Expected parsing behavior**
A clear description of how the code should be parsed or what syntax highlighting you expected.

**Actual behavior**
What actually happens when the parser encounters this code? Include any error messages.

**Environment:**

- OS: [e.g. Linux, macOS, Windows]
- Editor: [e.g. Neovim, VS Code, Emacs]
- tree-sitter-shellspec version: [e.g. 0.1.0]
- tree-sitter version: [e.g. 0.20.0]
- ShellSpec version: [e.g. 0.28.1]

**Tree-sitter parse output (if applicable)**
If you can run `tree-sitter parse`, please include the output:

```text
# tree-sitter parse output here
```

## Additional context

- Is this code from a real ShellSpec test file?
- Does the code work correctly with the ShellSpec test runner?
- Any other context that might help debug the issue.
