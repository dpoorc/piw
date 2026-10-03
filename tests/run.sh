#!/usr/bin/env bash
# piw CLI tests.
#
# Drives the real piw with a stub docker on PATH, so argument parsing, image
# tags, mounts, environment, and the container command are all exercised.
# Docker is not required, and the repo is never touched.
#
#   tests/run.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ── Sandbox ──────────────────────────────────────────────────────────────────
# A copy of the harness with a fake variants tree and dummy archives, so no
# test reaches the network or the real build inputs.
SANDBOX="$WORK/harness"
mkdir -p "$SANDBOX/variants/core" "$SANDBOX/variants/devops" \
  "$SANDBOX/variants/workstation" "$SANDBOX/build/archives"
cp "$ROOT/piw" "$SANDBOX/piw"
printf 'FROM scratch\n' > "$SANDBOX/variants/core/Dockerfile"
printf 'FROM piw:core\n' > "$SANDBOX/variants/devops/Dockerfile"
printf 'FROM piw:core\n' > "$SANDBOX/variants/workstation/Dockerfile"

# Dummy file for every archive piw knows, so ensure_archives never downloads.
# The names come from piw itself, so the fixtures cannot drift out of date.
for profile in core devops workstation; do
  while read -r archive; do
    [[ -n "$archive" ]] && : > "$SANDBOX/build/archives/$archive"
  done < <(bash -c "source <(sed -n '/^_profile_archives()/,/^}/p' '$ROOT/piw'); _profile_archives $profile")
done

# ── Stub docker ──────────────────────────────────────────────────────────────
STUB="$WORK/stub"
mkdir -p "$STUB"
cp "$ROOT/tests/stub-docker" "$STUB/docker"
chmod +x "$STUB/docker"

# Fail loudly if anything reaches for the network. A missing fixture must not
# become a silent 600 MB download.
cat > "$STUB/curl" <<'STUB'
#!/usr/bin/env bash
echo "test harness: unexpected curl: $*" >&2
exit 1
STUB
chmod +x "$STUB/curl"

# Keep piw from consulting a real npm registry for the pi version.
printf '#!/usr/bin/env bash\nexit 1\n' > "$STUB/npm"
chmod +x "$STUB/npm"
export PIW_TEST_DOCKER_LOG="$WORK/docker.log"
: > "$PIW_TEST_DOCKER_LOG"

piw() { (cd "$SANDBOX" && PATH="$STUB:$PATH" ./piw "$@"); }
log() { cat "$PIW_TEST_DOCKER_LOG"; }
reset_log() { : > "$PIW_TEST_DOCKER_LOG"; }

# ── Assertions ───────────────────────────────────────────────────────────────
ok() { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$1"; }

assert_status() { # name actual expected
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (status $2, want $3)"; fi
}
assert_contains() { # name haystack needle
  if [[ "$2" == *"$3"* ]]; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_not_contains() {
  if [[ "$2" != *"$3"* ]]; then ok "$1"; else bad "$1 (unexpected: $3)"; fi
}
assert_absent() { # name path
  if [[ ! -e "$2" ]]; then ok "$1"; else bad "$1 ($2 exists)"; fi
}

# ── Cases ────────────────────────────────────────────────────────────────────
printf '== piw tool install\n'
reset_log
out="$(piw tool install opentofu 2>&1)"
status=$?
assert_status "exits 0" "$status" "0"
assert_contains "reaches the container" "$(log)" "mise use -g opentofu"
assert_contains "mounts the store" "$(log)" "-v $SANDBOX/.pi/store:/home/pi/.local:z"
assert_not_contains "does not run the top-level install command" "$out" "Installed:"
assert_absent "creates no <spec>/piw directory" "$SANDBOX/opentofu"

printf '== piw tool install (every prefix)\n'
reset_log
piw tool install npm:typescript uv:ruff cargo:ripgrep \
  go:example.com/x bin:opentofu/opentofu@v1.12.6 >/dev/null 2>&1
assert_contains "npm" "$(log)" "npm install --global --prefix /home/pi/.local typescript"
assert_contains "uv" "$(log)" "UV_TOOL_BIN_DIR=/home/pi/.local/bin uv tool install --force ruff"
assert_contains "cargo" "$(log)" "cargo install --root /home/pi/.local ripgrep"
assert_contains "go" "$(log)" "GOBIN=/home/pi/.local/bin go install example.com/x"
assert_contains "bin" "$(log)" "mise use -g github:opentofu/opentofu@v1.12.6"

printf '== piw tool list\n'
reset_log
piw tool list >/dev/null 2>&1
assert_contains "runs in the container" "$(log)" "sh -c"
assert_contains "lists mise tools" "$(log)" "mise ls"

printf '== piw tool remove\n'
reset_log
piw tool remove opentofu >/dev/null 2>&1
assert_contains "unuses the mise tool" "$(log)" "mise unuse -g opentofu"

printf '== piw tool (errors)\n'
reset_log
out="$(piw tool bogus 2>&1)"
assert_status "unknown subcommand exits 1" "$?" "1"
assert_contains "unknown subcommand explains itself" "$out" "Unknown 'piw tool' subcommand"
out="$(piw tool install 2>&1)"
assert_status "install with no spec exits 1" "$?" "1"
assert_contains "install with no spec explains itself" "$out" "needs at least one spec"

printf '== piw --install\n'
reset_log
bindir="$WORK/bin"
piw --install "$bindir" >/dev/null 2>&1
if [[ -L "$bindir/piw" ]]; then
  ok "--install still creates the symlink"
else
  bad "--install still creates the symlink"
fi

printf '== piw build (base ordering)\n'
reset_log
piw build workstation >/dev/null 2>&1
core_line="$(log | grep -n 'variants/core/Dockerfile' | head -1 | cut -d: -f1)"
work_line="$(log | grep -n 'variants/workstation/Dockerfile' | head -1 | cut -d: -f1)"
if [[ -n "$core_line" && -n "$work_line" && "$core_line" -lt "$work_line" ]]; then
  ok "builds core before workstation"
else
  bad "builds core before workstation (core=$core_line workstation=$work_line)"
fi

printf '== piw --help\n'
out="$(piw --help 2>&1)"
assert_status "help exits 0" "$?" "0"
assert_contains "help lists the tool command" "$out" "piw tool install"

# ── Result ───────────────────────────────────────────────────────────────────
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
