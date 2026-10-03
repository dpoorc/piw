# piw

piw is a launcher and environment manager for the pi coding agent.
It runs pi inside a container and keeps the workspace native.

## Language

### Shape

**Harness**:
The clone of this repository, together with the local state inside it. One
directory that you can move.

**Upstream content**:
The files tracked in the repository. Everything a user receives by
cloning.

**Local state**:
Everything user-owned, under `.local/`. Gitignored.
_Avoid_: user data, dotfiles

**Workspace**:
The directory that pi operates on. It is mounted at the same path inside
the container.

### Tools

**Store**:
The persistent directory of tools that the user installed. It is mounted
at `/home/pi/.local` inside the container.
_Avoid_: tool store, tools dir, prefix

**Store tool**:
A tool that the user installed into the store, rather than one baked into
the image.

**Baked**:
Installed into the image at build time, and therefore present on every
launch with no network access.

**Layer**:
A build-time addition to the image, such as an apt package or an install
script that runs as root.

**Manifest**:
The declarative file that lists the user's store tools and layers.
_Avoid_: config, recipe, profile, Brewfile

### pi

**Agent directory**:
pi's own state directory: sessions, authentication, models, and settings.
It lives at `.local/agent`.
_Avoid_: config dir, PI_CONFIG_DIR

**Agent Skills directory**:
The cross-tool skills directory at `.local/agents/skills`, mounted at
`/home/pi/.agents/skills`. It is not the agent directory. The two names
differ by one character. `.local/agent` is pi's namespace.
`.local/agents/skills` follows the Agent Skills convention and other agent
tools read it.

**Extension**:
A pi package that adds behaviour. pi owns the installation of extensions.
_Avoid_: plugin, addon

### Retired

**Variant**:
The retired concept of a named environment with a hardcoded toolset. The
default image plus layers replaces it.
_Avoid_: profile, flavour, image variant
