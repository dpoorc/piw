# pi-harness — core variant
#
# Minimal coding agent environment: pi + essential CLI tools.
# The container user is `pi` (UID/GID remapped at runtime via --user).
# Bind-mount ~/.pi/agent and your project workspace at runtime.
#
# Build:
#   docker build -t pi-harness:core .
#
FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        jq \
        openssh-client \
    && rm -rf /var/lib/apt/lists/*

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
