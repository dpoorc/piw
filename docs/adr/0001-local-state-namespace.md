# Local state lives in one ignored namespace

## Status

accepted

## Context

The repository mixed upstream content with user-owned state. `.pi/` held
pi's agent directory, pi's program install, and piw's tool store.
`extensions/` held user-owned permission configuration. `.env` held
secrets. Tracked and untracked paths were interleaved, so the boundary was
invisible from the repository root.

`.pi/` is pi's namespace. pi scans `<workspace>/.pi/` for project
configuration. piw's store inside that directory caused a real defect: pi
reported the store as a deprecated project tools directory.

## Decision

All user-owned paths move into one gitignored namespace, `.local/`, and
`.pi/` is removed from the harness root. piw sets the agent directory
explicitly, so pi does not need `.pi/`.

```
.local/
├── .env          secrets
├── config/       piw's user configuration: manifest and layers
├── extensions/   pi's global extensions, user-owned
├── agent/        pi's agent directory
├── app/          pi's program install
└── store/        the tool store
```

## Consequences

- The public/private split is visible from the root: one ignored entry.
- pi never reads harness state as project configuration.
- `.local/` sits inside the workspace when the harness is self-hosted, so
  the agent can read it. Deny rules are required for the secrets and for
  pi's `auth.json`.
- The secrets file is `.local/.env`. Its basename stays `.env`, so the
  existing permission deny rules keep matching. No rule change is needed
  for it.
- Generated artifacts in tracked directories stay where they are. They are
  generated, not user-owned, and `build/archives/` must remain in the
  Docker build context.

## Considered options

- **Keep `.pi/` for pi and add a separate piw directory.** Rejected: two
  namespaces, and the split stays invisible from the root.
- **Name the namespace `.piw/`.** Rejected: accurate, but it puts a second
  dotted directory beside the one being deleted. `.local/` reads better
  against the store mount.
- **Ignore only part of the namespace.** Rejected: leaves untracked noise
  in `git status`.
- **Move the generated artifacts into the namespace too.** Rejected:
  Docker cannot copy from outside the build context.

## Amendment: flattened layout (2026-10-03)

#24 revised the layout before implementation. The `config/` directory and
the top-level `extensions/` directory are gone. `piw.conf` and `mise/` sit
directly under `.local/`. The permission config moved inside the agent
directory to `.local/agent/extensions/pi-permission-system/`, because
extension state belongs to pi. The amendment adds `.local/agents/skills/`
for the Agent Skills convention.

```
.local/
├── agent/          pi's agent directory, including extensions/
├── agents/skills/  the Agent Skills convention
├── app/            pi's program install
├── layers/         user layers, the build context
├── mise/           the mise config and lockfile
├── store/          the tool store
├── env             secrets
└── piw.conf        the layer manifest
```

The names `.local/agent` and `.local/agents` differ by one character and
hold different things. `.local/agent` is pi's namespace.
`.local/agents/skills` is the cross-tool Agent Skills convention.

The amendment has these consequences:

- The `.local/extensions/` directory is removed. Extension state lives
  inside the agent directory, which pi writes.
- The secrets file stays at `.local/.env`. Its basename keeps the existing
  deny rules matching.
- Only the ignored namespace changes shape. The tracked seed tree keeps
  its role.
