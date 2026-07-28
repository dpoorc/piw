# extensions.txt — Package Manifest

`extensions.txt` lists third-party pi packages to be installed into the
harness. It uses standard `pi install` syntax.

## Format

- One package per line
- Blank lines are ignored
- Lines starting with `#` are comments

```
# My packages
npm:pi-web-access@0.13.0
npm:@gotgenes/pi-permission-system
git:https://github.com/r3b1s/rtk-pi
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
git:https://github.com/r3b1s/rtk-pi
git:https://github.com/user/repo@v1.0.0
```

## How It Works

When you run `piw install-packages`:

1. Pi reads `extensions.txt`
2. For each package, runs `pi install <pkg>` inside the harness container
3. Already-installed packages are skipped (use `--force` to reinstall)
4. Results are summarized at the end

The installed packages are tracked in `.pi/agent/settings.json` under the
`"packages"` key.

## Typical Workflow

```bash
# Edit the manifest
$EDITOR extensions.txt

# Install new packages
piw install-packages

# Force reinstall to upgrade
piw install-packages --force

# See what would change
piw install-packages --dry-run
```
