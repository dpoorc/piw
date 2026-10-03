# Design Review

Observations from working inside the piw across multiple
sessions. This is a retrospective — what works well and where the
design shows strain.

## Strengths

**Clean architecture.** Each piece has a clear job: variants define
environments, skills define behavior, piw orchestrates, the permission
system gates access. No scope creep between layers.

**Transparent over magical.** piw is a single bash script you can read
end-to-end. Skills are Markdown files you can edit on the host. The
Dockerfiles are plain and self-contained. Nothing is generated,
compiled, or obscured.

**Security posture ahead of most personal dev tools.** SELinux `:z`
mount flags, no Docker socket exposed, no mid-session package
installs, granular permission configs with three modes, .env secrets
blocked by default-deny rules. This is production-grade thinking in
a local dev tool.

**Alignment-before-action culture.** The workflow skill enforces
propose-before-implement. Unusual for a coding agent harness. Increases
up-front thinking time but reduces rework.

**Thorough documentation.** 13 doc files covering architecture, design
rationale, workflow, research. Internally consistent. Answers found
without guessing.

**Lean default, extensible by design.** Core variant ships five CLI
tools. No bloat. Need more? Pick a different variant or create one.

## Weaknesses

**piw is growing beyond bash's comfort zone.** At 800+ lines and adding
features (--mode, --all, --force, --dry-run), bash becomes brittle.
String handling, argument parsing, error recovery, and array
manipulation are all footgun territory. Error handling is inconsistent
(some paths use `set -euo pipefail`, others don't).

**No tests, no CI.** Fine for a personal project. Blocks external
contributions. Even JSON schema validation of config files would
catch a class of bugs.

**Self-hosting is elegant but confusing.** The workspace is the harness
itself. Changes to piw happen from inside piw. For the
creator this is natural. For a newcomer: "Do I clone this into itself?
Do I need the harness to build the harness?"

**Some design decisions are implicit.** Why `file` and `tree` but not
`htop`? Why `rsync` approved but `eza` left out? The decisions are
sensible but undocumented. Writing down the criteria (size, utility
in a headless container, replaceability by agent tools) would help
others extend without guessing.

**Permission configs have partial redundancy.** Three mode files
(permissive, restricted, readonly) share common rules. Changes to
one often need backports to the others. A composable approach
(base config + mode overrides) would reduce duplication but adds
complexity.
