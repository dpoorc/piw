# pi-harness — devops variant
#
# Extends core with Python toolchain, Ansible, yq, yamllint, and
# other infrastructure management tools. Use this for provisioning,
# configuration management, and deployment work.
#
# Dependencies: pi-harness:core must be built first.
#   piw build core && piw build devops
#   or: piw build --all
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

CMD ["pi"]
