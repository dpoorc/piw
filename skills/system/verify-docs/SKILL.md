---
name: verify-docs
description: >
  Verify documentation against filesystem state and program
  behavior. Use when documentation describes paths, commands,
  config values, or conventions that may drift from reality.
  Checks static claims (files, structure) and behavioral claims
  (run the program, grep the codebase, inspect interfaces).
---

# Verify docs

Documentation makes claims. Some are about the filesystem
("the config is at `config/default.yaml`"). Some are about
behavior ("run `npm run dev` to start"). Some are about the
code itself ("all components use TypeScript strict mode").

This skill checks those claims against the codebase and the
tools that operate on it. You run it when you start work on
an unfamiliar project, after a refactor, or before a release.

## Claim types

Each claim in a doc falls into one of these categories:

| Type | What the doc says | How to check |
|------|-------------------|-------------|
| **Existence** | "File X is at path Y" | `test -f Y`, `test -d Y` |
| **Structure** | "Modules live in `src/features/`" | `ls src/features/`, check naming |
| **Behavior** | "Run `npm test` to verify" | Check if the script exists (`jq '.scripts.test' package.json`) |
| **Behavior (output)** | "`--help` shows the `build` command" | Run `tool --help \| grep build` |
| **Dependency** | "This project uses React 18" | `jq '.dependencies.react' package.json` |
| **Configuration** | "Set `LOG_LEVEL=debug` for verbose logging" | Check if the var is actually read (`grep -r 'LOG_LEVEL' src/`) |
| **Interface** | "The `auth()` function returns `{ token, user }`" | Grep for the function signature, inspect return type |
| **Convention** | "All components are PascalCase files" | `find src -name '*.tsx'` and check naming pattern |
| **Count / size** | "There are 15 API route handlers" | `find src/routes -name '*.ts' \| wc -l` and compare |

## Protocol — two-pass verification

Work in two passes. The first pass is cheap and read-only. The
second pass collects behavioral checks that need to run actual
programs. You present the second-pass list for approval.

### Pass 1: static verification

For each claim in the doc:

1. **Classify** the claim by type from the table above.
2. **If it is a static claim** (existence, structure, dependency,
   configuration, convention, count) — write the verification
   command, run it, compare expected vs actual, record the result.
3. **If it is a behavioral claim** (behavior, behavior output,
   interface) — do not run anything yet. Add the claim and its
   proposed verification command to the second-pass list.

Static checks are fast, read-only operations: `test -f`, `ls`,
`grep`, `jq`, `find`, `diff`. Run them without hesitation.

### Pass 2: behavioral verification

Collect all behavioral claims that passed the static checks but
still need a program run to confirm behavior. Present the list:

```
Behavioral checks needed:
- "npm test runs the test suite" → `npm test -- --dry-run || echo "dry-run not supported"`
- "pip install -e . installs the package" → check setup.py exists
  (static), then would need `pip install -e . --dry-run`
- "tool --help shows --dry-run flag" → `tool --help | grep dry-run`
```

For each item, note whether the command is safe to run:

| Safety | Examples | Action |
|--------|----------|--------|
| **Safe** — read-only, no side effects | `--help`, `--version`, `--dry-run`, syntax check | Run it directly. |
| **May modify state** — installs, writes, builds | `npm install`, `docker build`, `pip install` | Flag as `⚠` and let the user decide. |
| **Expensive** — takes more than a few seconds | Full test suite, integration tests, compilation | Flag as `⚠` and let the user decide. |

### Report

Group results by severity:

1. **Mismatches** — `✗` what the doc says is provably wrong
2. **Uncertain** — `⚠` could not verify without a side effect
3. **Matches** — `✓` the doc matches reality
4. **Unchecked** — `?` behavioral claims awaiting user approval

## Examples

Each example runs pass 1 first, then collects pass 2 items.

### Example 1: install and run

A README says:

> "Install with `pip install -r requirements.txt`. Set
> `DATABASE_URL` in `.env`. Run `python main.py`."

Checks:

| Claim | Command | Expected |
|-------|---------|----------|
| `requirements.txt` exists | `test -f requirements.txt` | exit 0 |
| `DATABASE_URL` in `.env` | `grep DATABASE_URL .env` | line found |
| `main.py` is an entry point | `grep -q "if __name__" main.py` | exit 0 |

If `.env` does not exist but the doc says to set a var there,
that is a mismatch. If `main.py` exists but has no entry-point
guard, the doc claim is misleading — the behavioral check fails
even though the existence check passes.

### Example 2: build and test

A CONTRIBUTING.md says:

> "Run `npm run lint` and `npm test` before committing.
> The project uses Jest and ESLint."

Checks:

| Claim | Command | Expected |
|-------|---------|----------|
| `npm run lint` exists | `jq '.scripts.lint' package.json` | non-null |
| `npm test` exists | `jq '.scripts.test' package.json` | non-null |
| Jest is a dependency | `jq '.devDependencies.jest // .dependencies.jest' package.json` | non-null |
| ESLint is configured | `test -f .eslintrc.*` or `grep -q eslint package.json` | exit 0 |

If `npm run lint` exists but ESLint is not configured, the
command may fail or do nothing. That is a doc gap.

### Example 3: architecture claim

An architecture doc says:

> "Feature modules are in `src/features/`. Each feature has a
> `components/` and `hooks/` subdirectory. There are 5 features."

Checks:

| Claim | Command | Expected |
|-------|---------|----------|
| `src/features/` exists | `test -d src/features` | exit 0 |
| Each feature has `components/` | `ls -d src/features/*/components/` | 5 directories |
| Each feature has `hooks/` | `ls -d src/features/*/hooks/` | 5 directories |
| There are 5 features | `ls -d src/features/*/ \| wc -l` | 5 |

If there are 6 features, the doc is stale. If a feature lacks
the documented subdirectories, the convention is not followed.

### Example 4: CLI help text

A tool's README says:

> "The CLI has a `--dry-run` flag and a `--format json` option."

**Pass 1 (static):** None — both claims are behavioral.

**Pass 2 (collected):**

| Claim | Command | Safety |
|-------|---------|--------|
| `--dry-run` flag exists | `tool --help | grep dry-run` | Safe — read-only |
| `--format json` option exists | `tool --help | grep "format.*json"` | Safe — read-only |

Both are safe to run directly. Run them immediately.

### Example 5: documented env vars match usage

An .env.example or config doc lists environment variables.

Check:

```
# Extract documented vars from .env.example (values after =)
# Extract vars actually read in source (process.env.X)
# Diff them
grep -oP '^[A-Z_]+(?==)' .env.example | sort > /tmp/documented
grep -rohP 'process\.env\.([A-Z_]+)' src/ | sed 's/process.env.//' | sort -u > /tmp/used
diff /tmp/documented /tmp/used
```

This shows:
- Vars in .env.example that the code never reads (dead config)
- Vars the code reads that are missing from .env.example (undocumented config)

### Example 6: tool version pinning

A README says "Requires Node 18 or later" and you see an
`.nvmrc` or `engines` field.

Check:

| Claim | Command | Expected |
|-------|---------|----------|
| engines.node in package.json | `jq '.engines.node' package.json` | `">=18"` or similar |
| .nvmrc matches | `cat .nvmrc` | `18` or `lts/hydrogen` |

If the doc says Node 18 but .nvmrc says 20, one of them is stale.

## When to use this skill

- You start work on an unfamiliar project and need to trust its
  README, CONTRIBUTING.md, or architecture docs.
- You finish a refactor that changes paths, flags, config keys,
  or module structure — verify the docs still match.
- You review a pull request that touches documentation.
- You notice a mismatch between what a doc says and what the
  filesystem or program shows.
- You are about to add new documentation and want to check
  whether the existing docs are accurate first.

## What this skill does not do

- It does not verify that documentation is complete — only that
  its concrete claims match reality.
- It does not verify that code works correctly — it only checks
  that the code exists, has the described shape, and produces
  the described output.
- It does not fix the documentation. It reports mismatches.
  The fix is your decision.
