# piw documentation

piw runs the [pi coding agent](https://pi.dev) in a Docker container. This
directory holds the documentation. For installation and a first run, read the
[README](../README.md).

## Quick links

| If you want to... | Read |
| ------------------- | ------ |
| Understand the model | [overview.md](overview.md) |
| Know why piw exists | [philosophy.md](philosophy.md) |
| Use the command line | [piw.md](piw.md) |
| Understand `.local/` | [state-directory.md](state-directory.md) |
| Control the agent | [permissions.md](permissions.md) |
| Learn the container strategy | [architecture/container-strategy.md](architecture/container-strategy.md) |
| Understand the skill system | [architecture/skills.md](architecture/skills.md) |
| See what is planned | [../roadmap.md](../roadmap.md) |
| Read the glossary | [../CONTEXT.md](../CONTEXT.md) |
| Read the state-namespace decision | [adr/0001-local-state-namespace.md](adr/0001-local-state-namespace.md) |

## Project layout

```
piw/
├── piw                     # the command-line tool
├── Dockerfile              # the default image
├── .env.example            # the secrets template
├── seed/                   # files piw seeds into .local/
│   ├── piw.conf            #   the layer manifest
│   ├── mise/config.toml    #   the store tool manifest
│   ├── permissions/        #   the permission modes
│   ├── models.json         #   provider and model configuration
│   └── settings.json       #   pi settings
├── layers/                 # shipped layers
│   └── workstation/        #   the workstation layer
├── skills/                 # agent skills
│   ├── system/             #   harness skills
│   ├── vendor/             #   external collections
│   ├── catalog.md          #   the hidden-skill index
│   └── generate-catalog.sh #   the catalog generator
├── agents/                 # sub-agent definitions
├── tests/                  # the hermetic test suite
│   ├── run.sh
│   └── stub-docker
├── docs/                   # this documentation
└── .local/                 # local state (gitignored)
```

## Reading order

A newcomer can read these in order:

1. [../README.md](../README.md) - install and first run.
2. [overview.md](overview.md) - the model.
3. [piw.md](piw.md) - the command set.
4. [state-directory.md](state-directory.md) - where state lives.

The rest is reference.
