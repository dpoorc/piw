# pi-harness: core

The minimal coding agent variant. Includes pi and the bare essentials
(git, curl, jq, openssh-client). Use this for general coding work where
you don't need language-specific toolchains or devops tooling.

## What's inside

| Tool | Purpose |
|------|---------|
| pi | Coding agent (interactive, print, JSON, RPC modes) |
| git | Version control |
| curl | HTTP requests |
| jq | JSON processing |
| openssh-client | SSH key management, git over SSH |

## Size

~XXX MB (pi + Node + Debian slim + tools)

## Usage

```bash
# From the harness root:
piw core /path/to/workspace
# or simply:
piw /path/to/workspace          # core is the default

# Build explicitly:
piw build core

# Or build directly:
docker build -t pi-harness:core variants/core
docker run --rm -it \
  --user $(id -u):$(id -g) \
  -e HOME=/home/pi \
  -e PI_CODING_AGENT_DIR=/home/pi/.pi/agent \
  -v .pi/agent:/home/pi/.pi/agent:z \
  -v /path/to/workspace:/path/to/workspace:z \
  -w /path/to/workspace \
  pi-harness:core
```
