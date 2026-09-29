---
id: 12
title: Migrate base image to Debian 13 (trixie) + refresh forensics tools
status: closed
priority: high
labels:
    - kind:feature
created: "2026-09-16"
updated: "2026-09-29"
closed: "2026-09-29"
---

## Context

The apt toolset in the workstation variant was frozen at Debian 12
(bookworm, July 2023 package set):

- `p7zip-full` is a dead upstream project (16.02, 2016). A fresh 7z with
  current features (zstd, RAR4/RAR5 extraction) is required for current
  forensics work.
- binwalk 2.3.3, exiftool 12.57, sleuthkit 4.11.1, testdisk 7.1,
  mediainfo 22.12 all lag upstream by 1-3 years.

## Task

Move the base image to `node:24-trixie-slim` (Debian 13, stable since
Aug 2025) and refresh the toolset:

1. Base swap in core + template Dockerfiles (devops/workstation extend core).
2. Replace `p7zip-full` with the official 7-Zip 26.03 build (`7zz`) from
   `build/archives`, `7z` symlink for script compatibility. The official
   build extracts RAR4/RAR5; Debian's trixie `7zip` package strips unRAR
   (DFSG) and would need the non-free `7zip-rar`.
3. `vim-common` → `xxd` (own package since trixie).
4. build/README manifest row + sha256 for the 7z archive.
5. Docs: workstation README/SKILL, variants/README, architecture docs,
   root README row, docs/index.md.

## Status (2026-09-29)

Committed. The workstation image was rebuilt. Verification ran inside
the running container (Debian 13.6):

- 7-Zip 26.03 (`7zz` plus the `7z` symlink). Rar and Rar5 appear in the
  format list. Create and extract round-trip passes.
- Archive sha256 matches build/README (dc99eff5...).
- OpenJDK 25.0.4.1, exiftool 13.25, sleuthkit 4.12.1 (fls/icat/mmls),
  testdisk 7.2, binwalk 2.4.3, xxd, MediaInfoLib 25.04, ffmpeg, rizin.

## Open

- Image sizes in variants/README.md were not re-measured. The container
  has no Docker CLI.
- A real `.rar` extraction is untested. Format support is confirmed
  instead.
- aarch64: fetch `7z2603-linux-arm64.tar.xz` and adjust the COPY
  filename (consistent with the existing manifest caveat).

## Constraints

- `piw update` uses `git pull --ff-only` and aborts on uncommitted work;
  commit this in its own change.
- build/archives is gitignored; the 7z tarball is a manual download
  (build/README "When to fetch manually").
