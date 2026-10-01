# Tool manager comparison

Research for the piw wayfinder map (ticket #18). Question: which manager
installs CLI tools and language toolchains into a custom prefix, inside a
non-root container, into a persistent mounted store, with checksum
verification?

Release data read from the GitHub REST API on 2026-10-01.

## Verdict

**mise** is the only candidate that satisfies every requirement at once:
no root, a fully overridable install root, a lockfile, per-directory
pinning, toolchains as well as prebuilt binaries, and verification that is
on by default for the aqua backend and for GitHub attestations on the
github backend.

Ranking: 1. mise. 2. aqua with `require_checksum: true`. 3. hand-rolled
with pinned sums. 4. cargo-binstall (Rust only). 5. asdf. 6. Homebrew.
7. Nix. 8. ubi, eget, pkgx.

No candidate combines a small size with real verification. Choosing small
means writing the verifier ourselves.

## Maintenance

| Tool | Maintainer | Latest | Date | Stars |
|---|---|---|---|---|
| mise | jdx | v2026.9.18 | 2026-09-30 | 34.5k |
| aqua | aquaproj | v2.63.0 | 2026-09-15 | 1.9k |
| asdf | asdf-vm | v0.20.2 | 2026-09-22 | 25.6k |
| ubi | houseabsolute | v0.12.0 | 2026-08-31 | 596 |
| eget | zyedidia | v1.3.4 | 2024-06-07 | 2.1k |
| Nix | NixOS | 2.35.2 | n/a | 17.8k |
| pkgx | pkgxdev | v2.11.0 | 2026-07-22 | 9.9k |
| cargo-binstall | cargo-bins | v1.24.0 | 2026-09-26 | 2.9k |
| Homebrew | Homebrew | 7.0.7 | 2026-09-28 | 49.9k |

eget is stale by about two years.

## Verification

| Tool | What is verified, and when |
|---|---|
| mise | aqua backend: cosign, SLSA, minisign, and GitHub attestations all default `true`. github backend: GitHub attestations checked by default; checksums need an explicit value or a lockfile. `mise.lock` is opt-in at creation. |
| aqua | Checksum verification is **off by default** (`enabled: false`, `require_checksum: false`). Cosign and SLSA run by default, but only when the registry entry and the publisher both supply metadata. |
| asdf | No verification in core. Depends entirely on each plugin. |
| ubi | **No verification code exists.** Mitigation is release age only. |
| eget | Best effort, then silent. Falls through to `NoVerifier{}`, whose `Verify` returns `nil`. |
| Nix | Content-addressed store with cache signatures. `require-sigs` defaults to `true`. |
| cargo-binstall | crates.io tarball checksum always verified. Binary signatures opt-in, minisign only. |
| Homebrew | Bottles carry a SHA-256 in the formula. A mismatch does not stop the install; it forces a source build. No signature or provenance check found. |

Two mise limits matter for the docs:

- "Support in the backend does not mean that every package supplies all of
  these checks."
- A lockfile entry with a checksum and provenance is trusted without
  re-verification unless `locked_verify_provenance` is true.

## Custom install root without root

| Tool | Custom root | Root needed |
|---|---|---|
| mise | `MISE_DATA_DIR` and friends | No. "mise never elevates privileges automatically." |
| aqua | `AQUA_ROOT_DIR` | No |
| asdf | `ASDF_DATA_DIR` | No |
| ubi | `-i/--in` | No |
| eget | `EGET_BIN` | No |
| Nix | `dest="/nix"` is hardcoded | **Yes** |
| pkgx | `$PKGX_DIR` | No for download, `pkgm` needs root |
| cargo-binstall | `--install-path`, `--root` | No |
| Homebrew | `--path` at install time | Prefix must be pre-provisioned |

Nix chroot stores exist as an escape hatch, but need user and mount
namespaces, and the docs call the logical-location change "not
recommended".

## Coverage

| Tool | Toolchains | Prebuilt binaries |
|---|---|---|
| mise | Yes | Yes |
| aqua | Partial, unverified | Yes |
| asdf | Yes, via plugins, often compiling | Yes |
| ubi | No | Yes |
| eget | No | Yes |
| Nix | Yes | Yes |
| pkgx | Yes | Yes |
| cargo-binstall | Rust only | Yes |
| Homebrew | Yes | Yes |

ubi is explicit: it recommends mise for per-project tooling, and describes
itself as suited to simple global installs. eget says it is only for
"simple, static prebuilt binaries".

## Behaviour when upstream publishes no checksums

mise proceeds for the github backend unless a checksum is set or a lockfile
exists; it refuses on mismatch. aqua proceeds unless `require_checksum` is
set. asdf, ubi, and eget always proceed. Nix refuses an unsigned substitute
when `require-sigs` is true. cargo-binstall proceeds with a warning.
Homebrew silently builds from source.

## Project-local configuration

mise supports `mise.toml`, `.mise.toml`, and `.tool-versions`,
hierarchically merged from every parent directory. aqua supports
`aqua.yaml` from the current directory to the root. asdf supports
`.tool-versions`. ubi, eget, cargo-binstall, and Homebrew have no
per-directory pinning.

## Multiple data roots

mise is the only candidate with a real multi-root model: a primary
writable `MISE_DATA_DIR`, a second writable `system_installs_dir`, and
read-only `MISE_SHARED_INSTALL_DIRS`.

Constraint to record: a second *writable* root needs its own
`MISE_DATA_DIR`, and that variable is read early, so it must come from the
environment rather than a config file.

aqua, asdf, and pkgx have a single root. Nix has multiple stores via
`--store`.

## Size and complexity

mise is one large Rust binary with a broad surface: backends, tasks, env,
shims, lockfiles. aqua is one binary plus a large external registry.
asdf is a small core plus a git repository of shell code per plugin. ubi
and eget are small and single-purpose. Nix is very large. pkgx is about
4 MiB plus the pantry. Homebrew is very large.

## Sources

- https://mise.jdx.dev/dev-tools/backends/
- https://mise.jdx.dev/dev-tools/backends/aqua.html
- https://mise.jdx.dev/dev-tools/backends/github.html
- https://mise.jdx.dev/dev-tools/mise-lock.html
- https://mise.jdx.dev/security.html
- https://mise.jdx.dev/directories.html
- https://mise.jdx.dev/configuration/settings.html
- https://aquaproj.github.io/docs/reference/config/checksum
- https://aquaproj.github.io/docs/reference/security/cosign-slsa/
- https://asdf-vm.com/manage/configuration.html
- https://asdf-vm.com/manage/plugins.html
- https://github.com/houseabsolute/ubi
- https://github.com/zyedidia/eget/blob/master/DOCS.md
- https://nix.dev/manual/nix/latest/installation/installing-binary
- https://nix.dev/manual/nix/latest/store/types/local-store
- https://docs.pkgx.sh/readme.md
- https://github.com/cargo-bins/cargo-binstall
- https://docs.brew.sh/Bottles
- https://docs.brew.sh/Installation

## Gaps

- Nix 2.35.2 release date is unverified. NixOS/nix publishes tags, not
  releases.
- pkgx verification is unverified. A GPG key is published, but no document
  states what pkgx verifies or when.
- aqua toolchain coverage in the registry was not checked.
- mise behaviour with no upstream checksum on a non-aqua backend is
  inferred from the documented rule that checks apply only where
  supported.
- Any claim that asdf is in maintenance mode is unverified.
- UID remapping was not tested. File-based managers are UID-agnostic when
  the mounted directory is writable. Homebrew and Nix both care about
  prefix ownership.
