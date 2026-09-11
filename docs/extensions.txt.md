# config-seeds/extensions.txt — Package Manifest

`config-seeds/extensions.txt` lists third-party pi packages to be installed
into the harness. It uses standard `pi install` syntax. The runtime copies
live in `.pi/agent/settings.json` under the `"packages"` key.

## Format

- One package per line
- Blank lines are ignored
- Lines starting with `#` are comments

```
# My packages
npm:pi-web-access@0.13.0
npm:@gotgenes/pi-permission-system
git:https://github.com/user/repo
```

## Package Syntax

### npm packages

```txt
npm:<package-name>[@<version>]
```

Installs from the npm registry. Versions are optional. Without a version,
the latest is used.

Examples:
```
npm:pi-web-access
npm:pi-web-access@0.13.0
npm:@gotgenes/pi-permission-system
```

### git packages

```txt
git:<repository-url>[@<ref>]
```

Installs from a git repository. Optionally pins to a branch, tag, or
commit hash.

Examples:
```
git:https://github.com/user/repo
git:https://github.com/user/repo@v1.0.0
```

## How It Works

When you run `piw update` (or `piw build` for a fresh mount):

1. Pi reads `config-seeds/extensions.txt`
2. For each extension, checks the config mount host-side (`.pi/agent/npm`,
   `.pi/agent/git`) for presence and installed version
3. Installs missing extensions and upgrades outdated npm extensions via
   `pi install <pkg>` inside the harness container
4. Results are summarized at the end

`git:` extensions are fetched **once at install time**. Manifest ref
bumps (`@<ref>`) are not re-fetched by sync — the mount strips the ref
so the version check reads empty and stays silent. Use
`piw update --force` to refresh a git extension.

The installed extensions are tracked in `.pi/agent/settings.json` under
`"packages"` and their code lives in the bind-mounted `npm/` and `git/`
trees — pi loads them at launch, no rebuild needed.

## Typical Workflow

```bash
# Edit the manifest
$EDITOR config-seeds/extensions.txt

# Apply the change (pull, rebuild, upgrade pi, sync extensions)
piw update

# Only sync pi + extensions against the current tree (skip build)
piw update --install-only

# Reinstall every listed extension
piw update --force

# See what would change without executing anything
piw update --dry-run
```
