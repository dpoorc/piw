---
id: 28
title: Migration of today variants
status: closed
priority: medium
labels:
    - wayfinder:task
relations:
    blocks:
        - 34
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-03"
closed: "2026-10-03"
---

## Question

Where does every tool in the current core, devops, and workstation images go?
Use the inventory: 56 installed items, 31 of them apt only. Decide which become
part of the baked default, which become shipped example layers, and which become
personal layers outside the repo. Produce the mapping table.

## The inventory, rebuilt

The inventory the question cites was never written to disk. It is also stale.
Rebuilt from the four Dockerfiles, the real numbers are **65 distinct items**:

| Mechanism | Count |
|---|---|
| apt | 42 |
| upstream archive | 15, from 14 archives |
| npm global | 3 |
| `uv tool install` | 3 |
| `go install` | 2 |

Four findings came out of the rebuild:

1. **No Dockerfile verifies a checksum.** All 14 archives have a recorded
   sha256 in `build/README.md`, and the build never consults it.
2. **Eight items are unpinned.** `git-issues` and `bettercap` use
   `go install @latest`. The three npm globals and the three uv tools carry no
   version at all.
3. **Four sources use `latest`.** `yq`, `hadolint`, `tflint`, and the ffmpeg
   archive. The sha256 pins the bytes, so the build does not break, but the
   recorded hash silently refers to an old release after an upstream
   publication.
4. **`git-issues` is in `core` today**, from a `golang:latest` builder stage.
   **`git-issues` leaves the default image** already decided that it should not
   be.

## Answer

### Four tiers, and what separates them

The tiers differ in **who applies them**, not in what they contain.

| Tier | Home | Applied | Owner |
|---|---|---|---|
| Default | the image | always | the harness |
| Seed | `<repo>/seed/` | once, on first install, if absent | the harness, then the user |
| Active | `.local/` | every launch | the user |
| Available | `<repo>/layers/` | **never** | the harness |

**The mount map is the enforcement.** A launch mounts exactly the paths listed
in **Store layout and mount map**. `<repo>/layers/` is not among them, so a
shipped layer cannot affect a launch even by accident. Inertness is a property
of the architecture, not a convention.

`config-seeds/` is the applied-once tier and is therefore the wrong home for an
optional stack: a seed switches on for everyone who clones. **#32** already
renames it to `seed/`, and that rename is now also justified by content, because
#21 has it carrying a starter `piw.conf` and a starter `mise.toml` alongside the
config files. A starter manifest is not configuration.

### The unit is a self-contained layer

A layer is a directory that holds a whole stack. `install.sh` becomes optional,
and three files join it:

```
.local/layers/workstation/
├── apt              apt packages, one per line
├── archives         url, sha256, and destination, one per line
├── mise.toml        the store tools this layer needs
└── install.sh       optional; anything the three above cannot express
```

**One mount holds every layer.** `.local/layers/` is mounted read-only, and
`.local/piw.conf` selects which are active:

```ini
[layers]
run:workstation
run:my-own
```

Many layers are active at once, applied in order, composed into one image. That
is the thing the old variants could not do: `devops` and `workstation` were
mutually exclusive because each forked the image, and layers do not fork it.

### There is no second noun

The repo ships layers. The user adopts the ones they want. `piw layer list`
distinguishes them by status rather than by noun, which keeps one concept and
one command group:

```
$ piw layer list
  NAME          STATUS      DESCRIPTION
  workstation   available   Full toolbox: compilers, forensics, infra
  my-own        active      My own bits
```

This is the same split the skills already have: `<repo>/skills/` is the shipped
set, `.local/agent/skills/` is the user's.

### The first-time experience

```sh
git clone … && cd piw
./install.sh                    # seeds .local/, builds the default image
piw                             # launches; the default is useful as it is

piw layer list                  # what else is there?
piw layer show workstation      # what is in it, before committing
piw layer add workstation       # copy it in, add one line
piw build                       # bake the image, populate the store
piw
```

### `piw build` populates the store

`piw build` builds the image **and** installs the store tools into
`.local/store`, so the first launch is instant rather than stalling on a
download. `mise upgrade` still updates the fast-moving tools afterwards without
a rebuild, so nothing is frozen by this.

This removes the per-tool question of baked versus store. **Everything mise can
carry is a store tool, installed at build time and updatable at any time.** The
image carries only what mise cannot: apt packages and three archives.

### mise carries 20 of the 23 non-apt items

Verified against mise 2026.9.17, which resolves every one of these:

| Today | mise spec | Resolves to |
|---|---|---|
| `go install …git-issues@latest` | `go:github.com/steviee/git-issues` | 0.0.0-2026 |
| `go install …bettercap/v2@latest` | `go:github.com/bettercap/bettercap/v2` | 2.41.7 |
| `npm install -g typescript` | `npm:typescript` | 7.0.2 |
| `npm install -g eslint` | `npm:eslint` | 10.11.0 |
| `npm install -g prettier` | `npm:prettier` | 3.9.9 |
| `uv tool install flake8` | `pypi:flake8` | 7.4.1 |
| `uv tool install mypy` | `pypi:mypy` | 2.3.1 |
| `uv tool install pylint` | `pypi:pylint` | 4.1.1 |
| archive `go1.27.1` | `core:go` | 1.27.1 |
| archive `rust-1.98.1` | `core:rust@1.98.1` | 1.98.1 |
| archive `7z2603` | `aqua:ip7z/7zip` | 26.03 |
| archive `tofu_1.12.6` | `aqua:opentofu/opentofu` | 1.13.0 |
| archive `packer_1.16.0` | `aqua:hashicorp/packer` | 1.16.1 |
| archive `hadolint` | `aqua:hadolint/hadolint` | 2.15.1 |
| archive `tflint` | `aqua:terraform-linters/tflint` | 0.64.0 |
| archive `uv` | `aqua:astral-sh/uv` | 0.12.21 |
| archive `yq` | `aqua:mikefarah/yq` | 4.54.1 |
| mise itself | `aqua:jdx/mise` | 2026.9.18 |

**Three items have no mise backend**: `rizin`, `ffmpeg` and `ffprobe` (the BtbN
build), and `yadm`. Those stay as archives.

Three consequences:

1. **`build/archives/` shrinks from 15 archives to 3.** It is 1.1 GB today, and
   the checksum table in `build/README.md` shrinks from 15 rows to 3.
2. **The eight unpinned items become pinned**, because mise records resolved
   versions in the lockfile.
3. **The four `latest` sources stop being a problem.** The lockfile pins the
   resolved version, so an upstream release cannot silently move a tool.

### mise reads a layer directly

mise has no include mechanism, but `mise -C <dir>` merges the global config with
`<dir>/mise.toml`. Verified: with a global `config.toml` declaring `prettier`
and a layer directory declaring `typescript`, `mise -C <layerdir> ls` reports
both. So a layer's `mise.toml` needs no merging into the user's config, and
`piw` never writes a file that mise also writes.

### The mapping table

**Default (24).** Fifteen come from today's variants; nine are new in
**Minimum base image**.

| Today's item | Was | Goes to |
|---|---|---|
| node, npm | base image | default |
| build-essential, pkg-config | core | default |
| git, curl, ca-certificates, openssh-client | core | default |
| jq, tree, unzip, file | core | default |
| python3 | devops | default |
| yq | devops | default |
| uv | workstation | default |
| mise | core | default |
| shellcheck | workstation | **default, newly added** |
| less, zip, xz-utils, procps, lsof, wget, bind9-dnsutils | not present | default, new |

**Shipped layer `layers/workstation/`, baked into the image (29).**

| Today's item | Was | Goes to |
|---|---|---|
| clang, gnupg, rsync | core | layer, `apt` |
| perl, fish, openjdk-25-jdk-headless | workstation | layer, `apt` |
| binutils, gdb, hashcat, john, nmap | workstation | layer, `apt` |
| tcpdump, tshark, bluez, libpcap-dev, libusb-1.0-0-dev | workstation | layer, `apt` |
| mediainfo, libimage-exiftool-perl, libarchive-zip-perl | workstation | layer, `apt` |
| binwalk, sleuthkit, foremost, steghide, testdisk, xxd | workstation | layer, `apt` |
| rizin | workstation | layer, `archives` |
| ffmpeg, ffprobe | workstation | layer, `archives` |
| yadm | workstation | layer, `archives` |

**Shipped layer `layers/workstation/`, store tools (16).**

| Today's item | Was | Goes to |
|---|---|---|
| git-issues | core, `go install` | layer, `mise.toml` |
| Go toolchain | workstation | layer, `mise.toml` |
| Rust toolchain, Rust musl target | workstation | layer, `mise.toml` |
| 7-Zip | workstation | layer, `mise.toml` |
| opentofu, packer | workstation | layer, `mise.toml` |
| hadolint, tflint | workstation | layer, `mise.toml` |
| bettercap | workstation | layer, `mise.toml` |
| typescript, eslint, prettier | workstation | layer, `mise.toml` |
| flake8, mypy, pylint | workstation | layer, `mise.toml` |

**Documented example, not shipped (4).** The `devops` variant does not ship as a
layer. Its four remaining items appear in the docs as a worked example of
writing one, which teaches more than a shipped directory does.

| Today's item | Was | Goes to |
|---|---|---|
| python3-pip, python3-venv | devops | docs example |
| ansible, yamllint | devops | docs example |

**No action (1).**

| Today's item | Was | Goes to |
|---|---|---|
| bash | core | nothing; the base image provides it |

**Deleted.**

| Item | Why |
|---|---|
| the powershell block | dead; commented out because Microsoft's repository was unreachable, and it targets `debian/12` |
| the `template` variant | replaced by `piw layer add`'s scaffold |
| `seed/extensions.txt` | dies with **Default extensions** |

### Adoption and drift

`piw layer add <name>` **copies** the shipped layer into
`.local/layers/<name>/` and appends `run:<name>`. The user owns the copy and can
edit it freely. Because a copy is frozen at the moment of copying, later
improvements to the shipped layer would otherwise never arrive, so drift is
reported the same way **Declared extensions** reports it for config seeds: by
`piw doctor` and by `piw update`, as a diff rather than a failure.

`piw layer update <name>`:

1. Compare `.local/layers/<name>/` against `<repo>/layers/<name>/`.
2. No `.piw-origin` stamp: report that the layer was not adopted by `piw`, do
   nothing. The hand-copied case must not be guessed at.
3. Identical: report "already up to date".
4. The adopted copy matches its stamp: apply the update and rewrite the stamp.
5. The adopted copy differs from its stamp: print the diff, write nothing, and
   name the override, `piw layer update <name> --replace`.

The stamp is one line, `.piw-origin`, holding a hash of the shipped layer at
adoption, and `piw` ignores it when diffing. It has to exist because a copy has
no history: `.local/` is gitignored, so nothing else distinguishes "the user
changed this" from "upstream changed this".

This is a stamp file, and **Fate of `piw update`** argued against one for image
staleness. The difference is the failure mode. There, a desynced stamp would
silently skip or force a rebuild. Here, a missing stamp makes `piw` refuse and
say so, which is the safe direction.

## Amendments

- **Layer mechanism**: `install.sh` becomes optional, and a layer may carry
  `apt`, `archives`, and `mise.toml`. A layer stops meaning "a root-time script"
  and starts meaning "a stack that belongs together".
- **CLI surface**: adds `layer list`, `layer show`, `layer add`, and
  `layer update`. `layer add` no longer only scaffolds; it also adopts a shipped
  layer.
- **Minimum base image**: adds `shellcheck`, making the default 24 items rather
  than 23.
- **Store layout and mount map**: adds a thirteenth mount,
  `.local/layers/` read-only, so mise can read each layer's `mise.toml` at
  runtime and `mise upgrade` can see a layer's tools.
- **Store layout and mount map** also carries a stale value in #23's Dockerfile,
  `MISE_GLOBAL_CONFIG_FILE=/home/pi/.local/mise.toml`, which must become
  `/home/pi/.config/mise/config.toml`.
- **#21** and **#22** and **#36** refer to `config-seeds/piw.conf` and
  `config-seeds/layers/`, which become `seed/piw.conf` and `<repo>/layers/`.

## Consequences

- **#32 grows**: the migration also moves `config-seeds/` to `seed/`, moves the
  shipped layers out to `<repo>/layers/`, and adds the mount and the stamp.
- **#34 gains its answer for tools**: the agent learns about project tools from
  the workflow skill, and the environment description does not carry a tool
  list.
- **#23's Dockerfile is nearly final**, needing only `shellcheck` and the
  `MISE_GLOBAL_CONFIG_FILE` correction.
- **`build/archives/` and `build/README.md` shrink to three rows.** The 1.1 GB
  directory leaves the repo.

## Open at implementation

- **Whether `piw layer add` refuses when the layer is already adopted.** It
  should, on the fail-loudly rule, with `layer update` as the named path.
- **Whether the Rust musl target survives.** `core:rust` resolves, but the musl
  std target was a separate archive. If mise cannot express it, it becomes an
  `install.sh` line or it is dropped.
- **Where the layer's `apt` and `archives` files sit in the generated
  Dockerfile.** `apt:` lines are already merged into one `RUN`, and
  `ADD --checksum` lines need to land beside them.
