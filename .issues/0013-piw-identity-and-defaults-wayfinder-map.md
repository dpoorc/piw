---
id: 13
title: piw identity and defaults — wayfinder map
status: open
priority: high
labels:
    - wayfinder:map
relations:
    related-to:
        - 14
        - 15
        - 16
        - 17
        - 18
        - 19
        - 20
        - 21
        - 22
        - 23
        - 24
        - 25
        - 26
        - 27
        - 28
        - 29
        - 30
        - 31
        - 32
        - 33
        - 34
        - 35
        - 36
        - 37
        - 38
created: "2026-10-01"
updated: "2026-10-02"
---

## Destination

`piw` is a portable, self-contained harness. You clone it, install it, and run it, and the whole thing lives in one directory you chose, which you can move.

It launches pi in a container, isolating the agent while keeping the workspace native. The base image stays minimal. Everything beyond the base comes from a declarative manifest that declares store tools and root-built layers, and it lives entirely in gitignored paths so upstream updates stay clean.

mise is the single install path, and every install runs inside the container. The host is never touched outside the mounted paths.

The harness ships one default image that is useful out of the box, and anyone can extend it, per harness or per project, without touching the upstream tree.

## Notes

**Skills to consult:** grilling, domain-modeling, research, prototype, ste-writing, writing-for-agents, verify-docs

**Domain:** a launcher and environment manager for the pi coding agent. piw owns isolation and environment. pi owns behaviour: its own install, extensions, skills, prompts, and settings.

**Standing preferences:**
- Principle order on conflict: isolation > transparency > leanness > composition
- Transparent configuration, not transparent implementation. Third-party tools are allowed, as Docker and pi already are, provided state stays inspectable and pinned versions stay visible
- The host is never touched outside the mounted paths. That is the security invariant
- User content lives only in gitignored paths. piw never writes a tracked file after install
- Do not promise version pinning that the backends cannot deliver
- Keep piw in bash, with the test suite as the guard
- Publishing is the intent, so defaults must not encode one person toolset
- Leanness is about time, not bytes. Build and launch must feel fast, network downloads included. Image size is acceptable when it buys a simpler or faster first run. Feels small beats is small
- Reproducibility means "this works on every machine, first try", not byte-for-byte copies. Pins are for that, not for carbon copies. Tool versions are carried by the mise lockfile

## Decisions so far

- [Decision: piw identity, principles, and scope](.issues/0014-decision-piw-identity-principles-and-sco.md) — piw is a launcher and wrapper managing isolation and environment, and pi owns behaviour. Isolation > transparency > leanness > composition. The host is never touched outside mounts. Two tool scopes.
- [Decision: default image contents](.issues/0015-decision-default-image-contents.md) — T0 plus T1 are all baked, so there is no provisioning step. mise is included. fd and rg come from pi, not from piw.
- [Decision: install model is a portable harness](.issues/0016-decision-install-model-is-a-portable-har.md) — the clone is the harness. User content stays in gitignored paths. PIW_HOME is an override, not the default.
- [Decision: mise is the install path](.issues/0017-decision-mise-is-the-install-path.md) — mise, using its backends and lockfile only. The docs must not claim universal checksum verification.
- [Research: tool manager comparison](.issues/0018-research-tool-manager-comparison.md) — mise is the only candidate meeting every requirement. Detail in `docs/research/2026-10-01-tool-manager-comparison.md`.
- [Research: prior art for extensible defaults](.issues/0019-research-prior-art-for-extensible-defaul.md) — small base, user declaration outside upstream, privileged step in a build step. Detail in `docs/research/2026-10-01-extensibility-prior-art.md`.
- [Repo shape: public content vs user state](.issues/0020-repo-shape-public-content-vs-user-state.md) — one gitignored `.local/` namespace holds all user state, and `.pi/` leaves the harness root. Generated artifacts stay in tracked directories. See `docs/adr/0001-local-state-namespace.md`.
- [User manifest: format and location](.issues/0021-user-manifest-format-and-location.md) — two files, no translation. `mise.toml` for `[tools]`, which mise alone parses. `.local/mise/config.toml` for `[tools]`, which mise alone parses. `.local/piw.conf`, line-oriented and POSIX-awk-readable, for `[layers]` and `[pi]`. Env is not a tool concern and stays out.
- [Layer mechanism](.issues/0022-layer-mechanism.md) — a layer is `.local/layers/<name>/` with a required `install.sh` run as root at build time, an optional `env`, and an optional `check.sh`. One user image, one Dockerfile, no chaining. `apt:` is sugar. No generated file on disk. `build/` disappears with `ADD --checksum`.
- [Minimum base image](.issues/0023-minimum-base-image.md) — `node:24-trixie-slim`, T0 and T1 from apt, and mise, yq, and uv from GitHub with `ADD --checksum`. Debian's `yq` is a different tool at 3.x, and `uv` is absent, so both come from GitHub. Roughly 490 MB of additions. The full Dockerfile is in the ticket.
- [Store layout and the container mount map](.issues/0024-store-layout-and-two-scope-plumbing.md) — one mount per piece, twelve in all. The harness becomes a read-only resource tree: skills, agents, and `APPEND_SYSTEM.md` mount read-only, which is safe because nothing in pi writes to those paths. `.local/mise/config.toml` replaces `.local/mise.toml`. `.local/extensions/` disappears into `.local/agent/extensions/`. `.local/agents/skills/` adds the Agent Skills convention. `.local/env` passes whole with `--env-file` and holds secrets only, so the API key allowlist goes.
- [Project tool declaration](.issues/0025-workspace-native-tools.md) — no project scope. mise already reads the project's own `mise.toml` from the working directory, and piw does not duplicate it. piw never installs project tools at launch and never runs `mise trust`. No piw command touches the project's tools; the agent runs `mise install` itself. The lockfile carries two platforms, not seven.
- [CLI surface](.issues/0026-cli-surface.md) — the final command set. `--profile`, `--all`, and `--offline` die. `--install` and `--uninstall` become `link` and `unlink`. The manifest gains `layer` beside `tool`, and `layer add` scaffolds a `run:` layer and points the user at both ways to edit it. There is no project command: piw manages the harness, not the project. Each command declares its flags, so a mismatched flag is an error. `doctor` checks four things, and reports seeded-config drift as a diff rather than a failure. `--version` is added.
- [Fate of piw update](.issues/0027-fate-of-piw-update.md) — `piw update` shrinks to a pull, a build, and `pi update --all` in the container. `ensure_pi`'s upgrade mode and `sync_extensions_for` die, because pi owns both. Launch detects a stale image by comparing a hash of the build plan against an image label, and refuses rather than rebuilding, so a manifest edit is never silent and never slow. `update` reports seeded-config drift, so an established user sees a newly added default. `--build-only` and `--install-only` die.
- [Default extensions](.issues/0038-how-are-the-default-extensions-declared.md) — the `packages` array in `settings.json` is the single source of truth, and `extensions.txt` and `sync_extensions_for` die with it. pi installs a declared package whose install path is missing, at startup, and loads its resources in the same pass, so piw never installs an extension. Seeded once, with drift reported as a diff by `doctor` and by `update`. The permission-config seed stays as a separate mechanism.
- [Low-frequency skills](.issues/0037-how-does-the-agent-learn-about-low-frequ.md) — `disable-model-invocation: true` removes a skill from the system prompt while keeping `/skill:name` working, and the harness already hides 21 of its 43 skills that way. The catalog's job is to be the model's index of the skills it cannot see, so it lists only the hidden ones. The workflow skill points at it and says to re-read it after compaction. The generator moves into the container and fails loudly. Note for the docs: pi's own documentation describes the mechanism misleadingly, and wrongly attributes it to the Agent Skills specification.

## Not yet specified

- Nothing at present. #20 through #26 cleared the fog.

## Out of scope

- aarch64 archives
- SELinux
- Publishing polish: contributor onboarding, packaging, release automation
- Session file pruning
- The setup command and skill, which is a downstream consumer rather than a destination element
