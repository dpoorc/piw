---
id: 92
title: Layer content changes invalidate apt and archive build steps
status: closed
priority: medium
labels:
    - kind:enhancement
    - state:ready-for-agent
relations:
    related-to:
        - 27
created: "2026-11-04"
updated: "2026-11-04"
closed: "2026-11-04"
---

Found during a `piw update` on the laptop.

A small edit to one layer reruns apt steps and archive downloads for other
layers. During rapid iteration in one session, this wastes minutes per edit.

## Root cause

`compose_plan` (`piw:357`) emits each `run:` layer in declared order as apt,
then archives, then `COPY` and `install.sh`. The generated plan interleaves
system inputs with layer content:

    FROM piw:default
    RUN apt-get install <workstation packages>
    ADD rizin / ffmpeg / yadm
    COPY workstation/ ; RUN install.sh
    RUN apt-get install libimage-exiftool-perl
    COPY pre-publish/ ; RUN install.sh

The pre-publish apt step sits after the workstation `COPY` and `install.sh`. A
one-line edit to `workstation/install.sh` invalidates the workstation content,
then the pre-publish apt step, then the pre-publish content. Docker caches a
linear plan, so any change invalidates every later step.

## Fix

Hoist the system inputs above all layer content. The invariant is:

    system packages first, archive downloads next, layer content last.

All apt packages from all layers merge into one `RUN` block. Archives become
one `ADD` each, grouped after the apt block. Layer `COPY` and `install.sh`
steps follow, in declared order.

The change splits the single `ops` array in `compose_plan` into three arrays
(`apt_ops`, `archive_ops`, `layer_ops`) and concatenates them in that order.
The emission loop does not change.

Generated plan after the fix:

    FROM piw:default
    RUN apt-get install <workstation packages + exiftool>
    ADD rizin / ffmpeg / yadm
    COPY workstation/ ; RUN install.sh
    COPY pre-publish/ ; RUN install.sh

## Trade-offs

| Effect | Result |
|---|---|
| Layer content change | Apt and archive steps stay cached. This is the goal. |
| Apt change | The merged apt block reruns, then archives and layers. Apt edits are rare. |
| Duplicate `apt-get update` | Removed. One block serves the whole image. |
| `install.sh` order | Unchanged between layers. All apt now precedes all scripts, which is safer. |
| Base tag move | Still rebuilds everything. The base tag floats by decision. |

## Acceptance

- A layer content change does not invalidate an apt step or an archive `ADD`.
- All apt packages from every layer merge into one `RUN` block.
- Layer `COPY` and `install.sh` steps keep their declared order.
- The plan test that asserts "a non-apt step splits apt groups"
  (`tests/run.sh:574`) is replaced. The new test asserts the new contract.
