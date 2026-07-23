# Skills architecture

Skills follow the [Agent Skills standard](https://agentskills.io).
They are Markdown files with YAML frontmatter, loaded by pi from
`~/.pi/agent/skills/`.

## Three-tier loading

Skills in this harness are categorized by how they affect the agent's
context:

| Tier | Mechanism | Path | Behavior |
|------|-----------|------|----------|
| **0 — Workflow** | `APPEND_SYSTEM.md` | Mounted at `~/.pi/agent/APPEND_SYSTEM.md` | Always in system prompt. Compressed version points to full skill. |
| **1 — Ready** | Standard pi skill discovery | `~/.pi/agent/skills/ready/` | Descriptions appear in system prompt XML. Agent reads on demand. |
| **2 — Index** | Skills with `disable-model-invocation: true` | `~/.pi/agent/skills/index/` | Hidden from system prompt. Loaded via `/skill:name` or explicit user request. |

### Tier 0: Workflow

The file `skills/workflow/APPEND_SYSTEM.md` is a short (<10 line)
system prompt appendage that:
1. Identifies the harness environment
2. Tells the agent to read the full workflow skill before acting
3. Instructs re-reading after compaction

The full workflow skill lives at `skills/workflow/SKILL.md` and is
discovered as a normal Tier 1 skill. The agent reads it on startup
and keeps it in context.

### Tier 1: Ready

Standard pi skills. The agent sees their names and descriptions in
the system prompt XML and can read them when relevant. These are
the everyday utility skills (web search, browser tools, etc.).

### Tier 2: Index

Skills with `disable-model-invocation: true` in their frontmatter.
The agent does not know about them from the system prompt — they
must be requested explicitly or discovered via a catalog skill.

A `SKILLS_INDEX.md` file in the `ready/` directory lists all
available skills across all tiers, giving the agent a lightweight
way to discover Tier 2 skills.

## How skills are mounted

```
Host                                  Container
────                                  ────────
skills/workflow/APPEND_SYSTEM.md  →   ~/.pi/agent/APPEND_SYSTEM.md  (read-only)
skills/                            →   ~/.pi/agent/skills/
```

The entire `skills/` directory is bind-mounted into the container.
This means:
- Skills are editable from either side
- Adding a skill on the host makes it available immediately on next
  container start
- The agent can browse the skills directory to discover available tools

## Why bind-mount instead of install?

Installing skills as pi packages (`pi install git:...`) is the standard
approach, but it creates a black box — the skill files live in
`~/.pi/agent/git/` or `~/.pi/agent/npm/`, outside the harness project.

Bind-mounting keeps everything in one place:
- Skills are version-controlled alongside the harness
- Skills are browsable and editable on the host
- No network access needed at container startup
- The agent can modify skills if needed (and the changes persist)
