# Container strategy

## Base image

`piw:default` uses `node:24-trixie-slim`:

- Node.js 24, which pi needs. npm comes with it, so npm is not in the apt
  list.
- Debian 13 (trixie), stable with current packages.
- The `slim` variant, for a smaller attack surface and faster pulls.

Alpine is not used. The musl libc compatibility problems with native npm
modules cost more than the size saving is worth.

## User mapping

The image creates a user `pi` at build time with UID and GID 1000. At launch,
piw passes `--user $(id -u):$(id -g)`, which maps the container user to the
host user. Files written through a mount then belong to the host user.

`/home/pi` is not writable, and it does not survive the container. The image
never creates it, so Docker creates it as `root` for the mount targets. The
container runs with `--rm`, so the directory is discarded. The store mount at
`/home/pi/.local` is the writable, persistent home area.

The runtime environment points every tool that writes to `$HOME` back into the
store mount:

```
MISE_DATA_DIR=/home/pi/.local/share/mise
XDG_CACHE_HOME=/home/pi/.local/cache
RUSTUP_HOME=/home/pi/.local/rustup
CARGO_HOME=/home/pi/.local/cargo
GOPATH=/home/pi/.local/go
```

Without this, a tool install fails with `Permission denied`.

## Mounts

A launch mounts the state, the tooling, and the workspace. See
[the overview](../overview.md#the-mount-map) for the full table. The
important points:

- The writable state lives in four mounts: `.local/agent`, `.local/store`,
  `.local/mise`, and `.local/app`.
- The tooling is read-only: `skills/`, `agents/`, the system-prompt
  appendage, the mode config, and `.local/layers`.
- The workspace mounts at the same path, so paths inside the agent match
  paths on the host.
- Every mount carries the `:z` flag for SELinux relabeling, which Fedora and
  RHEL need.

## Network

The launch adds `--add-host host.docker.internal:host-gateway`, so the
container can reach a service on the Docker host, such as a local model
server.

In `readonly` mode, the launch adds `--network none`. The container has no
network access at all.

## Secrets

piw passes the secrets file to the container with `--env-file .local/.env`
when the file exists. The `models.json` file refers to keys as `$VARIABLE`,
and pi resolves the reference at runtime. Keys are never written into a
configuration file.

## Images

| Image | Contents |
|-------|----------|
| `piw:default` | The base: Node, the apt tools, mise, yq, and uv |
| `piw:local` | `piw:default` plus the active layers |

The default image comes from the `Dockerfile`. piw composes `piw:local` from a
generated Dockerfile that starts `FROM piw:default` and appends one step per
active layer. The composed image carries the label `piw.plan=<hash>`. piw
compares the label against the current plan to detect a stale image.

pi is not in either image. pi lives in the `.local/app` mount, and its
extensions live in `.local/agent`. Both update without an image rebuild.
