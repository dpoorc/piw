# pi-harness — Docker environment for the pi coding agent

pi-harness wraps [pi](https://pi.dev) in a Docker container. It
isolates the agent from your host system while keeping the workspace
accessible through bind mounts. No dependency pollution, no host
modifications, no "works on my machine."

## Quick start

**Prerequisites:** Docker running, one API key for pi.

```bash
# Install the piw CLI
piw --install

# Launch pi in a project directory
piw ~/my-project

# Check your setup
piw doctor
```

See `.env.example` for API key setup. Copy it to `.env` and fill in
your keys before the first launch.

## CLI reference

| Command | Description |
|---------|-------------|
| `piw ~/project` | Launch pi (default: core variant, permissive mode) |
| `piw -r` | Resume a previous session |
| `piw build` | Build variant image and install packages |
| `piw doctor` | Diagnose harness setup |
| `piw install-packages` | Install packages from `extensions.txt` |
| `piw update` | Pull updates, rebuild, reinstall packages |
| `piw --mode restricted` | Launch with restricted permissions |
| `piw --profile devops` | Launch with the devops variant |

## Variants

| Variant | Tools |
|---------|-------|
| **core** | pi, git, curl, jq, openssh |
| **devops** | Core + Python + Ansible + yq |

## Documentation

Full docs are in [docs/index.md](docs/index.md). Topics include
architecture, permission modes, skill system, and rtk token
optimization.

## License

GPLv3. See [LICENSE](LICENSE).
