---
id: 15
title: 'Decision: default image contents'
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

What ships in the default image?

## Answer

Everything in T0 and T1 is baked. There is no provisioning step, so a fresh harness needs no network and no setup.

T0, foundation: node, npm, git, curl, ca-certificates, openssh-client, build-essential, pkg-config, mise.

T1, default: jq, yq, tree, uv, python3, less, file, unzip, zip, xz-utils, procps, lsof, wget, dnsutils.

Rationale: these change slowly, and baking is plainer than provisioning. build-essential is kept whole because source builds need it: cargo install, npm native modules, and Python without wheels. The store then exists only for what the user adds.

pi already downloads fd and rg itself into its own bin directory, so piw does not provide them.
