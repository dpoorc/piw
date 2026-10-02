---
id: 32
title: Migrate paths into the .local namespace
status: open
priority: high
labels:
    - wayfinder:task
relations:
    depends-on:
        - 20
        - 21
        - 22
        - 24
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-02"
---

Apply the decisions in #20, #21, #22, and #24 across the tree.

## Work

**Paths**

- Delete `.pi/` from the harness root. Move `agent`, `app`, and `store` under
  `.local/`.
- Move `extensions/` to `.local/agent/extensions/`, with the permission
  config at `.local/agent/extensions/pi-permission-system/config.json`.
- Move `.env` to `.local/env`. The basename changes, so the deny rules need
  updating. See #33.
- Move `mise.toml` to `.local/mise/config.toml`, and add
  `.local/mise/mise.lock`.
- Add `.local/agents/skills/` for the Agent Skills convention.
- Rename `config-seeds/` to `seed/`.

**piw**

- Update the 26 references to `.pi/`, the three resolvers, and every mount.
- Apply the mount map from #24. Skills, agents, and `APPEND_SYSTEM.md` become
  read-only.
- Add the mounts for `.local/mise` and `.local/agents/skills`.
- Replace the API key allowlist and the host-side `.env` sourcing with
  `--env-file .local/env`. Move `PI_CONFIG_DIR` and `PI_TOOLS_DIR` out of the
  env file.
- Set `MISE_DATA_DIR` and `MISE_GLOBAL_CONFIG_FILE` in the image.

**Repo hygiene**

- Update `.gitignore` and `.dockerignore`. `.dockerignore` must exclude
  `.local`.
- Update the documentation that mentions `.pi/`.
- Amend `docs/adr/0001-local-state-namespace.md` for the flattened layout and
  the removal of `.local/extensions/`.
- Add the `.local/agent` against `.local/agents` distinction to `CONTEXT.md`.
- Create the namespace with the right ownership on first run, as
  `ensure_tools_dir` does today.

## Acceptance

- `git status --porcelain` is empty after a full piw run.
- No tracked path is written after install.
- pi reports no deprecated-directory warning when the workspace is the harness
  directory.
- The agent can write `.local/agent/skills/` and `.local/agents/skills/`, and
  cannot write `<repo>/skills` or `<repo>/agents`.
- The stub-docker test asserts the full mount list from #24, and nothing else.
