# Permission System

pi-harness ships with `@gotgenes/pi-permission-system` to control the
agent's access to files, commands, and paths.

## Configuration

The permission config lives at `extensions/pi-permission-system/config.json`:

```json
{
  "permission": {
    "*": "allow",

    "path": {
      "*": "allow",
      ".env": "deny",
      ".env.*": "deny",
      ".env.example": "allow",
      "*.pem": "deny",
      "*.key": "deny"
    },

    "bash": {
      "*": "allow",
      "rm -rf *": "ask",
      "rm -r *": "ask",
      "sudo *": "ask",
      "chmod -R *": "ask",
      "chown -R *": "ask",
      "dd *": "ask",
      "mkfs*": "ask",
      "shutdown*": "ask",
      "poweroff*": "ask",
      "reboot*": "ask",
      "kill *": "ask",
      "pkill *": "ask"
    },

    "external_directory": {
      "*": "ask"
    }
  }
}
```

## Modes

piw supports three built-in permission modes, selectable via
`--mode` flag or `PIW_MODE` environment variable:

| Mode | Default policy | Use case |
|------|---------------|----------|
| `permissive` | `"*": "allow"` | General development (default) |
| `restricted` | `"*": "ask"` | Devops / sensitive environments |
| `readonly` | `"*": "deny"` | Investigation / audit only |

Usage:

```bash
piw ~/project                          # permissive (default)
piw --mode restricted ~/prod-project   # restricted
piw --mode readonly ~/investigation    # read-only

# Via env var:
export PIW_MODE=restricted
piw ~/project
```

### How modes work

Each mode corresponds to a config file alongside the default:

```
extensions/pi-permission-system/
├── config.json              # permissive mode
├── config.restricted.json   # restricted mode
└── config.readonly.json     # readonly mode
```

When a non-default mode is active, piw bind-mounts the mode-specific
config over the default in the container. The permission system reads
it at the same path — no extension changes needed.

For `readonly` mode, piw also applies Docker-level restrictions:
- Workspace is mounted read-only (`:ro`)
- Network access is disabled (`--network none`)

### Mode + project config = layered

Mode configs compose with [project-level overrides](#project-level-overrides):

```
mode config (e.g. restricted)
  → project config (.pi/extensions/pi-permission-system/config.json)
    = effective policy
```

This means you can use `--mode restricted` as a broad baseline and
still tighten further per-project — or loosen specific tools in a
given project while keeping the default restrictive.

### Custom modes

You can define your own mode by creating `config.<name>.json` in
the same directory and passing `--mode <name>`. The file is
resolved at `extensions/pi-permission-system/config.<name>.json`.

## Project-Level Overrides

You can override the mode (or the global default) on a per-project
basis by creating a project-local config file:

```bash
mkdir -p .pi/extensions/pi-permission-system
$EDITOR .pi/extensions/pi-permission-system/config.json
```

This config merges on top of the active mode config, with higher
precedence. So you can use `--mode permissive` globally but deny
`write` for a specific project:

```json
{
  "permission": {
    "write": "deny",
    "edit": "deny"
  }
}
```

Or run `--mode restricted` but allow `terraform plan` without
prompting in a particular project:

```json
{
  "permission": {
    "bash": {
      "terraform plan": "allow"
    }
  }
}
```

## Permission Levels

| Level | Behavior |
|-------|----------|
| `allow` | Operation proceeds without confirmation |
| `deny` | Operation is blocked with an error |
| `ask` | Agent is prompted for confirmation |

### Rule Matching

- `"*"` matches everything (wildcard)
- Rules are checked in order; the most specific match wins
- Path rules match against file paths the agent tries to read/write
- Bash rules match against shell commands the agent tries to execute

## Logging

The permission system logs all interactions to
`extensions/pi-permission-system/logs/pi-permission-system-permission-review.jsonl`:

```jsonl
{"timestamp":"2026-07-23T21:40:00.000Z","action":"deny","target":"read","path":"/home/<user>/Projekt/pi-harness/.env","rule":".env"}
{"timestamp":"2026-07-23T21:41:00.000Z","action":"allow","target":"read","path":"/home/<user>/Projekt/pi-harness/src/main.ts","rule":"*"}
```

Each log entry contains:
- `timestamp` — When the permission check occurred
- `action` — `allow`, `deny`, or `ask`
- `target` — The tool being used (read, write, bash, etc.)
- `path` or `command` — The specific resource
- `rule` — Which rule matched

## Reviewing Denied Access

Check the log for blocked actions:

```bash
grep '"deny"' extensions/pi-permission-system/logs/*.jsonl
```

If a legitimate access is being blocked, adjust the rules in `config.json`.
The agent cannot modify this file — edit it on the host.
