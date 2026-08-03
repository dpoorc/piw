---
name: variant
description: >
  Devops variant — infrastructure tooling: Python, Ansible, yq,
  yamllint, plus core tools (git, curl, jq, openssh-client).
---

# Devops variant

The devops variant extends core with Python tooling and
infrastructure management tools. Use it for Ansible playbooks,
Terraform configs, Kubernetes manifests, server provisioning,
and deployment pipelines.

## Installed tools

Core (inherited):

| Tool | Purpose |
|------|---------|
| pi | Coding agent |
| git | Version control |
| curl | HTTP requests |
| jq | JSON processing |
| openssh-client | SSH key management, git over SSH |

Devops additions:

| Tool | Purpose |
|------|---------|
| python3, pip, venv | Python toolchain |
| ansible | Configuration management and automation |
| yamllint | YAML linting |
| yq | YAML/JSON processor |

## Discovering more tools

To check if a tool is available:

- `which <tool>` — find the tool on PATH
- `command -v <tool>` — same, more portable
- `dpkg -l` — list all installed apt packages
- `<tool> --version` — check availability and version
