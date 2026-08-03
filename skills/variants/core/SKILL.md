---
name: variant
description: >
  Core variant — minimal tooling for general coding. pi, git, curl,
  jq, openssh-client. No language-specific toolchains.
---

# Core variant

The core variant has pi and the essential CLI tools. Use it for
general coding work that does not need language toolchains or
infrastructure tooling.

## Installed tools

| Tool | Purpose |
|------|---------|
| pi | Coding agent |
| git | Version control |
| curl | HTTP requests |
| jq | JSON processing |
| openssh-client | SSH key management, git over SSH |

## Discovering more tools

To check if a tool is available:

- `which <tool>` — find the tool on PATH
- `command -v <tool>` — same, more portable
- `dpkg -l` — list all installed apt packages
- `<tool> --version` — check availability and version
