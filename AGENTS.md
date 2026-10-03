# piw — piw workspace

piw is a piw coding agent configuration. It ships with system skills, vendor skills, Docker variants, and tooling for AI-assisted development workflows.

## Agent skills

### Issue tracker

Issues are tracked as local markdown files under `.issues/` using the git-issues schema and CLI (`git-issues` is pre-installed in the container). See `docs/agents/issue-tracker.md`.

### Triage labels

Labels use `<kind>:<value>` / `<state>:<value>` format (e.g., `kind:bug`, `state:needs-triage`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context — one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
