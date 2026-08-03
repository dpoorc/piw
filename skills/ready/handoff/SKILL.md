---
name: handoff
description: >
  Request and receive handoffs from other pi sessions. Use when
  transitioning between sessions, collecting context, or delegating
  work. A handoff transfers findings, WIP, and roadmap context.
---

# Handoff Skill

## When to request a handoff

- Session is about to end or restart
- Context compaction is about to happen and you want to preserve
  context before starting fresh
- Context is growing rapidly; request a handoff to capture findings
  then continue in a new session or after manual compaction
- Another session asks you to share your findings
- A task crosses session boundaries

## Compaction workflow

When agent context is growing rapidly (long conversation, many tool
calls), request a handoff from the current session before compaction:

1. Request a handoff from the current working session
2. The session responds with structured context (findings, WIP,
   open questions)
3. Preserve the handoff response for reference after compaction
4. After compaction or in a new session, use the handoff to
   re-establish context quickly
5. Process permanent findings into the project documentation.
   See the doc-writing skill ("Processing a handoff" section) for
   the section-to-doc mapping.

## Handoff template

When requesting a handoff from another session, ask for:

1. **Work done** — What did the session work on?
2. **Findings** — Bugs, issues, and design decisions discovered
3. **WIP** — Uncommitted changes or partial work
4. **Roadmap suggestions** — What should happen next?
5. **Other context** — Anything else relevant

## Handoff response format

Respond with structured sections matching the request. Keep it
concise. Use tables for comparisons and lists for options.

## After receiving a handoff

After compaction or session transfer, process the handoff into
the project's permanent documentation. This keeps findings from
being lost when the handoff is archived.

The doc-writing skill defines the procedure:

```
skills/ready/doc-writing/SKILL.md -> Section 10
```

Quick reference:

| Handoff section | Goes to |
|---|---|
| Work done | `roadmap.md` -> Completed |
| Findings (root cause) | `research/YYYY-MM-DD-topic.md` |
| Findings (persistent problem) | `known-issues/issue-name.md` |
| Roadmap suggestions | `roadmap.md` -> Todo |
| Config changes | `architecture/` or `environment.md` |
| WIP | Skip (ephemeral) |
