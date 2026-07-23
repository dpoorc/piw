# pi-harness — <name> variant
#
# <description of what this variant is for>
#
# Build:
#   docker build -t pi-harness:<name> .
#
FROM node:22-bookworm-slim

# ── System dependencies ──────────────────────────────────────────────────────
# RUN apt-get update && apt-get install -y --no-install-recommends \
#         <packages> \
#     && rm -rf /var/lib/apt/lists/*

# ── Language-specific toolchains ─────────────────────────────────────────────
# (install runtimes, package managers, linters, etc.)

# ── Pi coding agent ──────────────────────────────────────────────────────────
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# ── Container user ───────────────────────────────────────────────────────────
# UID/GID are remapped at runtime via --user in run.sh
# Pre-create writable subdirs so the remapped user (typically `node`, UID 1000)
# can write npm cache and pi state without owning /home/pi.
RUN useradd -m pi \
    && chmod 755 /home/pi \
    && mkdir -p /home/pi/.pi/agent /home/pi/.npm /home/pi/.cache \
    && chmod 777 /home/pi/.npm /home/pi/.cache \
    && chown -R pi:pi /home/pi

CMD ["pi"]
