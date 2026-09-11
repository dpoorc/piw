# pi-harness — devops variant
#
# Extends core with Python toolchain, Ansible, yq, yamllint, and
# other infrastructure management tools. Use this for provisioning,
# configuration management, and deployment work.
#
# Dependencies: pi-harness:core must be built first.
#   piw build core && piw build devops
#   or: piw build --all
# Build context is the repo root (build/archives provides the yq artifact);
# piw handles this automatically:
#   docker build -f variants/devops/Dockerfile -t pi-harness:devops .
#
FROM pi-harness:core

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

# yq — YAML/JSON processor (from build/archives)
COPY build/archives/yq_linux_amd64.tar.gz /tmp/yq.tar.gz
RUN set -eux; \
    tar -xzf /tmp/yq.tar.gz -C /tmp; \
    install -m755 /tmp/yq_linux_amd64 /usr/local/bin/yq; \
    rm -f /tmp/yq.tar.gz /tmp/yq_linux_amd64 /tmp/yq.1 /tmp/install-man-page.sh

CMD ["pi"]
