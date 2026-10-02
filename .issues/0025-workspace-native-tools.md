---
id: 25
title: How does a project declare its tools?
status: closed
priority: medium
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 26
    depends-on:
        - 24
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-02"
closed: "2026-10-02"
---

## Question

Does a project declare its own tools, and if so how?

Re-scoped by #22 and #5. Project level layers are dropped: per project images would rebuild or accumulate, and apt packages are rarely project specific. Project level tools are probably mise's job already, because mise reads a project's `mise.toml` and the container's working directory is the workspace.

Decide:

- Is that enough, or does piw need to do something?
- Does piw install project tools at launch, or leave it to the agent on demand?
- What happens when the project pins a version that is not in the store?
- Is the answer simply "no project scope, document mise"?

A "no" is a valid and useful answer. The ticket exists so the answer is written down rather than assumed.

## Answer

**There is no project scope in piw. mise already is the project scope, and piw
does not duplicate it.**

### The fact base

Verified against mise 2026.9.17 in the container.

**F1. mise reads a project `mise.toml` from the working directory, and the
working directory is the workspace.** `mise config ls` in a test project showed
both configs loaded:

```
/tmp/misetest/global/config.toml  ripgrep
/tmp/misetest/proj/mise.toml      jq
```

**F2. Project and global tools merge.** `mise install --dry-run` resolved
`jq@1.7.1` (project) and `ripgrep@15.2.0` (global) together.

**F3. A plain `[tools]` config needs no trust.** From `mise trust --help`:

> safe config files do not require trust: files that only contain `min_version`,
> `[tools]` entries with plain version strings (or arrays of them), and
> `[tasks]` without templates or tool options.

So the common case is free.

**F4. An unsafe untrusted config hard-errors on every read path, and does not
prompt.** With a tool option or a task template present, `mise ls` and
`mise config ls` both fail with `Config files in … are not trusted`. The
container is non-interactive, so there is nobody to answer a prompt.

**F5. `mise install` auto-trusts.** After `mise install --dry-run`, a
`trusted-configs/` entry appeared and `mise ls` worked. The recovery exists, but
only through that command.

**F6. Trust state lives outside `MISE_DATA_DIR`,** at `$XDG_STATE_HOME/mise`
(default `~/.local/state/mise`). In the container that is
`/home/pi/.local/state/mise`, inside the store mount, so it persists. It is
keyed by a hash of the config path, and the workspace keeps its host path, so
trust survives across launches.

**F7. `mise install` does not write a lockfile.** The project directory was
unchanged after a real install. Only `mise lock` writes `mise.lock`.

**F8. `mise lock` writes seven platforms by default.** linux x64 and arm64,
both glibc and musl, macOS both, and Windows. `lockfile_platforms` is unset.

**F9. `not_found_auto_install` defaults to true.** `mise exec -- jq --version`
with jq absent installed it in 1.4 seconds and then ran it.

**F10. Shims exist only for installed tools.** `mise reshim` did not create a
shim for a declared-but-uninstalled tool, and a bare `fzf` failed with
`command not found`.

### The two gaps

Neither is piw's to close.

1. **An unsafe config errors until trusted.** F4 and F5. A project that uses
   tool options or task templates must reach `mise install` before any other
   mise command works.
2. **A declared tool is not on PATH until it is installed.** F10. The
   declaration is free and the activation is not.

Once mise is invoked, F9 keeps the store current without further help.

### Final decisions

**No project scope.** A project declares tools in its own tracked `mise.toml`.
piw neither reads it, nor validates it, nor merges it. Adding a piw-level
project scope would be scope creep over a job mise already does.

**piw does not install project tools at launch.** It would add launch time
proportional to the project's tool count, and it would break under
`--network none` in readonly mode. The agent, or pi's escape hatch, runs the
install.

**A command exists to install the project's tools.** The explicit path. Its
name and shape belong to #26. The implicit path is the agent running
`mise install` itself.

**piw never runs `mise trust` on the workspace.** `mise install` auto-trusts
when the agent needs it. Pre-trusting every workspace at launch would
auto-trust a hostile project's `[tasks]` for no benefit. The agent already runs
project code, so this opens no new hole, but there is no reason to open it
early.

**The lockfile carries two platforms, not seven.**

```
[settings]
lockfile_platforms = ["linux-x64", "linux-arm64"]
```

Both glibc, because the base is Debian. That covers an x86 host and an Apple
Silicon host, and drops five platforms the container can never be. Verified:
with this setting the lockfile carries exactly the two named platforms. This
refines #21's lockfile decision rather than contradicting it.

**The agent learns about project tools from the workflow skill, not from a
global environment description.** The workflow skill already carries
harness-specific behaviour and is mounted read-only. A project that needs its
own note writes it in its own `AGENTS.md`. Amends #34.

## Consequences

- **#26 loses the two scopes** and gains one project-install command.
- **#34 narrows.** A global environment description may not be needed at all.
- **A correction to #24.** mise's state directory is outside `MISE_DATA_DIR` and
  lands in the store mount. Nothing changes in the map, because the store mount
  is already read-write, but the map should say so.
