---
id: 24
title: Store layout and the container mount map
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 25
        - 26
    depends-on:
        - 20
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-02"
closed: "2026-10-02"
---

## Question

How is the store laid out, and how does the container see the pieces of `.local/`?

Re-scoped by #22. The two-scope design is gone: there is one harness store and one user image, so `MISE_SHARED_INSTALL_DIRS` and the project store are out of scope.

What remains is the plumbing. mise needs a writable data directory, a global config file, and a lockfile, and #21 placed the config outside the store at `.local/mise.toml`. `.local/` also holds the agent directory, the pi install, the extensions, and the layers, and each needs a different container path. `MISE_DATA_DIR` is read early, so it must come from the environment rather than a config file.

Decide:

- The layout inside `.local/store/`.
- Which pieces of `.local/` get a mount, at which container path, and read-only or read-write.
- The `PATH` order inside the container.
- What `piw tool install`, `list`, and `remove` read and write.
- Whether `.local/env` is passed as `-e` flags or as an env file.

## Answer

### The `.local/` layout

```
.local/
├── agent/                    pi's agent directory (PI_CODING_AGENT_DIR)
│   ├── extensions/           permission config, seeded from seed/permissions/
│   ├── skills/               the user's own skills, no longer shadowed
│   └── (sessions, auth.json, settings.json, models.json, npm/, ...)
├── agents/
│   └── skills/               the Agent Skills convention (~/.agents/skills)
├── app/                      pi's install, mounted at /opt/pi
├── layers/                   user layers, the build context
├── mise/
│   ├── config.toml           the [tools] manifest, parsed by mise alone
│   └── mise.lock             the lockfile
├── store/                    mise's data directory
├── env                       secrets, passed with --env-file
└── piw.conf                  [layers] and [pi], parsed by piw with awk
```

Two changes to the layout from #21:

1. **`.local/mise.toml` becomes `.local/mise/config.toml`.** mise's own
   convention names the global file `config.toml`, and the directory is
   mounted at `/home/pi/.config/mise`.
2. **`.local/extensions/` disappears.** The permission config is extension
   state. It belongs in the agent directory, at
   `.local/agent/extensions/pi-permission-system/config.json`, seeded from
   `seed/permissions/`.

**Hazard:** `.local/agent/` and `.local/agents/` differ by one character
and hold different things. `.local/agent/` is pi's namespace.
`.local/agents/skills/` is the cross-tool Agent Skills convention. The
names mirror their container paths, so they are predictable, but the
similarity needs a line in `CONTEXT.md`.

### The mount map

| Host | Container | Mode | Why |
|---|---|---|---|
| `.local/agent` | `/home/pi/.pi/agent` | rw | pi's namespace. pi writes sessions, auth, and extension logs here. |
| `.local/store` | `/home/pi/.local` | rw | mise's data directory: installs, shims, and `bin`. |
| `.local/mise` | `/home/pi/.config/mise` | rw | The `[tools]` manifest and the lockfile. mise writes both. |
| `.local/app` | `/opt/pi` | rw | pi's install. `pi update self` writes here. |
| `.local/agents/skills` | `/home/pi/.agents/skills` | rw | The Agent Skills convention. Read by pi, and by other agent tools. |
| `<repo>/skills` | `<agent-dir>/skills` | ro | The harness's skills. Nothing in pi writes to this path. |
| `<repo>/agents` | `<agent-dir>/agents` | ro | Subagent definitions. Read by `@gotgenes/pi-subagents`. |
| `<repo>/skills/system/workflow/APPEND_SYSTEM.md` | `<agent-dir>/APPEND_SYSTEM.md` | ro | The system prompt addition. |
| the mode config | `<agent-dir>/extensions/pi-permission-system/config.json` | ro | The active permission mode. |
| the workspace | the same path | rw | The project. |
| `$HOME/.gitconfig` | `/home/pi/.gitconfig` | ro | Git identity. Optional. |
| `$HOME/.config/git` | `/home/pi/.config/git` | ro | Git config. Optional. |
| `.local/env` | not a mount | `--env-file` | Secrets. |

Twelve mounts, the same count as today, but the composition changed. The
`extensions/` overlay and the variant skill mount are gone, and the mise
config and the Agent Skills directory are new. The real gain is ownership,
not count: no overlay remains read-write over tracked content.

### Read-only mode

`--mode readonly` makes the workspace and the store read-only, and adds
`--network none`. The mise config and the Agent Skills directory become
read-only too, because neither has a job without installs.

The agent directory stays read-write. pi must write sessions, auth, and
extension logs, and a read-only agent directory would break pi rather than
restrict the project. Read-only is about the project, not about pi's
bookkeeping.

### PATH

Unchanged:

```
/opt/pi/node_modules/.bin:/home/pi/.local/bin:/home/pi/.local/share/mise/shims:$PATH
```

The store comes before the system, so a store tool shadows an apt tool of
the same name. That is the intent: the manifest wins over the base image.

### `.local/env`

Passed as `--env-file .local/env`. Every line is `KEY=value`, with no
`export` and no shell quoting, because that is what Docker accepts. **piw
does not parse the file.**

This removes the hardcoded allowlist of twelve API keys. Today `load_env`
sources `.env` on the host, then `cmd_launch` forwards only the keys in
`known_keys`. A user who adds a provider has to edit piw. With `--env-file`
the file passes through whole, and adding a provider is a one-line edit to
user state.

**Host-side overrides leave the file.** Today `.env` also carries
`PI_CONFIG_DIR` and `PI_TOOLS_DIR`, which piw reads on the host. Those are
configuration, not secrets, and they move to `piw.conf` or to the real
environment. Passing them through `--env-file` would leak host paths into
the container, where they mean nothing.

Git author name and email stay as `-e` flags. They come from the host's
git config, not from a file.

### What `piw tool` reads and writes

| Command | Reads | Writes |
|---|---|---|
| `piw tool install <spec>` | `.local/mise/config.toml` | `.local/mise/config.toml`, `.local/mise/mise.lock`, `.local/store/` |
| `piw tool list` | `.local/mise/config.toml`, `.local/mise/mise.lock` | nothing |
| `piw tool remove <name>` | `.local/mise/config.toml` | `.local/mise/config.toml`, `.local/mise/mise.lock` |

The manifest is the source of truth and the store is derived. Every one of
these runs `mise` inside the container through `_in_container`. The host
never runs mise.

### Findings

1. **`<agent-dir>/skills` and `<agent-dir>/agents` are read-only discovery
   roots.** Verified in `dist/core/package-manager.js` and
   `dist/core/resource-loader.js`: the skills directory feeds
   `collectAutoSkillEntries`, which reads. A search for `mkdir`,
   `writeFile`, `copyFile`, and `symlink` against any skills path returns
   nothing. So a read-only mount cannot break `pi install`.
2. **`<agent-dir>/extensions` is different: pi writes there.** Extension
   logs land in it. That is why the current repository contains
   `extensions/pi-permission-system/logs/…jsonl`: the overlay is
   read-write, so pi's output is written into the harness tree. Skills and
   agents can be shadowed safely; extensions cannot, which is the argument
   for moving it into `.local/agent/extensions/`.
3. **pi supports a vendor-neutral skills location.** `docs/skills.md` line
   61: "Pi also supports the Agent Skills locations `~/.agents/skills/`
   and `.agents/skills/`." Nothing shadows it, so it gives the user a
   personal global skills directory. It costs one mount.
4. **The settings resource arrays exist but are not needed.**
   `settings.json` accepts `skills`, `extensions`, `prompts`, and `themes`
   arrays with absolute paths. That would let the harness be declared
   instead of mounted, but it couples the launch to a user-editable file
   with a silent failure mode. A mount cannot be silently deleted.
5. **`pi-subagents` reads its global agents flat.** `readdirSync` on
   `<agent-dir>/agents`, filtered to `.md`. A subdirectory would not be
   discovered, so that directory must be a whole-directory overlay.

### Final decisions

**One mount per piece, not one mount for all of `.local/`.** Twelve mounts
cost no perceptible launch time, and mounting through a symlink into
another mount is fragile.

**The harness is a read-only resource tree.** Skills, agents, and
`APPEND_SYSTEM.md` are mounted read-only. When the harness is the
workspace, the same files are writable through the workspace mount, so
self-hosting still works. In every other workspace the agent cannot touch
tracked content.

**The user's skills directory is left alone.** No settings array and no
subdirectory mount. Nothing writes to `<agent-dir>/skills`, so shadowing
costs nothing, and the escape hatch for personal global skills is
`~/.agents/skills`.

**`.local/env` is secrets only, and it passes through whole.** No
allowlist, no host-side parsing, no host path overrides.

**`MISE_DATA_DIR` and `MISE_GLOBAL_CONFIG_FILE` are set explicitly, and
they mirror mise's defaults.** The values are written down so the paths are
greppable, and mise's conventions are not relied on silently:

```
ENV MISE_DATA_DIR=/home/pi/.local/share/mise \
    MISE_GLOBAL_CONFIG_FILE=/home/pi/.config/mise/config.toml
```

**`store/` keeps the layout mise gives it.** No custom subdirectory
structure. mise owns its own data directory.

## Consequences

- `docs/adr/0001-local-state-namespace.md` needs an amendment: the
  flattened layout, and the removal of `.local/extensions/`.
- `CONTEXT.md` needs the `.local/agent` against `.local/agents` distinction.
- The `build/` directory and the `variants/` tree are unaffected by this
  ticket. The mount map is about launch, not build.
- #25, how a project declares its tools, is unblocked.
