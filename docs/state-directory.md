# State directory

All local state lives in `.local/` at the harness root. The directory is
gitignored, so the private half of the harness never reaches a commit.

```
.local/
├── .env            secrets, passed to the container with --env-file
├── agent/          pi's agent directory
├── agents/skills/  the cross-tool skills directory
├── app/            pi's program install
├── layers/         the user's layers
├── mise/           the store tool manifest
├── piw.conf        the layer manifest
└── store/          the tools the user installed
```

## `agent/`

pi's own state directory. The launch mounts it at `/home/pi/.pi/agent`, and
piw points pi at it with `PI_CODING_AGENT_DIR`.

```
agent/
├── auth.json          authentication tokens (sensitive)
├── bin/               CLI tools installed by pi packages
├── extensions/        pi extensions
│   └── pi-permission-system/
├── git/               git-based package installs
├── intercom/          pi-intercom state
├── models.json        provider and model configuration
├── models-store.json  resolved model configuration
├── npm/               npm-based package installs
├── sessions/          session history
│   └── <workspace-hash>/
│       └── *.jsonl
└── settings.json      pi settings
```

Three paths inside `agent/` are mount points, not real files:

- `agent/skills/` receives the read-only `skills/` mount.
- `agent/agents/` receives the read-only `agents/` mount.
- `agent/APPEND_SYSTEM.md` receives the read-only system-prompt appendage.

Docker creates a missing mount point as `root:root`. This is expected.

### `settings.json` and `models.json`

piw seeds both from `seed/` on first launch, and never overwrites them
afterwards. `piw update` reports drift between the seeded copies and the
shipped versions. To restore a shipped file, remove the seeded copy and launch
again.

### `sessions/`

Each pi session is one JSONL file. The files are grouped by workspace path.
Resume a session with `piw -r`.

## `agents/skills/`

The cross-tool Agent Skills directory, mounted at `/home/pi/.agents/skills`.
Other agent tools read this path. It is not the agent directory:
`.local/agent` is pi's namespace, and `.local/agents/skills` follows the Agent
Skills convention. The two names differ by one character and hold different
things.

## `app/`

pi's program install, mounted at `/opt/pi`. piw installs and updates pi here,
so a new pi version needs no image rebuild.

## `layers/`

The user's layers. `piw layer add` copies a shipped layer here. The build
mounts this directory read-only at `/opt/piw/layers`.

## `mise/`

The store tool manifest at `mise/config.toml`. mise reads it inside the
container. Add tools here, or run `piw tool install <spec>`. The file is
seeded once and never overwritten.

## `piw.conf`

The layer manifest. It lists the apt packages and the layer directories that
`piw build` composes into the image. The file is seeded once and never
overwritten. See [piw.md](piw.md) for the format.

## `store/`

The persistent tool store, mounted at `/home/pi/.local`. mise installs tools
here, and the store `bin` directory is on `PATH` in the container. Because the
store is a mount, its tools survive an image rebuild.

## `env`

The secrets file. piw passes it to the container with `--env-file` when it
exists. Copy `.env.example` to `.local/.env` and fill in your keys. The
permission rules deny reads of this file.

## Environment overrides

Each path has an environment override: `PI_CONFIG_DIR`, `PI_PI_DIR`,
`PI_TOOLS_DIR`, `PIW_CONF`, and `PIW_MISE_CONFIG`. A relative value resolves
against the harness root. See [piw.md](piw.md).
