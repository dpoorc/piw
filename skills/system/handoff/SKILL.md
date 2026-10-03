---
name: handoff
description: >
  Request and receive handoffs for piw sessions. Use when
  transitioning between sessions, collecting context before
  compaction, or delegating work via pi-intercom. A handoff
  transfers findings, WIP, and roadmap context.
argument-hint: "What will the next session be used for?"
---

# handoff Skill

## What is a handoff

A handoff is a structured summary of session context. It lets a new
session continue work without restarting from scratch. The handoff
captures what was done, what was found, and what should happen next.

A handoff is not a permanent record. After the receiving session
processes its findings into the project documentation, the handoff
document is deleted.

## When to request a handoff

- Session is about to end or restart
- Context compaction is about to happen and you want to preserve
  context before starting fresh
- Context is growing rapidly; request a handoff to capture findings
  then continue in a new session or after manual compaction
- Another session asks you to share your findings via intercom
- A task crosses session boundaries
- You are about to hand work to a different pi session
- The user asks you to write a handoff

## When NOT to request a handoff

- The task fits in one session with room to spare
- The conversation is short and context is still fresh
- No new findings or decisions need to be preserved
- The work was exploratory with no actionable outcome

## Producing a handoff from current context

This is the primary path. Use it when the session needs to capture
its state before compaction, session end, or transfer.

1. Review what was done in this session: files changed, commands run,
   decisions made, findings uncovered.
2. Write the handoff document using the format below. Save to the
   project root as `piw-handoff-YYYY-MM-DD.md`.
3. Check for sensitive information (API keys, credentials, personal
   data). If the handoff will be committed to version control
   (cross-machine transfer), redact or exclude sensitive content.
   If it stays local (temp file, new session on same machine), flag
   any sensitive content so the receiving agent knows.
4. Reference existing artifacts (specs, plans, ADRs, commits, issues)
   by path or URL instead of duplicating their content.
5. Include a "Suggested skills" section listing skills the receiving
   session should load. Mention session-specific skills used during
   this session (e.g., code-review, domain-modeling, diagnosing-bugs).
   Boilerplate harness skills (workflow, ste-writing, piw-handoff)
   can be omitted — they are always available.
6. Process permanent findings into the project documentation after
   the handoff is complete. See the doc-writing skill ("Processing a
   handoff" section) for the section-to-doc mapping.

## Requesting a handoff from another session via intercom

Use this path when delegating work to another running pi session.
The pi-intercom skill defines the protocol for cross-session
coordination.

The intercom workflow is different from producing from current
context:

- Send a structured ask via `intercom({ action: "ask", ... })`
- The other session responds with findings or results
- No file is written to disk
- The handoff format below applies to the message body

## Handoff format

Write the handoff using the sections below as a guide. Keep it
concise. Use tables for comparisons and lists for options.

1. **Work done** — What was worked on? File paths, commands run,
   outputs produced.
2. **Findings** — Bugs, root causes, design decisions, things
   discovered.
3. **WIP** — Uncommitted changes, partial work, what is left
   unfinished.
4. **Suggested skills** — Skills the receiving session should load.
5. **Roadmap** — What should happen next, priorities, open
   questions.
6. **Other context** — Anything else relevant.

### Storage rules

- Store handoff documents at the project root with the
  name `piw-handoff-YYYY-MM-DD.md`.
- Do not commit handoff documents unless explicitly told.
  An exception is cross-workstation transfer (moving work
  between machines), where a committed handoff acts as a
  transport mechanism. Delete it after processing.
- After processing, delete the file or move it outside
  the repository. The project's `.gitignore` should exclude the
  `piw-handoff-*.md` pattern. Escalate if this is not the case.

## After receiving a handoff

After compaction or session transfer, process the handoff into
the project's permanent documentation. This keeps findings from
being lost when the handoff is archived.

The doc-writing skill defines the procedure:

```
skills/system/doc-writing/SKILL.md -> Section 10
```

Quick reference:

| Handoff section | Goes to |
|---|---|
| Work done | `roadmap.md` -> Completed |
| Findings (root cause) | `research/YYYY-MM-DD-topic.md` |
| Findings (persistent problem) | `known-issues/issue-name.md` |
| Roadmap | `roadmap.md` -> Todo |
| Config changes | `architecture/` or `environment.md` |
| WIP | Skip (ephemeral) |
