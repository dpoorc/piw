# Permissions

piw ships the [`@gotgenes/pi-permission-system`](https://github.com/gotgenes/pi-packages)
extension. It controls the agent's access to files, commands, and paths.

## Where the config lives

The permission system reads one JSON file per scope:

| Scope | Path |
|-------|------|
| Global | `.local/agent/extensions/pi-permission-system/config.json` |
| Project | `<workspace>/.pi/extensions/pi-permission-system/config.json` |

The global file is piw's. piw seeds it from `seed/permissions/config.json` on
the first launch and never overwrites it afterwards. The project file is
optional. The project file overrides the global file, and it loads only when
the project is trusted.

## The shipped policy

The default (`permissive`) policy allows most actions and denies the sensitive
files:

```json
{
  "permission": {
    "*": "allow",
    "path": {
      "*": "allow",
      ".env": "deny",
      ".env.*": "deny",
      "*/.env": "deny",
      "*/*.env": "deny",
      "*/.env.*": "deny",
      ".env.example": "allow",
      ".env.template": "allow",
      "*/.env.example": "allow",
      "*/.env.template": "allow",
      "*.pem": "deny",
      "*.key": "deny",
      ".local/agent/auth.json": "ask",
      "*/.local/agent/auth.json": "ask",
      ".local/agent/sessions/*": "ask",
      "*/.local/agent/sessions/*": "ask"
    },
    "external_directory": {
      "*": "ask"
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
    }
  }
}
```

The `.env` rules protect the secrets file. The patterns anchor to a path
segment, so `*/.env.*` matches a file named `.env.<something>` in any
directory. A leading `*` alone would be too greedy: the wildcard crosses `/`
and newlines, so it would also match the text `.env.` inside a commit message.

The `auth.json` and `sessions` rules cover the self-hosted case. When the
workspace is the harness itself, `.local/` is inside the workspace, so the
`external_directory` gate does not fire. These rules put pi's credentials and
session logs behind a prompt.

## Modes

piw ships three modes:

| Mode | Default policy | Use |
|------|----------------|-----|
| `permissive` | `"*": "allow"` | General development (default) |
| `restricted` | `"*": "ask"` | Sensitive environments |
| `readonly` | `"*": "deny"` | Investigation and audit |

```bash
piw ~/project                          # permissive
piw --mode restricted ~/prod-project   # restricted
piw --mode readonly ~/investigation    # read-only

export PIW_MODE=restricted             # or set the environment
piw ~/project
```

The shipped policies live in `seed/permissions/`:

```
seed/permissions/
├── config.json              # permissive
├── config.restricted.json   # restricted
└── config.readonly.json     # readonly
```

On the first launch, piw copies each missing policy into the live extension
directory, `.local/agent/extensions/pi-permission-system/`. piw seeds a file
only when it is absent, so your edits survive. Delete a live policy to restore
the shipped version on the next launch.

For a non-default mode, piw mounts the mode file over `config.json` in the
container, read-only. The permission system reads the same path, so no
extension change is needed.

For `readonly`, piw also applies container-level restrictions: the workspace
mounts read-only, and the network is disabled.

### Custom modes

Create `config.<name>.json` in `seed/permissions/`, or directly in
`.local/agent/extensions/pi-permission-system/`, and pass `--mode <name>`.

## Rule matching

A rule has one of three states:

| State | Behavior |
|-------|----------|
| `allow` | The action proceeds without a prompt |
| `deny` | The action is blocked with an error |
| `ask` | The user confirms the action |

Four surfaces compose, and the most restrictive result wins:

1. `path` - the cross-cutting gate. It applies to every file access: pi's
   tools, bash commands, MCP calls, and extension tools.
2. `external_directory` - the working-tree boundary. It decides whether a
   path outside the workspace is reachable.
3. The per-tool surfaces, such as `read`, `write`, and `edit`.
4. `bash` - the shell command patterns.

The order of restrictiveness is `deny` > `ask` > `allow`. A `path` allow
cannot loosen an `external_directory: ask`. Put an outside-CWD directory on
`external_directory` to silence its prompts.

Inside one surface map, the last matching rule wins. Put broad catch-alls
first and specific rules after.

A `*` in a pattern matches any character, including `/` and a newline. A
relative path matches both its written form and its working-directory-
normalized form.

## Logging

The permission system writes a review log to
`.local/agent/extensions/pi-permission-system/logs/`. Each line records the
time, the action, the tool, the value, and the rule that decided it.

```bash
grep '"deny"' .local/agent/extensions/pi-permission-system/logs/*.jsonl
```

## Changing the policy

Edit the live config on the host. The agent cannot change it: the permission
config is the gate, so it stays outside the agent's reach. For a persistent
change to a shipped mode, edit `seed/permissions/config.<mode>.json` and
remove the live copy.
