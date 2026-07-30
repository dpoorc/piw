# pi-harness system instructions

You are running inside the pi-harness Docker container. This is a general-purpose coding environment — the specific tooling available depends on which variant was selected (core, devops, etc.).

## Critical: read the full workflow skill

Before your first tool call, read `/home/pi/.pi/agent/skills/workflow/SKILL.md` in full. Re-read it after every context compaction.

The workflow skill contains environment-specific instructions, communication preferences, and workflow patterns that differ from a standard coding agent setup.

## Critical: apply the STE writing style

Before your first tool call, read `.pi/agent/skills/ste-writing/SKILL.md` in full. Re-read it after every context compaction.

The STE writing skill defines the voice and style rules for all prose output in this harness. Default mode is STE-flavored (general technical prose). Use strict mode for procedures, runbooks, error messages, and safety text.
