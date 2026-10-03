---
name: git-workflow
description: >
  Git conventions for projects developed inside the piw.
  Covers commit format, branch strategy, and integration with the
  alignment-before-action workflow. A global skill that gives way
  to project-local conventions.
---

# Git workflow

This skill defines git conventions for projects developed inside the
piw. It is a global skill: if a project has its own git
conventions (in a local skill or CONTRIBUTING.md), those take
priority.

## Commit format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short description>

<optional body with motivation>
```

Types:

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `chore` | Maintenance, tooling, config |
| `refactor` | Code change with no behavior change |
| `test` | Adding or updating tests |

Add a scope in parentheses for context: `feat(piw):`, `docs(workflow):`.

## Commit granularity

One logical change per commit. If the commit message needs "and also,"
split it into two commits. Each commit should leave the project in a
working state.

## Branch strategy

- **Solo work:** commit directly to `main`. Keep the working tree
  clean before switching context.
- **Collaborative projects:** use feature branches. Name them
  `<type>/<short-description>` (e.g., `feat/add-yadm-support`).
  Open a pull request for review before merging.

## Pre-commit hygiene

Before each commit:

1. Review the diff (`git diff --cached`).
2. Check for debug code, commented-out code, or unrelated changes.
3. Verify the commit message follows the format above.

## Relationship to the workflow skill

The workflow skill defines propose → align → implement. The commit is
the last step. Commit only code that was aligned first.
