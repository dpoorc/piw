# Handoff — pi-harness session 2026-08-02

## Work done

### Committed (9 commits on top of previous state)

| Commit | Description |
|--------|-------------|
| `e21c4b6` | fix(models): correct Fireworks baseUrl trailing slash |
| `e3eef3f` | feat(workflow): add writing style enforcement, container boundaries, improve APPEND_SYSTEM |
| `d9e5d25` | feat(skills): add handoff processing section linking to doc-writing |
| `87a35fa` | feat(skills): add git-workflow and doc-writing skills |
| `843e705` | feat(docs): add README, GPLv3 license, and yadm-bridge proposal |
| `2208689` | feat(piw): pass git identity and config into container |
| `8eb2671` | feat(skills): add variant-specific skills with conditional mount in piw |
| `36b094a` | refactor(skills): move ste-writing and doc-writing into ready/ |
| `57a40a1` | feat: create workstation variant, update to node:24, devops FROM core |

### pi-web-access fix

- Unpinned `pi-web-access` from `@0.13.0` in `extensions.txt`
- Created `.pi/agent/web-search.json` with `autoOpenBrowser: false` + `workflow: "auto-summary"`
- User needs to run `piw install-packages --force` to upgrade

### Git identity (piw)

- `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL` passed from host git config into container
- `~/.gitconfig` and `~/.config/git/config` conditionally mounted read-only
- User's git identity: dpoorc / dpoor@tutamail.com (set in local `.git/config`)

### Default profile

- `PIW_DEFAULT_PROFILE` env var in `.env` overrides hardcoded `core` default
- `DEFAULT_PROFILE="${PIW_DEFAULT_PROFILE:-core}"` in piw

### Workflow skill enhancements

- Writing style enforcement: STE rules take priority over style matching
- Container boundaries: workspace is the only host path, system paths are container-local
- Pre-flight check: verify alignment before edit/write calls
- Surface assumptions example: conflicting data sources

### APPEND_SYSTEM.md

Rewritten: consolidated "Critical: read X" sections into compact "Required reading" format. Added container boundary awareness.

### Skill directory restructuring

- `ste-writing/` and `doc-writing/` moved from top-level into `skills/ready/`
- Path references updated in APPEND_SYSTEM.md, writing-style.md, handoff skill
- `skills/` now contains: `index/`, `ready/`, `variants/`, `workflow/`

### Variant skills

- Created `skills/variants/core/SKILL.md`, `skills/variants/devops/SKILL.md`, `skills/variants/workstation/SKILL.md`
- piw conditionally mounts the active variant's skill at `~/.pi/agent/skills/variant/`

### Workstation variant (new)

- `variants/workstation/Dockerfile` — full toolset on `FROM pi-harness:core`
- Language toolchains: Go 1.24, Rust (rustup+clippy), Python+flake8/mypy/pylint, Java 17, JS/TS (typescript/eslint/prettier), Perl, Fish, Powershell 7
- Infra tools: opentofu 1.9, packer 1.12, yq, yadm, tflint, hadolint
- Security/analysis: nmap, tshark, tcpdump, rizin, gdb, hashcat, john, binutils, bettercap, bluez, shellcheck

### All variants updated

- Core: `node:24-bookworm-slim`, added `build-essential`, `clang`, `unzip`
- Devops: now `FROM pi-harness:core`, slimmed down (inherits core tools)
- Template: `node:24-bookworm-slim` only

## WIP — ready to implement

### Matt Pocock skill library adoption

The user wants to adopt [Matt Pocock's skill library](https://github.com/mattpocock/skills) in full. Key decisions reached:

- **Catalog approach**: Create `skills/ready/skills-catalog/SKILL.md` listing all available skills. Agent reads it on startup (referenced from APPEND_SYSTEM.md).
- **Model-activated vs hidden**: Some skills should remain model-activated (agent autonomously recognizes when to use them):
  - Recommended visible: `diagnosing-bugs`, `code-review`, `research`, `grilling`
  - Rest hidden via `disable-model-invocation: true`
  - User to confirm exact selection
- **Placement**: Model-activated in `skills/ready/`, hidden in `skills/index/`
- **Not adopting**: `setup-matt-pocock-skills` (pi-specific)
- **Existing handoff skill**: Keep ours (has doc-writing integration); Matt's is shorter and hidden

Matt's skills are already cloned at `/tmp/pi-github-repos/mattpocock/skills/`.

### Skills catalog

Create `skills/ready/skills-catalog/SKILL.md` that lists all available skills (built-in + Matt's) with descriptions. Update APPEND_SYSTEM.md to reference it.

## Open decisions

| Topic | Status |
|-------|--------|
| Which Matt skills stay model-activated? | Recommended: diagnosing-bugs, code-review, research, grilling. User to confirm. |
| Keep `ask-matt`? | Personal to Matt, could serve as general router. User to decide. |
| Skill tier vocabulary cleanup in `docs/architecture/skills.md` | Needs updating to reflect current `ready/`-based reality |
| Sub-agents / time awareness | Deferred |
| proposals.md | Removed (was from different project) |

## Suggested skills for next session

- `/skill:handoff` (pi-harness built-in) — process this handoff into permanent docs
- `/skill:doc-writing` — for writing skills-catalog and architecture updates
- Matt's skills once adopted: `/skill:diagnosing-bugs`, `/skill:code-review`, `/skill:research`
