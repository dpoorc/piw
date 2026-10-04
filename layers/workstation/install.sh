#!/usr/bin/env bash
# workstation layer install script. It runs as root inside the image, at build
# time. The archives file already fetched the three archives to /tmp with a
# checksum check, so this script only extracts them and installs the binaries.
set -euo pipefail

# rizin static build: unpack the whole tree under /usr/local.
tar -xJf /tmp/rizin.tar.xz -C /usr/local
rm -f /tmp/rizin.tar.xz

# ffmpeg and ffprobe static build. Only these two members are installed.
# ffplay is a media player and is useless in a headless container.
tar -xJf /tmp/ffmpeg.tar.xz -C /tmp --strip-components=2 \
    "ffmpeg-n9.0.2-22-g46d8f462ee-linux64-gpl-9.0/bin/ffmpeg" \
    "ffmpeg-n9.0.2-22-g46d8f462ee-linux64-gpl-9.0/bin/ffprobe"
mv /tmp/ffmpeg /tmp/ffprobe /usr/local/bin/
rm -f /tmp/ffmpeg.tar.xz

# yadm dotfiles manager. It is one script, so install it directly. No
# wrapper is needed now that the launch no longer sets YADM_HOME.
install -m755 /tmp/yadm /usr/local/bin/yadm
rm -f /tmp/yadm
