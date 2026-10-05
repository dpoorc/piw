# pre-publish layer

The tools for the `pre-publication` skill: secret detection and content
PII detection.

Adopt it with `piw layer add pre-publish`.

## What it carries

- `mise.toml`: `gitleaks` for secret detection in the working tree and in
  git history.
- `apt`: `libimage-exiftool-perl` for file, document, and media metadata.
- `install.sh`: `presidio-analyzer` and the spaCy `en_core_web_sm` model,
  installed into the system Python. presidio finds the content PII that
  regex cannot, such as names and postal addresses.

## Root risk

An install script runs as root at build time. A third-party layer can run
any command as root. Read a layer before you adopt it.
