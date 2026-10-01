---
id: 21
title: 'User manifest: format and location'
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 22
        - 26
        - 27
        - 34
    depends-on:
        - 20
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
closed: "2026-10-01"
---

## Question

What is the single declarative file a user edits to extend the harness, what does it declare, and where does it live?

It must cover store tools, root built system packages, pi extensions, and environment variables. It must extend the baked defaults rather than replace them. It must live in a gitignored path.

## Answer

Two files, and no translation between them.

### `.local/config/mise.toml`, with `mise.lock` beside it

mise's own format, holding `[tools]`. Read and written by mise inside the
container, through `MISE_GLOBAL_CONFIG_FILE`. **piw never parses it.**
That is the point of choosing a manager.

`mise.toml` cannot carry piw's sections. mise rejects an unknown
top-level table, verified against v2026.9.17:

```
[tools]
jq = "latest"

[piw]              -> mise ERROR error parsing config file
layers = ["zsh"]
```

### `.local/config/piw.conf`

piw's own file. Line-oriented, so that piw can read and write it on the
host with no parser dependency. piw must not assume python3, jq, or yq
are present, because it runs on the host and uses none of them today.

```
# .local/config/piw.conf

[layers]
apt:zsh
apt:gdb
run:my-setup          # .local/config/layers/my-setup/

[pi]
npm:pi-intercom
```

### Format spec

- `#` starts a comment at the start of a line, or after whitespace.
  This keeps `git:https://host/repo#v1` intact.
- Blank lines are ignored. CRLF is tolerated.
- `[name]` starts a section. The name matches `[A-Za-z0-9_.-]+`.
- Any other non-blank line is an entry.
- An entry before the first section is an error, not a silent drop.
- Duplicate sections merge. The writer appends to the last occurrence.
- Entries use the prefix convention already in `config-seeds/extensions.txt`.

### Parser and writer

Both directions, POSIX awk, about 20 lines total.

```awk
function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
BEGIN { section = "" }
{
  line = $0
  if (line ~ /^[[:space:]]*#/) next
  if (line ~ /^[[:space:]]*$/) next
  if (line ~ /^[[:space:]]*\[/) {
    body = line; sub(/[[:space:]]+#.*$/, "", body); body = trim(body)
    if (body !~ /^\[[A-Za-z0-9_.-]+\]$/) {
      print FILENAME ":" NR ": malformed section header" > "/dev/stderr"; exit 2
    }
    section = substr(body, 2, length(body) - 2); next
  }
  body = line; sub(/[[:space:]]+#.*$/, "", body); body = trim(body)
  if (body == "") next
  if (section == "") { print FILENAME ":" NR ": entry before any section" > "/dev/stderr"; exit 2 }
  print section "\t" body
}
```

### Verified

mawk 1.3.4, ten cases: inline comments, leading whitespace, duplicate
sections, empty sections, CRLF, `#` inside a value, entry before a
section, malformed header, idempotent rewrite, and round trip.

Gap: only mawk was available. gawk and BSD awk are untested. Every
construct is POSIX.

### What the manifest declares

| Where | Declares | Consumed by |
|---|---|---|
| `mise.toml` `[tools]` | store tools | mise, in the container |
| `piw.conf` `[layers]` | build-time image additions | piw, at build time |
| `piw.conf` `[pi]` | pi packages | pi, through `pi install` |

### What it does not declare

Environment variables. Env is not a tool concern. `.local/env` holds the
secrets and the path overrides, bash sources it, and piw passes the values
with `-e`.

### Write-through

`piw tool install X` adds X to the manifest and installs it, as `mise use`
and `npm install` do. The manifest is the source of truth and the store is
derived, so copying `.local/config/` to another machine rebuilds the
store.

### Boundary with pi

pi's `settings.json` keeps model, theme, and provider settings. The
manifest declares which packages to install, and pi performs the install.

### Consequences

- The config directory needs a read-only mount into the container. It is
  not mounted today. See #26.
- `config-seeds/` gains a starter `piw.conf` and a starter `mise.toml`.
- The project-level manifest for #25 uses the same format and the same
  section names, merged over the harness-level file.
