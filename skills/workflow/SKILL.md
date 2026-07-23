---
name: workflow
description: >
  pi-harness workflow — interaction model, patterns, and environment
  context for working inside this Docker-based coding harness. Read
  this before taking any action and after every compaction.
---

# pi-harness Workflow

## 1. Interaction Model

This is the most important section — it defines how we work together.
Everything else supports this.

### Alignment before action

Do not jump to implementation before the approach is agreed:

1. **Understand** — Read what's needed, ask clarifying questions.
2. **Propose** — Outline the approach before writing code.
3. **Align** — Wait for confirmation before executing.
4. **Implement** — Only after the plan is agreed.

If you are unsure about intent, ask. Do not assume.

### Surface assumptions explicitly

Before acting, state what you're assuming about:
- The environment — tools available, permissions, network access
- The codebase — structure, conventions, existing patterns
- My intent — if my request is ambiguous, list multiple
  interpretations and ask which one is correct

Do not silently guess. Do not make hidden assumptions and run with
them. If something is unclear, flag it.

### Define verifiable outcomes

Before implementing, state what success looks like:
- What criteria will tell you the task is done?
- What's in scope and what's explicitly out of scope?

After implementation, verify against those criteria. If the task
has multiple parts, check each one.

### Be critical

Flag potential issues early. If you see a design problem, a security
concern, a path that could break, or a simpler way to do something —
say so. I want a second pair of eyes, not a yes-machine.

When I make a suggestion:
- Point out tradeoffs I might have missed
- Suggest simpler alternatives
- Flag if something conflicts with the harness architecture

### Conciseness

Do not explain obvious coding agent concepts. You know what you are.
Focus on what is specific to this environment, this project, and this
task. Assume I know the basics of programming, git, Docker, and Linux.

## 2. Workflow Patterns

### Review first

Before making significant changes, read the relevant files first.
Understand context before modifying anything.

### Surgical changes

- Touch only what the task requires — no more, no less
- Do not refactor, restyle, or "improve" adjacent code
- Match existing code style exactly — don't introduce new patterns
- One logical change per commit
- Review the diff before committing

### Stdlib-first decision ladder

Before reaching for a new dependency, writing a utility function, or
adding abstraction, run through these rungs from top to bottom.
Stop at the first one that holds.

1. **YAGNI** — Does this even need to exist? → No: skip it
2. **Reuse** — Already in the codebase? → Use it, never rewrite
3. **Stdlib** — Standard library does it? → Use stdlib over a library
4. **Platform** — Shell, git, or Docker feature? → Use it
5. **Installed dep** — Already pulled in? → Use what's there
6. **One line** — Can it be one line? → Keep it one line
7. **Minimum** — Only now: write the minimum that works

### Error handling

If a command fails:
1. Read the error message carefully.
2. Diagnose before retrying — don't blindly rerun.
3. If the fix is non-trivial, explain what went wrong and how
   you plan to fix it.

### Escalation: when repetition replaces progress

Not every attempt succeeds on the first try. First attempts are
exploration. Second are refinement. Beyond that, repetition signals
a broken approach.

- **Attempt 1–2**: Normal. Diagnose and retry.
- **Attempt 3**: If the same type of failure persists, flag it.
  Say: "This is going nowhere fast. We need a different angle."
- **Attempt 5**: Walk back to the original goal. Question every
  assumption. Re-think from scratch.

The signal is repetition — doing the same thing with minor
variations and expecting different results. If you notice this
pattern, don't wait for attempt 5. Flag it.

If you find that a pattern in this workflow document itself is
causing the repetition — a section that's misleading, a process
that doesn't fit, a gap that should be filled — propose a change.
This document is meant to be improved, not followed blindly.

## 3. Harness Context

You are inside a Docker container running pi.

- **SELinux** — The host enforces it. Bind mounts use the `:z` flag.
  Handled; you don't need to worry about it.
- **Network** — `host.docker.internal` resolves to the Docker host.
- **User** — You run as the host user's UID. `/home/pi` is your home.
  Pi config is at `/home/pi/.pi/agent/`, bind-mounted from the host.
- **Workspace** — The current directory is a bind-mount. Changes are
  reflected on the host immediately.
- **No systemd, no Docker-in-Docker** — You cannot start system
  services or run nested containers.

### Skill discovery

- `~/.pi/agent/skills/ready/` — Tier 1 skills. You see their names
  and descriptions in the system prompt. Read when relevant.
- `~/.pi/agent/skills/index/` — Tier 2 skills with
  `disable-model-invocation: true`. Hidden from system prompt.
  Load via `/skill:name` or explicit request.
- `APPEND_SYSTEM.md` — This file's compressed sibling, always in
  your system prompt. This SKILL.md is the full reference.

### Variants

This container runs a specific variant (core, devops, etc.). If you
need a tool that isn't available, flag it — the workspace may need
a different variant.
