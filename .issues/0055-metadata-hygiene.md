---
id: 55
title: Metadata hygiene
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 60
    depends-on:
        - 51
        - 52
created: "2026-09-29"
updated: "2026-09-29"
closed: "2026-09-29"
---

## Question

Which metadata leaks, and how does the skill find and remove it?
Cover file metadata (EXIF, document author fields, PDF properties),
repository metadata, and commit identity.

## Answer

### Scope split with #58

`#55` owns metadata: file, document, and media metadata; repository
metadata; and commit identity.

`#58` owns content-level hygiene: strays, TODOs, absolute paths in
source, large binaries, and `.gitignore` gaps. `#58` also owns file
content as it appears in git history. `#55` owns commit metadata and
identity, not the file contents a commit carries.

Absolute paths baked into binaries go to `#58` as a content check.

### Detection

- `exiftool` as the primary reader for media, Office documents, and
  PDFs.
- Fallbacks: unzip `docProps/core.xml` for OOXML, raw grep for PDF
  `/Author`, and `file` for the rest.
- Git metadata from git itself: `git log --format`,
  `git config --list --show-origin`, `git remote -v`,
  `git notes list`, `git tag -n`.

### Removal policy

Select by default. Remove identity and location tags: `Artist`,
`OwnerName`, `SerialNumber`, `GPS*`, `Make`, `Model`, `Software`,
`creator`, `lastModifiedBy`, `Company`, `Manager`, and XMP and IPTC
identity fields.

Keep functional tags: `Orientation`, color profile, dimensions.

`exiftool -all=` is an option, with the warning that it drops
functional tags too, notably `Orientation`, which can rotate images.

Copyright and licensor fields belong to `#59`, not here.

### Destructive gate

In-place metadata edits cannot be undone, so they are destructive
under the `#53` gate. Prefer an out-of-place write (`-o`) and compare,
or rely on a tracked original. Require the backup otherwise. Re-read
the file after the edit to confirm the tag is gone.

### Commit identity

Three options, presented together, none automatic:

1. Set `user.name` and `user.email` to a project identity for future
   commits.
2. Rewrite past identity with `git-filter-repo` and a mailmap, under
   the `#54` gate.
3. Add `.mailmap` only for display remapping. It removes nothing.

### Repository metadata checklist

- Remotes, especially credentials embedded in URLs such as
  `https://user:token@host`. Highest-value item.
- `git config` - identity, credential helpers, custom keys holding
  local paths.
- Annotated tag messages - author and date.
- Git notes.
- Stash entries.
- Submodule URLs and `.gitmodules`.
- Git hooks - may hold paths or credentials.
- `.git/description` and the reflog.
