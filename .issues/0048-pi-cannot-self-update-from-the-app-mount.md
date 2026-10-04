---
id: 48
title: pi cannot self-update from the app mount
status: open
priority: high
labels:
    - kind:bug
    - state:ready-for-human
relations:
    related-to:
        - 27
created: "2026-10-04"
updated: "2026-10-04"
---

Found while diagnosing the laptop.

`pi update` refuses with:

    error: pi cannot self-update this installation.
    This installation is not managed by a global npm install. Update it with
    the package manager, wrapper, or source checkout that provides it.

    Location of pi executable: /opt/pi/node_modules/.bin/pi

## Root cause

pi decides whether it can self-update in `getSelfUpdateCommand`
(`dist/config.js`). It needs `isManagedByGlobalPackageManager`, which compares
the package directory against the global package roots. For an npm install,
`getGlobalPackageRoots` uses `npm root -g` and `getInferredNpmInstall`. The
latter recognizes a prefix only when the package sits at
`<prefix>/lib/node_modules/<pkg>`: it returns the prefix only when the parent of
`node_modules` is named `lib`.

`ensure_pi` runs:

    npm install --prefix /opt/pi @earendil-works/pi-coding-agent@<version>

That puts pi at `/opt/pi/node_modules/@earendil-works/pi-coding-agent`. The
parent of `node_modules` is `/opt/pi`, not `lib`. So pi cannot infer a global
prefix and refuses to update. The message is correct for this shape.

The defect also breaks the decision in #27: `piw update` runs `pi update --all`
and expects pi to own its own updates. pi cannot, in this install shape.

## Fix direction

Install pi as a global install under the same mount:

    npm install -g --prefix /opt/pi @earendil-works/pi-coding-agent@<version>

Then pi sits at `/opt/pi/lib/node_modules/...`, infers the prefix `/opt/pi`,
and its self-update command becomes `npm install -g --prefix /opt/pi ...`, which
writes back into the mount. Do not set `npm_config_prefix`: pi adds the
`--prefix` itself from the inferred shape.

Knock-on changes:

- `Dockerfile`: the runtime `PATH` gains `/opt/pi/bin` in place of
  `/opt/pi/node_modules/.bin`.
- `ensure_pi`: install with `-g`, clear `lib/node_modules` and `bin`, and verify
  `/opt/pi/bin/pi`.
- `_pi_installed_version`: read the version from
  `.../lib/node_modules/@earendil-works/pi-coding-agent/package.json`.
- The mount stays `.local/app` -> `/opt/pi`; the on-disk layout gains `lib/` and
  `bin/`.

## Do not implement yet

Hold this change. pi 1.0.2 breaks the Fireworks AI provider on the desktop: it
returns 401 "the API key you provided is invalid" for every key. An upgrade
triggered by this fix could remove a working provider. Wait until upstream
fixes the 1.0.2 provider defect, then land this.

## Acceptance

- After the fix, `pi update` in the container recognizes the installation as a
  global npm install and reports a self-update command that targets `/opt/pi`.
- A test pins the install path (`lib/node_modules`) and the image `PATH`.
