---
id: 39
title: Build the default image
status: closed
priority: high
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    blocks:
        - 43
created: "2026-10-03"
updated: "2026-10-03"
closed: "2026-10-03"
---

## Parent

#13 piw identity and defaults — wayfinder map. Implements **Minimum base image**.

## What to build

The image every launch uses, built from a single Dockerfile at the repo root. It is `piw:default`, based on `node:24-trixie-slim`, with Node and npm from the base and everything else baked, so a fresh clone needs no network and no setup.

The apt set is the decided one, with `shellcheck` added. `build-essential` stays whole because source builds need it. `mise`, `yq`, and `uv` are not in Debian in the versions wanted, so each arrives by `ADD --checksum`, which puts the pin and the hash on the same line and needs Dockerfile syntax 1.6. The runtime environment sets mise's data directory into the store, points mise's global config at the mounted config, and keeps the existing `PATH` prefix.

## Acceptance criteria

- [ ] `docker build` at the repo root produces `piw:default`
- [ ] The apt list matches the decided set exactly, including `shellcheck`, and `dnsutils` is spelled `bind9-dnsutils`
- [ ] Each of mise, yq, and uv is fetched with `ADD --checksum` and a SHA-256 that matches the decided pin
- [ ] `MISE_GLOBAL_CONFIG_FILE` points at the mounted mise config, not the superseded path
- [ ] The build needs no network beyond the pinned downloads

## Blocked by

None — can start immediately.
