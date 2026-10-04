# Overview

piw runs the [pi coding agent](https://pi.dev) in a Docker container. It has
four goals:

1. **Isolation without friction.** The agent runs in a container, so it cannot
   change the host by accident. The workflow still feels native: the
   workspace, the configuration, and the skills are bind-mounted, so every
   change is visible on the host at once.
2. **Transparency.** Skills are Markdown files. `piw` is one bash script. The
   Dockerfile is plain. Nothing is generated, compiled, or hidden.
3. **Leanness.** The default image carries the tools that most sessions need
   and nothing more. You add the rest.
4. **Composition.** Layers and store tools combine without limit. A layer adds
   to the image. A store tool lands in a persistent store.

When two goals conflict, the order above decides. Isolation wins over
transparency, transparency wins over leanness, and leanness wins over
composition.

## Two scopes

The harness has two kinds of files, and the boundary is visible from the
repository root:

| Scope | Location | In git |
|-------|----------|--------|
| Upstream content | the repository | yes |
| Local state | `.local/` | no |

**Upstream content** is everything a user receives by cloning: the `piw`
script, the `Dockerfile`, the seed files, the skills, and the docs.

**Local state** is everything the user owns: secrets, pi's state, installed
tools, and the user's layers. One gitignored directory holds all of it, so
`git status` stays clean and the private half never leaks into a commit.

`.local/` sits inside the workspace when the harness is self-hosted. The
permission rules deny the secrets file and gate pi's `auth.json`.

## The images

piw builds two images:

| Image | Contents | Built by |
|-------|----------|----------|
| `piw:default` | The base: Node, apt tools, mise, yq, uv | `piw build` |
| `piw:local` | `piw:default` plus the active layers | `piw build` |

`piw:default` comes from the `Dockerfile`. `piw:local` is composed from a
generated Dockerfile that starts `FROM piw:default` and appends one step per
active layer. A launch uses `piw:local`. The image carries the label
`piw.plan=<hash>` of the plan that built it, so piw can detect a stale image.

piw does not put pi in the image. pi lives in the `.local/app` mount, and its
extensions live in `.local/agent`. Both update without an image rebuild.

## Layers

A **layer** is a build-time addition to the image. It lives in a directory
with up to four files:

| File | Role |
|------|------|
| `apt` | One apt package per line |
| `archives` | One download per line: URL, sha256, and destination |
| `mise.toml` | Store tools to install after the image build |
| `install.sh` | A script that runs as root at build time |
| `README.md` | A description, shown by `piw layer list` |

The user adopts a layer by name in `.local/piw.conf`. The shipped layer,
`workstation`, adds compilers, infrastructure tools, and security and
forensics tools.

An install script runs as root. A third-party layer can run any command as
root. Read a layer before you adopt it.

## Store tools

A **store tool** is a tool that mise installs into `.local/store`. The store
mounts at `/home/pi/.local` inside the container, and its `bin` directory is
on `PATH`. Store tools survive an image rebuild, because they live in the
mount, not the image.

`piw tool install <spec>` adds one. mise resolves the spec, pins the version
in a lockfile, and checks the checksum where the backend provides one.

## The mount map

A launch mounts these paths:

| Host | Container | Mode |
|------|-----------|------|
| `.local/agent` | `/home/pi/.pi/agent` | rw |
| `.local/store` | `/home/pi/.local` | rw |
| `.local/mise` | `/home/pi/.config/mise` | rw |
| `.local/app` | `/opt/pi` | rw |
| `.local/agents/skills` | `/home/pi/.agents/skills` | rw |
| `.local/layers` | `/opt/piw/layers` | ro |
| `skills/` | `/home/pi/.pi/agent/skills` | ro |
| `agents/` | `/home/pi/.pi/agent/agents` | ro |
| `skills/system/workflow/APPEND_SYSTEM.md` | `/home/pi/.pi/agent/APPEND_SYSTEM.md` | ro |
| the mode config | `/home/pi/.pi/agent/extensions/pi-permission-system/config.json` | ro |
| the workspace | the same path | rw |
| `$HOME/.gitconfig` | `/home/pi/.gitconfig` | ro |
| `$HOME/.config/git` | `/home/pi/.config/git` | ro |

The mode config mounts only for a non-default mode. The workspace mounts
read-only in `readonly` mode. Every mount carries the `:z` flag for SELinux
relabeling, which Fedora and RHEL need.

The launch also passes `--env-file .local/.env` when the file exists, and
`--user $(id -u):$(id -g)` so files on the mount belong to the host user.

`/home/pi` is not writable and does not survive the container. The store
mount at `/home/pi/.local` is the writable, persistent home area. Every tool
that writes to `$HOME` points at a path under `.local/`.

## What the design does well

- **Clear roles.** A layer defines an environment. A skill defines behavior.
  `piw` orchestrates. The permission system gates access. The roles do not
  overlap.
- **Transparent over magical.** `piw` is a single script you can read
  end-to-end. Skills are Markdown. The Dockerfile is plain.
- **A security posture above most personal dev tools.** The mounts carry
  `:z` flags. The Docker socket is not exposed. No package installs happen
  mid-session. Three permission modes gate the agent, and the secrets rules
  deny by default.
- **Alignment before action.** The workflow skill asks the agent to propose
  before it implements. This costs time up front and saves rework.
- **Lean default, extensible by design.** The default image carries the base
  tools. Anything else is a layer or a store tool.

## Where the design shows strain

- **The script is large for bash.** `piw` is one file of well over a thousand
  lines. String handling, argument parsing, and error recovery are the
  awkward parts.
- **Self-hosting is elegant but confusing.** When the workspace is the harness
  itself, changes to `piw` happen from inside `piw`. This is natural for the
  author and surprising for a newcomer.
- **Some tool choices are implicit.** Why one tool and not another is not
  written down. The criteria are size, use in a headless container, and
  whether the agent can do the same job another way.
- **The permission configs share rules by copy.** The three mode files repeat
  common rules. A change to one often needs the same change in the others.
