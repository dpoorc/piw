# yadm bridge proposal

> **DATE:** 2026-08-02
> **STATUS:** Proposed. Implementation deferred to a dedicated session.

## Problem

The user's dotfiles are managed by [yadm](https://yadm.io/) with
`$HOME` as the worktree. The yadm repo lives at
`~/.local/share/yadm/repo.git` and config at `~/.config/yadm/`. Both
paths are inside `/home/<user>/`, the bind-mounted workspace.

The pi container does not have the yadm binary. The agent cannot run
`yadm status`, `yadm log`, `yadm diff`, or other commands to inspect
the dotfiles state.

## Goals

- The agent can run standard yadm commands from inside the container
- The agent can see git history, active changes, and file status
- The agent can stage, commit, and push changes to the dotfiles repo
- No SSH setup, no host-side daemon, no manual workarounds

## Approach

The yadm binary is a single bash script (~50 KB). The repo and config
are already accessible inside the container (bind-mounted at their
host paths).

### Option A: Install yadm in the container image

Add yadm to the core variant Dockerfile:

```dockerfile
RUN dnf install -y yadm
```

Then run yadm with the host's home as the target:

```bash
HOME=/home/<user> yadm status
```

This works because `$HOME` tells yadm where to find
`~/.config/yadm/` and `~/.local/share/yadm/`, both bind-mounted.

### Option B: Install yadm dynamically

Add yadm to `extensions.txt` or install on demand via curl:

```bash
curl -fsSL https://github.com/TheLocehiliosan/yadm/raw/master/yadm \
  -o /tmp/yadm && chmod +x /tmp/yadm
HOME=/home/<user> /tmp/yadm status
```

### Option C: piw yadm subcommand

A `piw yadm` subcommand that wraps the Docker run:

```bash
# piw yadm <args> runs yadm on the host via the container
piw yadm status
# expands to:
docker run --rm \
  -v /home/<user>:/home/<user>:z \
  -w /home/<user> \
  pi-harness:core \
  yadm status
```

This keeps the yadm logic out of the container image and makes it a
piw feature.

### Recommendation

Option A for simplicity and reliability. Option C as an additional
convenience wrapper (`piw yadm`). Combine A + C: install yadm in the
image and add a `piw yadm` subcommand.

## Risks

| Risk | Mitigation |
|---|---|
| `yadm bootstrap` runs arbitrary user scripts | Do not run it from inside the container without review. |
| `yadm alt` creates symlinks that point outside the bind mount | Test before assuming. Most targets are within `/home/<user>/`. |
| `yadm encrypt` / `yadm decrypt` work with `~/.local/share/yadm/archive` | The archive path is inside the bind mount. Should work. Test it. |
| `yadm` version mismatch between container and host | Pin the yadm version in the Dockerfile or use the dynamic install. |

## Next steps

1. Add `yadm` to the core variant Dockerfile
2. Decide on a `piw yadm` subcommand interface
3. Test commands: `status`, `log --oneline -5`, `diff`, `add -A`,
   `commit`, `push`, `alt`
