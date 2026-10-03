#!/usr/bin/env bash
# piw CLI tests.
#
# Drives the real piw with a stub docker on PATH, so argument parsing, image
# tags, mounts, environment, and the container command are all exercised.
# Docker is not required, and the real repo is never touched.
#
#   tests/run.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ── Sandbox ──────────────────────────────────────────────────────────────────
# A copy of the harness with a dummy Dockerfile and seed tree, so no test
# reaches the network or the real build inputs.
SANDBOX="$WORK/harness"
mkdir -p "$SANDBOX/skills/system/workflow" "$SANDBOX/skills/vendor"
cp "$ROOT/piw" "$SANDBOX/piw"
cp "$ROOT/.gitignore" "$SANDBOX/.gitignore"
cp "$ROOT/skills/generate-catalog.sh" "$SANDBOX/skills/generate-catalog.sh"
cp "$ROOT/skills/system/workflow/SKILL.md" "$SANDBOX/skills/system/workflow/SKILL.md"
cp "$ROOT/skills/system/workflow/APPEND_SYSTEM.md" \
  "$SANDBOX/skills/system/workflow/APPEND_SYSTEM.md"
cp -r "$ROOT/seed" "$SANDBOX/seed"
printf 'FROM scratch\n' > "$SANDBOX/Dockerfile"

# A fake pi install, so ensure_pi takes the offline "already present" path.
PI_APP="$SANDBOX/.local/app"
mkdir -p "$PI_APP/node_modules/.bin" \
  "$PI_APP/node_modules/@earendil-works/pi-coding-agent"
printf '{"name":"@earendil-works/pi-coding-agent","version":"9.9.9"}\n' \
  > "$PI_APP/node_modules/@earendil-works/pi-coding-agent/package.json"
printf '#!/usr/bin/env bash\nexit 0\n' > "$PI_APP/node_modules/.bin/pi"
chmod +x "$PI_APP/node_modules/.bin/pi"

# Sandbox git repo: proves that piw writes only into the ignored namespace.
git -C "$SANDBOX" init -q
git -C "$SANDBOX" -c user.name=test -c user.email=test@example.com add -A
git -C "$SANDBOX" -c user.name=test -c user.email=test@example.com \
  commit -qm "sandbox"

# ── Stub docker ──────────────────────────────────────────────────────────────
STUB="$WORK/stub"
mkdir -p "$STUB"
cp "$ROOT/tests/stub-docker" "$STUB/docker"
chmod +x "$STUB/docker"

# Fail loudly if anything reaches for the network. A missing fixture must not
# become a silent download.
cat > "$STUB/curl" <<'STUB'
#!/usr/bin/env bash
echo "test harness: unexpected curl: $*" >&2
exit 1
STUB
chmod +x "$STUB/curl"

# Keep piw from consulting a real npm registry for versions.
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
assert_exists() { # name path
  if [[ -e "$2" ]]; then ok "$1"; else bad "$1 ($2 missing)"; fi
}

# ── Cases ────────────────────────────────────────────────────────────────────
printf '== piw tool list (namespace creation)\n'
reset_log
piw tool list >/dev/null 2>&1
assert_contains "runs in the container" "$(log)" "sh -c"
assert_contains "lists mise tools" "$(log)" "mise ls"
assert_exists "creates .local/agent" "$SANDBOX/.local/agent"
assert_exists "creates .local/store/bin" "$SANDBOX/.local/store/bin"
assert_exists "creates .local/app" "$SANDBOX/.local/app"
assert_exists "creates .local/mise" "$SANDBOX/.local/mise"
assert_exists "creates .local/layers" "$SANDBOX/.local/layers"
assert_exists "creates .local/agents/skills" "$SANDBOX/.local/agents/skills"

printf '== piw tool install\n'
reset_log
out="$(piw tool install opentofu 2>&1)"
status=$?
assert_status "exits 0" "$status" "0"
assert_contains "reaches the container" "$(log)" "mise use -g opentofu"
assert_contains "mounts the store" "$(log)" "-v $SANDBOX/.local/store:/home/pi/.local:z"
assert_not_contains "does not run the top-level install command" "$out" "Installed:"

printf '== piw tool install (every prefix)\n'
reset_log
piw tool install npm:typescript uv:ruff cargo:ripgrep \
  go:example.com/x bin:opentofu/opentofu@v1.12.6 >/dev/null 2>&1
assert_contains "npm" "$(log)" "npm install --global --prefix /home/pi/.local typescript"
assert_contains "uv" "$(log)" "UV_TOOL_BIN_DIR=/home/pi/.local/bin uv tool install --force ruff"
assert_contains "cargo" "$(log)" "cargo install --root /home/pi/.local ripgrep"
assert_contains "go" "$(log)" "GOBIN=/home/pi/.local/bin go install example.com/x"
assert_contains "bin" "$(log)" "mise use -g github:opentofu/opentofu@v1.12.6"

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

printf '== piw build (default image)\n'
reset_log
piw build >/dev/null 2>&1
assert_contains "builds piw:default from the root Dockerfile" "$(log)" \
  "build -f $SANDBOX/Dockerfile -t piw:default $SANDBOX"

printf '== piw launch
'
mkdir -p "$WORK/proj"
reset_log
out="$(piw "$WORK/proj" 2>&1)"
status=$?
assert_status "launch exits 0" "$status" "0"
assert_contains "mounts the agent directory" "$(log)" "-v $SANDBOX/.local/agent:/home/pi/.pi/agent:z"
assert_contains "mounts the store" "$(log)" "-v $SANDBOX/.local/store:/home/pi/.local:z"
assert_contains "mounts the workspace" "$(log)" "-v $WORK/proj:$WORK/proj:z"
assert_contains "runs pi in the default image" "$(log)" "-w $WORK/proj piw:default pi"

printf '== piw build (missing Dockerfile)\n'
mv "$SANDBOX/Dockerfile" "$WORK/Dockerfile.bak"
reset_log
out="$(piw build 2>&1)"
status=$?
assert_status "build fails without the Dockerfile" "$status" "1"
assert_contains "build names the missing file" "$out" "Dockerfile not found"
mv "$WORK/Dockerfile.bak" "$SANDBOX/Dockerfile"

printf '== piw --help\n'
out="$(piw --help 2>&1)"
assert_status "help exits 0" "$?" "0"
assert_contains "help lists the tool command" "$out" "piw tool install"
assert_contains "help names the default image" "$out" "Build the default image"

printf '== piw --install\n'
reset_log
bindir="$WORK/bin"
piw --install "$bindir" >/dev/null 2>&1
if [[ -L "$bindir/piw" ]]; then
  ok "--install creates the symlink"
else
  bad "--install creates the symlink"
fi
assert_exists "install creates the namespace" "$SANDBOX/.local/store/bin"

printf '== no retired names\n'
# The pattern is split so this test file does not match its own search.
if grep -Eq 'varia[n]ts|config[-]seeds|PIW_DEFAULT_PROFILE|pi-harness' "$SANDBOX/piw"; then
  bad "piw names no retired variant paths"
else
  ok "piw names no retired variant paths"
fi

printf '== sandbox stays clean\n'
if [[ -z "$(git -C "$SANDBOX" status --porcelain)" ]]; then
  ok "piw writes only into the ignored namespace"
else
  bad "piw mutated the tracked tree:"
  git -C "$SANDBOX" status --porcelain | sed 's/^/    /'
fi
assert_absent "no .pi/ in the sandbox" "$SANDBOX/.pi"
assert_absent "no extensions/ in the sandbox" "$SANDBOX/extensions"
assert_absent "no root env in the sandbox" "$SANDBOX/.env"

# ── Result ───────────────────────────────────────────────────────────────────
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
