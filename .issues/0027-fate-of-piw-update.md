---
id: 27
title: Fate of piw update
status: closed
priority: medium
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 30
    depends-on:
        - 21
        - 22
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-02"
closed: "2026-10-02"
---

## Question

What does piw update mean once variants are gone?

Today it pulls the repo, rebuilds images, upgrades pi, and syncs extensions. Decide which of those survive, which move to the pi own commands, and what rebuilds when a layer or the manifest changes.

## Answer

### What `piw update` becomes

Three steps, in order:

1. `git pull --ff-only` the harness. Fail loudly on divergence.
2. `piw build`.
3. `pi update --all` in the container, which covers pi, the extensions, and the
   model catalogs in one command.

### What dies

- **`ensure_pi`'s upgrade mode.** pi owns its own updates through `pi update`.
  `ensure_pi` shrinks to "install pi if it is missing", which #23 already
  decided.
- **`sync_extensions_for`.** `pi install` and `pi update --extensions` already
  do this. The replacement is one command in the container.
- **The variants loop and `--all`.** Variants are going.
- **`--build-only` and `--install-only`.** Both exist only because `update`
  bundles three things. Once `piw build` and `pi update --all` are individually
  addressable, each flag is a way of suppressing two thirds of a command. The
  user runs the command they want instead.

### The rebuild trigger

This was the substantive question, and it is settled as **detect and refuse**.

**Launch generates the plan in memory, hashes it, and compares the hash against
a label written at build time.** If the hash differs, launch prints the reason
and the fix, which is `piw build`, and exits. It never rebuilds on its own.

The mechanism is cheap enough to fit a launch path that `7acc8ff` deliberately
made offline and minimal:

1. The plan is deterministic, so regenerating it costs one `piw.conf` parse and
   a check that each `run:` layer's `install.sh` exists.
2. The hash covers the plan, the contents of `.local/layers/`, and the root
   Dockerfile, so an edited `install.sh` counts as a change.
3. `docker build --label` writes the hash at build time. Reading it rides on the
   `docker image inspect` that launch already makes, so there is no extra docker
   call and no stamp file to desync.

The four options and why the others lost:

| Option | Verdict |
|---|---|
| Explicit `piw build` only | Fails silently. A manifest edit changes nothing until someone notices. |
| Launch detects and rebuilds | Ruled out by the leanness preference. A build at launch can take minutes. |
| The mutating commands rebuild | Does not cover hand edits, which #22 explicitly supports. |
| **Launch detects and refuses** | Chosen. Never silent, never slow. |

### Final decisions

**`piw update` survives, with the pull.** The destination is "clone it, install
it, and run it", and one command that brings the whole harness current is what
makes the clone model comfortable. `--ff-only` refuses to guess when the user
has diverged, and says so.

**`pi update --models` is folded in.** A stale model catalog is the same class
of staleness as a stale pi, and `pi update --all` already covers it.

**Launch detects staleness and refuses.** It never rebuilds. The signal is an
image label holding a hash of the plan, the layer files, and the root
Dockerfile.

**`--no-cache` and `--dry-run` stay on `build`.** `--force` stays on `update` as
a passthrough to `pi update --all --force`.

**`--build-only` and `--install-only` die.**

### Findings

1. **`ensure_pi` carries an upgrade mode that pi now owns.** It queries npm for
   the latest version and installs it. `pi update` does the same job better.
2. **`sync_extensions_for` reimplements `pi install`.** It reads
   `extensions.txt`, checks each package's version on npm, and installs it.
3. **`_npm_latest_version` has five call sites.** This ticket and **CLI surface**
   remove four of them: the extension sync twice, and the `doctor` version
   checks twice. After both, only `ensure_pi`'s install path remains, which is
   when pi is missing.
4. **There is no staleness check today.** `ensure_image` builds only when the
   image is absent, so a manifest edit is invisible until someone notices.

## Consequences

- **#35 narrows to a single case.** After this ticket and **CLI surface**, the
  only host-side npm call left is `ensure_pi` installing a missing pi.
- **#38 carries the extension question.** Extensions are neither store tools nor
  layers, and they have no ticket of their own.
- **#29 gains a test target.** The staleness check is pure shell logic around a
  hash comparison, so `stub-docker` can cover it.
- **#30 must document the refusal.** A user who edits `piw.conf` and launches
  will meet the message, and the docs should say what it means.
