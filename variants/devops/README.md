# piw: devops

Extends the core variant with Python tooling and infrastructure
management tools. Use this for Ansible playbooks, Terraform configs,
Kubernetes manifests, server provisioning, and deployment pipelines.

## What's inside

| Tool | Purpose |
|------|---------|
| pi | Coding agent |
| git, curl, jq, openssh-client | Core tooling (inherited) |
| python3, pip, venv | Python toolchain for scripts and modules |
| ansible | Configuration management and automation |
| yamllint | YAML linting (playbooks, manifests, CI configs) |
| yq | YAML/JSON processing (jq for YAML) |

## Size

~XXX MB (pi + Node + Debian slim + Python + Ansible + tools)

## Usage

```bash
# From the harness root:
piw --profile devops /path/to/workspace

# Build explicitly:
piw build devops

# Or build directly:
docker build -t piw:devops variants/devops
docker run --rm -it \
  --user $(id -u):$(id -g) \
  -e HOME=/home/pi \
  -e PI_CODING_AGENT_DIR=/home/pi/.pi/agent \
  -v .pi/agent:/home/pi/.pi/agent:z \
  -v /path/to/workspace:/path/to/workspace:z \
  -w /path/to/workspace \
  piw:devops
```
