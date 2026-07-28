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

### Permission Levels

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
