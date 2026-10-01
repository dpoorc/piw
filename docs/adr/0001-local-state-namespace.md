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
- The secrets file is `.local/env`. The permission rules match the basename
  `.env`, so they must be updated to match the new name.
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
