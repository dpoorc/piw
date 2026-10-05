#!/usr/bin/env bash
# pre-publish layer install script. It runs as root inside the image, at build
# time. It installs presidio, the content PII detector, into the system Python.
#
# presidio-analyzer is a library, not a CLI. mise's pypi backend installs a
# library into a private venv that the skill's interpreter cannot import, so
# install it with uv into the system Python instead.
set -euo pipefail

# The spaCy small English model. presidio uses it for the entities that regex
# cannot find, such as names and postal addresses. The model version must match
# the spaCy minor version that presidio-analyzer resolves.
spacy_model="https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"

uv pip install --system --break-system-packages \
    "presidio-analyzer==2.2.364" \
    "$spacy_model"
