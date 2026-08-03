# pi-harness — workstation variant
#
# Full development environment: language toolchains, linters,
# infrastructure tools, and security analysis tools.
# Use this for general development, devops, and security research.
#
# Dependencies: pi-harness:core must be built first.
#   piw build core && piw build workstation
#   or: piw build --all
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
        rizin \
        yamllint \
        bluez \
    && rm -rf /var/lib/apt/lists/*

# ── Layer 2: Powershell (MS repo, apt-based) ─────────────────────────────────
RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
    && curl -sSL "https://packages.microsoft.com/config/debian/12/prod.list" \
        | tee /etc/apt/sources.list.d/microsoft.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends powershell \
    && rm -rf /var/lib/apt/lists/*

# ── Layer 3: Go toolchain ────────────────────────────────────────────────────
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64) go_arch="amd64" ;; \
        aarch64) go_arch="arm64" ;; \
        *) echo "Unsupported arch: $arch"; exit 1 ;; \
    esac; \
    curl -fsSL "https://go.dev/dl/go1.24.0.linux-${go_arch}.tar.gz" \
        | tar -xz -C /usr/local \
    && ln -s /usr/local/go/bin/go /usr/local/bin/go

# ── Layer 3: Rust toolchain ──────────────────────────────────────────────────
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --no-modify-path \
    && rustup component add clippy

# ── Layer 3: Infrastructure and utility binaries ─────────────────────────────
# yq — YAML/JSON processor
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64) yq_arch="amd64" ;; \
        aarch64) yq_arch="arm64" ;; \
        *) echo "Unsupported arch: $arch"; exit 1 ;; \
    esac; \
    curl -sSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${yq_arch}" \
        -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# yadm — dotfiles manager
RUN curl -fsSL https://github.com/TheLocehiliosan/yadm/raw/master/yadm \
        -o /usr/local/bin/yadm && chmod +x /usr/local/bin/yadm

# opentofu — Infrastructure as Code
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64) tofu_arch="amd64" ;; \
        aarch64) tofu_arch="arm64" ;; \
        *) echo "Unsupported arch: $arch"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/opentofu/opentofu/releases/latest/download/tofu_1.9.0_linux_${tofu_arch}.tar.gz" \
        | tar -xz -C /usr/local/bin/ tofu

# packer — Image builder
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64) packer_arch="amd64" ;; \
        aarch64) packer_arch="arm64" ;; \
        *) echo "Unsupported arch: $arch"; exit 1 ;; \
    esac; \
    curl -fsSL "https://releases.hashicorp.com/packer/1.12.0/packer_1.12.0_linux_${packer_arch}.zip" \
        -o /tmp/packer.zip && unzip -o /tmp/packer.zip -d /usr/local/bin/ && rm -f /tmp/packer.zip

# hadolint — Dockerfile linter
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64) hadolint_arch="x86_64" ;; \
        aarch64) hadolint_arch="arm64" ;; \
        *) echo "Unsupported arch: $arch"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-${hadolint_arch}" \
        -o /usr/local/bin/hadolint && chmod +x /usr/local/bin/hadolint

# tflint — Terraform/OpenTofu linter
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64) tflint_arch="amd64" ;; \
        aarch64) tflint_arch="arm64" ;; \
        *) echo "Unsupported arch: $arch"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_${tflint_arch}.zip" \
        -o /tmp/tflint.zip && unzip -o /tmp/tflint.zip -d /usr/local/bin/ && rm -f /tmp/tflint.zip

# ── Layer 4: bettercap (Go-based, needs Go installed) ────────────────────────
RUN GOPATH=/tmp/gopath /usr/local/go/bin/go install \
        github.com/bettercap/bettercap@latest \
    && mv /tmp/gopath/bin/bettercap /usr/local/bin/ \
    && rm -rf /tmp/gopath

# ── Layer 5: JavaScript/TypeScript tooling (volatile npm) ────────────────────
RUN npm install -g \
        typescript \
        eslint \
        prettier

# ── Layer 5: Python tooling (volatile pip) ────────────────────────────────────
RUN pip3 install --no-cache-dir \
        flake8 \
        mypy \
        pylint

CMD ["pi"]
