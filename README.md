# piw

piw is a launcher and environment manager for the
[pi coding agent](https://pi.dev). It runs pi inside a Docker container and
keeps your workspace native.

The container holds the tooling and the isolation. The workspace stays on the
host and is bind-mounted at the same path. The agent cannot change the host
outside the paths you mount.

## Prerequisites

- Docker, running.
- At least one API key for pi.

## Quick start

```bash
git clone https://github.com/dpoorc/piw.git
cd piw

# Put the CLI on your PATH.
./piw link

# Build the default image and compose your layers.
piw build

# Put your keys in the secrets file.
cp .env.example .local/.env
$EDITOR .local/.env

# Check the setup.
piw doctor

# Launch pi in a project.
piw ~/my-project
```

The first build needs network access. Later builds use the Docker cache.

## How it works

piw keeps two kinds of files apart:

- **Upstream content** - the files in this repository.
- **Local state** - everything under `.local/`. Gitignored.

```
.local/
├── .env        your secrets
├── agent/      pi's state: sessions, auth, extensions
├── agents/     skills that other agent tools read
├── app/        pi's program install
├── layers/     your layers
├── mise/       the store tool manifest
├── piw.conf    the layer manifest
└── store/      the tools you installed
```

The image is tooling and isolation only. pi and its extensions live in the
mounts, so they update without an image rebuild.

Two mechanisms add tools:

- A **layer** adds tools to the image at build time. It can install apt
  packages or run a script as root.
- A **store tool** is one that mise installs into `.local/store`. It survives
  an image rebuild.

See [the overview](docs/overview.md) for the full model.

## Verification

The test suite drives the real `piw` against a stub `docker`. It covers
argument parsing, image tags, mounts, environment, and the container command.
It needs no Docker daemon and no network.

```bash
bash tests/run.sh
```

The suite does not run a real container. Build and launch are verified by hand
on a Docker host. Treat the container behaviour as verified, not proven.

## Documentation

Start at [docs/index.md](docs/index.md).

## License

GPLv3. See [LICENSE](LICENSE).

piw is a community wrapper. It is not an official product of the pi project.
