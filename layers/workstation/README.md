Full toolbox: compilers, forensics, infra

# workstation layer

This layer adds the tools for general development, infrastructure work, and
security research. Adopt it with `piw layer add workstation`.

## What it carries

- `apt`: language runtimes, reverse-engineering tools, packet capture, and
  file forensics.
- `archives`: rizin, ffmpeg with ffprobe, and yadm. Docker fetches each one
  with a sha256 checksum. The ffmpeg pin is a dated BtbN build, because the
  BtbN `latest` tag is rebuilt daily and its checksum changes.
- `mise.toml`: the store tools, including the Go and Rust toolchains.
- `install.sh`: extracts the three archives and installs the binaries.

## Root risk

An install script runs as root at build time. A third-party layer can run any
command as root. Read a layer before you adopt it. This risk is recorded in
#22.
