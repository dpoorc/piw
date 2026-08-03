# pi-harness: workstation

Full development environment for general development, devops, and
security research. Extends the core variant with multiple language
toolchains, linters, infrastructure tools, and analysis tools.

## What's inside

### Language toolchains

| Toolchain | Tools | Linters |
|-----------|-------|---------|
| C/C++ | gcc, g++, clang, make, cmake (from core) | — |
| Go | go 1.24 | go vet (built-in) |
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

## Size

~2-3GB (pi + Node + Debian + all toolchains)

## Usage

```bash
# Build:
piw build workstation

# Launch:
piw --profile workstation /path/to/workspace

# Set as default (in .env):
PIW_DEFAULT_PROFILE=workstation
```
