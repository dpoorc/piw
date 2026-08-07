# Skills architecture

Skills follow the [Agent Skills standard](https://agentskills.io).
They are Markdown files with YAML frontmatter, loaded by pi from
`~/.pi/agent/skills/`.

## Organization model

Skills are organized by provenance, not by a
discovery-tier system. Two source directories exist:

- `skills/system/` — Built-in harness skills. Maintained as part of
  the piw project.
- `skills/vendor/` — External collections, added as git submodules.
  Each vendor has a subdirectory with its own bucket structure
  (e.g., `mattpocock/engineering/`, `mattpocock/productivity/`).

A variant-specific skill is mounted from the variant's own directory:

- `variants/<profile>/SKILL.md` → `skills/variant/SKILL.md`

The variant skill documents the toolset available in the container.
It is not part of the system or vendor collections.

## Visibility

Pi uses the `disable-model-invocation` frontmatter flag to control
whether a skill appears in the system prompt XML. This flag is the
only mechanism that controls visibility:

- Flag is `false` or absent — the agent sees the skill name and
  description in the system prompt XML. The agent can read the
  skill without a direct user request.
- Flag is `true` — the skill is hidden from the system prompt.
  The agent can only load it via `/skill:<name>` or an explicit
  user request.

The flag controls **visibility**, not theme or quality. A system
skill can have the flag set; a vendor skill can have it unset.
The flag is set per-skill in the SKILL.md frontmatter.

## Always-loaded skill (APPEND_SYSTEM.md)

The file `skills/system/workflow/APPEND_SYSTEM.md` is mounted
separately as a system prompt appendage at
`~/.pi/agent/APPEND_SYSTEM.md`. It is always present in the agent's
system prompt. It is short (<10 lines) and tells the agent to read
the full workflow and STE-writing skills before acting.

The full workflow skill is at `skills/system/workflow/SKILL.md`.
It is a normal skill that pi discovers from the skills directory.
The agent reads it on startup and keeps it in context.

## Skill catalog

The file `skills/catalog.md` lists every available skill with its
name, description, invocation mode, and tracker dependency. The
agent can read this file to discover skills that are hidden from
the system prompt.

The catalog is generated from SKILL.md frontmatter by the script
`skills/generate-catalog.sh`. It is committed to the repository.

To regenerate the catalog:

```bash
piw generate-catalog
```

## How skills are mounted

```
Host                                            Container
────                                            ────────
skills/system/workflow/APPEND_SYSTEM.md      →  ~/.pi/agent/APPEND_SYSTEM.md  (ro)
skills/                                       →  ~/.pi/agent/skills/           (rw)
variants/<profile>/SKILL.md                   →  ~/.pi/agent/skills/variant/SKILL.md  (ro)
```

The `skills/` directory is bind-mounted as a whole.
The variant skill and APPEND_SYSTEM.md are separate read-only
mounts.

This means:

- Skills are editable from either side of the bind mount.
- Adding a skill on the host makes it available on next container
  start.
- The agent can browse `~/.pi/agent/skills/` to discover SKILL.md
  files that are hidden from the system prompt.
- Skills are version-controlled alongside the harness.

## How to add a new skill collection

To add skills from a new external collection:

1. `git submodule add <url> skills/vendor/<name>`
2. (optional) Create `skills/vendor/<name>/.promoted-buckets` to
   control which directories appear in the catalog.
3. `piw generate-catalog`
4. Commit the submodule and the updated catalog.

The existing vendor collection (mattpocock) follows this pattern.
The catalog script scans each vendor's `skills/` subdirectory,
respects the `.promoted-buckets` file, and writes a unified index.

## Why bind-mount instead of install?

Installing skills as pi packages (`pi install git:...`) is the
standard approach. But it creates a black box — the skill files
live in `~/.pi/agent/git/` or `~/.pi/agent/npm/`, outside the
harness project.

Bind-mounting keeps everything in one place:

- Skills are version-controlled alongside the harness.
- Skills are browsable and editable on the host.
- No network access is needed at container startup.
- The agent can modify skills if needed, and the changes persist.
