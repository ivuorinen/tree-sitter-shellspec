---
name: Grammar Issue
about: Report a specific grammar parsing problem or conflict
title: "[GRAMMAR] "
labels: grammar, bug
assignees: ivuorinen
---

## Grammar Issue Type

- [ ] Parsing error (code doesn't parse at all)
- [ ] Incorrect parse tree structure
- [ ] Grammar conflicts during generation
- [ ] Performance issue with large files
- [ ] Integration issue with tree-sitter-bash

## ShellSpec code causing the issue

```shellspec
# Paste the problematic ShellSpec code here
```

### Current parse tree output

If you can run `tree-sitter parse`, please include the current output:

```text
# Current parse tree here
```

### Expected parse tree structure

Describe or show what the parse tree should look like:

```text
# Expected parse tree structure here
```

### Grammar generation output

If this causes issues during `npm run generate`, include any conflict warnings or errors:

```text
# Grammar generation output here
```

## Environment

- tree-sitter-shellspec version: [e.g. 0.1.0]
- tree-sitter CLI version: [e.g. 0.20.8]
- Node.js version: [e.g. 18.17.0]
- OS: [e.g. macOS 13.5]

## Impact

- How does this affect syntax highlighting?
- Does it break editor functionality?
- Is this blocking real-world usage?

## Additional context

- Related to specific ShellSpec features?
- Reproducible with minimal example?
- Any workarounds discovered?
