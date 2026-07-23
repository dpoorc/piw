# Overview

pi-harness wraps the [pi coding agent](https://pi.dev) in a Docker
container with three design goals:

## 1. Isolation without friction

The agent runs in a container — no accidental host modifications,
no dependency pollution, no "works on my machine." But the workflow
doesn't feel containerized: the workspace is bind-mounted, config is
bind-mounted, and skills are bind-mounted. Everything you do in the
agent is reflected on the host immediately.

## 2. Lean by default, extensible by design

The **core** variant ships with just git, curl, jq, and SSH. That's
it. If you need Python, Ansible, or Kubernetes tooling, you select a
different variant (`devops`, or a custom one). No bloat, no overhead.

## 3. Transparent tooling

Skills are plain Markdown files in `skills/`, mounted directly into
the container. You can browse them, edit them, add new ones, or remove
them — on the host or from inside the container. No black boxes.

## How it works

```
piw ./my-project
 │
 ├── Sources .env for API keys
 ├── Builds pi-harness:core (if not cached)
 ├── Mounts .pi/agent/ → /home/pi/.pi/agent
 ├── Mounts skills/ → /home/pi/.pi/agent/skills
 ├──── with APPEND_SYSTEM.md overlaid (read-only)
 ├── Mounts ./my-project → ./my-project (same path)
 ├── Sets PI_CODING_AGENT_DIR=/home/pi/.pi/agent
 └── Drops you into the pi interactive session
```

The system prompt includes a compressed workflow (APPEND_SYSTEM.md)
that tells the agent to read the full workflow skill on startup and
after every compaction. The agent is aware of the harness environment
from the first turn.
