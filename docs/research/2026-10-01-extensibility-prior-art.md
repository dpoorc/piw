# Prior art for extensible defaults

Research for the piw wayfinder map (ticket #19). Two questions: how do
established tools ship a minimal sane default plus a user extension
mechanism, and which projects treat a cloned repository as the working
directory?

## The pattern everyone uses

All nine surveyed mechanisms answer the same way, in three parts:

1. Keep a small base.
2. Let the user declare additions in a file that lives **outside** the
   upstream tree.
3. Run privileged install steps in a **build step**, never at runtime.

## Extension mechanisms

| Mechanism | Extension unit | Root at build | Upstream stays generic | Main cost |
|---|---|---|---|---|
| devcontainer Features | tgz or OCI artifact with `install.sh` | Yes, by design | Yes | Build steps, third-party root code |
| Nix flakes | `flake.nix` inputs | Store, unprivileged builds | Yes | Experimental, steep curve |
| Dagger modules | Source module in git | Root inside module containers | Yes | Engine plus SDK required |
| Universal Blue / BlueBuild | Container image, module scripts | Root in Containerfile `RUN` | Yes | Rebuilds, signing, reboot |
| Homebrew | Formula, tap, Brewfile | No root (refuses sudo) | Yes | No version pinning |
| Devbox | `devbox.json` | No root | Yes | Nix dependency |
| Flox | `manifest.toml` | sudo at install time | Yes | Nix plus a CLI |
| Toolbx / distrobox | Container image, `distrobox.ini` | Root inside container | Yes | Drift, weak security promise |
| asdf / mise | Plugin repo, registry backend | No root | Yes | Unversioned plugin code |

### Closest precedents for a bash-plus-Docker harness

1. **devcontainer Features.** A feature is a folder with
   `devcontainer-feature.json` and an `install.sh`, distributed as an OCI
   artifact. The install script runs as root during the image build, which
   is exactly the apt-only problem, solved by design. Users declare
   features in their own `devcontainer.json`.
2. **BlueBuild modules.** A declarative `recipe.yml` with an ordered
   `modules[]` list. "Custom modules overwrite the default modules." A
   module is only a script plus JSON configuration, so the least new
   machinery is required.
3. **Brewfile.** The clearest precedent for one file mixing several
   sources. The lesson it teaches is a warning: Homebrew refuses to
   promise version pinning, and says so. "`brew bundle` does not and will
   not have a concept of a `Brewfile` lock file."

### Poor fits

Nix, Devbox, and Flox each add a second package manager and a store to a
harness built on Docker plus a shell script. rpm-ostree needs a bootable
host and a reboot. Toolbx and distrobox use mutable containers, which is
the opposite of an immutable image.

## The cloned-repo-as-workdir pattern

| Uses the clone as the work tree | Keeps the program global, config separate |
|---|---|
| yadm, bare-git dotfiles | chezmoi, home-manager, pre-commit, direnv, just, devcontainers, Docker Compose |

yadm: "yadm instead uses your `$HOME` directory _as_ its working
directory." Git data lives at `$HOME/.local/share/yadm/repo.git`.

chezmoi states the split directly: the source directory is common to all
machines, and the config file is specific to the local machine.

### Benefits claimed

- No symlink farm and no relocation. "You don't have to move your
  dotfiles, or have them symlinked from another location."
- Git is inherited whole: branch, merge, rebase, submodules.
- For a harness, one clone holds both program and state, so there is no
  second directory and no extra mount.

### Drawbacks

- **Untracked-file noise.** "For dotfiles, this is usually a massive list
  of files."
- **Local files can block a clone.** Files that differ are left
  unmodified, and the user must resolve them.
- **Template copies cannot merge upstream.** GitHub: "Branches created
  from a template have unrelated histories, which means you cannot create
  pull requests or merge between the branches." A repository created from
  a template also starts with a single commit.
- **Fork copies can sync, but then the user's copy is a fork.**

The merge-conflict rate itself is not documented anywhere found, so that
risk is inferred from the two facts above rather than measured.

### How projects separate program from configuration

| Project | Program | User configuration |
|---|---|---|
| chezmoi | Installed binary | Source dir plus machine-local config file |
| home-manager | Nix | `~/.config/home-manager`, overridable with `--flake` |
| pre-commit | Installed binary | `.pre-commit-config.yaml` in the project, cache in `~/.cache` |
| direnv | Installed binary | `.envrc` in the project, plus per-machine approval |
| just | Installed binary | `justfile` in the project |
| devcontainers | CLI or editor | `.devcontainer/devcontainer.json` in the project |
| Docker Compose | `docker compose` | `compose.yaml` in the project |

## Application to piw

piw already follows the safer split for **state**: `.pi/agent` is
gitignored and `PI_CONFIG_DIR` overrides it. What remains entangled is the
program and the upstream content sharing a tree with user configuration.

Suggested shape, stated as a proposal:

- A default image built by `piw`, whose Dockerfile stays free of personal
  tools.
- A user manifest outside the tracked tree, one line per extension.
- Extension kinds: pi packages (already exists), a Dockerfile fragment
  applied as a final build stage, and an install script run as root in
  that stage.
- State stays in `.pi/agent`, gitignored, overridable.

## Sources

- https://containers.dev/implementors/features/
- https://containers.dev/implementors/features-distribution/
- https://containers.dev/implementors/spec/
- https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-flake.html
- https://nix.dev/manual/nix/2.35/development/experimental-features.html
- https://docs.dagger.io/0.18/features/reusability
- https://blue-build.org/reference/module/
- https://blue-build.org/reference/recipe/
- https://github.com/ublue-os/image-template/blob/main/README.md
- https://docs.brew.sh/Brew-Bundle-and-Brewfile
- https://docs.brew.sh/Taps
- https://www.jetify.com/devbox/docs/configuration/
- https://flox.dev/docs/man/manifest.toml
- https://distrobox.it/usage/distrobox-assemble/
- https://github.com/containers/toolbox
- https://asdf-vm.com/plugins/create.html
- https://mise.jdx.dev/dev-tools/backends/
- https://yadm.io/docs/overview
- https://yadm.io/docs/faq
- https://chezmoi.io/user-guide/setup/
- https://home-manager.dev/manual/unstable/nix-flakes/standalone.html
- https://pre-commit.com/
- https://direnv.net/
- https://just.systems/man/en/
- https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template

## Gaps

- No primary source was fetched for the general Nix privilege model. The
  Devbox documentation carries the adjacent claim.
- The exact Dagger CLI flag for consuming a remote module was not verified.
- The VS Code dotfiles personalization page could not be fetched. The CLI
  `additional-features` flag was verified from source instead.
- No primary source quantifies merge-conflict frequency for the
  cloned-repo pattern.
- Flox per-package privilege behaviour is inferred from the install page.
- Devbox rootless behaviour rests on the docs plus two open issue reports,
  which may be stale.
