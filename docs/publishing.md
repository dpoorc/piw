# Publishing pi-harness

> **REFERENCE** — Considerations for making this harness public.
> Not a plan. Just a record of what was discussed so you can pick
> it up later.

## Before publishing

### README.md

The repo root has no README.md. GitHub shows visitors
`docs/index.md` by default, but a root README.md is the platform
standard. Write a one-pager:

- What pi-harness is (one paragraph)
- Quick start: prerequisites, install, first run
- Link to full docs

### LICENSE

No license file currently exists. Pick one:

| License | Effect |
|---------|--------|
| MIT | Most permissive. Others can use, modify, distribute without restriction. |
| Apache 2.0 | MIT-like with patent protection. Standard for many dev tools. |
| GPLv3 | Copyleft. Derivatives must stay open. |

### CONTRIBUTING.md

The alignment-before-action workflow is distinctive. Document it so
contributors understand the proposal process before opening PRs that
skip it.

### CI

Minimal GitHub Actions:

- Build both variants (core, devops)
- Run `piw doctor --profile <name>` on each
- Validate JSON configs parse
- Check that config-seeds/extensions.txt packages install without error

Even basic CI signals the project is maintained.

### .env.example

Already exists. Make sure every env var a user might need is listed.
Currently covers: ANTHROPIC_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY,
FIREWORKS_API_KEY, SILICONFLOW_API_KEY, and config overrides.

## Audience

This is not a beginner tool. The README should set that expectation
early. The user needs to:

- Have Docker installed and running
- Have at least one API key for pi
- Be comfortable editing JSON configs
- Understand that the agent has a "think first" workflow

Target audience: power users of
[pi](https://github.com/earendil-works/pi) who want Docker isolation,
configurable permissions, and a composable tooling environment.

## Potential friction points

| Friction | Mitigation |
|----------|-----------|
| Docker required | State clearly in README. Provide `piw doctor` to diagnose. |
| API key setup | `.env` + `models.json` is manual. Consider a `piw init` that prompts for keys. |
| Mode/profile complexity | A "first run" example: `piw --profile core ~/my-project`. |
| Agent thinks before acting | Frame this as a feature in the README, not a bug. |
| No browser in container | Document the curator crash workaround (`workflow:"none"`). |
| Self-hosting confusion | Clarify that the workspace is independent from the harness repo. |

## Naming

Current split: repo is `pi-harness`, CLI tool is `piw`.

| Option | Pros | Cons |
|--------|------|------|
| Keep as-is | Descriptive + distinctive tool name. Known convention (docker/docker, eslint/eslint). | Repo name is generic. |
| Rename repo to `piw` | Tool/repo match (ripgrep/rg, bat, fd). More brandable. | SEO loss. Touch every doc and path. |
| Rename both to something new | Clean break. | Loses all existing references. |

Recommendation: keep `pi-harness` as the repo name and `piw` as the
tool name. This split is well-understood. If you rename, do it
before publishing — not after.

## Relationship to pi

This harness wraps [pi](https://pi.dev) / `@earendil-works/pi-coding-agent`.
It is a community wrapper, not an official product. Be explicit about
this in the README to set expectations about support scope.
