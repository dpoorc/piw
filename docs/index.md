# pi-harness documentation

A Docker-based harness for the [pi coding agent](https://pi.dev).
Designed to be lean, flexible, and composable — you carry exactly
the tooling you need and no more.

## Quick links

| If you want to… | Start here |
|-----------------|------------|
| Understand the big picture | [overview.md](overview.md) |
| Know why this exists | [philosophy.md](philosophy.md) |
| Choose or create a variant | [architecture/variants.md](architecture/variants.md) |
| Understand the skill system | [architecture/skills.md](architecture/skills.md) |
| Learn how the user likes to work | [workflow/mannerisms.md](workflow/mannerisms.md) |
| See what skills are available | [research/skills-survey.md](research/skills-survey.md) |
| See evaluated tools and future options | [research/tools-evaluation.md](research/tools-evaluation.md) |
| Read the piw CLI reference | [piw.md](piw.md) |
| Add third-party packages | [extensions.txt.md](extensions.txt.md) |
| Understand permission rules | [permissions.md](permissions.md) |
| Learn about rtk token optimization | [rtk.md](rtk.md) |
| Understand the state directory layout | [state-directory.md](state-directory.md) |

## Project layout

```
pi-harness/
├── piw                     # Entry point — build & run any variant
├── .env                    # API keys and config (gitignored)
├── .pi/                    # Runtime state: sessions, config, auth (gitignored)
├── .env.example            # Template for .env
├── variants/               # Docker image profiles
│   ├── core/               #   Minimal tooling
│   ├── devops/             #   Python + Ansible + infra tools
│   └── template/           #   Scaffold for new variants
├── skills/                 # Agent skills (bind-mounted)
│   ├── workflow/           #   Harness workflow (always loaded)
│   ├── ready/              #   Tier 1 skills, auto-discovered
│   └── index/              #   Tier 2 skills, loaded on demand
├── extensions/             # Custom TypeScript extensions (bind-mounted)
├── extensions.txt          # Third-party package manifest
├── models.json             # Provider/model configuration
└── docs/                   # Documentation
    ├── index.md            #   This file
    ├── overview.md         #   High-level architecture
    ├── philosophy.md       #   Design rationale
    ├── piw.md              #   CLI reference
    ├── extensions.txt.md   #   Package manifest format
    ├── permissions.md      #   Permission system
    ├── rtk.md              #   Token optimization
    ├── state-directory.md  #   .pi/ directory layout
    ├── architecture/       #   Architecture docs
    ├── workflow/           #   Workflow docs
    └── research/           #   Research docs

## Planned work

- Populate `skills/ready/` with Tier 1 community skills
- Test permission system in practice (verify `external_directory` doesn't
  trigger falsely on skill/config paths)
- Align template variant Dockerfile with core/devops (usermod -l pi node pattern)
- Fix yq arch detection in devops variant (hardcoded amd64)
- Add `--build-only`/`--install-only` split to `piw update`
- Add `--force` flag to `piw install-packages`
- Add `--dry-run` flag to `piw install-packages`
- Create docs: piw CLI reference, extensions.txt format, permissions, rtk, state-directory
- MCP integration (deferred)
```
