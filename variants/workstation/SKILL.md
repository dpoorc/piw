---
name: variant
description: >
  Workstation variant — full development environment with Go, Rust,
  Python, Java, JS/TS, C/C++, infrastructure tools (opentofu, packer,
  yq), and security analysis tools (nmap, tshark, radare2, bettercap).
---

# Workstation variant

The workstation variant extends core with multiple language
toolchains, linters, infrastructure tools, and security analysis
tools. Use it for general development, devops, and security research.

## Installed tools

### Language toolchains

| Toolchain | Compiler / Runtime | Linter / Analyzer |
|-----------|-------------------|-------------------|
| C/C++ | gcc, g++, clang, make, cmake | (core provides) |
| Go | go 1.27 | go vet |
| Rust | rustc, cargo | clippy |
| Python | python3, pip | flake8, mypy, pylint |
| JavaScript/TS | node, npm | typescript, eslint, prettier |
| Java | openjdk-17-jdk | (javac) |
| Shell | bash, fish | shellcheck |
| Powershell | pwsh (PS 7) | — |

### Infrastructure tools

opentofu, packer, yq, yadm, tflint, hadolint

### Security and analysis tools

nmap, tcpdump, tshark, rizin, binutils, gdb, hashcat, john,
bettercap, bluez

### Media tools

ffmpeg (9.0 static), ffprobe, mediainfo, exiftool

### File forensics tools

binwalk, sleuthkit, foremost, steghide, testdisk (incl. photorec),
p7zip-full, xxd

## Discovering more tools

To check if a specific tool is available:

- `which <tool>` — find the tool on PATH
- `command -v <tool>` — same, more portable
- `dpkg -l` — list all installed apt packages
- `<tool> --version` — check availability and version

## Hardware-dependent tools

Some tools in this variant need host hardware access (WiFi
interfaces, Bluetooth dongles, SDRs). The tools are installed
for file-based analysis, but live capture requires the host:

| Tool | Works in container | Needs host for |
|------|-------------------|----------------|
| bettercap | HTTP/HTTPS proxy, ARP spoofing | WiFi deauth, packet injection |
| bluez tools | File-based BLE analysis | Live BLE scanning |
| nmap | Container network scanning | Host network scanning |
| tcpdump | Container interface capture | Host interface capture |

For host-level operations, run the tool on the host and copy
captured data into the workspace for analysis inside the container.
