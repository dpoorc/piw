---
id: 34
title: Environment description for the agent
status: closed
priority: medium
labels:
    - wayfinder:grilling
relations:
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-03"
closed: "2026-10-03"
---

## Questions

- Generated from the manifest and the store, or written by the user?
- Where does it live? A skill, `APPEND_SYSTEM.md`, or a file the agent reads on
  demand?
- What belongs in it? Tool names and versions, or only the capabilities that
  matter?
- What keeps it true after a tool is added or removed?

## Input from #25

Project tools do not belong in a global environment description. A project that
needs its own note writes it in its own `AGENTS.md`, and harness behaviour
belongs in the workflow skill, which is already mounted and read at session
start. So this ticket may resolve to "nothing global is needed", and that is a
valid answer.

## What exists today

**`skills/variant/SKILL.md` is a zero-byte, untracked placeholder.** It exists
so `piw` has something to mount over:

```bash
local variant_skill="$SCRIPT_DIR/variants/$profile/SKILL.md"
[[ -f "$variant_skill" ]] && variant_skill_volumes+=(-v "$variant_skill:/home/pi/.pi/agent/skills/variant/SKILL.md:z,ro")
```

The real content is `variants/workstation/SKILL.md`, and it is **a 60-line tool
inventory**: language toolchains, infrastructure tools, security tools, media
tools, forensics tools, a discovery-commands section, and a hardware-caveats
section.

**It contains versions.** "go 1.27", "ffmpeg (9.0 static)", "7-Zip 26.03". Each
one is a future lie, and the mise lockfile now owns the truth.

**The workflow skill's section 3 is stale in two ways.** Its "Skill discovery"
subsection describes `~/.pi/agent/skills/ready/` and `~/.pi/agent/skills/index/`
tiers that **do not exist**; the real tree is `system/`, `variant/`, and
`vendor/`. Its "Variants" subsection says "This container runs a specific
variant (core, devops, etc.)". So section 3 needs rewriting whether or not the
description is large.

## Answer

### Written, not generated

A generated description would have to live in `.local/`, because `piw` never
writes a tracked file after install. The agent would then have to be told to
read it, and it would go stale between builds. A description of what the
environment **is** does not change when a tool is added. A generated inventory
would be accurate on the day it was written and wrong the first time anyone ran
`mise install`.

### Capabilities and limits, never an inventory

No tool names and no versions. `mise ls`, `mise which`, and `command -v` answer
the inventory question better than a document can, and they cannot be wrong.

The description points at the store and PATH and lets the agent explore. It
also states the one thing exploration cannot reveal: **the container is not the
host.** Some tasks need host-side functionality a container cannot reach, such
as live packet capture, radio and Bluetooth I/O, WiFi injection, and the host
network stack. That is a property of the environment rather than of any one
tool, so it is general and it does not depend on which layers are active.

### The agent asks for what is missing

The base image is deliberately small, and a tool that is absent is not a
problem to work around. The rule already exists in section 4, "Iterative
Improvement", which says to propose rather than work around. It needs updating
for layers: it names "variant(s)" as the target, and layers are what a proposal
now becomes.

### It lives in the workflow skill

**Project tool declaration** already decided that harness behaviour belongs in
the workflow skill, which is mounted and read at session start. It is the only
candidate that is read once and carries prose well, and section 3 needs
rewriting regardless.

### `APPEND_SYSTEM.md` does not grow

`APPEND_SYSTEM.md` is the one piece of harness text that is **always in the
system prompt**, so it is the only thing that survives compaction by
construction. That gives it a narrow job: state what must never be lost, and
point at what must be re-read. It keeps its two must-reads, the workflow skill
and the STE skill, and gains nothing.

The catalog does not join that list. It is a lookup rather than a standing
obligation, and demanding it before the first tool call would make every session
read a file most sessions do not need, which is the cost the whole
`disable-model-invocation` mechanism exists to avoid. The workflow skill points
at it instead, and the existing "read them again after every context
compaction" line already carries the re-read, because following it lands the
agent in the workflow skill, which carries the catalog instruction.

### Layers do not ship skills

Decided outright in this ticket, to stop the question from drifting.

A layer cannot ship a skill today, and the reason is structural: `<repo>/skills/`
is mounted at `<agent-dir>/skills`, where pi looks, while `.local/layers/` is
mounted at `/opt/piw/layers`, which pi does not scan. The three ways around it
would each cost something real: copying skills into `.local/agent/skills/`
introduces drift on a second kind of content, and pointing pi's `skills` setting
at the layer path makes `piw` maintain a user-owned `settings.json`.

So layers ship **no skills**, and the capability the old variant skill had is
replaced by two cheaper things: a general note in section 3, and an optional
`README.md` beside the layer, readable at `/opt/piw/layers/<name>/README.md`.

### The new section 3

```markdown
## 3. Harness Context

You are inside a Docker container running pi.

The workspace directory is the only host path accessible inside the
container. System paths (/var/log, /etc, /run, /sys, /proc) are
container-local and reflect the container state, not the host.
Tools such as systemctl, journalctl, dmesg, and sshd are not
available.

- **SELinux** — The host enforces it. Bind mounts use the `:z` flag.
  Handled; you don't need to worry about it.
- **Network** — `host.docker.internal` resolves to the Docker host.
- **User** — You run as the host user's UID. `/home/pi` is your home.
  Pi config is at `/home/pi/.pi/agent/`, bind-mounted from the host.
- **Workspace** — The current directory is a bind-mount. Changes are
  reflected on the host immediately.
- **No systemd, no Docker-in-Docker** — You cannot start system
  services or run nested containers.

### The container is not the host

Some tasks need host-side functionality a container cannot reach:
live packet capture, radio and Bluetooth I/O, WiFi injection, and the
host network stack. Tools installed here still work on files and on
the container's own interfaces, so the usual answer is to capture on
the host and bring the result into the workspace. When a task needs
the host, say so rather than reporting an empty result as a finding.

### Installed tools

The base image is deliberately small. Everything else lives in the
store, managed by mise. Ask rather than assume:

- `mise ls` — every tool the store provides, with versions
- `mise which <tool>` — where a tool came from
- `command -v <tool>` — whether a tool is on PATH
- `mise search <term>` — what mise could install

When you need a tool that is not present, do not work around it
silently and do not install it yourself. Propose it. See section 4.

### Skills

Skills come from two places: `system/` is the harness's own, and
`vendor/` is third-party. Every skill is invocable with `/skill:name`.

Skills marked `disable-model-invocation: true` are **not** in your
system prompt. They cost nothing per turn, so the harness uses that
mark for anything you are unlikely to need. The catalog at
`skills/catalog.md` lists them with their paths. Read it when a task
might match a skill you have not seen, and again after a compaction,
because a summary can drop it.

An active layer may carry notes at `/opt/piw/layers/<name>/README.md`.
```

The "Skill discovery" and "Variants" subsections are both removed.

## Findings

1. **`skills/variant/` is not content.** It is a zero-byte, untracked file that
   exists only as a mount target. The bucket dies with the variants, and the
   name `variant` is gone from the skills tree.
2. **Section 3's "Skill discovery" subsection was wrong about the mechanism as
   well as the paths.** It described an `index/` tier as "skills with
   `disable-model-invocation: true`", which is the mechanism **Low-frequency
   skills** settled, but the tier itself does not exist.
3. **The catalog generator's promoted-bucket list is why `misc/` is missing.**
   It defaults to `engineering productivity`, and `misc/` holds four skills that
   are active in the harness: `git-guardrails-claude-code`,
   `migrate-to-shoehorn`, `scaffold-exercises`, `setup-pre-commit`.
   `in-progress/` is correctly excluded. This is **Low-frequency skills**'
   business, but it confirms that finding.
4. **`vendor/` is a whole cloned repository, not a skills directory.**
   `skills/vendor/mattpocock/` holds `.agents`, `.changeset`, `.claude-plugin`,
   `.github`, `.out-of-scope`, `docs`, `scripts`, and `skills`. The entire tree
   is mounted read-only into `<agent-dir>/skills`. pi skips dot-directories and
   `node_modules`, so the dot-directories are inert, but `docs/` and `scripts/`
   are scanned. Nothing there is named `SKILL.md` today, so nothing happens, but
   a vendor update could change that.

## Consequences

- **Migrate paths into the `.local` namespace** deletes `skills/variant/` and
  the variant-skill mount, and rewrites section 3.
- **Low-frequency skills** owns the catalog's scan set and its output.
- **Tests and CI** gains a target: the catalog must cover `misc/`, and the
  generator must fail loudly rather than emitting empty descriptions.
- **Docs rewrite for publishing** describes the environment for a human reader,
  which is a different job from section 3's job of describing it for the agent.
- **Section 4 needs updating for layers**: its proposal table names "which
  variant(s) does it belong in", and a proposal now targets a layer.
