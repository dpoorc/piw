---
id: 17
title: 'Decision: mise is the install path'
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-01"
closed: "2026-10-01"
---

## Question

Which manager installs tools and toolchains into the store?

## Answer

mise. It is the only candidate meeting every requirement at once: no root, a fully overridable install root, a lockfile, per directory pinning, toolchains as well as prebuilt binaries, and verification on by default for the aqua backend and for GitHub attestations on the github backend.

It also gives the two tool scopes directly: one writable root, MISE_DATA_DIR, plus read only shared roots, MISE_SHARED_INSTALL_DIRS.

Accepted costs: a large fast moving binary, roughly 153 MB, and a feature surface broader than we need. We use the backends and the lockfile only.

Honesty requirement for the docs: mise states that support in a backend does not mean every package supplies every check, and that a lockfile entry with a recorded checksum is trusted without re verification. The docs must not claim that every tool is checksum verified.

Rejected: aqua (checksum verification off by default, single store root), asdf (no verification in core), ubi (no verification code), eget (stale, silent no op verifier), Nix (installer requires root), Homebrew (heavy, no pinning by design), cargo-binstall (Rust only), pkgx (a runner, not an installer).
