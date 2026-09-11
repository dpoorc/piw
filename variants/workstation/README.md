# pi-harness: workstation

Full development environment for general development, devops, and
security research. Extends the core variant with multiple language
toolchains, linters, infrastructure tools, and analysis tools.

## What's inside

### Language toolchains

| Toolchain | Tools | Linters |
|-----------|-------|---------|
| C/C++ | gcc, g++, clang, make, cmake (from core) | — |
| Go | go 1.27 | go vet (built-in) |
| Rust | rustc, cargo | clippy |
| Python | python3, pip, venv | flake8, mypy, pylint |
| JavaScript/TypeScript | node, npm (from core) | typescript, eslint, prettier |
| Java | openjdk-17-jdk | — |
| Perl | perl | — |
| Shell | bash, fish | shellcheck |
| Powershell | pwsh (PS 7) | — |

### Infrastructure tools

| Tool | Purpose |
|------|---------|
| yq | YAML/JSON processor |
| opentofu | Infrastructure as Code |
| packer | Image builder |
| yadm | Dotfiles manager |
| tflint | OpenTofu/Terraform linter |
| hadolint | Dockerfile linter |

### Security and analysis tools

| Tool | Purpose | Container notes |
|------|---------|-----------------|
| nmap | Network scanning | Works within container network |
| tcpdump | Packet capture | Captures container's interfaces |
| tshark | PCAP analysis | Full file-based analysis |
| rizin | Binary analysis (radare2 fork) | Fully functional |
| binutils | Binary utilities (strings, objdump) | Fully functional |
| gdb | Debugging | Fully functional |
| hashcat | Password cracking | CPU-only (no GPU passthrough) |
| john | Password cracking | CPU-only |
| bettercap | Network attack/monitoring | HTTP/HTTPS proxy works; WiFi needs host |
| bluez | Bluetooth analysis | Tools present; hardware needs host |

Tools requiring host hardware access (WiFi interfaces, Bluetooth
dongles, SDRs) are documented but not activated in the container.
Use the host for live capture, then analyze captured files in the
container.

### Media tools

| Tool | Purpose |
|------|---------|
| ffmpeg (9.0 static) | Transcode, extract frames and audio |
| ffprobe | Media stream analysis (codec, resolution, duration) |
| mediainfo | Container and stream summary in human form |
| exiftool | Deep metadata extraction (EXIF, GPS, maker notes) |

ffmpeg and ffprobe come from the BtbN static 9.0 build. Debian
bookworm's apt ffmpeg is 5.1 (2022) and lacks current codecs.

### File forensics tools

| Tool | Purpose |
|------|---------|
| binwalk | Embedded and firmware file analysis |
| sleuthkit | Disk and filesystem forensics (fls, icat, mmls) |
| foremost | File carving from raw dumps |
| testdisk / photorec | Partition and data recovery from disk images |
| steghide | Hidden-payload analysis (steganography) |
| p7zip-full | Deep archive extraction (7z, rar, and more) |
| xxd | Hex inspection (from vim-common) |

## Size

~3-4GB (pi + Node + Debian + all toolchains + ffmpeg)

## Usage

```bash
# Build:
piw build workstation

# Launch:
piw --profile workstation /path/to/workspace

# Set as default (in .env):
PIW_DEFAULT_PROFILE=workstation
```
