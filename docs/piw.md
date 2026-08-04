# piw CLI Reference

`piw` is the entry point for pi-harness. It manages Docker images,
installs packages, and launches pi sessions.

## Synopsis

```bash
piw [--profile <name>] [--resume|-r] [--help] [<path>]
piw build [<profile>] [--all] [--no-cache]
piw install-packages [<profile>] [--all] [--force] [--dry-run]
piw update [<profile>] [--all] [--build-only] [--install-only] [--no-cache]
piw doctor [<profile>]
piw --install [<dir>]
piw --uninstall [<dir>]
```

## Global Options

| Flag | Description |
|------|-------------|
| `--profile <name>` | Select variant profile (default: `core`). Acts as default for subcommands. |
| `-r`, `--resume` | Launch with session picker (resume a previous session) |
| `--help`, `-h` | Show help text |

## Commands

### Launch (default)

```
piw                         Launch with default profile in current directory
piw ./my-project            Launch with specific workspace
piw --profile devops        Launch with devops variant
piw -r                      Launch and pick a session to resume
```

- Builds the Docker image if not cached
- Sources `.env` for API keys
- Bind-mounts config, skills, extensions, and workspace
- Drops into the `pi` interactive session

### `build`

```
piw build                   Build default profile + install packages
piw build devops            Build devops profile + install packages
piw build --all             Build all variants + install packages
piw build --no-cache        Full rebuild (ignore Docker cache)
```

- Always runs `install-packages` after building
- `--all` iterates all non-template variants

### `install-packages`

```
piw install-packages                    Install packages for default profile
piw install-packages devops             Install packages for devops
piw install-packages --all              Install packages for all variants
piw install-packages --force            Force reinstall all packages
piw install-packages --dry-run          Show what would be installed
piw install-packages --force --dry-run  Show what --force would do
```

Packages are read from `extensions.txt`. Already-installed packages are
skipped unless `--force` is given.

### `update`

```
piw update                  Pull git, build, install packages
piw update --all            Update all variants
piw update --build-only     Pull + rebuild, skip package install
piw update --install-only   Pull + install packages, skip build
piw update --all --no-cache Full rebuild all from scratch
```

- Auto-stashes local changes before `git pull` (pops after)
- Uses `--ff-only` to prevent accidental merge commits
- Default (no split flags) does pull + build + install

### `doctor`

```
piw doctor                  Diagnose default profile
piw doctor devops           Diagnose devops profile
```

Checks: Docker, variant dir, Docker image, `.env`, API keys, config
directory, skills, extensions, packages, rtk, git repository status.

### `--install` / `--uninstall`

```
piw --install               Install piw symlink into ~/.local/bin/
piw --install ~/bin         Install piw symlink into ~/bin/
piw --uninstall             Remove piw symlink from ~/.local/bin/
```

Also seeds config directory (settings.json, models.json) if missing.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `PI_CONFIG_DIR` | Override pi state directory (default: `.pi/agent/`) |
| `YADM_HOME` | Host home passed into the container at launch. The yadm wrapper uses it so dotfiles resolve to the host's repo/config. Not set on the host-side; it is internal to the container. |
| `ANTHROPIC_API_KEY` | Anthropic API key |
| `OPENAI_API_KEY` | OpenAI API key |
| `GEMINI_API_KEY` | Google Gemini API key |
| `FIREWORKS_API_KEY` | Fireworks AI API key |
| (and others) | See `.env.example` for full list |

All API keys are sourced from `.env` (if present) or the host environment.

## Flag Compatibility

| Flag | launch | build | install-packages | update | doctor |
|------|--------|-------|------------------|--------|--------|
| `--profile` | ✅ | ✅ (default) | ✅ (default) | ✅ (default) | ✅ (default) |
| `--all` | ❌ | ✅ | ✅ | ✅ | ❌ |
| `--no-cache` | ❌ | ✅ | ❌ | ✅ | ❌ |
| `--force` | ❌ | ❌ | ✅ | ❌ | ❌ |
| `--dry-run` | ❌ | ❌ | ✅ | ❌ | ❌ |
| `--build-only` | ❌ | ❌ | ❌ | ✅ | ❌ |
| `--install-only` | ❌ | ❌ | ❌ | ✅ | ❌ |
| `--resume` | ✅ | ❌ | ❌ | ❌ | ❌ |

`--build-only` and `--install-only` are mutually exclusive.
