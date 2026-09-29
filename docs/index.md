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
| See a design review of the harness | [architecture/design-review.md](architecture/design-review.md) |
| Read about publishing considerations | [publishing.md](publishing.md) |
| Understand permission rules and modes | [permissions.md](permissions.md) |
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
│   ├── workstation/        #   Full toolchains + security/forensics
│   └── template/           #   Scaffold for new variants
├── skills/                 # Agent skills (bind-mounted)
│   ├── system/             #   Built-in harness skills
│   ├── vendor/             #   External collections (git submodules)
│   └── catalog.md          #   Unified skill index
├── extensions/             # Custom TypeScript extensions (bind-mounted)
├── config-seeds/           # Repo-owned default config (seeded into .pi/agent/)
│   ├── extensions.txt      #   Third-party package manifest
│   ├── models.json         #   Provider/model configuration
│   └── settings.json       #   Pi settings seed
├── build/                  # Image build inputs
│   ├── archives/           #   Manual downloads (gitignored)
│   └── README.md           #   Archive manifest + fetch instructions
└── docs/                   # Documentation
    ├── index.md            #   This file
    ├── overview.md         #   High-level architecture
    ├── philosophy.md       #   Design rationale
    ├── piw.md              #   CLI reference
    ├── extensions.txt.md   #   Package manifest format
    ├── permissions.md      #   Permission system
    ├── state-directory.md  #   .pi/ directory layout
    ├── architecture/       #   Architecture docs
    │   └── design-review.md #     Design retrospective
    ├── workflow/           #   Workflow docs
    ├── handoffs/           #   Session handoffs (gitignored)
    ├── research/           #   Research docs (incl. a2-prototype/)
    ├── publishing.md       #   Public release considerations
    └── session-file-management.md  #   Session log proposals

## Planned work

### Done

- Template variant aligned with core/devops (usermod -l pi node pattern)
- yq arch detection in devops variant (uname -m branching instead of amd64)
- pi moved out of the image into the config mount (`piw` ensure_pi); `piw update` upgrades pi + syncs extensions version-aware; `--force`/`--dry-run` on update; stash-based update removed (ff-only pull only)
- Workstation media + forensics tooling: ffmpeg 9.0 static (archive), mediainfo, exiftool, binwalk, sleuthkit, foremost, steghide, testdisk, 7zz (7-Zip 26.03), xxd
- Doc–reality mismatches fixed: workstation in variant docs, `node:24` base, real image sizes
- `--mode` flag for permission profiles (permissive, restricted, readonly)
- Permission external_directory allow for config paths
- STE writing skill (auto-read via APPEND_SYSTEM.md)
- Handoff skill

### Next up

- Expand vendor skills with additional collections (ongoing)
- Upstream pi-web-access browser curator fix (after other non-deferred items)
- Discuss `--profile` semantics cleanup

### Deferred

- `--mode readonly` network restriction (needs reopen on demand)
- MCP integration

## Known Issues

- **pi-web-access: browser curator crash** — `web_search` tries to open a
  browser for the curator UI, which fails in the container (no browser
  installed). The error handler then crashes with `ReferenceError:
  sendCuratorFallbackUpdate is not defined`. See
  [research/known-issues.md](research/known-issues.md).
```
