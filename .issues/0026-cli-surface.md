---
id: 26
title: CLI surface
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 29
        - 30
    depends-on:
        - 21
        - 22
        - 24
        - 25
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-02"
closed: "2026-10-02"
---

## Question

What is the final command set, and what does each command do?

Known changes: the --profile flag and the profile concept go away. #25 drops the two tool scopes, and the project gains no command at all: piw manages the harness, not the project. The user manifest and layers need commands or flags. pi update self and pi install are invoked in the container rather than reimplemented.

Also decide whether the argument parser needs further hardening, given the subcommand collision fixed in 4e74ccc.

## Answer

### The command set

| Command | Does |
|---|---|
| `piw` | Launch in the current directory |
| `piw <path>` | Launch with that workspace |
| `piw build` | Build the image from the manifest |
| `piw tool install <spec>` | Add a tool to the manifest, install it |
| `piw tool remove <spec>` | Remove a tool from the manifest |
| `piw tool list` | List the store |
| `piw layer add <spec>` | Add a layer, scaffolding a directory for `run:` |
| `piw layer remove <name>` | Remove a layer |
| `piw layer list` | List the manifest's layers |
| `piw doctor` | Diagnose the harness |
| `piw link [dir]` | Put piw on PATH |
| `piw unlink [dir]` | Take piw off PATH |
| `piw generate-catalog` | Regenerate the catalog. Fate in #37 |
| `piw update` | Fate in #27 |
| `piw --version` | Print the version |
| `piw --help` | Print help |

**There is no `project` command.** An explicit command for the workspace's
tools was proposed and rejected. piw manages the harness, not the project, and
no piw command writes to the workspace. This amends #25.

### The flags

| Flag | Fate | Why |
|---|---|---|
| `--mode` | survives | launch |
| `-r`, `--resume` | survives | launch |
| `--no-cache` | survives | build |
| `--dry-run` | survives | build. #22 gave it the build plan |
| `--profile` | dies | profiles are going |
| `--all` | dies | variants are going |
| `--offline` | dies | see below |
| `--force`, `--build-only`, `--install-only` | defer to #27 | belong to `update` |
| `--install`, `--uninstall` | become commands | `link` and `unlink` |

### Final decisions

**The manifest gains a second noun.** `tool` and `layer` sit side by side,
because the manifest has two halves and both need a way in. `piw tool install`
writes `mise/config.toml`. `piw layer add` writes `piw.conf`.

**`piw layer add` scaffolds, and then points somewhere.** `apt:zsh` is one
line, so it is appended. A `run:` layer needs a directory with an `install.sh`,
so piw creates `.local/layers/<name>/install.sh` with a commented starter and
appends `run:<name>`. It then prints the two ways forward: edit the file by
hand, or launch piw with the harness directory as the workspace and edit it
from inside the container. The user should never have to guess the shape.

**`--install` and `--uninstall` become `link` and `unlink`.** They do real work
and they are currently invisible, because a flag that sets `COMMAND` does not
appear in the help table. `link` is the more correct word, but it is
unconventional, so both the readme and the help text must explain it. That
requirement is carried into #30.

**The parser hardens.** Each command declares the flags it accepts, and
anything else is an error. Today `piw -r build` builds and discards `--resume`
without a word, and `piw doctor foo` reads `foo` as a profile name. Roughly
fifteen lines of bash turns a silent misread into a message.

**`doctor` checks four things.** Docker and the daemon, that the image exists,
that the store and the manifest agree, and that the seeded config files match
their seeds. The variant and extension checks die with their concepts. The
seeded-config check reports a **diff**, not a pass or fail, because those files
belong to the user and divergence is expected.

**`--offline` dies.** It means "build from `build/archives/`, download
nothing". #22 removes that directory, because `ADD --checksum` fetches each
archive from its pinned URL at build time. The base image has to be pulled in
any case, so the flag was never fully offline. A flag that silently degrades to
"use the Docker cache" is worse than no flag.

**`--version` is added.** There is none today.

### Findings

1. **There is no `--version`.**
2. **`--install` and `--uninstall` are flags that set `COMMAND`.** They work,
   but they are absent from the help table, so they are undiscoverable.
3. **Flags meaningless for the chosen command are silently ignored.**
   `piw -r build` builds and drops `--resume`. `piw doctor foo` treats `foo` as
   a profile.
4. **The skills catalog is broken and unwired.** Found while resolving this
   ticket, and filed separately as #37. `piw generate-catalog` produces
   `skills/catalog.md`, nothing consumes it, the committed copy was generated by
   a run whose YAML extraction failed silently, and the generator omits the
   `misc` bucket and `skills/variant/`.

## Consequences

- **#37** carries the catalog question, including whether `generate-catalog`
  survives.
- **#27** carries `update` and the three flags that belong to it.
- **#30** must explain `link` and `unlink` in both the readme and the help text.
- **`--offline` and `--all` die**, which removes `ensure_archives`,
  `_archive_url`, `_profile_archives`, and the variants flag from the script.
