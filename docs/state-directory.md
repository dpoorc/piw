# State Directory (.pi/agent/)

The `.pi/agent/` directory (configurable via `PI_CONFIG_DIR`) holds all
pi runtime state. It is gitignored and lives outside the harness source.

## Layout

```
.pi/agent/
├── APPEND_SYSTEM.md        # Overlaid at runtime (read-only bind mount)
├── auth.json               # Authentication tokens (sensitive)
├── bin/                    # Installed CLI tools from packages
├── extensions/             # Bind-mounted from harness root
├── git/                    # Git-based package installs
│   └── github.com/...      #   Cloned repositories
├── intercom/               # pi-intercom state
│   ├── broker.pid          #   Broker process ID
│   └── broker.sock         #   Broker Unix socket
├── models-store.json       # Resolved model configurations
├── models.json             # Provider/model configuration
├── npm/                    # npm-based package installs
│   ├── package.json        #   Installed npm packages
│   ├── package-lock.json   #   Dependency lock
│   └── node_modules/       #   Package artifacts
├── sessions/               # Session history
│   └── <workspace-hash>/   #   Per-workspace session logs
│       └── *.jsonl         #       Individual session files
├── settings.json           # Pi configuration (model, theme, packages list)
└── skills/                 # Bind-mounted from harness root
```

## Key Files

### `settings.json`

Runtime configuration. Seeded from `settings.json` in the harness root.

```json
{
  "defaultProvider": "fireworks",
  "defaultModel": "accounts/fireworks/models/deepseek-v4-flash",
  "packages": ["npm:pi-web-access@0.13.0", ...]
}
```

### `models.json`

Provider/model definitions. Seeded once from the harness root on first
launch. Note: this is a one-time copy — changes to the source
`models.json` are not synced automatically (remove the seeded copy to
re-seed).

### `sessions/`

Each pi session is logged as a JSONL file. Session files are organized
by workspace path (hashed). Resume a session with `piw -r`.

## Notes

- The entire `.pi/` directory is gitignored — no state leaks into version
  control
- Sessions, auth tokens, and installed packages are all local to this
  harness clone
- The `PI_CONFIG_DIR` env var can point to a different location (useful
  for sharing config across multiple harness clones)
