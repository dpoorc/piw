#!/usr/bin/env bash
# Run the pre-publication seam tests.
#
# This runner is separate from the host repository suite, because the
# skill may move to its own repository. Run it from anywhere.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$here/run_seam_a.py" "$@"
