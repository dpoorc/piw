# syntax=docker/dockerfile:1.6
# piw - default image
#
# The base every launch uses. The build bakes every T0 and T1 item from
# issue #15, so a fresh harness needs no network and no setup.
#
# Base: the official Node 24 image on Debian 13 (trixie). Node and npm come
# from here, which is why they are not in the apt list.
#
# Build: docker build -t piw:default .

FROM node:24-trixie-slim

# -- T0 and T1 from apt ------------------------------------------------------
# The image keeps build-essential whole because source builds need it: cargo
# install, npm native modules, and Python without wheels. Its toolchain is the
# largest part of this image, at roughly 218 MB.
#
# apt versions are not pinned: the base tag floats by decision, and Debian
# carries the security fixes. hadolint's DL3008 is expected.
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        git \
        curl \
        ca-certificates \
        openssh-client \
        jq \
        tree \
        python3 \
        less \
        file \
        unzip \
        zip \
        xz-utils \
        procps \
        lsof \
        wget \
        bind9-dnsutils \
        shellcheck \
    && rm -rf /var/lib/apt/lists/*

# -- Tools Debian does not have ----------------------------------------------
# Each download carries its own checksum, so the pin and the hash sit next to
# each other. ADD --checksum needs Dockerfile syntax 1.6 or later.

# mise, the tool manager that owns the store. Not in Debian. Do not strip it:
# the saving is uncompressed, so the layer saving is small.
ADD --checksum=sha256:a31542ee4d660b048d9ddc8f60ed024bff13bd292c08fecde5739ef7a5721dbc \
    https://github.com/jdx/mise/releases/download/v2026.9.17/mise-v2026.9.17-linux-x64.tar.xz \
    /tmp/mise.tar.xz
RUN tar -xJf /tmp/mise.tar.xz -C /tmp \
    && install -m755 /tmp/mise/bin/mise /usr/local/bin/mise \
    && rm -rf /tmp/mise.tar.xz /tmp/mise

# yq. Debian's `yq` is the Python jq wrapper at 3.x, not mikefarah's Go yq.
ADD --checksum=sha256:38b907b21b1b04327fb9481c595331d925a67c6ee1aabd0ef419d0b7d12dfb3d \
    https://github.com/mikefarah/yq/releases/download/v4.53.6/yq_linux_amd64.tar.gz \
    /tmp/yq.tar.gz
RUN tar -xzf /tmp/yq.tar.gz -C /tmp \
    && install -m755 /tmp/yq_linux_amd64 /usr/local/bin/yq \
    && rm -rf /tmp/yq.tar.gz /tmp/yq_linux_amd64 /tmp/yq.1 /tmp/install-man-page.sh

# uv. Not in Debian at all.
ADD --checksum=sha256:745765a3b6e360ad76743599ae5c42e9278c7edf8bbff9fc76d05bf2623a04dd \
    https://github.com/astral-sh/uv/releases/download/0.12.13/uv-x86_64-unknown-linux-gnu.tar.gz \
    /tmp/uv.tar.gz
RUN tar -xzf /tmp/uv.tar.gz -C /tmp \
    && install -m755 /tmp/uv-x86_64-unknown-linux-gnu/uv /usr/local/bin/uv \
    && install -m755 /tmp/uv-x86_64-unknown-linux-gnu/uvx /usr/local/bin/uvx \
    && rm -rf /tmp/uv.tar.gz /tmp/uv-x86_64-unknown-linux-gnu

# -- Runtime environment ------------------------------------------------------
# The mount targets mirror the map in docs/overview.md.
# /home/pi is not writable: the image never creates it, so Docker makes it
# as root for the mount targets. It is also ephemeral, because the container
# runs with --rm. The store mount at /home/pi/.local is the writable,
# persistent home area. Point every tool that reaches outside ~/.local back
# into it, or the tool install fails with 'Permission denied'.
#
# piw sets HOME=/home/pi on every run, so mise finds its global config at
# ~/.config/mise (the mounted .local/mise) and loads ~/.config/mise/conf.d.
# Do not pin MISE_GLOBAL_CONFIG_FILE: an explicit path disables the conf.d
# scan that carries each active layer's tools.
ENV MISE_DATA_DIR=/home/pi/.local/share/mise \
    XDG_CACHE_HOME=/home/pi/.local/cache \
    RUSTUP_HOME=/home/pi/.local/rustup \
    CARGO_HOME=/home/pi/.local/cargo \
    GOPATH=/home/pi/.local/go \
    PATH=/opt/pi/node_modules/.bin:/home/pi/.local/bin:/home/pi/.local/share/mise/shims:$PATH

CMD ["pi"]
