#!/usr/bin/env bash
# piw CLI tests.
#
# Drives the real piw with a stub docker on PATH, so argument parsing, image
# tags, mounts, environment, and the container command are all exercised.
# Docker is not required, and the real repo is never touched.
#
#   tests/run.sh
set -uo pipefail

# The developer shell may export piw overrides. Clear them so the suite is
# hermetic.
unset PI_CONFIG_DIR PI_PI_DIR PI_TOOLS_DIR PIW_CONF PIW_MISE_CONFIG PIW_MODE

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

# Synthetic shipped layers. The real repo ships no layers yet, so the tests
# carry their own. `updatable` is small and stays in git so a test can modify
# the shipped copy and restore it afterwards.
mkdir -p "$SANDBOX/layers/workstation" "$SANDBOX/layers/updatable"
printf 'clang\nnmap\n' > "$SANDBOX/layers/workstation/apt"
printf 'https://example.test/x.tar.gz deadbeef /tmp/x.tar.gz\n' \
  > "$SANDBOX/layers/workstation/archives"
printf '[tools]\n"npm:typescript" = "latest"\n' > "$SANDBOX/layers/workstation/mise.toml"
printf '#!/bin/sh\n' > "$SANDBOX/layers/workstation/install.sh"
printf 'Full toolbox: compilers, forensics, infra\n' \
  > "$SANDBOX/layers/workstation/README.md"
printf 'alpha\n' > "$SANDBOX/layers/updatable/apt"
printf '#!/bin/sh\n' > "$SANDBOX/layers/updatable/install.sh"
printf 'Updatable layer\n' > "$SANDBOX/layers/updatable/README.md"

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

# Stub git so the update pull is observable and controllable without a network
# or a real remote. `pull` is logged and `remote` reports a fake origin. Every
# other invocation goes to the real git, so the git identity reads still work.
REAL_GIT="$(command -v git)"
export PIW_TEST_GIT_LOG="$WORK/git.log"
: > "$PIW_TEST_GIT_LOG"
cat > "$STUB/git" <<STUB
#!/usr/bin/env bash
for arg in "\$@"; do
  case "\$arg" in
  pull)
    printf 'git %s\n' "\$*" >> "\${PIW_TEST_GIT_LOG:?}"
    if [[ "\${PIW_TEST_PULL_FAIL:-}" == "1" ]]; then
      echo "fatal: Not possible to fast-forward, aborting." >&2
      exit 1
    fi
    exit 0
    ;;
  remote)
    [[ "\${PIW_TEST_NO_REMOTE:-}" == "1" ]] && exit 0
    echo "origin"
    exit 0
    ;;
  esac
done
exec "$REAL_GIT" "\$@"
STUB
chmod +x "$STUB/git"

export PIW_TEST_DOCKER_LOG="$WORK/docker.log"
: > "$PIW_TEST_DOCKER_LOG"

# Which images `docker image inspect` reports as present. Space-separated.
# Empty means no image exists, so a launch falls back to piw:default.
export PIW_TEST_IMAGES=""

# A controlled home keeps the host git identity and host git config out of the
# runs, so the exact container argv is deterministic.
TEST_HOME="$WORK/home"
mkdir -p "$TEST_HOME"
piw() {
  (cd "$SANDBOX" && env \
    -u PI_CONFIG_DIR -u PI_PI_DIR -u PI_TOOLS_DIR \
    -u PIW_CONF -u PIW_MISE_CONFIG -u PIW_MODE \
    HOME="$TEST_HOME" \
    GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null \
    PATH="$STUB:$PATH" ./piw "$@")
}
# Call a piw function directly, without running a command. The source guard in
# piw stops before main, so only the definitions load.
piw_fn() { (source "$SANDBOX/piw"; "$@"); }
log() { cat "$PIW_TEST_DOCKER_LOG"; }
reset_log() { : > "$PIW_TEST_DOCKER_LOG"; }

# Point the stub at a matching image label for the current sandbox state, so a
# launch that should proceed passes the staleness check.
sync_label() {
  local h steps
  steps="$(piw_fn resolve_layers 2>/dev/null || true)"
  if [[ -n "$steps" ]]; then
    h="$(piw_fn plan_hash)"
    PIW_TEST_IMAGES="piw:default piw:local"
    PIW_TEST_LABELS="piw:local=$h"
  else
    h="$(piw_fn default_plan_hash)"
    PIW_TEST_IMAGES="piw:default"
    PIW_TEST_LABELS="piw:default=$h"
  fi
  export PIW_TEST_IMAGES PIW_TEST_LABELS
}

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
# Compare two multi-line strings exactly. On mismatch, print a unified diff.
assert_output() { # name actual expected
  if [[ "$2" == "$3" ]]; then
    ok "$1"
  else
    bad "$1 (output differs)"
    diff <(printf '%s\n' "$3") <(printf '%s\n' "$2") | sed 's/^/    /' >&2
  fi
}

# The environment and base mounts every container invocation carries. The
# exact-argv tests build the expected run line from this base. The layer mount
# is separate because a workspace mount can precede it.
seam_base="--add-host host.docker.internal:host-gateway"
seam_base+=" --user $(id -u):$(id -g)"
seam_base+=" -e HOME=/home/pi"
seam_base+=" -e PI_CODING_AGENT_DIR=/home/pi/.pi/agent"
seam_base+=" -e npm_config_cache=/tmp/.npm-cache"
seam_base+=" -e npm_config_ignore_scripts=true"
seam_base+=" -v $SANDBOX/.local/agent:/home/pi/.pi/agent:z"
seam_base+=" -v $SANDBOX/.local/store:/home/pi/.local:z"
seam_base+=" -v $SANDBOX/.local/mise:/home/pi/.config/mise:z"
seam_base+=" -v $SANDBOX/.local/app:/opt/pi:z"
seam_base+=" -v $SANDBOX/.local/agents/skills:/home/pi/.agents/skills:z"
seam_base+=" -v $SANDBOX/skills:/home/pi/.pi/agent/skills:z,ro"
seam_base+=" -v $SANDBOX/agents:/home/pi/.pi/agent/agents:z,ro"
seam_base+=" -v $SANDBOX/skills/system/workflow/APPEND_SYSTEM.md:/home/pi/.pi/agent/APPEND_SYSTEM.md:z,ro"
seam_layers="-v $SANDBOX/.local/layers:/opt/piw/layers:z,ro"

# ── Cases ────────────────────────────────────────────────────────────────────
printf '== piw tool list (namespace creation)\n'
reset_log
piw tool list >/dev/null 2>&1
first_label="$(piw_fn default_plan_hash)"
assert_output "first run builds the default image with the plan label" \
  "$(log | grep '^build ')" \
  "build -f $SANDBOX/Dockerfile -t piw:default $SANDBOX --label piw.plan=$first_label"
assert_contains "tool list runs in the default image" "$(log)" "piw:default mise ls"
missing=()
for d in agent store/bin app mise layers agents/skills; do
  [[ -d "$SANDBOX/.local/$d" ]] || missing+=(".local/$d")
done
assert_status "creates the whole .local namespace" "${#missing[@]}" "0"

printf '== piw tool install\n'
reset_log
out="$(piw tool install opentofu 2>&1)"
status=$?
assert_status "tool install exits 0" "$status" "0"
assert_output "tool install announces the mise install only" \
  "$(printf '%s\n' "$out" | grep -v '^INFO: Build')" \
  "INFO: Installing opentofu into the tool store…"
assert_output "tool install reaches mise in the container" \
  "$(log | grep '^run ' | sed 's/.* piw:default //')" "mise use -g opentofu"

printf '== piw tool install (every spec goes to mise)\n'
reset_log
piw tool install npm:typescript pypi:ruff go:example.com/x \
  cargo:ripgrep >/dev/null 2>&1
assert_output "every spec goes to mise" \
  "$(log | grep '^run ' | sed 's/.* piw:default //')" \
  "$(printf 'mise use -g %s\n' npm:typescript pypi:ruff go:example.com/x cargo:ripgrep)"

printf '== piw tool remove\n'
reset_log
piw tool remove opentofu >/dev/null 2>&1
assert_output "remove unuses the mise tool" \
  "$(log | grep '^run ' | sed 's/.* piw:default //')" "mise unuse -g opentofu"

printf '== piw tool (errors)\n'
out="$(piw tool bogus 2>&1)"
assert_status "unknown subcommand exits 1" "$?" "1"
assert_output "unknown subcommand explains itself" "$out" \
  "ERROR: Unknown 'piw tool' subcommand: bogus
Usage: piw tool install <spec>... | list | remove <spec>..."
out="$(piw tool install 2>&1)"
assert_status "install with no spec exits 1" "$?" "1"
assert_output "install with no spec explains itself" \
  "$(printf '%s\n' "$out" | grep -v '^INFO: Build')" \
  "ERROR: piw tool install needs at least one spec.
  Example: piw tool install npm:typescript pypi:ruff"

printf '== piw tool runs through the container seam\n'
reset_log
piw tool list >/dev/null 2>&1
assert_output "tool run uses the container seam" \
  "$(log | grep '^run ' | head -1)" \
  "run --rm $seam_base $seam_layers piw:default mise ls"

printf '== piw build (default image)\n'
reset_log
piw build >/dev/null 2>&1
default_label="$(piw_fn default_plan_hash)"
assert_output "builds piw:default from the root Dockerfile with the plan label" \
  "$(log | grep '^build ' | head -1)" \
  "build -f $SANDBOX/Dockerfile -t piw:default $SANDBOX --label piw.plan=$default_label"

printf '== piw launch (exact argv)\n'
mkdir -p "$WORK/proj"
sync_label
reset_log
out="$(piw "$WORK/proj" 2>&1)"
status=$?
assert_status "launch exits 0" "$status" "0"
run_line="$(grep '^run ' "$PIW_TEST_DOCKER_LOG" | head -1)"
assert_output "launch argv is exact" "$run_line" \
  "run --rm -it $seam_base -v $WORK/proj:$WORK/proj:z $seam_layers -w $WORK/proj piw:default pi"

printf '== piw launch passes the env file\n'
printf 'ANTHROPIC_API_KEY=test-key\n' > "$SANDBOX/.local/.env"
sync_label
reset_log
out="$(ANTHROPIC_API_KEY=host-only piw "$WORK/proj" 2>&1)"
assert_output "passes the env file and does not forward a host API key" \
  "$(grep '^run ' "$PIW_TEST_DOCKER_LOG" | head -1)" \
  "run --rm -it ${seam_base/ -v / --env-file $SANDBOX/.local/.env -v } -v $WORK/proj:$WORK/proj:z $seam_layers -w $WORK/proj piw:default pi"
rm -f "$SANDBOX/.local/.env"

printf '== piw --mode readonly\n'
sync_label
reset_log
out="$(piw --mode readonly "$WORK/proj" 2>&1)"
status=$?
readonly_run="run --rm -it --add-host host.docker.internal:host-gateway"
readonly_run+=" --user $(id -u):$(id -g)"
readonly_run+=" -e HOME=/home/pi"
readonly_run+=" -e PI_CODING_AGENT_DIR=/home/pi/.pi/agent"
readonly_run+=" -e npm_config_cache=/tmp/.npm-cache"
readonly_run+=" -e npm_config_ignore_scripts=true"
readonly_run+=" --network none"
readonly_run+=" -v $SANDBOX/.local/agent:/home/pi/.pi/agent:z"
readonly_run+=" -v $SANDBOX/.local/store:/home/pi/.local:z,ro"
readonly_run+=" -v $SANDBOX/.local/mise:/home/pi/.config/mise:z,ro"
readonly_run+=" -v $SANDBOX/.local/app:/opt/pi:z"
readonly_run+=" -v $SANDBOX/.local/agents/skills:/home/pi/.agents/skills:z,ro"
readonly_run+=" -v $SANDBOX/skills:/home/pi/.pi/agent/skills:z,ro"
readonly_run+=" -v $SANDBOX/agents:/home/pi/.pi/agent/agents:z,ro"
readonly_run+=" -v $SANDBOX/skills/system/workflow/APPEND_SYSTEM.md:/home/pi/.pi/agent/APPEND_SYSTEM.md:z,ro"
readonly_run+=" -v $SANDBOX/.local/agent/extensions/pi-permission-system/config.readonly.json:/home/pi/.pi/agent/extensions/pi-permission-system/config.json:z,ro"
readonly_run+=" -v $WORK/proj:$WORK/proj:z,ro"
readonly_run+=" $seam_layers"
readonly_run+=" -w $WORK/proj piw:default pi"
assert_output "readonly launch argv is exact" \
  "$(printf 'status=%s\n%s' "$status" "$(grep '^run ' "$PIW_TEST_DOCKER_LOG" | head -1)")" \
  "status=0
$readonly_run"

printf '== piw build (missing Dockerfile)\n'
mv "$SANDBOX/Dockerfile" "$WORK/Dockerfile.bak"
reset_log
out="$(piw build 2>&1)"
status=$?
assert_output "build fails without the Dockerfile and names it" \
  "$(printf 'status=%s\n%s' "$status" "$out")" \
  "status=1
ERROR: Dockerfile not found at $SANDBOX/Dockerfile
  The default image builds from the repository root Dockerfile."
mv "$WORK/Dockerfile.bak" "$SANDBOX/Dockerfile"

printf '== piw --help\n'
out="$(piw --help 2>&1)"
assert_status "help exits 0" "$?" "0"
assert_output "help lists the command set and explains link and unlink" \
  "$(printf '%s\n' "$out" | grep '^  piw ')" \
  "$(cat <<'HELP'
  piw [<path>]                 Launch in the current directory or <path>
  piw build                    Build the default image and the layer image
  piw tool install <spec>...   Install tools into the shared store
  piw tool remove <spec>...    Remove tools from the shared store
  piw tool list                List tools in the shared store
  piw layer add <name|apt:...> Adopt a shipped layer, or scaffold a new one
  piw layer remove <name>      Remove a layer from the manifest
  piw layer list               List shipped and active layers
  piw layer show <name>        Show a layer's contents
  piw layer update <name>      Update an adopted layer
  piw doctor                   Diagnose the harness
  piw link [dir]               Put piw on PATH (symlink into dir)
  piw unlink [dir]             Take piw off PATH (remove the symlink)
  piw generate-catalog         Regenerate the skills catalog
  piw update                   Pull, report drift, rebuild, and update pi
  piw --version                Print the version
  piw --help                   Show this help
HELP
)"

printf '== piw --version\n'
out="$(piw --version 2>&1)"
assert_status "version exits 0" "$?" "0"
if [[ "$out" =~ ^piw\ [0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  ok "--version prints piw <version>"
else
  bad "--version prints piw <version> (got: $out)"
fi

printf '== parser: launch is the default case\n'
mkdir -p "$WORK/proj"
sync_label
reset_log
out="$(piw "$WORK/proj" 2>&1)"
assert_contains "piw <path> launches in the workspace" "$(log)" \
  "-w $WORK/proj piw:default pi"
reset_log
out="$(piw 2>&1)"
assert_contains "bare piw uses the current directory" "$(log)" \
  "-w $SANDBOX piw:default pi"
out="$(piw launch 2>&1)"
status=$?
assert_status "'launch' is not a command word" "$status" "1"
assert_contains "'launch' is read as a workspace path" "$out" "Workspace not found"

printf '== parser: a flag on the wrong command errors\n'
while IFS='|' read -r invocation command flag; do
  out="$(piw $invocation $flag 2>&1)"
  status=$?
  assert_output "rejects '$flag' on '$command'" \
    "$(printf 'status=%s\n%s' "$status" "$out")" \
    "status=1
ERROR: '$flag' is not a flag of the '$command' command.
  Run 'piw --help' for the command set and each command's flags."
done <<'CASES'
doctor|doctor|--no-cache
build|build|--resume
tool list|tool|--dry-run
doctor|doctor|--mode
CASES

printf '== parser: retired flags are gone\n'
for flag in --build-only --install-only --install --uninstall; do
  out="$(piw "$flag" 2>&1)"
  status=$?
  assert_output "$flag is rejected" \
    "$(printf 'status=%s\n%s' "$status" "$out")" \
    "status=1
ERROR: '$flag' is not a flag of the 'launch' command.
  Run 'piw --help' for the command set and each command's flags."
done
if grep -qE 'build-only|install-only|--install|--uninstall' "$SANDBOX/piw"; then
  bad "piw no longer names the retired flags"
else
  ok "piw no longer names the retired flags"
fi

printf '== piw link and unlink\n'
reset_log
bindir="$WORK/bin"
piw link "$bindir" >/dev/null 2>&1
if [[ -L "$bindir/piw" ]]; then
  ok "link creates the symlink"
else
  bad "link creates the symlink"
fi
assert_exists "link creates the namespace" "$SANDBOX/.local/store/bin"
piw unlink "$bindir" >/dev/null 2>&1
assert_absent "unlink removes the symlink" "$bindir/piw"

printf '== starters seed once\n'
rm -f "$SANDBOX/.local/piw.conf" "$SANDBOX/.local/mise/config.toml"
piw link "$WORK/bin-seed" >/dev/null 2>&1
if [[ -f "$SANDBOX/.local/piw.conf" && -f "$SANDBOX/.local/mise/config.toml" ]]; then
  ok "install seeds both starters"
else
  bad "install seeds both starters"
fi
if diff -q "$SANDBOX/seed/piw.conf" "$SANDBOX/.local/piw.conf" >/dev/null \
  && diff -q "$SANDBOX/seed/mise/config.toml" \
    "$SANDBOX/.local/mise/config.toml" >/dev/null; then
  ok "both starters begin as copies of the seed"
else
  bad "both starters begin as copies of the seed"
fi

# An edited live file must survive every later run.
printf '# edited by the user\n[layers]\nrun:mine\n' > "$SANDBOX/.local/piw.conf"
printf '# edited by the user\n[tools]\n' > "$SANDBOX/.local/mise/config.toml"
piw link "$WORK/bin-seed2" >/dev/null 2>&1
assert_output "keeps edited starters" \
  "$(cat "$SANDBOX/.local/piw.conf"; printf -- '---\n'; cat "$SANDBOX/.local/mise/config.toml")" \
  "# edited by the user
[layers]
run:mine
---
# edited by the user
[tools]"

# Launch seeds the same two files.
rm -f "$SANDBOX/.local/piw.conf" "$SANDBOX/.local/mise/config.toml"
sync_label
piw "$WORK/proj" >/dev/null 2>&1
if [[ -f "$SANDBOX/.local/piw.conf" && -f "$SANDBOX/.local/mise/config.toml" ]]; then
  ok "launch seeds both starters"
else
  bad "launch seeds both starters"
fi

printf '== manifest resolvers\n'
assert_output "manifest and mise config resolvers" \
  "$(printf '%s\n' \
    "$(piw_fn resolve_piw_conf)" \
    "$(PIW_CONF=/tmp/piw-elsewhere.conf piw_fn resolve_piw_conf)" \
    "$(PIW_CONF=sub/piw.conf piw_fn resolve_piw_conf)" \
    "$(piw_fn resolve_mise_config)" \
    "$(PIW_MISE_CONFIG=/tmp/mise-elsewhere.toml piw_fn resolve_mise_config)" \
    "$(PIW_MISE_CONFIG=sub/mise.toml piw_fn resolve_mise_config)")" \
  "$SANDBOX/.local/piw.conf
/tmp/piw-elsewhere.conf
$SANDBOX/sub/piw.conf
$SANDBOX/.local/mise/config.toml
/tmp/mise-elsewhere.toml
$SANDBOX/sub/mise.toml"

printf '== manifest parser\n'
FIX="$WORK/manifest"
mkdir -p "$FIX"

cat > "$FIX/good.conf" <<'CONF'
# a comment
   # an indented comment

[layers]
apt:zsh gdb
run:my-setup   # trailing comment

[pi]
npm:pi-intercom
git:https://host/repo#v1
CONF
out="$(PIW_CONF="$FIX/good.conf" piw_fn parse_piw_conf 2>&1)"
status=$?
assert_output "good manifest parses and strips comments" \
  "$(printf 'status=%s\n%s' "$status" "$out")" \
  "$(printf 'status=0\nlayers\t%s\nlayers\t%s\npi\t%s\npi\t%s\n' \
    'apt:zsh gdb' 'run:my-setup' 'npm:pi-intercom' 'git:https://host/repo#v1')"

printf '[layers]\napt:zsh\n[layers]\napt:gdb\n' > "$FIX/merge.conf"
out="$(PIW_CONF="$FIX/merge.conf" piw_fn parse_piw_conf 2>&1)"
assert_output "duplicate sections merge" "$out" \
  "$(printf 'layers\t%s\nlayers\t%s\n' 'apt:zsh' 'apt:gdb')"

printf 'orphan:entry\n' > "$FIX/orphan.conf"
out="$(PIW_CONF="$FIX/orphan.conf" piw_fn parse_piw_conf 2>"$FIX/err")"
status=$?
assert_output "an entry before a section stops and names the file and line" \
  "$(printf 'status=%s\nstdout=%s\nstderr=%s' "$status" "$out" "$(cat "$FIX/err")")" \
  "status=2
stdout=
stderr=$FIX/orphan.conf:1: entry before any section"

printf '[layers\napt:zsh\n' > "$FIX/bad-header.conf"
out="$(PIW_CONF="$FIX/bad-header.conf" piw_fn parse_piw_conf 2>"$FIX/err")"
status=$?
assert_output "a malformed header stops and names the file and line" \
  "$(printf 'status=%s\nstdout=%s\nstderr=%s' "$status" "$out" "$(cat "$FIX/err")")" \
  "status=2
stdout=
stderr=$FIX/bad-header.conf:1: malformed section header"

printf '# only a comment\n\n   \n' > "$FIX/empty.conf"
out="$(PIW_CONF="$FIX/empty.conf" piw_fn parse_piw_conf 2>&1)"
assert_output "a comment-only manifest emits nothing" \
  "$(printf 'status=%s\n%s' "$?" "$out")" "status=0"

printf '[layers]\r\napt:zsh\r\n' > "$FIX/crlf.conf"
out="$(PIW_CONF="$FIX/crlf.conf" piw_fn parse_piw_conf 2>&1)"
assert_output "CRLF entries parse clean" "$out" \
  "$(printf 'layers\t%s\n' 'apt:zsh')"

# The shipped starter must parse to nothing.
out="$(PIW_CONF="$SANDBOX/seed/piw.conf" piw_fn parse_piw_conf 2>&1)"
assert_output "the shipped starter parses to nothing" \
  "$(printf 'status=%s\n%s' "$?" "$out")" "status=0"

printf '== layers: plan composition\n'
LAYERS="$SANDBOX/.local/layers"

# A layer with apt and no script needs no COPY and no install.
rm -rf "$LAYERS"
mkdir -p "$LAYERS/aptonly"
printf 'zsh\ngdb\n' > "$LAYERS/aptonly/apt"
printf '[layers]\nrun:aptonly\n' > "$SANDBOX/.local/piw.conf"
plan="$(piw_fn compose_plan 2>&1)"
assert_output "an apt-only layer composes one apt step and no script" "$plan" \
  "$(printf '# syntax=docker/dockerfile:1.6\nFROM piw:default\n\n# apt\nRUN apt-get update \\\n && apt-get install -y --no-install-recommends \\\n        %s \\\n        %s \\\n && rm -rf /var/lib/apt/lists/*\n' zsh gdb)"

# Several layers compose in the declared order.
mkdir -p "$LAYERS/first" "$LAYERS/second"
printf '#!/bin/sh\n' > "$LAYERS/first/install.sh"
printf '#!/bin/sh\n' > "$LAYERS/second/install.sh"
printf '[layers]\nrun:first\nrun:second\n' > "$SANDBOX/.local/piw.conf"
plan="$(piw_fn compose_plan 2>&1)"
assert_output "layers compose in the declared order" "$plan" \
  "$(printf '# syntax=docker/dockerfile:1.6\nFROM piw:default\n\n# layer first\nCOPY first/ /tmp/piw-layer-first/\nRUN bash /tmp/piw-layer-first/install.sh \\\n && rm -rf /tmp/piw-layer-first\n\n# layer second\nCOPY second/ /tmp/piw-layer-second/\nRUN bash /tmp/piw-layer-second/install.sh \\\n && rm -rf /tmp/piw-layer-second\n')"

# Consecutive apt declarations coalesce into one operation.
printf '[layers]\napt:zsh\napt:gdb\nrun:first\n' > "$SANDBOX/.local/piw.conf"
printf 'ripgrep\n' > "$LAYERS/first/apt"
plan="$(piw_fn compose_plan 2>&1)"
assert_output "consecutive apt declarations coalesce" "$plan" \
  "$(printf '# syntax=docker/dockerfile:1.6\nFROM piw:default\n\n# apt\nRUN apt-get update \\\n && apt-get install -y --no-install-recommends \\\n        %s \\\n        %s \\\n        %s \\\n && rm -rf /var/lib/apt/lists/*\n\n# layer first\nCOPY first/ /tmp/piw-layer-first/\nRUN bash /tmp/piw-layer-first/install.sh \\\n && rm -rf /tmp/piw-layer-first\n' zsh gdb ripgrep)"

# A non-apt step between apt declarations keeps them separate.
printf '[layers]\napt:zsh\nrun:first\napt:gdb\n' > "$SANDBOX/.local/piw.conf"
plan="$(piw_fn compose_plan 2>&1)"
assert_output "a non-apt step splits apt groups" "$plan" \
  "$(printf '# syntax=docker/dockerfile:1.6\nFROM piw:default\n\n# apt\nRUN apt-get update \\\n && apt-get install -y --no-install-recommends \\\n        %s \\\n        %s \\\n && rm -rf /var/lib/apt/lists/*\n\n# layer first\nCOPY first/ /tmp/piw-layer-first/\nRUN bash /tmp/piw-layer-first/install.sh \\\n && rm -rf /tmp/piw-layer-first\n\n# apt\nRUN apt-get update \\\n && apt-get install -y --no-install-recommends \\\n        %s \\\n && rm -rf /var/lib/apt/lists/*\n' zsh ripgrep gdb)"

# Archives become one ADD --checksum each.
mkdir -p "$LAYERS/arch"
printf 'https://example.test/x.tar.gz abc123def456 /tmp/x.tar.gz\n' > "$LAYERS/arch/archives"
printf '[layers]\nrun:arch\n' > "$SANDBOX/.local/piw.conf"
plan="$(piw_fn compose_plan 2>&1)"
assert_output "an archive becomes one ADD --checksum" "$plan" \
  "$(printf '# syntax=docker/dockerfile:1.6\nFROM piw:default\n\n# archive\nADD --checksum=sha256:%s %s %s\n' abc123def456 https://example.test/x.tar.gz /tmp/x.tar.gz)"

# A malformed archive line stops before Docker.
mkdir -p "$LAYERS/badarch"
printf 'https://example.test/x.tar.gz abc /tmp/x extra\n' > "$LAYERS/badarch/archives"
printf '[layers]\nrun:badarch\n' > "$SANDBOX/.local/piw.conf"
reset_log
out="$(piw build 2>&1)"
status=$?
assert_output "a malformed archive stops before Docker and names the file" \
  "$(printf 'status=%s\nbuilds=%s\n%s' "$status" "$(log | grep '^build ')" "$out")" \
  "status=1
builds=
ERROR: Malformed archive line in $SANDBOX/.local/layers/badarch/archives: https://example.test/x.tar.gz abc /tmp/x extra
  Expected: <url> <sha256> <destination>"

# An unknown [layers] prefix stops.
printf '[layers]\nbogus:thing\n' > "$SANDBOX/.local/piw.conf"
out="$(piw_fn resolve_layers 2>&1)"
status=$?
assert_output "an unknown prefix stops and names the entry" \
  "$(printf 'status=%s\n%s' "$status" "$out")" \
  "status=1
ERROR: Unknown [layers] entry 'bogus:thing' in $SANDBOX/.local/piw.conf.
  Use 'apt:<pkg> [<pkg>...]' or 'run:<name>'."

# An empty run: entry stops.
printf '[layers]\nrun:\n' > "$SANDBOX/.local/piw.conf"
out="$(piw_fn resolve_layers 2>&1)"
status=$?
assert_status "an empty run entry stops" "$status" "1"

# The plan hash changes when a layer file changes.
printf '[layers]\nrun:first\n' > "$SANDBOX/.local/piw.conf"
h1="$(piw_fn plan_hash)"
printf 'extra\n' >> "$LAYERS/first/apt"
h2="$(piw_fn plan_hash)"
if [[ -n "$h1" && "$h1" != "$h2" ]]; then
  ok "plan hash changes with a layer file"
else
  bad "plan hash changes with a layer file"
fi

# A missing manifest stops and names the path.
out="$(PIW_CONF="$WORK/absent-piw.conf" piw_fn resolve_layers 2>&1)"
status=$?
assert_output "a missing manifest stops and names the path" \
  "$(printf 'status=%s\n%s' "$status" "$out")" \
  "status=1
ERROR: Layer manifest not found: $WORK/absent-piw.conf
  Run 'piw link' or launch piw to seed the starter manifest."

# A missing run: layer stops before Docker and names the entry and the path.
printf '[layers]\nrun:ghost\n' > "$SANDBOX/.local/piw.conf"
reset_log
out="$(piw build 2>&1)"
status=$?
assert_output "a missing layer stops before Docker and names entry and path" \
  "$(printf 'status=%s\nbuilds=%s\n%s' "$status" "$(log | grep '^build ')" "$out")" \
  "status=1
builds=
ERROR: Layer 'ghost' not found: $SANDBOX/.local/layers/ghost
  Declared as 'run:ghost' in $SANDBOX/.local/piw.conf."

printf '== layers: build\n'
# A dry run prints the plan and invokes no Docker.
printf '[layers]\nrun:first\n' > "$SANDBOX/.local/piw.conf"
reset_log
out="$(piw build --dry-run 2>&1)"
status=$?
assert_output "dry run prints the plan and invokes no Docker" \
  "$(printf 'status=%s\ndocker=%s\n%s' "$status" "$(log)" \
    "$(printf '%s\n' "$out" | grep -E 'FROM piw:default|# layer first|conf.d|mise install|Nothing executed|Build plan')")" \
  "status=0
docker=
INFO: (dry-run) Build plan:
FROM piw:default
# layer first
(dry-run) Would write the active-layer tool fragments to .local/mise/conf.d/
(dry-run) Would install the store tools: mise install
INFO: (dry-run) Nothing executed."

# With layers, piw builds piw:local from stdin with the layers context.
reset_log
out="$(piw build 2>&1)"
status=$?
plan_label="$(piw_fn plan_hash)"
assert_output "builds piw:local from stdin with the plan label" \
  "$(printf 'status=%s\n%s' "$status" "$(grep '^build ' "$PIW_TEST_DOCKER_LOG" | grep ' -t piw:local ')")" \
  "status=0
build -f - -t piw:local --label piw.plan=$plan_label $SANDBOX/.local/layers"

# --no-cache reaches the local build.
reset_log
piw build --no-cache >/dev/null 2>&1
assert_output "no-cache reaches the local build" \
  "$(grep '^build ' "$PIW_TEST_DOCKER_LOG" | grep ' -t piw:local ')" \
  "build -f - -t piw:local --label piw.plan=$plan_label --no-cache $SANDBOX/.local/layers"

# With no layers, piw builds no user image.
printf '[layers]\n' > "$SANDBOX/.local/piw.conf"
reset_log
piw build >/dev/null 2>&1
assert_not_contains "no layers builds no piw:local" "$(log)" "piw:local"

printf '== store: build installs the global and active-layer tools\n'
rm -rf "$LAYERS"
mkdir -p "$LAYERS/alpha" "$LAYERS/beta" "$LAYERS/inactive"
printf '#!/bin/sh\n' > "$LAYERS/alpha/install.sh"
printf '[tools]\n"npm:typescript" = "latest"\n' > "$LAYERS/alpha/mise.toml"
printf '#!/bin/sh\n' > "$LAYERS/beta/install.sh"
printf '[tools]\n"npm:eslint" = "latest"\n' > "$LAYERS/beta/mise.toml"
printf '#!/bin/sh\n' > "$LAYERS/inactive/install.sh"
printf '[tools]\n"npm:prettier" = "latest"\n' > "$LAYERS/inactive/mise.toml"
printf '[layers]\nrun:alpha\nrun:beta\n' > "$SANDBOX/.local/piw.conf"
reset_log
out="$(piw build 2>&1)"
status=$?
assert_output "build installs the global and active-layer stores in one step" \
  "$(printf 'status=%s\n%s' "$status" \
    "$(log | grep '^run ' | sed 's/.* piw:\(default\|local\) //')")" \
  "status=0
mise install
bash /home/pi/.pi/agent/skills/generate-catalog.sh"
assert_exists "an active layer becomes a conf.d fragment" \
  "$SANDBOX/.local/mise/conf.d/alpha.toml"
assert_exists "every active layer becomes a conf.d fragment" \
  "$SANDBOX/.local/mise/conf.d/beta.toml"
assert_absent "an inactive layer leaves no fragment" \
  "$SANDBOX/.local/mise/conf.d/inactive.toml"

printf '== store: survives a rebuild\n'
printf 'marker\n' > "$SANDBOX/.local/store/marker"
reset_log
piw build >/dev/null 2>&1
assert_exists "store contents survive a rebuild" "$SANDBOX/.local/store/marker"
assert_contains "rebuild mounts the existing store" "$(log)" \
  "-v $SANDBOX/.local/store:/home/pi/.local:z"
assert_output "rebuild reinstalls the global and layer stores" \
  "$(log | grep '^run ' | sed 's/.* piw:\(default\|local\) //')" \
  "mise install
bash /home/pi/.pi/agent/skills/generate-catalog.sh"

printf '== layers: launch uses the image the manifest needs\n'
# With layers: piw:local and the full plan hash.
printf '[layers]\nrun:alpha\n' > "$SANDBOX/.local/piw.conf"
mkdir -p "$SANDBOX/.local/layers/alpha"
printf '#!/bin/sh\n' > "$SANDBOX/.local/layers/alpha/install.sh"
local_label="$(piw_fn plan_hash)"
PIW_TEST_IMAGES="piw:default piw:local"
PIW_TEST_LABELS="piw:local=$local_label"
reset_log
out="$(piw "$WORK/proj" 2>&1)"
assert_contains "launch with layers uses piw:local" \
  "$(grep '^run ' "$PIW_TEST_DOCKER_LOG" | head -1)" "piw:local"

# Without layers: piw:default and the default Dockerfile hash.
printf '[layers]\n' > "$SANDBOX/.local/piw.conf"
default_label="$(piw_fn default_plan_hash)"
PIW_TEST_IMAGES="piw:default"
PIW_TEST_LABELS="piw:default=$default_label"
reset_log
out="$(piw "$WORK/proj" 2>&1)"
assert_contains "launch without layers uses piw:default" \
  "$(grep '^run ' "$PIW_TEST_DOCKER_LOG" | head -1)" "piw:default"

printf '== launch: staleness check\n'
# A matching label proceeds.
printf '[layers]\n' > "$SANDBOX/.local/piw.conf"
matching_label="$(piw_fn default_plan_hash)"
PIW_TEST_IMAGES="piw:default"
PIW_TEST_LABELS="piw:default=$matching_label"
reset_log
out="$(piw "$WORK/proj" 2>&1)"
assert_contains "a matching label launches" "$(log)" "piw:default pi"

# A mismatched label refuses, names the fix, and never builds.
PIW_TEST_LABELS="piw:default=deadbeef"
reset_log
out="$(piw "$WORK/proj" 2>&1)"
status=$?
assert_output "a mismatched label refuses, names the fix, and never builds" \
  "$(printf 'status=%s\nbuilds=%s\n%s' "$status" "$(log | grep '^build ')" "$out")" \
  "status=1
builds=
INFO: pi 9.9.9 present.
ERROR: Image 'piw:default' is stale.
  The image was not built from the current plan.
  Expected plan hash: $matching_label
  Image plan hash:    deadbeef
  Run 'piw build' to rebuild the image."

# A missing label refuses.
PIW_TEST_LABELS=""
reset_log
out="$(piw "$WORK/proj" 2>&1)"
status=$?
assert_output "a missing label refuses, names the fix, and never builds" \
  "$(printf 'status=%s\nbuilds=%s\n%s' "$status" "$(log | grep '^build ')" "$out")" \
  "status=1
builds=
INFO: pi 9.9.9 present.
ERROR: Image 'piw:default' is stale.
  The image was not built from the current plan.
  Expected plan hash: $matching_label
  Image plan hash:    <none>
  Run 'piw build' to rebuild the image."

# A required piw:local that is missing refuses and names piw build.
printf '[layers]\nrun:alpha\n' > "$SANDBOX/.local/piw.conf"
PIW_TEST_IMAGES="piw:default"
PIW_TEST_LABELS=""
reset_log
out="$(piw "$WORK/proj" 2>&1)"
status=$?
assert_output "a missing piw:local refuses, names the image and the fix" \
  "$(printf 'status=%s\nbuilds=%s\n%s' "$status" "$(log | grep '^build ')" "$out")" \
  "status=1
builds=
INFO: pi 9.9.9 present.
ERROR: Required image 'piw:local' is missing.
  Run 'piw build' to build it."

# Leave the manifest with no layers for the later launch tests.
printf '[layers]\n' > "$SANDBOX/.local/piw.conf"

printf '== default Dockerfile\n'
df="$ROOT/Dockerfile"
assert_exists "Dockerfile at the repo root" "$df"
df_body="$(cat "$df" 2>/dev/null || true)"
assert_output "the syntax directive and base are the decided ones" \
  "$(sed -n '1p' "$df"; grep -m1 '^FROM ' "$df")" \
  "# syntax=docker/dockerfile:1.6
FROM node:24-trixie-slim"

# The apt set must match the decided 19 exactly, so an extra or a missing
# package fails the suite.
apt_set="$(sed -n '/--no-install-recommends/,/&& rm -rf/p' "$df" | grep -vE 'RUN|rm -rf' | awk '{print $1}' | grep -v '^$' | sort | tr '\n' ' ')"
apt_expected="bind9-dnsutils build-essential ca-certificates curl file git jq less lsof openssh-client pkg-config procps python3 shellcheck tree unzip wget xz-utils zip "
assert_status "apt set matches the decided 19 exactly" "$apt_set" "$apt_expected"

# Each pin must sit on the ADD that names its URL, so a swapped digest fails.
assert_output "each pinned download sits on its ADD" \
  "$(grep -oE 'sha256:[0-9a-f]+|https://github.com/[^ ]+' "$df" | paste -d' ' - -)" \
  "sha256:a31542ee4d660b048d9ddc8f60ed024bff13bd292c08fecde5739ef7a5721dbc https://github.com/jdx/mise/releases/download/v2026.9.17/mise-v2026.9.17-linux-x64.tar.xz
sha256:38b907b21b1b04327fb9481c595331d925a67c6ee1aabd0ef419d0b7d12dfb3d https://github.com/mikefarah/yq/releases/download/v4.53.6/yq_linux_amd64.tar.gz
sha256:745765a3b6e360ad76743599ae5c42e9278c7edf8bbff9fc76d05bf2623a04dd https://github.com/astral-sh/uv/releases/download/0.12.13/uv-x86_64-unknown-linux-gnu.tar.gz"

# HOME=/home/pi (set at every run) lets mise find the mounted config and its
# conf.d fragments. A pinned MISE_GLOBAL_CONFIG_FILE would disable that scan.
assert_status "mise discovers its config from HOME, not a pinned file" \
  "$(grep -c 'MISE_GLOBAL_CONFIG_FILE=' "$df" || true)" "0"
assert_contains "the mise data dir lives in the mounted store" \
  "$df_body" "MISE_DATA_DIR=/home/pi/.local/share/mise"

# The rejected decisions stay rejected.
bad_names=()
for name in "strip /usr/local/bin/mise" git-issues "npm install"; do
  grep -qF "$name" "$df_body" && bad_names+=("$name")
done
assert_status "rejected decisions stay rejected" "${#bad_names[@]}" "0"

printf '== no retired names\n'
# The pattern is split so this test file does not match its own search.
if grep -Eq 'varia[n]ts|config[-]seeds|PIW_DEFAULT_PROFILE|pi-harness' "$SANDBOX/piw"; then
  bad "piw names no retired variant paths"
else
  ok "piw names no retired variant paths"
fi

printf '== seed: settings.json holds the pi defaults\n'
assert_output "the seed settings.json holds the pi defaults" \
  "$(cat "$SANDBOX/seed/settings.json")" \
  "$(cat <<'SETTINGS'
{
  "enableSkillCommands": true,
  "packages": [
    "npm:pi-web-access",
    "npm:@gotgenes/pi-permission-system",
    "npm:pi-intercom",
    "npm:pi-time-awareness",
    "npm:@gotgenes/pi-subagents"
  ]
}
SETTINGS
)"
assert_absent "seed/extensions.txt is gone" "$SANDBOX/seed/extensions.txt"

printf '== settings seed once\n'
rm -f "$SANDBOX/.local/agent/settings.json"
sync_label
piw "$WORK/proj" >/dev/null 2>&1
assert_exists "launch seeds settings.json" "$SANDBOX/.local/agent/settings.json"
printf '{"packages":["npm:custom"]}\n' > "$SANDBOX/.local/agent/settings.json"
piw "$WORK/proj" >/dev/null 2>&1
assert_output "keeps an edited settings.json" \
  "$(cat "$SANDBOX/.local/agent/settings.json")" '{"packages":["npm:custom"]}'

printf '== extensions machinery is gone\n'
if grep -qE 'sync_extensions_for|_pkg_mount_dir|_pkg_installed_version' "$SANDBOX/piw"; then
  bad "piw still names the extensions machinery"
else
  ok "piw no longer names the extensions machinery"
fi

printf '== layers: list and show\n'
rm -rf "$SANDBOX/.local/layers"
mkdir -p "$SANDBOX/.local/layers/my-own"
printf '#!/bin/sh\n' > "$SANDBOX/.local/layers/my-own/install.sh"
printf 'My own bits\n' > "$SANDBOX/.local/layers/my-own/README.md"
printf '[layers]\nrun:my-own\n' > "$SANDBOX/.local/piw.conf"
out="$(piw layer list 2>&1)"
assert_output "layer list shows shipped and active layers with descriptions" \
  "$(printf 'status=%s\n%s' "$?" "$out")" \
  "status=0
NAME           STATUS     DESCRIPTION
my-own         active     My own bits
updatable      available  Updatable layer
workstation    available  Full toolbox: compilers, forensics, infra"

out="$(piw layer show workstation 2>&1)"
assert_output "layer show prints the shipped layer's contents" \
  "$(printf 'status=%s\n%s' "$?" "$out")" \
  "status=0
Layer: workstation
Source: shipped
Directory: $SANDBOX/layers/workstation

apt packages:
  clang
  nmap

archives:
  https://example.test/x.tar.gz deadbeef /tmp/x.tar.gz

mise.toml: yes
install.sh: yes"

printf '== layers: add adopts a shipped layer\n'
rm -rf "$SANDBOX/.local/layers"
printf '# starter\n[layers]\n# none\n\n[pi]\nnpm:pi-intercom\n' > "$SANDBOX/.local/piw.conf"
out="$(piw layer add workstation 2>&1)"
status=$?
assert_output "adopting a shipped layer reports both ways forward" \
  "$(printf 'status=%s\n%s' "$status" "$out")" \
  "status=0
Adopted shipped layer 'workstation' into $SANDBOX/.local/layers/workstation.
  Wrote the .piw-origin stamp and added 'run:workstation' to $SANDBOX/.local/piw.conf.

Two ways forward:
  1. Edit the layer files by hand under .local/layers/.
  2. Launch piw with the harness directory as the workspace, then edit
     the same files from inside the container."

if [[ -d "$SANDBOX/.local/layers/workstation" \
  && -f "$SANDBOX/.local/layers/workstation/.piw-origin" ]]; then
  ok "adopt copies the layer directory and its stamp"
else
  bad "adopt copies the layer directory and its stamp"
fi
stamp_file="$SANDBOX/.local/layers/workstation/.piw-origin"
stamp="$(cat "$stamp_file")"
if [[ "$(wc -l < "$stamp_file")" -eq 1 && "$stamp" =~ ^[0-9a-f]{64}$ ]]; then
  ok "the origin stamp is one sha256 line"
else
  bad "the origin stamp is one sha256 line (got: $stamp)"
fi
assert_output "adopt appends run:<name> inside [layers], keeping the rest" \
  "$(cat "$SANDBOX/.local/piw.conf")" \
  "# starter
[layers]
# none

run:workstation
[pi]
npm:pi-intercom"

out="$(piw layer add workstation 2>&1)"
status=$?
assert_output "re-adding an adopted layer names layer update" \
  "$(printf 'status=%s\n%s' "$status" "$out")" \
  "status=1
ERROR: Layer 'workstation' is already present at $SANDBOX/.local/layers/workstation.
  Use 'piw layer update workstation' to update it."

# A manifest without a trailing newline must not glue the new entry onto the
# last line.
printf '# starter\n[layers]\nrun:first' > "$SANDBOX/.local/piw.conf"
piw layer add apt:zsh >/dev/null 2>&1
conf="$(cat "$SANDBOX/.local/piw.conf")"
if printf '%s\n' "$conf" | grep -qx 'apt:zsh' \
  && printf '%s\n' "$conf" | grep -qx 'run:first'; then
  ok "appends after a file with no trailing newline"
else
  bad "appends after a file with no trailing newline"
fi

printf '== layers: add scaffolds without a shipped layer\n'
rm -rf "$SANDBOX/.local/layers/my-own"
out="$(piw layer add my-own 2>&1)"
status=$?
assert_output "scaffolding a new layer reports both ways forward" \
  "$(printf 'status=%s\n%s' "$status" "$out")" \
  "status=0
Scaffolded layer 'my-own' at $SANDBOX/.local/layers/my-own.
  Added 'run:my-own' to $SANDBOX/.local/piw.conf.

Two ways forward:
  1. Edit the layer files by hand under .local/layers/.
  2. Launch piw with the harness directory as the workspace, then edit
     the same files from inside the container."
assert_output "the scaffold install.sh is a commented starter" \
  "$(cat "$SANDBOX/.local/layers/my-own/install.sh")" \
  "$(cat <<'STARTER'
#!/usr/bin/env bash
# Layer install script. It runs as root inside the image, at build time.
#
# apt packages and archives belong in the `apt` and `archives` files beside
# this script. Use this script for anything they cannot express.
#
# Every command must be non-interactive and safe to rerun.
set -euo pipefail

# Example:
#   install -m 0755 ./tool /usr/local/bin/tool
STARTER
)"
assert_contains "scaffold appends run:<name>" \
  "$(cat "$SANDBOX/.local/piw.conf")" "run:my-own"

printf '== layers: add apt: appends the line\n'
piw layer add apt:zsh gdb >/dev/null 2>&1
assert_contains "appends the apt entry as-is" \
  "$(cat "$SANDBOX/.local/piw.conf")" "apt:zsh gdb"

printf '== layers: remove drops the entry, keeps the directory\n'
out="$(piw layer remove my-own 2>&1)"
status=$?
assert_output "remove drops the run entry, keeps the directory, and says so" \
  "$(printf 'status=%s\n%s' "$status" "$out")" \
  "status=0
Removed 'my-own' from $SANDBOX/.local/piw.conf.
Kept the layer directory: $SANDBOX/.local/layers/my-own
  Remove it by hand if you no longer need it."
assert_not_contains "removes the run: entry" \
  "$(cat "$SANDBOX/.local/piw.conf")" "run:my-own"
assert_exists "keeps the layer directory" "$SANDBOX/.local/layers/my-own"

printf '== layers: update reports the five drift cases\n'
UPD="$SANDBOX/layers/updatable"
git -C "$SANDBOX" checkout -- layers/updatable

# 2. No stamp: report and do nothing.
rm -rf "$SANDBOX/.local/layers/updatable"
mkdir -p "$SANDBOX/.local/layers/updatable"
printf 'alpha\n' > "$SANDBOX/.local/layers/updatable/apt"
out="$(piw layer update updatable 2>&1)"
status=$?
assert_output "a layer with no stamp is reported, not guessed at" \
  "$(printf 'status=%s\n%s' "$status" "$out")" \
  "status=0
Layer 'updatable' was not adopted by piw (no .piw-origin stamp).
  Nothing to do. A hand-copied layer is left alone."
assert_absent "no stamp: writes nothing" "$SANDBOX/.local/layers/updatable/.piw-origin"

# 3. Identical: already up to date.
rm -rf "$SANDBOX/.local/layers/updatable"
printf '[layers]\nrun:updatable\n' > "$SANDBOX/.local/piw.conf"
piw layer add updatable >/dev/null 2>&1
out="$(piw layer update updatable 2>&1)"
assert_output "an untouched adopted layer is already up to date" \
  "$(printf 'status=%s\n%s' "$?" "$out")" \
  "status=0
Layer 'updatable' is already up to date."

# 4. The copy matches its stamp: apply the update.
printf 'beta\n' >> "$UPD/apt"
out="$(piw layer update updatable 2>&1)"
assert_output "an untouched copy takes the shipped update" \
  "$(printf 'status=%s\n%s' "$?" "$out")" \
  "status=0
Updated layer 'updatable' from the shipped copy.
  Rewrote the .piw-origin stamp."
assert_output "the update copies the new content" \
  "$(cat "$SANDBOX/.local/layers/updatable/apt")" "alpha
beta"
git -C "$SANDBOX" checkout -- layers/updatable

# 5. The copy differs from its stamp: print the diff, write nothing.
rm -rf "$SANDBOX/.local/layers/updatable"
printf '[layers]\nrun:updatable\n' > "$SANDBOX/.local/piw.conf"
piw layer add updatable >/dev/null 2>&1
printf 'local-change\n' >> "$SANDBOX/.local/layers/updatable/apt"
printf 'upstream-change\n' >> "$UPD/apt"
out="$(piw layer update updatable 2>&1)"
status=$?
selected="$(printf '%s\n' "$out" | grep -E 'has local changes|local-change|upstream-change|piw layer update updatable --replace')"
assert_output "an edited copy shows the diff and names the override" \
  "$(printf 'status=%s\n%s' "$status" "$selected")" \
  "status=0
Layer 'updatable' has local changes since adoption.
-local-change
+upstream-change
    piw layer update updatable --replace"
assert_output "an edited copy writes nothing" \
  "$(cat "$SANDBOX/.local/layers/updatable/apt")" "alpha
local-change"

# 5b. --replace overrides rule 5.
out="$(piw layer update updatable --replace 2>&1)"
assert_output "replace applies the update" \
  "$(printf 'status=%s\n%s' "$?" "$out")" \
  "status=0
Updated layer 'updatable' from the shipped copy.
  Rewrote the .piw-origin stamp."
assert_output "replace brings the shipped content and drops the local change" \
  "$(cat "$SANDBOX/.local/layers/updatable/apt")" "alpha
upstream-change"
git -C "$SANDBOX" checkout -- layers/updatable

printf '== update: four steps\n'
# No layers, so step 4 runs in piw:default.
printf '[layers]\n' > "$SANDBOX/.local/piw.conf"
PIW_TEST_IMAGES="piw:default"
PIW_TEST_LABELS=""
: > "$PIW_TEST_GIT_LOG"
reset_log
# Make a seeded file differ, so step 2 has something to report.
printf '{"packages":["npm:custom"]}\n' > "$SANDBOX/.local/agent/settings.json"
out="$(piw update 2>&1)"
status=$?
assert_status "update exits 0" "$status" "0"
assert_output "update pulls with ff-only" \
  "$(cat "$PIW_TEST_GIT_LOG")" "git -C $SANDBOX pull --ff-only"
assert_contains "update reports seeded drift" "$out" "DIFFERS from the seed"
assert_output "update rebuilds the default image" \
  "$(log | grep '^build ' | head -1)" \
  "build -f $SANDBOX/Dockerfile -t piw:default $SANDBOX --label piw.plan=$(piw_fn default_plan_hash)"
assert_contains "update runs pi update --all" "$(log)" "piw:default pi update --all"

# --force passes through to pi update.
: > "$PIW_TEST_GIT_LOG"
reset_log
out="$(piw update --force 2>&1)"
assert_contains "update --force passes --force" "$(log)" \
  "piw:default pi update --all --force"

# --dry-run prints the four steps and executes none.
: > "$PIW_TEST_GIT_LOG"
reset_log
out="$(piw update --dry-run 2>&1)"
status=$?
assert_output "update --dry-run prints the four steps and executes none" \
  "$(printf 'status=%s\ndocker=%s\ngit=%s\n%s' "$status" "$(log)" "$(cat "$PIW_TEST_GIT_LOG")" "$out")" \
  "$(cat <<'DRY'
status=0
docker=
git=
piw update

1. Pull the harness
   (dry-run) Would run: git pull --ff-only

2. Seeded config drift (a diff is a report, not a failure)
   (dry-run) Would report settings.json, models.json, permissions, piw.conf, and mise/config.toml

3. Rebuild
   (dry-run) Would run: piw build

4. Update pi
   (dry-run) Would run in piw:default: pi update --all

✓ (dry-run) Nothing executed. Run without --dry-run to apply.
DRY
)"

# A divergent pull fails loudly and stops before the build.
: > "$PIW_TEST_GIT_LOG"
reset_log
export PIW_TEST_PULL_FAIL=1
out="$(piw update 2>&1)"
status=$?
unset PIW_TEST_PULL_FAIL
assert_output "a divergent pull fails loudly and stops before the build" \
  "$(printf 'status=%s\nbuilds=%s\n%s' "$status" "$(log | grep '^build ')" "$out")" \
  "status=1
builds=
piw update

1. Pull the harness
   git pull --ff-only
fatal: Not possible to fast-forward, aborting.
ERROR: git pull --ff-only failed.
  The branch diverged from the remote, or local changes overlap.
  Resolve it by hand, then retry. piw does not merge."

printf '== doctor: four checks, drift is a report\n'
rm -rf "$SANDBOX/.local/layers"
printf '[layers]\n' > "$SANDBOX/.local/piw.conf"
# The seeded global manifest declares git-issues, so the stub must list it.
cp "$SANDBOX/seed/mise/config.toml" "$SANDBOX/.local/mise/config.toml"
export PIW_TEST_MISE_LS="go:github.com/steviee/git-issues 0.0.0"
PIW_TEST_IMAGES="piw:default"
out="$(piw doctor 2>&1)"
status=$?
assert_output "doctor reports four checks and the exit-code rule" \
  "$(printf 'status=%s\n%s' "$status" \
    "$(printf '%s\n' "$out" | grep -E '^(piw doctor|1\. Docker|2\. Image|3\. Store|4\. Seeds|Exit code rule)')")" \
  "status=0
piw doctor
1. Docker
2. Image
3. Store
4. Seeds (a diff is a report, not a failure)
Exit code rule: 0 when checks 1-3 pass, 1 when any of them fails."

# A seeded diff is reported and does not fail.
printf '{"packages":["npm:custom"]}\n' > "$SANDBOX/.local/agent/settings.json"
out="$(piw doctor 2>&1)"
status=$?
if [[ "$status" == 0 && "$out" == *"DIFFERS from the seed"* ]]; then
  ok "a seeded diff is reported and does not fail doctor"
else
  bad "a seeded diff is reported and does not fail doctor (status $status)"
fi

# Check 3: a declared tool that mise does not list fails; one that it lists
# passes. The stub prints PIW_TEST_MISE_LS for `mise ls`.
export PIW_TEST_MISE_LS=""
printf '[tools]\n"npm:typescript" = "latest"\n' > "$SANDBOX/.local/mise/config.toml"
out="$(piw doctor 2>&1)"
status=$?
if [[ "$status" == 1 && "$out" == *"MISSING: npm:typescript"* ]]; then
  ok "a missing store tool fails doctor and is named"
else
  bad "a missing store tool fails doctor and is named (status $status)"
fi
PIW_TEST_MISE_LS="npm:typescript 7.0.2"
out="$(piw doctor 2>&1)"
status=$?
if [[ "$status" == 0 && "$out" == *"installed: npm:typescript"* ]]; then
  ok "an installed store tool passes doctor and is reported"
else
  bad "an installed store tool passes doctor and is reported (status $status)"
fi
PIW_TEST_MISE_LS=""

# Check 2: a missing image fails.
PIW_TEST_IMAGES=""
out="$(piw doctor 2>&1)"
status=$?
if [[ "$status" == 1 && "$out" == *"MISSING"* ]]; then
  ok "a missing image fails doctor and is named"
else
  bad "a missing image fails doctor and is named (status $status)"
fi
PIW_TEST_IMAGES=""

printf '== catalog: hidden skills only\n'
# The fixture lives outside the sandbox, so the generated tree never touches
# the tracked sandbox. The four misc skills are marked hidden here to prove
# that the generator walks every bucket, including misc.
CATFIX="$WORK/catalog"
mkdir -p "$CATFIX/skills/system/hidden-skill" \
  "$CATFIX/skills/system/visible-skill" \
  "$CATFIX/skills/vendor/acme/skills/misc/alpha" \
  "$CATFIX/skills/vendor/acme/skills/misc/beta" \
  "$CATFIX/skills/vendor/acme/skills/misc/gamma" \
  "$CATFIX/skills/vendor/acme/skills/misc/delta"
cp "$ROOT/skills/generate-catalog.sh" "$CATFIX/skills/generate-catalog.sh"

printf -- '---\nname: hidden-skill\ndescription: A hidden skill the catalog must list.\ndisable-model-invocation: true\n---\n' \
  > "$CATFIX/skills/system/hidden-skill/SKILL.md"
printf -- '---\nname: visible-skill\ndescription: A visible skill the catalog must omit.\n---\n' \
  > "$CATFIX/skills/system/visible-skill/SKILL.md"
for n in alpha beta gamma delta; do
  printf -- '---\nname: misc-%s\ndescription: The %s skill in the misc bucket.\ndisable-model-invocation: true\n---\n' \
    "$n" "$n" > "$CATFIX/skills/vendor/acme/skills/misc/$n/SKILL.md"
done

catalog_one="$(bash "$CATFIX/skills/generate-catalog.sh" 2>/dev/null)"
catalog_two="$(bash "$CATFIX/skills/generate-catalog.sh" 2>/dev/null)"
assert_contains "the catalog lists a hidden skill" "$catalog_one" '`hidden-skill`'
assert_not_contains "the catalog omits a visible skill" "$catalog_one" 'visible-skill'
for n in alpha beta gamma delta; do
  assert_contains "the four misc skills appear: $n" "$catalog_one" "misc-$n"
done
assert_contains "an entry names the path" "$catalog_one" '`system/hidden-skill/SKILL.md`'
assert_output "two runs are byte-identical" "$catalog_two" "$catalog_one"
entry_total="$(printf '%s\n' "$catalog_one" | grep -c '^- \*\*' || true)"
path_total="$(printf '%s\n' "$catalog_one" | grep -c 'SKILL\.md`)$' || true)"
empty_total="$(printf '%s\n' "$catalog_one" | grep -c ' -  (' || true)"
assert_status "the catalog holds the five hidden skills" "$entry_total" "5"
assert_status "every entry has a path" "$path_total" "$entry_total"
assert_status "no entry has an empty description" "$empty_total" "0"

printf '== catalog: a missing description fails loudly\n'
ERRFIX="$WORK/catalog-broken"
mkdir -p "$ERRFIX/skills/system/broken"
cp "$ROOT/skills/generate-catalog.sh" "$ERRFIX/skills/generate-catalog.sh"
printf -- '---\nname: broken\ndisable-model-invocation: true\n---\n' \
  > "$ERRFIX/skills/system/broken/SKILL.md"
out="$(bash "$ERRFIX/skills/generate-catalog.sh" 2>&1)"
status=$?
assert_output "a missing description exits non-zero and names the skill" \
  "$(printf 'status=%s\n%s' "$status" "$out")" \
  "status=1
ERROR: broken has no readable description (system/broken/SKILL.md)"

printf '== piw generate-catalog runs in the container\n'
reset_log
out="$(piw generate-catalog 2>&1)"
status=$?
assert_status "generate-catalog exits 0" "$status" "0"
assert_contains "generate-catalog runs the generator in the container" \
  "$(log)" "bash /home/pi/.pi/agent/skills/generate-catalog.sh"
assert_not_contains "generate-catalog does not call host python3" "$(log)" "python3"
assert_exists "generate-catalog writes the catalog on the host" \
  "$SANDBOX/skills/catalog.md"

printf '== layers: the shipped workstation layer\n'
# The shipped layer is inert until adopted. Adoption copies it into
# .local/layers/, which is what `piw layer add` does.
rm -rf "$SANDBOX/.local/layers"
mkdir -p "$SANDBOX/.local/layers"
cp -r "$ROOT/layers/workstation" "$SANDBOX/.local/layers/workstation"
printf '[layers]\nrun:workstation\n' > "$SANDBOX/.local/piw.conf"

out="$(piw layer show workstation 2>&1)"
show_summary="$(printf '%s\n' "$out" | awk '
  /^apt packages:/ {sec="apt"; next}
  /^archives:/ {sec="arch"; next}
  /^mise.toml: yes/ {mise=1; next}
  /^install.sh: yes/ {script=1; next}
  sec=="apt" && /^  / {a++}
  sec=="arch" && /^  / {r++}
  END {printf "apt=%d arch=%d mise=%d script=%d", a, r, mise, script}
')"
assert_output "layer show names the 25 apt packages, 3 archives, mise table, and script" \
  "$show_summary" "apt=25 arch=3 mise=1 script=1"

plan="$(piw_fn compose_plan 2>&1)"
plan_summary="$(printf '%s\n' "$plan" | awk '
  /^RUN apt-get update/ {apt++}
  /^        [a-z]/ {pkg++}
  /^ADD --checksum=/ {add++}
  /^COPY workstation\// {copy++}
  /^RUN bash \/tmp\/piw-layer-workstation\/install.sh/ {run++}
  END {printf "apt=%d pkgs=%d add=%d copy=%d run=%d", apt, pkg, add, copy, run}
')"
assert_output "the shipped layer composes one apt install, three archives, and the script" \
  "$plan_summary" "apt=1 pkgs=25 add=3 copy=1 run=1"

printf '== layers: the shipped pre-publish layer\n'
rm -rf "$SANDBOX/.local/layers"
mkdir -p "$SANDBOX/.local/layers"
cp -r "$ROOT/layers/pre-publish" "$SANDBOX/.local/layers/pre-publish"
printf '[layers]\nrun:pre-publish\n' > "$SANDBOX/.local/piw.conf"

out="$(piw layer show pre-publish 2>&1)"
if [[ "$out" == *"libimage-exiftool-perl"* && "$out" == *"mise.toml: yes"* && "$out" == *"install.sh: yes"* ]]; then
  ok "layer show names the pre-publish apt package, mise table, and script"
else
  bad "layer show names the pre-publish apt package, mise table, and script"
fi

if grep -q '^gitleaks' "$ROOT/layers/pre-publish/mise.toml" \
   && grep -q '^git-filter-repo' "$ROOT/layers/pre-publish/mise.toml" \
   && grep -q '^libimage-exiftool-perl' "$ROOT/layers/pre-publish/apt"; then
  ok "the pre-publish layer declares gitleaks, git-filter-repo, and exiftool"
else
  bad "the pre-publish layer declares gitleaks, git-filter-repo, and exiftool"
fi

plan="$(piw_fn compose_plan 2>&1)"
plan_summary="$(printf '%s\n' "$plan" | awk '
  /apt-get install/ {apt++}
  /^        libimage-exiftool-perl/ {pkg++}
  /^COPY pre-publish\// {copy++}
  /^RUN bash \/tmp\/piw-layer-pre-publish\/install.sh/ {run++}
  END {printf "apt=%d pkg=%d copy=%d run=%d", apt, pkg, copy, run}
')"
assert_output "the pre-publish layer composes its apt package and script" \
  "$plan_summary" "apt=1 pkg=1 copy=1 run=1"

printf '== sandbox stays clean\n'
if [[ -z "$(git -C "$SANDBOX" status --porcelain)" ]]; then
  ok "piw writes only into the ignored namespace"
else
  bad "piw mutated the tracked tree:"
  git -C "$SANDBOX" status --porcelain | sed 's/^/    /'
fi
stray=()
for p in .pi extensions .env; do
  [[ -e "$SANDBOX/$p" ]] && stray+=("$p")
done
assert_status "no stray root artifacts" "${#stray[@]}" "0"

# ── Result ───────────────────────────────────────────────────────────────────
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
