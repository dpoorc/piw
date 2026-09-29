# pi-harness — core variant
#
# Minimal coding agent environment: pi + essential CLI tools.
# Includes build-essential and clang for basic compilation.
# The container user is `pi` (UID/GID remapped at runtime via --user).
# Bind-mount ~/.pi/agent and your project workspace at runtime.
#
# Build (from repo root, so build/archives is in the build context):
#   docker build -f variants/core/Dockerfile -t pi-harness:core .
#
# ── Build stage: git-issues (local file-based issue tracker) ─────────────────
FROM golang:latest AS git-issues-builder
RUN go install github.com/steviee/git-issues@latest

# ── Final stage ─────────────────────────────────────────────────────────────
FROM node:24-trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        clang \
        curl \
        file \
        git \
        gnupg \
        jq \
        openssh-client \
        rsync \
        tree \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Pi coding agent — installed into its own bind-mounted app dir at runtime
# (piw ensure_pi, default .pi/app under the harness dir), not baked into
# the image. The image is tooling + isolation only; the PATH entry makes
# the mounted pi executable when the mount is present.
ENV PATH="/opt/pi/node_modules/.bin:${PATH}"

# git-issues — local file-based issue tracker
COPY --from=git-issues-builder /go/bin/git-issues /usr/local/bin/git-issues

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
