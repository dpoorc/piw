# Skills architecture

Skills follow the [Agent Skills standard](https://agentskills.io). A skill is
a Markdown file with YAML frontmatter, loaded by pi from
`~/.pi/agent/skills/`.

## Organization

Skills are organized by provenance. Two source directories exist:

- `skills/system/` - the harness skills. Maintained as part of piw.
- `skills/vendor/` - external collections, added as git submodules. Each
  vendor has a subdirectory with its own bucket structure, for example
  `mattpocock/engineering/`.

Sub-agent definitions live in `agents/`. They are not skills. They mount at
`~/.pi/agent/agents/`, and the agent reads them as sub-agent roles.

## Visibility

Pi uses the `disable-model-invocation` frontmatter flag to control whether a
skill appears in the system prompt:

- The flag is `false` or absent: the agent sees the skill name and description
  in the system prompt, and can read the skill without a direct request.
- The flag is `true`: the skill is hidden from the system prompt. The agent
  loads it with `/skill:<name>` or on an explicit user request.

The flag controls visibility only. A system skill can set the flag; a vendor
skill can leave it unset. The flag is set per skill in the `SKILL.md`
frontmatter.

## The always-loaded skill

`skills/system/workflow/APPEND_SYSTEM.md` mounts separately at
`~/.pi/agent/APPEND_SYSTEM.md`. It is always present in the system prompt. It
is short, and it tells the agent to read the full workflow and STE-writing
skills before acting.

The full workflow skill is a normal skill at
`skills/system/workflow/SKILL.md`. The agent reads it on startup and keeps it
in context.

## The catalog

`skills/catalog.md` lists every skill that the system prompt hides. The agent
reads this file to discover a hidden skill. The catalog holds each skill's
name, description, and path.

`skills/generate-catalog.sh` builds the catalog from the `SKILL.md`
frontmatter. It scans `skills/system/` and `skills/vendor/`, keeps the skills
marked `disable-model-invocation: true`, and reads the frontmatter with `yq`.
A hidden skill with a missing or unreadable description is an error that names
the skill. The output is sorted, so two runs are byte-identical.

Regenerate the catalog with:

```bash
piw generate-catalog
```

The command runs automatically at the end of `build` and `update`.

## The mounts

```
Host                                         Container
────                                         ─────────
skills/                                      ~/.pi/agent/skills/          (ro)
agents/                                      ~/.pi/agent/agents/          (ro)
skills/system/workflow/APPEND_SYSTEM.md      ~/.pi/agent/APPEND_SYSTEM.md (ro)
```

The `skills/` directory mounts as a whole, read-only. The agent reads the
skills, and the host owns them. The `agents/` directory mounts the same way.

Because the mounts are read-only, the agent cannot change a skill. A change
happens on the host, and the next container start picks it up.

## Adding a skill collection

To add an external collection:

1. `git submodule add <url> skills/vendor/<name>`
2. (Optional) Create `skills/vendor/<name>/.promoted-buckets` to select the
   directories that appear in the catalog.
3. `piw generate-catalog`
4. Commit the submodule and the catalog.

The catalog script scans each vendor's `skills/` subdirectory, respects the
`.promoted-buckets` file, and writes the unified index.

## Why bind-mount instead of install?

Installing skills as pi packages is the standard approach. It puts the skill
files in a package directory, outside the harness project.

Bind-mounting keeps the skills in one place:

- The skills are version-controlled with the harness.
- The skills are browsable and editable on the host.
- No network access is needed at container start.
- The read-only mount keeps the agent from changing them.
