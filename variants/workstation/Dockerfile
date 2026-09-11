# pi-harness — workstation variant
#
# Full development environment: language toolchains, linters,
# infrastructure tools, and security analysis tools.
# Use this for general development, devops, and security research.
#
# Dependencies: pi-harness:core must be built first.
#   piw build core && piw build workstation
#   or: piw build --all
# Build context is the repo root (build/archives provides all downloaded
# artifacts); piw handles this automatically:
#   docker build -f variants/workstation/Dockerfile -t pi-harness:workstation .
#
FROM pi-harness:core

# ── Layer 1: Language toolchains and linters (stable apt) ─────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        perl \
        fish \
        openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# ── Layer 1: Security and analysis tools (stable apt) ────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        binutils \
        gdb \
        hashcat \
        john \
        nmap \
        shellcheck \
        tcpdump \
        tshark \
        yamllint \
        bluez \
        libpcap-dev \
        pkg-config \
        libusb-1.0-0-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Layer 2: rizin static binary (not in Debian repos) ───────────────────────
# The rizin project does not provide a Debian package via apt.
# Static binaries are published for each GitHub release.
COPY build/archives/rizin-v0.9.1-static-x86_64.tar.xz /tmp/rizin.tar.xz
RUN tar -xJf /tmp/rizin.tar.xz -C /usr/local && rm -f /tmp/rizin.tar.xz

# ── Layer 2: Powershell (MS repo, apt-based) — COMMENTED OUT ────────────────
# Microsoft's package repo was unreachable at build time (connection reset).
# Uncomment when the network issue is resolved.
#RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc \
#        | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
#    && curl -sSL "https://packages.microsoft.com/config/debian/12/prod.list" \
#        | tee /etc/apt/sources.list.d/microsoft.list \
#    && apt-get update \
#    && apt-get install -y --no-install-recommends powershell \
#    && rm -rf /var/lib/apt/lists/*

# ── Layer 3: Go toolchain ────────────────────────────────────────────────────
COPY build/archives/go1.27.1.linux-amd64.tar.gz /tmp/go.tar.gz
RUN tar -xzf /tmp/go.tar.gz -C /usr/local \
    && ln -s /usr/local/go/bin/go /usr/local/bin/go \
    && rm -f /tmp/go.tar.gz

# ── Layer 3: Rust toolchain ──────────────────────────────────────────────────
ENV CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
# Direct toolchain install from build/archives (no rustup, no network).
# GNU is the default toolchain; the musl std is added as a target for
# statically linked pure-Rust builds (rustup's `target add` equivalent).
COPY build/archives/rust-1.98.1-x86_64-unknown-linux-gnu.tar.xz /tmp/rust-gnu.tar.xz
COPY build/archives/rust-1.98.1-x86_64-unknown-linux-musl.tar.xz /tmp/rust-musl.tar.xz
RUN set -eux; \
    cd /tmp; \
    tar -xJf rust-gnu.tar.xz; \
    ./rust-1.98.1-x86_64-unknown-linux-gnu/install.sh --prefix=/usr/local --without=rust-docs; \
    tar -xJf rust-musl.tar.xz; \
    cp -r rust-1.98.1-x86_64-unknown-linux-musl/rust-std-x86_64-unknown-linux-musl/lib/rustlib/x86_64-unknown-linux-musl \
        /usr/local/lib/rustlib/; \
    rm -rf /tmp/rust-*; \
    rustc --version; cargo --version

# ── Layer 3: Infrastructure and utility binaries ─────────────────────────────
# yq — YAML/JSON processor (from build/archives)
COPY build/archives/yq_linux_amd64.tar.gz /tmp/yq.tar.gz
RUN set -eux; \
    tar -xzf /tmp/yq.tar.gz -C /tmp; \
    install -m755 /tmp/yq_linux_amd64 /usr/local/bin/yq; \
    rm -f /tmp/yq.tar.gz /tmp/yq_linux_amd64 /tmp/yq.1 /tmp/install-man-page.sh

# yadm — dotfiles manager (pinned). Installed to libexec and wrapped so it
# runs against the host's home when launched via piw (YADM_HOME is passed at
# launch). Without YADM_HOME the wrapper is a no-op (defaults to $HOME).
COPY build/archives/yadm-3.5.0 /tmp/yadm
RUN mkdir -p /usr/local/libexec \
    && install -m755 /tmp/yadm /usr/local/libexec/yadm \
    && printf '#!/bin/sh\nexec env HOME="${YADM_HOME:-$HOME}" /usr/local/libexec/yadm "$@"\n' \
        > /usr/local/bin/yadm && chmod +x /usr/local/bin/yadm \
    && rm -f /tmp/yadm

# opentofu — Infrastructure as Code (from build/archives)
COPY build/archives/tofu_1.12.6_linux_amd64.tar.gz /tmp/tofu.tar.gz
RUN tar -xzf /tmp/tofu.tar.gz -C /usr/local/bin/ tofu && rm -f /tmp/tofu.tar.gz

# packer — Image builder (from build/archives)
COPY build/archives/packer_1.16.0_linux_amd64.zip /tmp/packer.zip
RUN unzip -o /tmp/packer.zip -d /usr/local/bin/ && rm -f /tmp/packer.zip

# hadolint — Dockerfile linter (from build/archives)
COPY build/archives/hadolint-linux-x86_64 /usr/local/bin/hadolint
RUN chmod +x /usr/local/bin/hadolint

# tflint — Terraform/OpenTofu linter (from build/archives)
COPY build/archives/tflint_linux_amd64.zip /tmp/tflint.zip
RUN unzip -o /tmp/tflint.zip -d /usr/local/bin/ && rm -f /tmp/tflint.zip

# ── Layer 4: bettercap (Go-based, needs Go installed) ────────────────────────
RUN GOPATH=/tmp/gopath /usr/local/go/bin/go install \
        github.com/bettercap/bettercap/v2@latest \
    && mv /tmp/gopath/bin/bettercap /usr/local/bin/ \
    && rm -rf /tmp/gopath

# ── Layer 5: JavaScript/TypeScript tooling (volatile npm) ────────────────────
RUN npm install -g \
        typescript \
        eslint \
        prettier

# ── Layer 6: Python tooling (uv-based) ────────────────────────────────────────
# uv is a Rust-based Python package manager. `uv tool install` puts each tool
# into its own isolated environment (like pipx), avoiding PEP 668 conflicts
# with the system Python. The binary comes from build/archives: astral's
# installer script fetches from GitHub releases, which offline builds avoid.
COPY build/archives/uv-x86_64-unknown-linux-gnu.tar.gz /tmp/uv.tar.gz
RUN set -eux; \
    tar -xzf /tmp/uv.tar.gz -C /tmp; \
    uv_dir="$(find /tmp -mindepth 1 -maxdepth 1 -type d -name 'uv-*' | head -1)"; \
    install -m755 "$uv_dir/uv" /usr/local/bin/uv; \
    rm -rf /tmp/uv.tar.gz "$uv_dir"; \
    UV_TOOL_BIN_DIR=/usr/local/bin uv tool install --no-cache flake8 \
    && UV_TOOL_BIN_DIR=/usr/local/bin uv tool install --no-cache mypy \
    && UV_TOOL_BIN_DIR=/usr/local/bin uv tool install --no-cache pylint

CMD ["pi"]
