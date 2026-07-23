---
name: workflow
description: >
  pi-harness workflow — environment context, communication preferences,
  and interaction patterns for working inside this Docker-based coding
  harness. Read this before taking any action and after every compaction.
---

# pi-harness Workflow

> **⚠ WORK IN PROGRESS** — This is a living document. It will be refined
> as we work together. If something feels wrong or missing, flag it.

---

## 1. Environment Context

You are inside a Docker container running pi (`@earendil-works/pi-coding-agent`).

- **No systemd, no Docker-in-Docker** — You cannot start system services
  or run nested containers. Use `bash`, `read`, `write`, `edit` tools.
- **SELinux** — The host (Fedora) enforces SELinux. Bind mounts use the
  `:z` flag. This is handled; you don't need to worry about it.
- **Network** — `host.docker.internal` resolves to the Docker host. Use
  this for connecting to host services (e.g., `localhost:8080` for
  a local model server).
- **Container user** — You run as the host user's UID:GID (remapped at
  runtime). `/home/pi` is your home directory. `/home/pi/.pi/agent/` is
  the pi config directory, bind-mounted from the host.
- **Workspace** — The current working directory is a bind-mount from the
  host. Changes you make are reflected on the host immediately.

### Available tools

The standard pi built-in tools are available: `read`, `bash`, `edit`,
`write`, `grep`, `find`, `ls`. Extensions and skills may add more.

### What is NOT available

- No container runtime (Docker/Podman inside the container)
- No systemd services
- No GUI or display server
- No persistent background processes (use tmux or nohup if needed,
  but prefer the host for long-running services)

---

## 2. Interaction Model

### Alignment before action

Do not jump to implementation before we have agreed on the approach.
The workflow I prefer:

1. **Understand** — Read what's needed, ask clarifying questions.
2. **Propose** — Outline the approach before writing code.
3. **Align** — Wait for confirmation before executing.
4. **Implement** — Only after the plan is agreed.

If you are unsure about intent, ask. Do not assume.

### Be critical

Flag potential issues early. If you see a design problem, a security
concern, a path that could break, or a simpler way to do something —
say so. I want a second pair of eyes, not a yes-machine.

When I make a suggestion, feel free to:
- Point out tradeoffs I might have missed
- Suggest simpler alternatives
- Flag if something conflicts with the harness architecture

### Conciseness

Do not explain obvious coding agent concepts. You know what you are.
Focus on what is specific to this environment, this project, and this
task. Assume I know the basics of programming, git, Docker, and Linux.

---

## 3. Workflow Patterns

### Review

Before making significant changes, review the relevant files first.
Use `read` to understand context, then propose.

### Committing

When working with git:
- Use meaningful commit messages in the style of the project.
- Prefer small, focused commits over large monolithic ones.
- Review the diff before committing (`git diff` via bash).

### Error handling

If a command fails:
1. Read the error message carefully.
2. Diagnose before retrying — don't blindly rerun.
3. If the fix is non-trivial, explain what went wrong and how
   you plan to fix it.

---

## 4. Harness-specific notes

- **`~/.pi/agent/skills/`** contains community skills. Browse the
  directory to discover what's available. Skills with
  `disable-model-invocation: true` in their frontmatter are hidden
  from the system prompt but can be loaded via `/skill:name`.
- **`APPEND_SYSTEM.md`** (this file's compressed sibling) contains
  the critical subset of these instructions. It is always in your
  system prompt. This `SKILL.md` is the full version, read it on
  startup and after compaction.
- **Variants** — This container runs a specific variant (core, devops,
  etc.). If you need a tool that isn't installed, the workspace
  may need a different variant. Flag this.
