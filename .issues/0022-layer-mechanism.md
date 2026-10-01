---
id: 22
title: Layer mechanism
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 26
        - 27
        - 28
        - 34
    depends-on:
        - 20
        - 21
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
closed: "2026-10-01"
---

## Question

How is a user layer declared and applied?

The prior art agrees that the privileged step belongs in a build step, not at runtime. devcontainer Features use a directory with a manifest and an install.sh run as root during the build. BlueBuild uses ordered script modules that can be overridden locally.

Decide the unit, the ordering, how piw composes it into the image, whether example layers ship in repo, and how to state the security note that a layer script runs as root at build time.

## Answer

### The unit

A layer is a directory under `.local/layers/<name>/`.

```
.local/layers/user-layer/
├── install.sh     required. runs as root, at build time
├── env            optional. KEY=value lines, emitted as ENV
└── check.sh       optional. runs after the build, as the host UID
```

Manifest side:

```
[layers]
apt:zsh gdb          sugar, merged into one apt RUN
run:user-layer       a directory
```

Rejected alternatives:

- **Dockerfile fragment.** Can restructure the image, so piw must either
  trust it or reimplement Dockerfile parsing.
- **Declarative install kinds** (`npm:`, `cargo:`, `pip:`, `binary:`).
  Duplicates mise and becomes a tower of cards.
- **Apt names only.** Cannot express Go, Rust, npm, or a binary.
- **An OCI artifact.** Correct endgame for sharing, but it needs
  publishing infrastructure.
- **Chained Dockerfiles with `ARG BASE`.** Full power, but one image per
  layer, and verbose for the common case.

### The contract

- Runs as root, at build time, inside the image.
- cwd is `/`. No arguments. Network is available.
- `set -euo pipefail` is recommended.
- Never re-run at launch. There is no runtime root.
- **No idempotence requirement.** Docker re-runs the script only when its
  `COPY` changes, and it re-runs against the cached image from before that
  copy. A script never sees its own effects.

### The mechanism

1. Build `pi-harness:default` from the root `Dockerfile`.
2. Parse `.local/piw.conf` and take `[layers]` in order.
3. Resolve each entry. If a `run:` layer or its `install.sh` is missing,
   stop before invoking Docker, and name the entry and the expected path.
4. Generate the plan in memory.
5. `docker build -f - -t pi-harness:local .local/layers`
6. Run `check.sh`, when present, in a fresh container from the built
   image, as the host UID.
7. An empty `[layers]` means no user image. The launch action uses the
   base.

The generated plan:

```
FROM pi-harness:default

# [layers] apt:zsh gdb
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        zsh \
        gdb \
 && rm -rf /var/lib/apt/lists/*

# [layers] run:user-layer
COPY user-layer/ /tmp/piw-layer/
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH
RUN bash /tmp/piw-layer/install.sh \
 && rm -rf /tmp/piw-layer
```

- `ENV` precedes the `RUN`, so the script sees its own declared
  environment. Rust's `CARGO_HOME` forces this.
- `COPY <name>/ /tmp/piw-layer/` is how a layer ships a payload. The
  script installs from there, and the `rm` keeps the image small.
- Consecutive `apt:` entries merge into one `RUN`, because each one
  otherwise repeats `apt-get update`. Order is preserved otherwise.

### One user image

Every layer lives in one Dockerfile, built in order. There is no chaining
of images and no image per layer.

### Transparency

No generated file on disk. `--dry-run` prints the plan, and a failed build
reprints it. Regeneration is deterministic, so the plan is always
available and can never go stale.

### Robustness

- `piw layer new <name>` scaffolds a layer with the contract in comments.
- Fail on the host, before Docker, when a layer is missing.
- Print the plan when a build fails.
- `check.sh` is the only automated test a user layer can have. It runs as
  the host UID, because the agent runs as a non-root user, so a check that
  passes as root can still fail in practice.

### The root risk

The wording for the docs and for `piw build` output:

> A layer script runs as root, at build time, inside the image. No host
> path is mounted during a build, so your files are not exposed. The
> result is the image your agent then runs in. Treat a third-party layer
> as you would a third-party Dockerfile: read it first.

### Pinning

Layers are not pinned. Debian does not keep old versions, so a pinned apt
version breaks at the next repository update. Reproducibility comes from
the store tools and the mise lockfile, not from layers.

### Consequences

- `build/` disappears. `ADD --checksum=sha256:` is verified at Dockerfile
  syntax 1.6, so mise and uv are fetched with a verified checksum and the
  pin sits next to the thing it pins. The 1.1 GB archive directory and
  roughly 100 lines of piw go with it.
- The default image Dockerfile lives at the repository root. There is
  exactly one Dockerfile, and `docker build .` then works.
- `config-seeds/layers/workstation/` ships the current workstation stack
  as an adoptable layer. `piw.conf` ships with `[layers]` empty and a
  commented example, so nobody pays for it by default.
- The launch action must decide whether to rebuild the user image. #26.
- The default action has no name. #26.
- The build needs Dockerfile syntax 1.6 or later. Unverified on the
  target host.
