---
id: 23
title: Minimum base image
status: closed
priority: high
labels:
    - wayfinder:task
relations:
    blocks:
        - 28
    related-to:
        - 13
        - 36
created: "2026-10-01"
updated: "2026-10-01"
closed: "2026-10-01"
---

## Question

Fix the exact baked list, how each item is installed, and the resulting image size.

T0 and T1 are already decided in the default contents ticket. This ticket turns the list into a Dockerfile: apt package, archive, or official installer for each item, on the Debian 13 base, plus the measured size.

## Answer

### Base image

`FROM node:24-trixie-slim`

Node 24 and npm come from the base, which is why they are not in the apt
list. Debian trixie's own `nodejs` is older. The slim variant keeps the
image down.

### The exact list and its source

| Item | Source |
|---|---|
| node, npm | the base image |
| git, curl, ca-certificates, openssh-client | apt |
| build-essential, pkg-config | apt |
| jq, tree, python3, less, file, unzip, zip, xz-utils, procps, lsof, wget | apt |
| dnsutils | apt, as `bind9-dnsutils` |
| mise | GitHub release, `ADD --checksum` |
| yq | GitHub release, `ADD --checksum` |
| uv | GitHub release, `ADD --checksum` |

### Two corrections to the T1 list

1. **`dnsutils` is transitional.** Install `bind9-dnsutils`.
2. **Debian's `yq` is a different tool.** trixie ships yq **3.4.3**,
   which is the Python jq wrapper. mikefarah's Go yq is **4.53.6**, and
   the syntax differs. `yq -p toml` does not exist in 3.x. The docs and
   scripts assume mikefarah's, so it comes from GitHub.
3. **`uv` is not in Debian at all.** Only the unrelated `tox-uv` plugin
   is.

### The Dockerfile

```dockerfile
# pi-harness - default image
#
# The base every launch uses. T0 and T1 from issue #15 are all baked, so a
# fresh harness needs no network and no setup.
#
# Base: the official Node 24 image on Debian 13 (trixie). Node and npm come
# from here, which is why they are not in the apt list.
#
# Build: docker build -t pi-harness:default .

FROM node:24-trixie-slim

# -- T0 and T1 from apt ------------------------------------------------------
# build-essential is kept whole because source builds need it: cargo install,
# npm native modules, and Python without wheels. Its toolchain is the largest
# part of this image, at roughly 218 MB.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        git \
        curl \
        ca-certificates \
        openssh-client \
        jq \
        tree \
        python3 \
        less \
        file \
        unzip \
        zip \
        xz-utils \
        procps \
        lsof \
        wget \
        bind9-dnsutils \
    && rm -rf /var/lib/apt/lists/*

# -- Tools Debian does not have ----------------------------------------------
# Each download carries its own checksum, so the pin and the hash sit next to
# each other. ADD --checksum needs Dockerfile syntax 1.6 or later.

# mise, the install path for store tools. Not in Debian. The binary is large
# and is not stripped upstream; strip saves about 21 MB.
ADD --checksum=sha256:a31542ee4d660b048d9ddc8f60ed024bff13bd292c08fecde5739ef7a5721dbc \
    https://github.com/jdx/mise/releases/download/v2026.9.17/mise-v2026.9.17-linux-x64.tar.xz \
    /tmp/mise.tar.xz
RUN tar -xJf /tmp/mise.tar.xz -C /tmp \
    && install -m755 /tmp/mise/bin/mise /usr/local/bin/mise \
    && strip /usr/local/bin/mise \
    && rm -rf /tmp/mise.tar.xz /tmp/mise

# yq. Debian's `yq` is the Python jq wrapper at 3.x, not mikefarah's Go yq.
ADD --checksum=sha256:38b907b21b1b04327fb9481c595331d925a67c6ee1aabd0ef419d0b7d12dfb3d \
    https://github.com/mikefarah/yq/releases/download/v4.53.6/yq_linux_amd64.tar.gz \
    /tmp/yq.tar.gz
RUN tar -xzf /tmp/yq.tar.gz -C /tmp yq_linux_amd64 \
    && install -m755 /tmp/yq_linux_amd64 /usr/local/bin/yq \
    && rm -rf /tmp/yq.tar.gz /tmp/yq_linux_amd64 /tmp/yq.1 /tmp/install-man-page.sh

# uv. Not in Debian at all.
ADD --checksum=sha256:745765a3b6e360ad76743599ae5c42e9278c7edf8bbff9fc76d05bf2623a04dd \
    https://github.com/astral-sh/uv/releases/download/0.12.13/uv-x86_64-unknown-linux-gnu.tar.gz \
    /tmp/uv.tar.gz
RUN tar -xzf /tmp/uv.tar.gz -C /tmp \
    && install -m755 /tmp/uv-x86_64-unknown-linux-gnu/uv /usr/local/bin/uv \
    && install -m755 /tmp/uv-x86_64-unknown-linux-gnu/uvx /usr/local/bin/uvx \
    && rm -rf /tmp/uv.tar.gz /tmp/uv-x86_64-unknown-linux-gnu

# -- Runtime environment ------------------------------------------------------
# The mount targets are provisional until #24 settles the mount map.
ENV MISE_DATA_DIR=/home/pi/.local/share/mise \
    MISE_GLOBAL_CONFIG_FILE=/home/pi/.local/mise.toml \
    PATH=/opt/pi/node_modules/.bin:/home/pi/.local/bin:/home/pi/.local/share/mise/shims:$PATH

CMD ["pi"]
```

### Size

| Piece | Size |
|---|---|
| apt T0 and T1, toolchain excluded | 58 MB, a floor |
| build-essential closure | 218 MB |
| mise | 153 MB, 125 MB after strip |
| uv | 47 MB |
| yq | 14 MB |
| node:24-trixie-slim | not measured |

Roughly 490 MB of additions, and that is a floor because `less`, `zip`,
`wget`, and `bind9-dnsutils` were not installed in the measuring
container.

The exact figure needs a build on the host:

```
docker build -t pi-harness:default .
docker image inspect --format '{{.Size}}' pi-harness:default
```

For scale, the current workstation image holds 2014 MB of installed dpkg
packages.

### Pins

| Tool | Version | Asset | sha256 |
|---|---|---|---|
| mise | v2026.9.17 | `mise-v2026.9.17-linux-x64.tar.xz` | `a31542ee…` |
| yq | v4.53.6 | `yq_linux_amd64.tar.gz` | `38b907b2…` |
| uv | 0.12.13 | `uv-x86_64-unknown-linux-gnu.tar.gz` | `745765a3…` |

The mise and uv digests cross-check against `build/README.md`. The mise
tar.xz digest comes from the GitHub release metadata, which is the
authoritative source. The tar.gz is the alternative if that is not
trusted, at 51 MB instead of 30 MB.

### Findings

1. **`git-issues` is in the current core image but not in T0 or T1.** It
   is built from `golang:latest AS git-issues-builder`, a heavy builder
   stage for one small Go tool. New ticket.
2. **The base tag floats.** `node:24-trixie-slim` follows patch updates,
   which brings security fixes and breaks bit-for-bit reproducibility. A
   digest pin is the alternative, but it rots. Recommendation: keep the
   tag, and say so.
3. **`ADD --checksum` needs Dockerfile syntax 1.6 or later.** Unverified
   on the target host.
4. **mise is the largest single baked item after the toolchain.** 125 MB
   even stripped. Baking it was decided in #15; this is the price, and it
   is worth seeing written down.
5. **The current `_archive_url` fetches yq, hadolint, and tflint from
   `releases/latest`.** A pinned sha256 and a floating URL cannot both be
   right, so those three break whenever upstream publishes. `ADD
   --checksum` forces a pinned URL, which removes the class of bug.

## Decisions after review

### Do not strip mise

Rejected. The 21 MB saved is uncompressed, so the compressed layer saving
is a fraction of that, and it is small against a roughly 250 MB image. A
build step and a small risk of breaking the binary are not worth it.
Download size and disk size are not the constraint here.

### `git-issues` does not ship in the default image

The `golang:latest` builder stage is removed. `git-issues` ships in the
workstation layer instead, which also serves this project's own workflow
until it moves to GitHub's issue tracker. See #36.

## Final decisions

### The base tag floats

`node:24-trixie-slim`, not a digest pin. piw has to keep up with the tools
around it. Reproducibility in this project means "this works on every
machine, first try", not byte-for-byte copies. Tool versions are carried
by the mise lockfile, not by the base image.

### Image size is acceptable, and it is not the constraint

Roughly 490 MB of additions is fine. The constraint is **build time**,
including the network downloads, and the feel of the first run. Feels
small beats is small. No ceiling is stated, and none is enforced. The
verdict comes from the user, by feel, after a real build.

This is consistent with rejecting `strip`: stripping mise saves disk, not
build time, so it buys nothing under this rule.

### pi stays in the mount

`CMD ["pi"]` stays, and the image does not install pi. pi evolves fast, so
baking it would cause problems and solve little. piw owns pi's install and
`pi update self` owns updates. The image keeps no second source of truth
for pi.

### `build-essential` stays whole

218 MB, kept for `cargo install`, npm native modules, and Python without
wheels. The reasoning from #15 is unchanged, and the size is now known
rather than assumed.
