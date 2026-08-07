# Writing Style: STE (Simplified Technical English)

## Overview

This harness uses an adapted [ASD-STE100](https://asd-ste100.org) Simplified
Technical English writing style for all prose output. The goal is to eliminate
"AI slop" — verbose, generic, marker-rich prose — and produce clear, direct
technical writing.

## Source

Adapted from [woosal1337/blog](https://github.com/woosal1337/blog/tree/main/videos/ep01-the-cure-for-ai-slop)
(experimental results: 50-74% reduction in AI tells across Claude and GPT-5.5).

## Skill

**Location:** `~/.pi/agent/skills/system/ste-writing/SKILL.md` (auto-loaded via APPEND_SYSTEM.md)

**Auto-read:** The file `~/.pi/agent/APPEND_SYSTEM.md` instructs the agent to
read this skill before every tool call and after every context compaction.

## Modes

| Mode | When | Rules |
|------|------|-------|
| **STE-flavored** (default) | General prose — docs, READMEs, PR descriptions, comments | Sentence/paragraph/voice discipline, relaxed vocabulary |
| **strict** | Procedures, runbooks, safety text, error messages | Full STE ruleset including vocabulary lockdown |

## What it covers

- Documentation, READMEs, pull-request text
- Error messages, release notes, code comments
- Never code, identifiers, command syntax, or Dockerfiles

## Verification

The skill includes a self-lint checklist (8 items) that the agent runs before
returning text. This covers sentence length, semicolons, contractions, passive
voice, nominalizations, vocabulary choice, and preamble removal.
