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

# Create the pi user. UID/GID are remapped at runtime via --user in run.sh.
# 755 on /home/pi so any UID can traverse into it after remapping.
# Create the pi user. UID/GID are remapped at runtime via --user in piw.
# Pre-create writable subdirs so the remapped user (typically `node`, UID 1000)
# can write npm cache and pi state without owning /home/pi.
RUN useradd -m pi \
    && chmod 755 /home/pi \
    && mkdir -p /home/pi/.pi/agent /home/pi/.npm /home/pi/.cache \
    && chmod 777 /home/pi/.npm /home/pi/.cache \
    && chown -R pi:pi /home/pi

CMD ["pi"]
