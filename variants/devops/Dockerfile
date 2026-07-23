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

# Create the pi user (UID/GID remapped at runtime)
RUN useradd -m pi \
    && chmod 755 /home/pi \
    && mkdir -p /home/pi/.pi/agent \
    && chown -R pi:pi /home/pi

CMD ["pi"]
