# pi-harness — <name> variant
#
# <description of what this variant is for>
#
# Build (from repo root):
#   docker build -f variants/<name>/Dockerfile -t pi-harness:<name> .
#
FROM node:24-trixie-slim

# ── System dependencies ──────────────────────────────────────────────────────
# RUN apt-get update && apt-get install -y --no-install-recommends \
#         <packages> \
#     && rm -rf /var/lib/apt/lists/*

# ── Language-specific toolchains ─────────────────────────────────────────────
# (install runtimes, package managers, linters, etc.)

# ── Pi coding agent ──────────────────────────────────────────────────────────
# Installed into its own bind-mounted app dir at runtime (piw ensure_pi,
# default .pi/app under the harness dir), not baked into the image.
# Image = tooling + isolation.
ENV PATH="/opt/pi/node_modules/.bin:/home/pi/.local/bin:${PATH}"

# ── npm security ────────────────────────────────────────────────────────────
# Disable install scripts globally (supply chain security)
RUN npm config set ignore-scripts true

# ── Container user ───────────────────────────────────────────────────────────
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
