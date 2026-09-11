---
id: 11
title: 'Re-apply workstation media/forensics tooling from stash@{0}'
status: done
priority: high
labels:
    - kind:feature
    - state:resolved
relations: []
created: "2026-09-11"
updated: "2026-09-11"
---

## Context

`git stash` list contains `stash@{0}` ("piw update auto-stash") — created
by the old auto-stash code path that `update` no longer uses. It holds the
**only surviving copy** of a prior session's uncommitted workstation work:

- `variants/workstation/Dockerfile`: ffmpeg (BtbN static 9.0) plus
  mediainfo, exiftool, binwalk, sleuthkit, foremost, steghide, testdisk,
  p7zip, xxd layers (+37 lines)
- `variants/workstation/README.md`, `variants/workstation/SKILL.md`
- `variants/README.md`, core/devops READMEs, `docs/architecture/variants.md`,
  `docs/index.md`, `roadmap.md`, root `README.md`

The current tree's workstation Dockerfile no longer contains the
media/forensics layers (they were dropped when the archives refactor
rewrote the file). The stash is the only copy.

## Task

Re-apply the media/forensics work **adapted to the archives model**:

1. Add a `build/archives/` entry for ffmpeg static (~150 MB, gitignored —
   consistent with the other archives)
2. Wire it into `_profile_archives` + `_archive_url` + manifest/checksum rows
3. `COPY` from `build/archives` instead of curl in the Dockerfile
4. Restore the README/SKILL/docs changes (verify against the current tree
   first — they may already be partially applied)

## Resolution (2026-09-11)

- ffmpeg n9.0 gpl archive downloaded, sha256-verified
  (16e4a4a1…d329395), tar extraction verified locally, wired into
  `_profile_archives`/`_archive_url`/build README manifest + checksums
- Media/forensics apt layer (10 packages) added to workstation Dockerfile
- Docs restored, adapted: workstation README/SKILL (go 1.27), variants
  README sizes + workstation row, root README, architecture/variants.md
  (node:24), docs/index.md, roadmap Completed entry
- The stash's pre-refactor doc content (rtk, install-packages, root
  extensions.txt) was **not** restored — those were superseded by the
  refactor.

## Constraints

- The stash is now redundant: this commit carries the work. `stash@{0}`
  may be dropped once this commit is verified (verified = workstation
  image builds with media tools available).
- `piw update` uses `git pull --ff-only` and will abort if uncommitted work
  overlaps; commit this in its own change.
