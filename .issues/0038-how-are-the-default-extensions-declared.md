---
id: 38
title: How are the default extensions declared, seeded, and updated?
status: closed
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
closed: "2026-10-02"
---

## Question

Extensions are neither store tools nor layers. They come from pi's own package
manager, they live in the agent directory, and they are the one part of the
current setup with no ticket covering its migration.

Surfaced while resolving **Fate of piw update**. The closest ticket is
**Migration of today's variants**, but that one is scoped to the tools baked
into the core, devops, and workstation images. Extensions are not in those
images. This ticket is where the extension story gets decided.

## Answer

**Seed the declaration. pi does the rest.**

### The mechanism

`.local/agent/settings.json` carries a `packages` array. Seed it once with the
five defaults. pi installs any declared package whose install path is missing,
at startup, with no prompt and no terminal. Verified end to end: a fresh agent
directory with `packages: ["npm:pi-time-awareness"]` and nothing installed
produced `npm/node_modules/pi-time-awareness` on the first start.

The install and the resource collection happen in the same pass, so a newly
installed package's extension **loads on that same startup**:

```js
if (parsed.type === "npm") {
  let installedPath = this.getNpmInstallPath(parsed, resolvedScope);
  if (!existsSync(installedPath) || !await this.installedNpmMatchesConfiguredVersion(parsed, installedPath)) {
    if (!await installMissing()) continue;
    installedPath = this.getNpmInstallPath(parsed, resolvedScope);
  }
  metadata.baseDir = installedPath;
  this.collectPackageResources(installedPath, accumulator, filter2, metadata);
}
```

`pi list` does not install, because listing does not resolve. `PI_OFFLINE`
disables the install, which means an offline first run gets no extensions.

### What dies

- `config-seeds/extensions.txt`. Two descriptions of one list is one too many.
- `sync_extensions_for`, and its version checks.
- `_pkg_mount_dir` and `_pkg_installed_version`.
- Two of `_npm_latest_version`'s five call sites.

### Final decisions

**The `packages` array is the single source of truth.** `extensions.txt` goes.
The seed is a `settings.json` holding `enableSkillCommands` and the five
default packages.

**Seed once.** #24's rule stands: harness-owned files mount, user-owned files
seed once. `settings.json` is user-owned, so piw writes it only when it is
absent.

**Drift is reported by `doctor` and by `piw update`.** `doctor` already reports
it as a diff rather than a failure. `update` reports it too, because the user
who needs to see a newly added default is the established user, and they are the
one running `update`. A diff, not a failure: the file is theirs.

**The permission-config seeding stays, unchanged.** The permission system's
policy is harness content that must land at
`<agent-dir>/extensions/pi-permission-system/config.json`, per #24. It is not a
package declaration and it does not share a mechanism with one.

**The first-launch install cost is accepted.** Five packages, a handful of
seconds, once. It is pi's own work rather than piw's, and `piw update` will
reconcile them afterwards through `pi update --all`.

### Findings

1. **pi installs declared-but-missing packages at startup**, and collects their
   resources in the same pass.
2. **`pi list` does not install.** Listing does not resolve.
3. **`PI_OFFLINE` disables the install**, so an offline first run gets no
   extensions.
4. **`config-seeds/settings.json` and `extensions.txt` describe the same five
   packages**, and neither knows about the other.

### Not verified

- A `git:` source. All five defaults are `npm:`, so this does not bite today.
- Whether the container's `npm_config_ignore_scripts=true` disturbs any of the
  five.
- Whether the install finishes before the first model turn in a real container
  launch, as opposed to a non-interactive test.

All three belong to implementation rather than to this decision.

## Consequences

- **#35 shrinks to a single call site.** After this ticket, **CLI surface**, and
  **Fate of piw update**, the only host-side npm call left is `ensure_pi`
  installing a missing pi.
- **#27 gains a drift report.** Its three steps become four.
- **#30 must document two things**: the drift behaviour, and the first-launch
  install cost, so that a slow first start is explained rather than mysterious.
