---
id: 93
title: Attach the container to the local AI network
status: in-progress
priority: medium
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    related-to:
        - 27
created: "2026-11-10"
updated: "2026-11-10"
---

The container reaches a model service over the network. A dockerized model
service, such as llama.cpp or ollama, lives on its own Docker network. The
container must join that network to reach the service by container name.

## Change

Attach every `container_run` to the `localai` Docker network when Docker has
it. A new `PIW_NETWORK` override names another network. An empty value disables
the attachment.

    resolve_network() {
      # default localai; PIW_NETWORK overrides; empty disables
      # print the name when `docker network inspect` succeeds
      # return 1 only when PIW_NETWORK is set and Docker lacks the network
    }

The existence check keeps the clone-and-run model. `docker run --network
localai` fails when the network is absent, so piw attaches only when the
network exists.

## Remove the readonly network cutoff

Readonly mode used `--network none`. That contradicts the mode's purpose: pi
must reach a model service, so a network cutoff would defeat it. Readonly keeps
its read-only mounts and its permission policy. The network is no longer
restricted. The tool permissions are the read-only enforcement.

## Behavior

| Mode | `localai` present | `localai` absent |
|---|---|---|
| permissive | `--network localai` | default bridge |
| restricted | `--network localai` | default bridge |
| readonly | `--network localai` | default bridge |

`PIW_NETWORK`:

| Value | Present | Absent |
|---|---|---|
| unset (default `localai`) | attach | skip silently |
| set, non-empty | attach | error, exit 1 |
| set, empty | no attach | no attach |

## Caveat

`localai` is a normal bridge network, so the container can still reach the
internet through NAT. This is accepted. A container cannot be both connected
to a local service and fully isolated without an `--internal` network.

## Acceptance

- Every mode attaches to `localai` when Docker has it.
- No mode passes `--network none`.
- An absent default network adds no flag and does not stop piw.
- An explicit `PIW_NETWORK` that Docker lacks stops piw and names the network.
- An empty `PIW_NETWORK` disables the attachment without error.

## Verification

The test suite covers the resolver and the container argv. A live check is
pending: launch piw and confirm a dockerized model service on `localai`
resolves by container name.
