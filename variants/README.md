# Variants

A variant is a Docker image profile — a pre-configured environment with
a specific set of tools and capabilities. Each variant lives in its own
directory under `variants/<name>/` and is self-contained.

## Why variants?

Not every coding session needs the same tooling. A quick TypeScript
refactor doesn't need Ansible and yamllint; a server provisioning
session does. Variants let you carry exactly what you need and no more.

## Available variants

| Variant | Description | Size (approx) |
|---------|-------------|---------------|
| [core](core/) | Minimal: pi + git, curl, jq, openssh | ~1 GB |
| [devops](devops/) | Core + Python + Ansible + yq | ~1.5 GB |
| [workstation](workstation/) | Core + toolchains + security and forensics tools | ~3-4 GB |

## Creating a new variant

Use the [template](template/) as a starting point:

```bash
cp -r variants/template variants/my-variant
# Edit both files, then:
piw build my-variant            # build the image
piw --profile my-variant        # launch it
```

### Guidelines

1. **Start from `node:24-bookworm-slim`** — this keeps all variants on the
   same base, maximizing layer cache reuse.
2. **Keep images lean** — prefer `--no-install-recommends` and clean up
   apt lists. Every MB matters when you pull on a new machine.
3. **No entrypoint scripts** — the `CMD ["pi"]` is the entrypoint.
   Runtime setup (UID remapping, mounts) is handled by `piw`.
4. **Document the toolbox** — every variant README should list what's
   installed and why. Users (and the agent) need to know what's available.
