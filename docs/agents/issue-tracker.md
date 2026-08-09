# Issue tracker: Local Markdown (git-issues)

Issues for this repo live as markdown files with YAML frontmatter under `.issues/`.

## Convention

- One issue per file: `.issues/<id>-<slug>.md`
- Schema uses YAML frontmatter: `id`, `title`, `status`, `priority`, `labels`, `relations`
- Status values: `open`, `in-progress`, `closed`, `wontfix`
- Priority values: `low`, `medium`, `high`, `critical`
- Labels use `kind:<value>` and `state:<value>` format (see `triage-labels.md`)
- Relations: `blocks`, `depends-on`, `related-to`, `duplicates`
- Body is free-form markdown after the frontmatter

## Management

Use the `git-issues` CLI (pre-installed in the container at `/usr/local/bin/git-issues`):

- `git-issues init` — initialize `.issues/` in a project
- `git-issues new --title "..." --priority high --label bug` — create an issue
- `git-issues list` — list open issues
- `git-issues next` — next unblocked, highest-priority issue
- `git-issues claim <id>` — mark as in-progress
- `git-issues show <id>` — show details
- `git-issues done <id>` — close
- `git-issues relate <id> blocks <id>` — declare dependency
- `git-issues graph --open-only` — dependency tree

See `.issues/.agent.md` for the full command reference.

## When a skill says "publish to the issue tracker"

Create an issue via `git-issues new` with the appropriate title, priority, and labels.

## When a skill says "fetch the relevant ticket"

Read the file at `.issues/<id>-<slug>.md` or use `git-issues show <id>`.

## Wayfinding operations (for `/wayfinder`)

- **Map**: `.issues/<id>-map.md` with decisions and pending questions
- **Child ticket**: `.issues/<id>-<slug>.md` with the question in the body
- **Blocking**: `relations.depends-on` in the YAML frontmatter
- **Frontier**: scan for issues with `status: open` and no unresolved `depends-on` relations
- **Claim**: set `status: in-progress` via `git-issues claim <id>`
- **Resolve**: append the answer under `## Answer`, set `status: closed`
