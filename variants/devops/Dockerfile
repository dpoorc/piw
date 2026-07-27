# pi-harness — devops variant
#
# Extends core with Python toolchain, Ansible, yq, yamllint, and
# other infrastructure management tools. Use this for provisioning,
# configuration management, and deployment work.
#
# Build:
#   docker build -t pi-harness:devops .
#
FROM node:22-bookworm-slim

# Core tools (same as core variant)
RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        jq \
        openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Python toolchain
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Infrastructure tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        ansible \
        yamllint \
    && rm -rf /var/lib/apt/lists/*

# yq — YAML/JSON processor
RUN curl -sSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" \
        -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Pi coding agent
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# rtk (Rust Token Killer) — CLI proxy that cuts bash output tokens by up to 90%
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64) rtk_arch="x86_64-unknown-linux-musl" ;; \
        aarch64) rtk_arch="aarch64-unknown-linux-gnu" ;; \
        *) echo "Unsupported arch: $arch"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/rtk-ai/rtk/releases/download/v0.43.0/rtk-${rtk_arch}.tar.gz" \
    | tar -xz -C /usr/local/bin/

# Disable npm install scripts globally (supply chain security)
RUN npm config set ignore-scripts true

# Rename the base image's `node` user to `pi`. At runtime, piw remaps
# the host user's UID into the container via --user, so the name doesn't
# affect permissions — but the container user should be called `pi`.
RUN usermod -l pi node \
    && groupmod -n pi node \
    && usermod -d /home/pi -m pi \
    && chmod 755 /home/pi \
    && mkdir -p /home/pi/.npm /home/pi/.cache \
    && chmod 777 /home/pi/.npm /home/pi/.cache

CMD ["pi"]
