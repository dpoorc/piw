# Container strategy

## Base image

All variants use `node:24-trixie-slim` as their base. This gives us:

- Node.js v24 (required by pi)
- Debian 13 Trixie (stable, current packages)
- `slim` variant (smaller attack surface, faster pulls)

No Alpine — the musl libc compatibility issues with native npm modules
aren't worth the size savings for a development tool.

## User mapping

The container has a user `pi` created at build time with a default
UID/GID of 1000. At runtime, `piw` uses `--user $(id -u):$(id -g)`
to remap to the host user's identity.

`/home/pi` is `chmod 755` (world-traversable) so that any UID can
reach it after remapping. The `.pi/agent` subdirectory is covered by
a bind mount from the host, so actual file permissions match the host
user.

## State directory

Pi state (sessions, config, auth) lives in `.pi/agent/` inside the
harness directory by default. This is gitignored. The `PI_CONFIG_DIR`
environment variable in `.env` can override this path.

Inside the container, the config directory is at `/home/pi/.pi/agent`
and pi is told about it via `PI_CODING_AGENT_DIR`.

## Bind mounts

| Host path | Container path | Purpose | Mode |
|-----------|---------------|---------|------|
| `.pi/agent/` | `/home/pi/.pi/agent` | Config, sessions, credentials | `rw` |
| `skills/` | `/home/pi/.pi/agent/skills` | Agent skills | `rw` |
| `skills/system/workflow/APPEND_SYSTEM.md` | `/home/pi/.pi/agent/APPEND_SYSTEM.md` | System prompt appendage | `ro` |
| `variants/<profile>/SKILL.md` | `/home/pi/.pi/agent/skills/variant/SKILL.md` | Variant toolset doc | `ro` |
| Workspace | Same path | Project files | `rw` |

All mounts use the `:z` flag for SELinux relabeling (required on Fedora
and RHEL-based systems).

## Config directory

Pi's `PI_CODING_AGENT_DIR` environment variable is set to
`/home/pi/.pi/agent` inside the container, which corresponds to
`.pi/agent/` on the host. This means all pi state files (sessions,
settings, auth tokens, installed packages) are kept in the harness
directory, out of version control.

## yadm bridge

The workstation variant ships [yadm](https://yadm.io/), a dotfiles
manager that treats `$HOME` as its work tree. The container user's
home is `/home/pi`, but the real dotfiles live under the host home
(e.g. `/home/<user>`), which is bind-mounted as the workspace.

To make yadm operate on the host's dotfiles, `piw` passes
`YADM_HOME` at launch (the host's `$HOME`). The installed yadm is a
small wrapper:

```sh
#!/bin/sh
exec env HOME="${YADM_HOME:-$HOME}" /usr/local/libexec/yadm "$@"
```

It re-exports `HOME` to the host home before running the real yadm
(at `/usr/local/libexec/yadm`), so config
(`$HOME/.config/yadm/`), data (`$HOME/.local/share/yadm/`), and
work tree all resolve to the host. Without `YADM_HOME` (interactive
shell, other contexts) the wrapper is a no-op and yadm behaves
normally against the container home.

## Network

`--add-host host.docker.internal:host-gateway` enables the container
to reach services running on the Docker host (e.g., a local llama.cpp
server at port 8080, or a local OpenShell gateway).

## API keys

Keys are sourced from `.env` (if present) and passed to the container
via `-e VAR_NAME` flags. The `models.json` file uses `$VARIABLE`
syntax that pi resolves at runtime, so keys never need to be baked
into configuration files.
