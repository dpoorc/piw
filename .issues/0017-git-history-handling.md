---
id: 17
title: Git history handling
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 23
    depends-on:
        - 16
created: "2026-09-29"
updated: "2026-09-29"
closed: "2026-09-29"
---

## Question

When is git history rewrite in scope, which tools perform it, how is
a backup taken, and how does the skill hand off credential rotation?

## Answer

### Authorization and rotation

Rewrite is a user-approved option. It is never automatic, and it is
never a substitute for rotation. A secret in history is already
leaked; removing it does not revoke it. Rotate, or confirm rotation,
independently.

Commit identity rewriting and history squashing are separate optional
actions. They are never leak fixes, consistent with `#14`.

### Tool

Require `git-filter-repo`. No fallbacks. If it is absent, install it
into the container or the workspace. Upstream git recommends it, and
it is a single MIT-licensed script.

Do not use `git filter-branch` - git itself warns that it has "a glut
of gotchas generating mangled history". Do not use BFG. The skill
does not silently downgrade.

### Scope

Rewrite all local refs that contain the object - branches and tags -
by default.

Never push. A force-push is the user's action, and the skill hands it
off. Warn that forks, clones, CI artifacts, pull-request refs, and
host-side caches retain the secret. Host-side cleanup is a hand-off.

### Backup protocol

Two backups before any rewrite:

1. A backup ref, for example `refs/backup/prepublish-<date>`.
2. A `git bundle` written to `.local/prepublish/`.

Verify the bundle, then print the exact restore command. No rewrite
runs without both, even after approval.

### Rotation hand-off

The skill gives:

- the list of affected credentials;
- the provider's revocation page or location;
- the confirmation step that proves the credential is dead.

Publish stays blocked until the user confirms rotation. The skill
makes no network calls, consistent with `#19`.

### After the rewrite

Drop the unreachable objects locally:

```
git reflog expire --expire=now --all
git gc --prune=now
```

Then re-run the history scan to confirm the object is gone.

State plainly that the remote, forks, and clones still hold the
secret until each is dealt with. The rewrite is local until a
force-push happens.
