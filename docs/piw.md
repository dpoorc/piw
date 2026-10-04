# piw CLI reference

`piw` is the entry point. It builds the images, manages the tool store and the
layers, and launches pi in the container.

## Model

The image is tooling and isolation only. pi lives in the app mount
(`.local/app`), and its extensions live in the agent mount (`.local/agent`).
Both update without an image rebuild. `piw update` is the one command that
brings the repository, the images, and pi up to date.

## Synopsis

```bash
piw [<path>] [--mode <name>] [-r|--resume]
piw build [--no-cache] [--dry-run]
piw tool install <spec>... | remove <spec>... | list
piw layer add <name|apt:...> | remove <name> | list | show <name> | update <name> [--replace]
piw doctor
piw link [dir] | unlink [dir]
piw generate-catalog
piw update [--no-cache] [--force] [--dry-run]
piw --version | --help
```

The first argument selects the command. A known command word is a command.
Anything else is a launch, so `piw ~/my-project` works without a keyword.

## Launch

```
piw                         Launch in the current directory
piw ~/my-project            Launch with a specific workspace
piw --mode restricted       Launch with a permission mode
piw -r                      Launch and pick a session to resume
```

A launch does this:

1. Builds the image if it is missing or stale.
2. Ensures pi is present in the app mount, and installs it when missing.
3. Passes the secrets file to the container.
4. Mounts the state, the skills, the layers, and the workspace.
5. Starts the pi interactive session.

| Flag | Meaning |
|------|---------|
| `--mode <name>` | Select a permission mode: `permissive`, `restricted`, or `readonly` |
| `-r`, `--resume` | Launch with the session picker |

## build

```
piw build                   Build the default image and the layer image
piw build --no-cache        Full rebuild, ignore the Docker cache
piw build --dry-run         Print the plan, run nothing
```

`build` builds `piw:default`, composes the active layers into `piw:local`,
installs the store tools, and regenerates the skills catalog.

## tool

```
piw tool install <spec>...  Install tools into the shared store
piw tool remove <spec>...   Remove tools from the shared store
piw tool list               List the tools in the shared store
```

Every install runs inside the container and lands in `.local/store`, so tools
survive a container recreation. The store `bin` directory is on `PATH` in the
container.

The store draws from two places: the global manifest at
`.local/mise/config.toml`, and one fragment per active layer under
`.local/mise/conf.d/`. `piw build` writes the fragments.

A spec names a tool. mise resolves most specs. The prefixes select a specific
manager:

| Prefix | Manager |
|--------|---------|
| (none) | mise, by registry name |
| `mise:` | mise, any backend |
| `bin:` | mise, a GitHub release binary |
| `npm:` | npm |
| `uv:` | uv |
| `cargo:` | cargo |
| `go:` | go |

## layer

```
piw layer add <name>        Adopt a shipped layer, or scaffold a new one
piw layer add apt:<pkg>...  Append an apt entry to the manifest
piw layer remove <name>     Remove a layer entry from the manifest
piw layer list              List the shipped and active layers
piw layer show <name>       Show a layer's contents
piw layer update <name>     Update an adopted layer
  --replace                 Overwrite local changes to the adopted layer
```

`layer add <name>` copies a shipped layer into `.local/layers/` and adds a
`run:<name>` entry to the manifest. When the name is not shipped, it scaffolds
a new layer with an `install.sh`. `layer remove` removes the manifest entry and
leaves the directory in place.

The manifest is `.local/piw.conf`. It holds two sections:

```ini
[layers]
apt:zsh gdb
run:my-setup

[pi]
npm:pi-intercom
```

`[layers]` declares build-time additions. `apt:` names Debian packages. `run:`
names a layer directory at `.local/layers/<name>/`. `[pi]` declares pi
packages, which pi installs itself.

`piw build` copies an active layer's `mise.toml` to
`.local/mise/conf.d/<name>.toml`, so the layer's tools resolve from any
directory. A layer directory holds up to five files:

| File | Role |
|------|------|
| `apt` | One apt package per line |
| `archives` | One download per line: URL, sha256, and destination |
| `mise.toml` | Store tools to install after the image build |
| `install.sh` | A script that runs as root at build time |
| `README.md` | A description, shown by `piw layer list` |

## doctor

```
piw doctor
```

`doctor` runs four checks:

1. Docker is on `PATH` and the daemon answers.
2. The launch image is present.
3. Every tool in the manifest is installed in the store.
4. The seeded files match the shipped versions (a report, not a failure).

The exit code is 0 when checks 1 to 3 pass, and 1 when any of them fails.
Check 4 never changes the exit code.

## link and unlink

```
piw link                    Put piw on PATH (default: ~/.local/bin)
piw link ~/bin              Put piw on PATH (a specific directory)
piw unlink                  Take piw off PATH
```

`link` makes a symlink to the `piw` script in the directory. `unlink` removes
it.

## generate-catalog

```
piw generate-catalog
```

`generate-catalog` regenerates `skills/catalog.md` from the `SKILL.md` files.
The catalog lists the skills that pi hides from the system prompt. The command
runs automatically at the end of `build` and `update`.

## update

```
piw update                  Pull, rebuild, and update pi
piw update --no-cache       Full rebuild, ignore the Docker cache
piw update --force          Force the pi update
piw update --dry-run        Show the plan, run nothing
```

`update` runs four steps in order:

1. Pull the harness with `git pull --ff-only`. A divergent branch stops the
   update. piw does not merge.
2. Report drift in the seeded files. A difference is a report, not a failure.
3. Rebuild the images and the store.
4. Update pi and its extensions in the container.

## Environment variables

| Variable | Meaning |
|----------|---------|
| `PI_CONFIG_DIR` | Override the agent directory (default: `.local/agent`) |
| `PI_PI_DIR` | Override the app directory (default: `.local/app`) |
| `PI_TOOLS_DIR` | Override the store directory (default: `.local/store`) |
| `PIW_CONF` | Override the layer manifest (default: `.local/piw.conf`) |
| `PIW_MISE_CONFIG` | Override the store tool manifest (default: `.local/mise/config.toml`) |
| `PIW_MODE` | Select a permission mode |

Secrets are read from `.local/.env`. See [.env.example](../.env.example).

## Tests

```bash
bash tests/run.sh
```

The suite drives the real `piw` against a stub `docker`. It covers argument
parsing, image tags, mounts, environment, and the container command. It needs
no Docker daemon and no network, and it runs in a temporary sandbox.
