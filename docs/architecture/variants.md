# Variants architecture

A variant is a Docker image profile — a self-contained environment
with a specific tool set. Variants live in `variants/<name>/`, each
with its own `Dockerfile` and `README.md`.

## Why dedicated directories instead of a multi-stage Dockerfile?

Dedicated variant directories scale without architectural regret:

- **Self-documenting** — Every variant's Dockerfile, README, and any
  variant-specific files live together. You can understand a variant
  without reading any other directory.
- **No merge conflicts** — Adding a new variant never touches an
  existing file (except `variants/README.md`).
- **Variant-specific extras** — If a variant needs custom configs,
  scripts, or even its own skills, there's a natural place for them.
- **Community-friendly** — A new variant is one directory with a
  clear interface (`Dockerfile` + `README.md`).

The tradeoff is minor duplication between Dockerfiles. This is managed
by keeping each variant on the same base image (`node:24-trixie-slim`)
so Docker's layer cache handles the shared layers efficiently.

## Structure

```
variants/
├── README.md             # Overview + how to create variants
├── template/             # Scaffold for new variants
│   ├── Dockerfile
│   └── README.md
├── core/                 # Minimal: pi + git + curl + jq + SSH
│   ├── Dockerfile
│   └── README.md
├── devops/               # Core + Python + Ansible + yq + yamllint
│   ├── Dockerfile
│   └── README.md
└── workstation/          # Core + toolchains + security/forensics
    ├── Dockerfile
    └── README.md
```

## How variants are selected

`piw --profile <name>` picks `variants/<name>/Dockerfile` and
tags the image as `piw:<name>`. If the image isn't cached,
it's built automatically.

## Creating a new variant

```bash
cp -r variants/template variants/my-variant
# Edit variants/my-variant/Dockerfile
# Edit variants/my-variant/README.md
piw build my-variant
piw --profile my-variant
```

See the [template README](../../variants/template/README.md) for
guidelines. Build all variants with `piw build <name>`.
