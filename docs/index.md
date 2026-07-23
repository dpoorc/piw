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
│   └── ready/              #   Community skills, auto-discovered
├── models.json             # Provider/model configuration
└── docs/                   # This directory
```
