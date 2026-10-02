---
id: 38
title: How are the default extensions declared, seeded, and updated?
status: open
priority: medium
labels:
    - wayfinder:grilling
relations:
    related-to:
        - 13
        - 28
        - 35
created: "2026-10-02"
updated: "2026-10-02"
---

## Question

Extensions are neither store tools nor layers. They come from pi's own package
manager, they live in the agent directory, and they are the one part of the
current setup with no ticket covering its migration.

Surfaced while resolving **Fate of piw update**. The closest ticket is
**Migration of today's variants**, but that one is scoped to the tools baked
into the core, devops, and workstation images. Extensions are not in those
images. This ticket is where the extension story gets decided.

## Facts

1. `config-seeds/extensions.txt` lists five npm packages, one per line, in
   `pi install` syntax.
2. `sync_extensions_for` reimplements what `pi install` and
   `pi update --extensions` already do, and it queries npm on the host. That is
   the bug in #35.
3. pi declares installed packages in `settings.json` under the `packages` array,
   which accepts npm, git, and local sources.
4. `pi install` writes that declaration to `<agent-dir>/settings.json`. With
   `--local` it writes to `<workspace>/.pi/settings.json` instead.
5. `config-seeds/settings.json` currently holds only `enableSkillCommands`.
   There is no `packages` key, so the seed and `extensions.txt` are two
   descriptions of the same thing.
6. Extensions install into `<agent-dir>/npm/node_modules/`.
7. The permission system's config is seeded separately, from
   `seed/permissions/` into
   `<agent-dir>/extensions/pi-permission-system/config.json`, per #24.
8. `_npm_latest_version` has five call sites: `ensure_pi`'s install path,
   `sync_extensions_for` twice, and `cmd_doctor` twice. #26 already removes the
   doctor checks. Removing the extension sync leaves one.

## Questions

- Does `extensions.txt` survive, or does the `packages` array in
  `settings.json` become the single source of truth? Two descriptions of one
  list is one too many.
- If piw seeds the declarations, is it a one-time seed or a sync on every
  launch? #24's rule is "harness-owned files mount, user-owned files seed once",
  and `settings.json` is user-owned.
- On first launch, does piw run `pi install` for each default, or seed the
  declaration and let pi install it? The second is faster and stays offline,
  which the launch path prefers.
- Does the permission config seeding stay, and is it the same mechanism as the
  package declarations or a separate one?
- Does #35 resolve by deletion, once `sync_extensions_for` and the doctor
  version checks are gone?
- What happens to a user's own extensions when the harness's defaults change?
