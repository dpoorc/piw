# piw CLI Reference

`piw` is the entry point for pi-harness. It manages Docker images and
the pi runtime (pi itself + extensions) in the bind-mounted config dir.

## Model

The Docker image is tooling + isolation only. pi lives in its own app
mount; extensions live in the config mount. Both update without image
rebuilds:

```
.pi/                      ← harness-owned dir (gitignored)
├── app/                  ← pi app mount (npm prefix, reinstallable)
│   └── node_modules/@earendil-works/pi-coding-agent
└── agent/                ← config mount (pi state + extensions)
    ├── npm/              ← npm extensions (pi-managed)
    ├── git/              ← git extensions (pi-managed)
    ├── settings.json     ← pi's package bookkeeping
    └── models.json       ← model/provider config
```

`piw update` is the one command that brings everything — repo, images,
pi, extensions — current. Extension tweaks (code in the mount) need no
wrapper involvement: pi reloads them on next launch or `/reload`.

## Synopsis

```bash
piw [--profile <name>] [--resume|-r] [--help] [<path>]
piw build [<profile>] [--all] [--no-cache] [--offline]
piw update [<profile>] [--all] [--build-only] [--install-only] [--force] [--dry-run] [--no-cache] [--offline]
piw doctor [<profile>]
piw generate-catalog
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
- Ensures pi is installed in the app mount (`ensure_pi`, default
  `.pi/app`); installs it if missing (requires network)
- Sources `.env` for API keys
- Bind-mounts config, skills, extensions, and workspace
- Drops into the `pi` interactive session

### `build`

```
piw build                   Build default profile + provision mount
piw build devops            Build devops profile + provision mount
piw build --all             Build all variants + provision mount
piw build --no-cache        Full rebuild (ignore Docker cache)
piw build --offline         Build from build/archives only (no downloads)
```

- Builds tooling images (no pi layer — pi comes from the config mount)
- After building: installs pi if missing, then syncs extensions from
  `config-seeds/extensions.txt` (install missing, upgrade outdated)
- Regenerates the skills catalog

`--offline` applies to the image builds; mount provisioning (pi
install/upgrade, extension sync) still needs npm and fails with
guidance when offline and something is missing.

### `update`

```
piw update                      Pull, rebuild, upgrade pi, sync extensions
piw update --all                Update all variants
piw update --build-only         Pull + rebuild, skip pi/extensions
piw update --install-only       Pull + sync pi/extensions, skip build
piw update --force              Reinstall every listed extension
piw update --dry-run            Show the plan (pi, extensions, images) — no executions
piw update --all --no-cache     Full rebuild all from scratch
piw update --offline            Require build/archives present, no downloads
```

Order of operations:

1. `git pull --ff-only` — never stashes. Uncommitted work blocks
   update: if local changes overlap incoming updates it aborts with
   instructions (commit or unshelve locally, then retry). Commit your
   work before running `piw update`.
2. Rebuild variant images (`--install-only` skips).
3. Upgrade pi in the config mount when npm shows a newer version.
4. Sync extensions: install missing, upgrade outdated npm extensions
   (`--force` reinstalls every listed extension).
5. Regenerate the skills catalog.

Dry-run prints the plan host-side: pi installed vs latest, each
extension's status, and which images would rebuild. Nothing executes
(no git pull, no docker builds, no installs).

`--offline` covers **image builds only**: it requires `build/archives`
present and never downloads archives. Pi install and extension sync
still need npm — with no network, pi update/install or extension
upgrades fail with guidance instead of silently proceeding.

### `doctor`

```
piw doctor                  Diagnose default profile
piw doctor devops           Diagnose devops profile
```

Checks: Docker, variant dir, Docker image, `.env`, API keys, config
directory, skills, extensions, **pi version in the config mount vs npm
latest**, per-extension installed/latest status, build archives, skills
catalog freshness, git repository status.

### `generate-catalog`

Regenerates `skills/catalog.md` from the `SKILL.md` files. Runs
automatically at the end of `build` and `update`.

### `tool`

Manage the shared tool store at `.pi/store`, mounted at `/home/pi/.local`
inside the container.

```
piw tool install npm:typescript
piw tool install uv:ruff
piw tool install cargo:ripgrep
piw tool install go:github.com/bettercap/bettercap/v2
piw tool install opentofu
piw tool install bin:opentofu/opentofu@v1.12.6
piw tool list
piw tool remove npm:typescript
```

Every install runs inside the container and lands in the store, so tools
survive container recreation. The store bin directory is on PATH in the
container.

Specs dispatch to the manager that owns each ecosystem:

| Prefix | Manager | Notes |
|--------|---------|-------|
| `npm:` | npm | Installed under the store prefix |
| `uv:` | uv | Python CLI tools |
| `cargo:` | cargo | Rust crates |
| `go:` | go | Go modules. `go install` has no uninstall |
| `mise:` | mise | Any mise backend, for example `mise:cargo:ripgrep` |
| `bin:` | mise | GitHub release binary, for example `bin:opentofu/opentofu@v1.12.6` |
| (no prefix) | mise | Registry name, for example `ripgrep` or `opentofu` |

Bare specs and `bin:` specs resolve through mise. It pins versions, and
it verifies checksums where the backend provides them. mise also installs
language toolchains, so `piw tool install rust` works without the
`workstation` profile. The `uv:`, `cargo:`, and `go:` prefixes are
conveniences that use the toolchains already in the image.

The store lives at `.pi/store`. mise data and its global `mise.toml` live
inside it, so installed tools survive container recreation.

The store sits beside pi's own `.pi/agent` and `.pi/app`. Do not put it in
`.pi/tools`: pi reads that path as a deprecated project tools directory and
warns on start.

Project-local tools are planned: a gitignored `.pi/store` in the project,
placed ahead of the shared store on PATH.

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
| `PI_PI_DIR` | Override pi app directory (default: `.pi/app`; set to an absolute path e.g. `~/.local/share/pi-node` for pi-standard placement) |
| `PI_TOOLS_DIR` | Override the tool store directory (default: `.pi/store`) |
| `YADM_HOME` | Host home passed into the container at launch. The yadm wrapper uses it so dotfiles resolve to the host's repo/config. Not set on the host-side; it is internal to the container. |
| `ANTHROPIC_API_KEY` | Anthropic API key |
| `OPENAI_API_KEY` | OpenAI API key |
| `GEMINI_API_KEY` | Google Gemini API key |
| `FIREWORKS_API_KEY` | Fireworks AI API key |
| (and others) | See `.env.example` for full list |

All API keys are sourced from `.env` (if present) or the host environment.

## Tests

```
tests/run.sh
```

Drives the real `piw` with a stub `docker` on PATH. Argument parsing, image
tags, mounts, environment, and the container command are all exercised. No
Docker daemon is needed, and the suite runs in under a second.

The suite runs in a temporary sandbox with a fake variants tree, dummy
archives, and stubs for `curl` and `npm`, so it never touches the repo or the
network. Run it after any change to `piw`.

## Flag Compatibility

| Flag | launch | build | update | doctor |
|------|--------|-------|--------|--------|
| `--profile` | ✅ | ✅ (default) | ✅ (default) | ✅ (default) |
| `--all` | ❌ | ✅ | ✅ | ❌ |
| `--no-cache` | ❌ | ✅ | ✅ | ❌ |
| `--force` | ❌ | ❌ | ✅ | ❌ |
| `--dry-run` | ❌ | ❌ | ✅ | ❌ |
| `--build-only` | ❌ | ❌ | ✅ | ❌ |
| `--install-only` | ❌ | ❌ | ✅ | ❌ |
| `--offline` | ❌ | ✅ | ✅ | ❌ |
| `--resume` | ✅ | ❌ | ❌ | ❌ |

`--build-only` and `--install-only` are mutually exclusive.
