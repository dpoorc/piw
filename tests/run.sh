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

# ── Cases ────────────────────────────────────────────────────────────────────
printf '== piw tool list (namespace creation)\n'
reset_log
piw tool list >/dev/null 2>&1
first_label="$(piw_fn default_plan_hash)"
assert_contains "first-run build writes the plan label" "$(log)" "--label piw.plan=$first_label"
assert_contains "runs in the container" "$(log)" "piw:default mise ls"
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

printf '== piw tool install (every spec goes to mise)\n'
reset_log
piw tool install npm:typescript pypi:ruff go:example.com/x \
  cargo:ripgrep >/dev/null 2>&1
assert_contains "npm spec" "$(log)" "mise use -g npm:typescript"
assert_contains "pypi spec" "$(log)" "mise use -g pypi:ruff"
assert_contains "go spec" "$(log)" "mise use -g go:example.com/x"
assert_contains "cargo spec" "$(log)" "mise use -g cargo:ripgrep"
assert_not_contains "no npm dispatch" "$(log)" "npm install --global"
assert_not_contains "no uv dispatch" "$(log)" "uv tool install"
assert_not_contains "no cargo dispatch" "$(log)" "cargo install --root"
assert_not_contains "no go install dispatch" "$(log)" "go install"

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

printf '== piw tool runs through the container seam\n'
reset_log
piw tool list >/dev/null 2>&1
assert_contains "tool run mounts the store" "$(log)" "-v $SANDBOX/.local/store:/home/pi/.local:z"
assert_contains "tool run mounts the layers read-only" "$(log)" "-v $SANDBOX/.local/layers:/opt/piw/layers:z,ro"
assert_contains "tool run mounts the agent directory" "$(log)" "-v $SANDBOX/.local/agent:/home/pi/.pi/agent:z"
assert_contains "tool run uses the container user" "$(log)" "--user $(id -u):$(id -g)"
assert_contains "tool run runs in the default image" "$(log)" "piw:default mise ls"

printf '== piw build (default image)\n'
reset_log
piw build >/dev/null 2>&1
assert_contains "builds piw:default from the root Dockerfile" "$(log)" \
  "build -f $SANDBOX/Dockerfile -t piw:default $SANDBOX"
default_label="$(piw_fn default_plan_hash)"
assert_contains "writes the default plan label" "$(log)" "--label piw.plan=$default_label"

printf '== piw launch (exact argv)\n'
mkdir -p "$WORK/proj"
sync_label
reset_log
out="$(piw "$WORK/proj" 2>&1)"
status=$?
assert_status "launch exits 0" "$status" "0"
run_line="$(grep '^run ' "$PIW_TEST_DOCKER_LOG" | head -1)"
expected_run="run --rm -it --add-host host.docker.internal:host-gateway"
expected_run+=" --user $(id -u):$(id -g)"
expected_run+=" -e HOME=/home/pi"
expected_run+=" -e YADM_HOME=$TEST_HOME"
expected_run+=" -e PI_CODING_AGENT_DIR=/home/pi/.pi/agent"
expected_run+=" -e npm_config_cache=/tmp/.npm-cache"
expected_run+=" -e npm_config_ignore_scripts=true"
expected_run+=" -v $SANDBOX/.local/agent:/home/pi/.pi/agent:z"
expected_run+=" -v $SANDBOX/.local/store:/home/pi/.local:z"
expected_run+=" -v $SANDBOX/.local/mise:/home/pi/.config/mise:z"
expected_run+=" -v $SANDBOX/.local/app:/opt/pi:z"
expected_run+=" -v $SANDBOX/.local/agents/skills:/home/pi/.agents/skills:z"
expected_run+=" -v $SANDBOX/skills:/home/pi/.pi/agent/skills:z,ro"
expected_run+=" -v $SANDBOX/agents:/home/pi/.pi/agent/agents:z,ro"
expected_run+=" -v $SANDBOX/skills/system/workflow/APPEND_SYSTEM.md:/home/pi/.pi/agent/APPEND_SYSTEM.md:z,ro"
expected_run+=" -v $WORK/proj:$WORK/proj:z"
expected_run+=" -v $SANDBOX/.local/layers:/opt/piw/layers:z,ro"
expected_run+=" -w $WORK/proj piw:default pi"
assert_status "launch argv is exact" "$run_line" "$expected_run"
assert_not_contains "no Anthropic key allowlist flag" "$run_line" "-e ANTHROPIC_API_KEY"
assert_not_contains "no OpenAI key allowlist flag" "$run_line" "-e OPENAI_API_KEY"
assert_not_contains "no Gemini key allowlist flag" "$run_line" "-e GEMINI_API_KEY"

printf '== piw launch passes the env file\n'
printf 'ANTHROPIC_API_KEY=test-key\n' > "$SANDBOX/.local/env"
sync_label
reset_log
out="$(ANTHROPIC_API_KEY=host-only piw "$WORK/proj" 2>&1)"
assert_contains "passes the env file" "$(log)" "--env-file $SANDBOX/.local/env"
assert_not_contains "does not forward a host API key" "$(log)" "-e ANTHROPIC_API_KEY"
rm -f "$SANDBOX/.local/env"

printf '== piw --mode readonly\n'
sync_label
reset_log
out="$(piw --mode readonly "$WORK/proj" 2>&1)"
status=$?
assert_status "readonly launch exits 0" "$status" "0"
assert_contains "readonly workspace is read-only" "$(log)" "-v $WORK/proj:$WORK/proj:z,ro"
assert_contains "readonly store is read-only" "$(log)" "-v $SANDBOX/.local/store:/home/pi/.local:z,ro"
assert_contains "readonly mise config is read-only" "$(log)" "-v $SANDBOX/.local/mise:/home/pi/.config/mise:z,ro"
assert_contains "readonly Agent Skills dir is read-only" "$(log)" "-v $SANDBOX/.local/agents/skills:/home/pi/.agents/skills:z,ro"
assert_contains "readonly mounts the mode config read-only" "$(log)" "-v $SANDBOX/.local/agent/extensions/pi-permission-system/config.readonly.json:/home/pi/.pi/agent/extensions/pi-permission-system/config.json:z,ro"
assert_contains "readonly adds no network" "$(log)" "--network none"
assert_contains "readonly keeps the agent directory writable" "$(log)" "-v $SANDBOX/.local/agent:/home/pi/.pi/agent:z "
assert_not_contains "readonly does not make the agent directory read-only" "$(log)" "-v $SANDBOX/.local/agent:/home/pi/.pi/agent:z,ro"

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
for cmd in build "tool install" "tool remove" "tool list" \
  "layer add" "layer remove" "layer list" "layer show" "layer update" \
  doctor link unlink generate-catalog update --version; do
  assert_contains "help lists 'piw $cmd'" "$out" "piw $cmd"
done
assert_contains "help explains link" "$out" "Put piw on PATH"
assert_contains "help explains unlink" "$out" "Take piw off PATH"

printf '== piw --version\n'
out="$(piw --version 2>&1)"
assert_status "version exits 0" "$?" "0"
if [[ "$out" =~ ^piw\ [0-9]+\.[0-9]+ ]]; then
  ok "--version prints piw <version>"
else
  bad "--version prints piw <version> (got: $out)"
fi

printf '== parser: launch is the default case\n'
mkdir -p "$WORK/proj"
sync_label
reset_log
out="$(piw "$WORK/proj" 2>&1)"
assert_status "piw <path> launches" "$?" "0"
assert_contains "path launch runs pi" "$(log)" " $WORK/proj pi"
reset_log
out="$(piw 2>&1)"
assert_status "bare piw launches" "$?" "0"
assert_contains "bare piw uses the current directory" "$(log)" " -w $SANDBOX piw:default pi"
out="$(piw launch 2>&1)"
status=$?
if [[ "$status" -ne 0 ]]; then ok "'launch' is not a command word"; else bad "'launch' is not a command word"; fi
assert_contains "'launch' is read as a workspace path" "$out" "Workspace not found"

printf '== parser: a flag on the wrong command errors\n'
out="$(piw doctor --no-cache 2>&1)"
assert_status "doctor --no-cache exits 1" "$?" "1"
assert_contains "names the command" "$out" "doctor"
assert_contains "names the offending flag" "$out" "--no-cache"
out="$(piw build --resume 2>&1)"
assert_status "build --resume exits 1" "$?" "1"
assert_contains "build names the offending flag" "$out" "--resume"
out="$(piw tool list --dry-run 2>&1)"
assert_status "tool list --dry-run exits 1" "$?" "1"
assert_contains "tool names the offending flag" "$out" "--dry-run"
out="$(piw doctor --mode permissive 2>&1)"
assert_status "doctor --mode exits 1" "$?" "1"
assert_contains "doctor names --mode" "$out" "--mode"

printf '== parser: retired flags are gone\n'
for flag in --build-only --install-only --install --uninstall; do
  out="$(piw "$flag" 2>&1)"
  assert_status "$flag exits 1" "$?" "1"
  assert_contains "$flag is rejected" "$out" "$flag"
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
assert_exists "install seeds .local/piw.conf" "$SANDBOX/.local/piw.conf"
assert_exists "install seeds .local/mise/config.toml" "$SANDBOX/.local/mise/config.toml"
if diff -q "$SANDBOX/seed/piw.conf" "$SANDBOX/.local/piw.conf" >/dev/null; then
  ok "piw.conf starts as a copy of the starter"
else
  bad "piw.conf starts as a copy of the starter"
fi
if diff -q "$SANDBOX/seed/mise/config.toml" "$SANDBOX/.local/mise/config.toml" >/dev/null; then
  ok "mise config starts as a copy of the starter"
else
  bad "mise config starts as a copy of the starter"
fi

# An edited live file must survive every later run.
printf '# edited by the user\n[layers]\nrun:mine\n' > "$SANDBOX/.local/piw.conf"
printf '# edited by the user\n[tools]\n' > "$SANDBOX/.local/mise/config.toml"
piw link "$WORK/bin-seed2" >/dev/null 2>&1
assert_contains "keeps an edited piw.conf" "$(cat "$SANDBOX/.local/piw.conf")" "run:mine"
assert_contains "keeps an edited mise config" "$(cat "$SANDBOX/.local/mise/config.toml")" "# edited by the user"

# Launch seeds the same two files.
rm -f "$SANDBOX/.local/piw.conf" "$SANDBOX/.local/mise/config.toml"
sync_label
piw "$WORK/proj" >/dev/null 2>&1
assert_exists "launch seeds .local/piw.conf" "$SANDBOX/.local/piw.conf"
assert_exists "launch seeds .local/mise/config.toml" "$SANDBOX/.local/mise/config.toml"

printf '== manifest resolvers\n'
assert_status "piw.conf default path" "$(piw_fn resolve_piw_conf)" "$SANDBOX/.local/piw.conf"
assert_status "absolute PIW_CONF wins" \
  "$(PIW_CONF=/tmp/piw-elsewhere.conf piw_fn resolve_piw_conf)" "/tmp/piw-elsewhere.conf"
assert_status "relative PIW_CONF sits under the harness" \
  "$(PIW_CONF=sub/piw.conf piw_fn resolve_piw_conf)" "$SANDBOX/sub/piw.conf"
assert_status "mise config default path" "$(piw_fn resolve_mise_config)" "$SANDBOX/.local/mise/config.toml"
assert_status "absolute PIW_MISE_CONFIG wins" \
  "$(PIW_MISE_CONFIG=/tmp/mise-elsewhere.toml piw_fn resolve_mise_config)" "/tmp/mise-elsewhere.toml"
assert_status "relative PIW_MISE_CONFIG sits under the harness" \
  "$(PIW_MISE_CONFIG=sub/mise.toml piw_fn resolve_mise_config)" "$SANDBOX/sub/mise.toml"

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
assert_status "good manifest exits 0" "$?" "0"
assert_contains "entry under [layers]" "$out" $'layers\tapt:zsh gdb'
assert_contains "strips a trailing comment" "$out" $'layers\trun:my-setup'
assert_contains "entry under [pi]" "$out" $'pi\tnpm:pi-intercom'
assert_contains "keeps # inside a value" "$out" $'pi\tgit:https://host/repo#v1'
assert_not_contains "drops comments" "$out" "a comment"

printf '[layers]\napt:zsh\n[layers]\napt:gdb\n' > "$FIX/merge.conf"
out="$(PIW_CONF="$FIX/merge.conf" piw_fn parse_piw_conf 2>&1)"
assert_contains "duplicate sections merge (first)" "$out" $'layers\tapt:zsh'
assert_contains "duplicate sections merge (second)" "$out" $'layers\tapt:gdb'

printf 'orphan:entry\n' > "$FIX/orphan.conf"
out="$(PIW_CONF="$FIX/orphan.conf" piw_fn parse_piw_conf 2>"$FIX/err")"
status=$?
assert_status "entry before a section exits non-zero" "$status" "2"
assert_status "entry error writes nothing to stdout" "$out" ""
assert_contains "entry error names the file and line" "$(cat "$FIX/err")" "$FIX/orphan.conf:1"
assert_contains "entry error states the reason" "$(cat "$FIX/err")" "entry before any section"

printf '[layers\napt:zsh\n' > "$FIX/bad-header.conf"
out="$(PIW_CONF="$FIX/bad-header.conf" piw_fn parse_piw_conf 2>"$FIX/err")"
status=$?
assert_status "malformed header exits non-zero" "$status" "2"
assert_status "header error writes nothing to stdout" "$out" ""
assert_contains "header error names the file and line" "$(cat "$FIX/err")" "$FIX/bad-header.conf:1"
assert_contains "header error states the reason" "$(cat "$FIX/err")" "malformed section header"

printf '# only a comment\n\n   \n' > "$FIX/empty.conf"
out="$(PIW_CONF="$FIX/empty.conf" piw_fn parse_piw_conf 2>&1)"
assert_status "comment-only manifest exits 0" "$?" "0"
assert_status "comment-only manifest emits nothing" "$out" ""

printf '[layers]\r\napt:zsh\r\n' > "$FIX/crlf.conf"
out="$(PIW_CONF="$FIX/crlf.conf" piw_fn parse_piw_conf 2>&1)"
assert_contains "CRLF entry parses clean" "$out" $'layers\tapt:zsh'

# The shipped starter must parse to nothing.
out="$(PIW_CONF="$SANDBOX/seed/piw.conf" piw_fn parse_piw_conf 2>&1)"
assert_status "shipped starter exits 0" "$?" "0"
assert_status "shipped starter emits nothing" "$out" ""

printf '== layers: plan composition\n'
LAYERS="$SANDBOX/.local/layers"

# A layer with apt and no script needs no COPY and no install.
rm -rf "$LAYERS"
mkdir -p "$LAYERS/aptonly"
printf 'zsh\ngdb\n' > "$LAYERS/aptonly/apt"
printf '[layers]\nrun:aptonly\n' > "$SANDBOX/.local/piw.conf"
plan="$(piw_fn compose_plan 2>&1)"
assert_contains "apt-only layer emits its packages" "$plan" "zsh"
assert_contains "apt-only layer emits every package" "$plan" "gdb"
assert_not_contains "apt-only layer emits no COPY" "$plan" "COPY"
assert_not_contains "apt-only layer emits no script" "$plan" "install.sh"

# Several layers compose in the declared order.
mkdir -p "$LAYERS/first" "$LAYERS/second"
printf '#!/bin/sh\n' > "$LAYERS/first/install.sh"
printf '#!/bin/sh\n' > "$LAYERS/second/install.sh"
printf '[layers]\nrun:first\nrun:second\n' > "$SANDBOX/.local/piw.conf"
plan="$(piw_fn compose_plan 2>&1)"
first_line="$(printf '%s\n' "$plan" | grep -n '# layer first' | cut -d: -f1)"
second_line="$(printf '%s\n' "$plan" | grep -n '# layer second' | cut -d: -f1)"
if [[ -n "$first_line" && -n "$second_line" && "$first_line" -lt "$second_line" ]]; then
  ok "layers compose in the declared order"
else
  bad "layers compose in the declared order (first=$first_line second=$second_line)"
fi

# Consecutive apt declarations coalesce into one operation.
printf '[layers]\napt:zsh\napt:gdb\nrun:first\n' > "$SANDBOX/.local/piw.conf"
printf 'ripgrep\n' > "$LAYERS/first/apt"
plan="$(piw_fn compose_plan 2>&1)"
count="$(printf '%s\n' "$plan" | grep -c 'apt-get install')"
assert_status "consecutive apt declarations coalesce" "$count" "1"
assert_contains "coalesced group keeps a manifest package" "$plan" "gdb"
assert_contains "coalesced group keeps a layer package" "$plan" "ripgrep"

# A non-apt step between apt declarations keeps them separate.
printf '[layers]\napt:zsh\nrun:first\napt:gdb\n' > "$SANDBOX/.local/piw.conf"
plan="$(piw_fn compose_plan 2>&1)"
count="$(printf '%s\n' "$plan" | grep -c 'apt-get install')"
assert_status "a non-apt step splits apt groups" "$count" "2"

# Archives become one ADD --checksum each.
mkdir -p "$LAYERS/arch"
printf 'https://example.test/x.tar.gz abc123def456 /tmp/x.tar.gz\n' > "$LAYERS/arch/archives"
printf '[layers]\nrun:arch\n' > "$SANDBOX/.local/piw.conf"
plan="$(piw_fn compose_plan 2>&1)"
assert_contains "archive becomes ADD --checksum" "$plan" \
  "ADD --checksum=sha256:abc123def456 https://example.test/x.tar.gz /tmp/x.tar.gz"
assert_not_contains "no hand-written checksum check" "$plan" "sha256sum"
assert_contains "plan states the Dockerfile syntax" "$plan" "# syntax=docker/dockerfile:1.6"

# A malformed archive line stops before Docker.
mkdir -p "$LAYERS/badarch"
printf 'https://example.test/x.tar.gz abc /tmp/x extra\n' > "$LAYERS/badarch/archives"
printf '[layers]\nrun:badarch\n' > "$SANDBOX/.local/piw.conf"
reset_log
out="$(piw build 2>&1)"
status=$?
if [[ "$status" -ne 0 ]]; then ok "malformed archive exits non-zero"; else bad "malformed archive exits non-zero (status $status)"; fi
assert_contains "malformed archive names the file" "$out" "badarch/archives"
assert_status "malformed archive invokes no docker" "$(log)" ""

# An unknown [layers] prefix stops.
printf '[layers]\nbogus:thing\n' > "$SANDBOX/.local/piw.conf"
out="$(piw_fn resolve_layers 2>&1)"
status=$?
assert_status "unknown prefix stops" "$status" "1"
assert_contains "unknown prefix names the entry" "$out" "bogus:thing"

# An empty run: entry stops.
printf '[layers]\nrun:\n' > "$SANDBOX/.local/piw.conf"
out="$(piw_fn resolve_layers 2>&1)"
status=$?
assert_status "empty run entry stops" "$status" "1"

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
assert_status "missing manifest stops" "$status" "1"
assert_contains "missing manifest names the path" "$out" "$WORK/absent-piw.conf"

# A missing run: layer stops before Docker and names the entry and the path.
printf '[layers]\nrun:ghost\n' > "$SANDBOX/.local/piw.conf"
reset_log
out="$(piw build 2>&1)"
status=$?
if [[ "$status" -ne 0 ]]; then ok "missing layer exits non-zero"; else bad "missing layer exits non-zero (status $status)"; fi
assert_contains "missing layer names the entry" "$out" "run:ghost"
assert_contains "missing layer names the expected path" "$out" "$SANDBOX/.local/layers/ghost"
assert_status "missing layer invokes no docker" "$(log)" ""

printf '== layers: build\n'
# A dry run prints the plan and invokes no Docker.
printf '[layers]\nrun:first\n' > "$SANDBOX/.local/piw.conf"
reset_log
out="$(piw build --dry-run 2>&1)"
status=$?
assert_status "dry-run exits 0" "$status" "0"
assert_contains "dry-run prints the base" "$out" "FROM piw:default"
assert_contains "dry-run prints the layer" "$out" "# layer first"
assert_contains "dry-run prints the global store step" "$out" "mise install"
assert_contains "dry-run prints the layer store step" "$out" \
  "mise -C /opt/piw/layers/first install"
assert_status "dry-run invokes no docker" "$(log)" ""

# With layers, piw builds piw:local from stdin with the layers context.
reset_log
out="$(piw build 2>&1)"
status=$?
assert_status "build with layers exits 0" "$status" "0"
assert_contains "builds piw:local from stdin" "$(log)" "build -f - -t piw:local"
assert_contains "writes the plan label" "$(log)" "--label piw.plan="
assert_contains "uses .local/layers as context" "$(log)" "$SANDBOX/.local/layers"
plan_label="$(grep -o 'piw.plan=[0-9a-f]*' "$PIW_TEST_DOCKER_LOG" | head -1 | cut -d= -f2)"
if [[ "$plan_label" =~ ^[0-9a-f]{64}$ ]]; then
  ok "plan label is a sha256"
else
  bad "plan label is a sha256 (got: $plan_label)"
fi

# --no-cache reaches the local build.
reset_log
piw build --no-cache >/dev/null 2>&1
assert_contains "no-cache reaches the local build" "$(log)" \
  "--no-cache $SANDBOX/.local/layers"

# With no layers, piw builds no user image.
printf '[layers]\n' > "$SANDBOX/.local/piw.conf"
reset_log
piw build >/dev/null 2>&1
assert_not_contains "no layers builds no piw:local" "$(log)" "piw:local"

printf '== store: build installs the global and active-layer tools\n'
rm -rf "$LAYERS"
mkdir -p "$LAYERS/alpha" "$LAYERS/beta" "$LAYERS/inactive"
printf '#!/bin/sh\n' > "$LAYERS/alpha/install.sh"
printf '#!/bin/sh\n' > "$LAYERS/beta/install.sh"
printf '#!/bin/sh\n' > "$LAYERS/inactive/install.sh"
printf '[layers]\nrun:alpha\nrun:beta\n' > "$SANDBOX/.local/piw.conf"
reset_log
out="$(piw build 2>&1)"
status=$?
assert_status "build with active layers exits 0" "$status" "0"
assert_contains "installs the global store" "$(log)" "piw:local mise install"
assert_contains "installs the alpha layer store" "$(log)" "mise -C /opt/piw/layers/alpha install"
assert_contains "installs the beta layer store" "$(log)" "mise -C /opt/piw/layers/beta install"
assert_not_contains "does not install an inactive layer" "$(log)" "/opt/piw/layers/inactive"
global_line="$(grep -n -- ' mise install' "$PIW_TEST_DOCKER_LOG" | head -1 | cut -d: -f1)"
alpha_line="$(grep -n -- 'mise -C /opt/piw/layers/alpha install' "$PIW_TEST_DOCKER_LOG" | head -1 | cut -d: -f1)"
beta_line="$(grep -n -- 'mise -C /opt/piw/layers/beta install' "$PIW_TEST_DOCKER_LOG" | head -1 | cut -d: -f1)"
if [[ -n "$global_line" && -n "$alpha_line" && -n "$beta_line" \
  && "$global_line" -lt "$alpha_line" && "$alpha_line" -lt "$beta_line" ]]; then
  ok "store steps run in order: global, alpha, beta"
else
  bad "store steps run in order (global=$global_line alpha=$alpha_line beta=$beta_line)"
fi

printf '== store: survives a rebuild\n'
printf 'marker\n' > "$SANDBOX/.local/store/marker"
reset_log
piw build >/dev/null 2>&1
assert_exists "store contents survive a rebuild" "$SANDBOX/.local/store/marker"
assert_contains "rebuild mounts the existing store" "$(log)" \
  "-v $SANDBOX/.local/store:/home/pi/.local:z"
assert_contains "rebuild reinstalls the global store" "$(log)" " mise install"
assert_contains "rebuild reinstalls the layer store" "$(log)" \
  "mise -C /opt/piw/layers/alpha install"

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
assert_status "launch with layers exits 0" "$?" "0"
run_line="$(grep '^run ' "$PIW_TEST_DOCKER_LOG" | head -1)"
assert_contains "launch with layers uses piw:local" "$run_line" "piw:local"

# Without layers: piw:default and the default Dockerfile hash.
printf '[layers]\n' > "$SANDBOX/.local/piw.conf"
default_label="$(piw_fn default_plan_hash)"
PIW_TEST_IMAGES="piw:default"
PIW_TEST_LABELS="piw:default=$default_label"
reset_log
out="$(piw "$WORK/proj" 2>&1)"
assert_status "launch without layers exits 0" "$?" "0"
run_line="$(grep '^run ' "$PIW_TEST_DOCKER_LOG" | head -1)"
assert_contains "launch without layers uses piw:default" "$run_line" "piw:default"

printf '== launch: staleness check\n'
# A matching label proceeds.
printf '[layers]\n' > "$SANDBOX/.local/piw.conf"
matching_label="$(piw_fn default_plan_hash)"
PIW_TEST_IMAGES="piw:default"
PIW_TEST_LABELS="piw:default=$matching_label"
reset_log
out="$(piw "$WORK/proj" 2>&1)"
assert_status "matching label exits 0" "$?" "0"
assert_contains "matching label launches" "$(log)" "piw:default pi"

# A mismatched label refuses, names the fix, and never builds.
PIW_TEST_LABELS="piw:default=deadbeef"
reset_log
out="$(piw "$WORK/proj" 2>&1)"
assert_status "mismatched label exits 1" "$?" "1"
assert_contains "mismatched label names staleness" "$out" "stale"
assert_contains "mismatched label names the fix" "$out" "piw build"
assert_not_contains "mismatched label invokes no build" "$(log)" "build"

# A missing label refuses.
PIW_TEST_LABELS=""
reset_log
out="$(piw "$WORK/proj" 2>&1)"
assert_status "missing label exits 1" "$?" "1"
assert_contains "missing label names staleness" "$out" "stale"
assert_contains "missing label names the fix" "$out" "piw build"
assert_not_contains "missing label invokes no build" "$(log)" "build"

# A required piw:local that is missing refuses and names piw build.
printf '[layers]\nrun:alpha\n' > "$SANDBOX/.local/piw.conf"
PIW_TEST_IMAGES="piw:default"
PIW_TEST_LABELS=""
reset_log
out="$(piw "$WORK/proj" 2>&1)"
assert_status "missing piw:local exits 1" "$?" "1"
assert_contains "missing piw:local names the image" "$out" "piw:local"
assert_contains "missing piw:local names the fix" "$out" "piw build"
assert_not_contains "missing piw:local invokes no build" "$(log)" "build"

# Leave the manifest with no layers for the later launch tests.
printf '[layers]\n' > "$SANDBOX/.local/piw.conf"

printf '== default Dockerfile\n'
df="$ROOT/Dockerfile"
assert_exists "Dockerfile at the repo root" "$df"
df_body="$(cat "$df" 2>/dev/null || true)"
assert_status "syntax directive is line 1" "$(sed -n '1p' "$df")" "# syntax=docker/dockerfile:1.6"
assert_contains "uses the Node 24 trixie base" "$df_body" "FROM node:24-trixie-slim"
assert_not_contains "does not pin the base digest" "$df_body" "node:24-trixie-slim@"

# The apt set must match the decided 19 exactly, so an extra or a missing
# package fails the suite.
apt_set="$(sed -n '/--no-install-recommends/,/&& rm -rf/p' "$df" | grep -vE 'RUN|rm -rf' | awk '{print $1}' | grep -v '^$' | sort | tr '\n' ' ')"
apt_expected="bind9-dnsutils build-essential ca-certificates curl file git jq less lsof openssh-client pkg-config procps python3 shellcheck tree unzip wget xz-utils zip "
if [[ "$apt_set" == "$apt_expected" ]]; then
  ok "apt set matches the decided 19 exactly"
else
  bad "apt set differs (got: $apt_set)"
fi

# Each pin must sit on the ADD that names its URL, so a swapped digest fails.
mise_block="$(grep -A1 'ADD --checksum=sha256:a31542ee4d660b048d9ddc8f60ed024bff13bd292c08fecde5739ef7a5721dbc' "$df")"
assert_contains "fetches mise with its pin" "$mise_block" "https://github.com/jdx/mise/releases/download/v2026.9.17/mise-v2026.9.17-linux-x64.tar.xz"
yq_block="$(grep -A1 'ADD --checksum=sha256:38b907b21b1b04327fb9481c595331d925a67c6ee1aabd0ef419d0b7d12dfb3d' "$df")"
assert_contains "fetches yq with its pin" "$yq_block" "https://github.com/mikefarah/yq/releases/download/v4.53.6/yq_linux_amd64.tar.gz"
uv_block="$(grep -A1 'ADD --checksum=sha256:745765a3b6e360ad76743599ae5c42e9278c7edf8bbff9fc76d05bf2623a04dd' "$df")"
assert_contains "fetches uv with its pin" "$uv_block" "https://github.com/astral-sh/uv/releases/download/0.12.13/uv-x86_64-unknown-linux-gnu.tar.gz"

assert_contains "points mise at the mounted config" "$df_body" "MISE_GLOBAL_CONFIG_FILE=/home/pi/.config/mise/config.toml"
assert_not_contains "drops the superseded mise path" "$df_body" "MISE_GLOBAL_CONFIG_FILE=/home/pi/.local/mise.toml"

# The rejected decisions stay rejected.
assert_not_contains "does not strip mise" "$df_body" "strip /usr/local/bin/mise"
assert_not_contains "does not ship git-issues" "$df_body" "git-issues"
assert_not_contains "does not install pi" "$df_body" "npm install"

printf '== no retired names\n'
# The pattern is split so this test file does not match its own search.
if grep -Eq 'varia[n]ts|config[-]seeds|PIW_DEFAULT_PROFILE|pi-harness' "$SANDBOX/piw"; then
  bad "piw names no retired variant paths"
else
  ok "piw names no retired variant paths"
fi

printf '== seed: settings.json holds the pi defaults\n'
settings="$(cat "$SANDBOX/seed/settings.json")"
assert_contains "settings enables skill commands" "$settings" '"enableSkillCommands"'
for pkg in \
  npm:pi-web-access \
  npm:@gotgenes/pi-permission-system \
  npm:pi-intercom \
  npm:pi-time-awareness \
  npm:@gotgenes/pi-subagents; do
  assert_contains "settings declares $pkg" "$settings" "$pkg"
done
assert_absent "seed/extensions.txt is gone" "$SANDBOX/seed/extensions.txt"

printf '== settings seed once\n'
rm -f "$SANDBOX/.local/agent/settings.json"
sync_label
piw "$WORK/proj" >/dev/null 2>&1
assert_exists "launch seeds settings.json" "$SANDBOX/.local/agent/settings.json"
printf '{"packages":["npm:custom"]}\n' > "$SANDBOX/.local/agent/settings.json"
piw "$WORK/proj" >/dev/null 2>&1
assert_contains "keeps an edited settings.json" \
  "$(cat "$SANDBOX/.local/agent/settings.json")" "npm:custom"

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
assert_status "layer list exits 0" "$?" "0"
ws_row="$(printf '%s\n' "$out" | grep '^workstation')"
my_row="$(printf '%s\n' "$out" | grep '^my-own')"
assert_contains "list shows the shipped layer" "$ws_row" "workstation"
assert_contains "shipped layer is available" "$ws_row" "available"
assert_contains "list shows the active layer" "$my_row" "my-own"
assert_contains "active layer is active" "$my_row" "active"
assert_contains "shipped description comes from README" "$ws_row" \
  "Full toolbox: compilers, forensics, infra"
assert_contains "active description comes from README" "$my_row" "My own bits"
assert_contains "list names the NAME column" "$out" "NAME"
assert_contains "list names the STATUS column" "$out" "STATUS"

out="$(piw layer show workstation 2>&1)"
assert_status "layer show exits 0" "$?" "0"
assert_contains "show names the shipped source" "$out" "Source: shipped"
assert_contains "show lists an apt package" "$out" "clang"
assert_contains "show lists an archive" "$out" "https://example.test/x.tar.gz"
assert_contains "show reports mise.toml" "$out" "mise.toml: yes"
assert_contains "show reports install.sh" "$out" "install.sh: yes"

printf '== layers: add adopts a shipped layer\n'
rm -rf "$SANDBOX/.local/layers"
printf '# starter\n[layers]\n# none\n\n[pi]\nnpm:pi-intercom\n' > "$SANDBOX/.local/piw.conf"
out="$(piw layer add workstation 2>&1)"
assert_status "layer add exits 0" "$?" "0"
assert_exists "adopt copies the layer directory" "$SANDBOX/.local/layers/workstation"
assert_exists "adopt writes the stamp" "$SANDBOX/.local/layers/workstation/.piw-origin"
assert_contains "adopt appends run:<name>" "$(cat "$SANDBOX/.local/piw.conf")" "run:workstation"
assert_contains "add prints the first way forward" "$out" "by hand"
assert_contains "add prints the second way forward" "$out" "workspace"
stamp_lines="$(wc -l < "$SANDBOX/.local/layers/workstation/.piw-origin")"
assert_status "stamp is one line" "$stamp_lines" "1"
if [[ "$(cat "$SANDBOX/.local/layers/workstation/.piw-origin")" =~ ^[0-9a-f]{64}$ ]]; then
  ok "stamp holds a sha256"
else
  bad "stamp holds a sha256"
fi
conf="$(cat "$SANDBOX/.local/piw.conf")"
assert_contains "keeps the [pi] section" "$conf" "npm:pi-intercom"
assert_contains "keeps the starter comment" "$conf" "# starter"
line_layer="$(printf '%s\n' "$conf" | grep -n 'run:workstation' | cut -d: -f1)"
line_pi="$(printf '%s\n' "$conf" | grep -n '^\[pi\]' | cut -d: -f1)"
if [[ -n "$line_layer" && -n "$line_pi" && "$line_layer" -lt "$line_pi" ]]; then
  ok "appends inside [layers], before [pi]"
else
  bad "appends inside [layers], before [pi] (layer=$line_layer pi=$line_pi)"
fi
out="$(piw layer add workstation 2>&1)"
assert_status "re-adding an adopted layer exits 1" "$?" "1"
assert_contains "re-add names layer update" "$out" "piw layer update workstation"

# A manifest without a trailing newline must not glue the new entry onto the
# last line.
printf '# starter\n[layers]\nrun:first' > "$SANDBOX/.local/piw.conf"
piw layer add apt:zsh >/dev/null 2>&1
conf="$(cat "$SANDBOX/.local/piw.conf")"
if printf '%s\n' "$conf" | grep -qx 'apt:zsh' && printf '%s\n' "$conf" | grep -qx 'run:first'; then
  ok "appends after a file with no trailing newline"
else
  bad "appends after a file with no trailing newline"
fi

printf '== layers: add scaffolds without a shipped layer\n'
rm -rf "$SANDBOX/.local/layers/my-own"
out="$(piw layer add my-own 2>&1)"
assert_status "scaffold exits 0" "$?" "0"
assert_exists "scaffold creates the directory" "$SANDBOX/.local/layers/my-own"
assert_exists "scaffold creates install.sh" "$SANDBOX/.local/layers/my-own/install.sh"
assert_contains "scaffold install.sh is a commented starter" \
  "$(cat "$SANDBOX/.local/layers/my-own/install.sh")" "# Example:"
assert_contains "scaffold appends run:<name>" "$(cat "$SANDBOX/.local/piw.conf")" "run:my-own"

printf '== layers: add apt: appends the line\n'
piw layer add apt:zsh gdb >/dev/null 2>&1
assert_contains "appends the apt entry as-is" "$(cat "$SANDBOX/.local/piw.conf")" "apt:zsh gdb"

printf '== layers: remove drops the entry, keeps the directory\n'
out="$(piw layer remove my-own 2>&1)"
assert_status "remove exits 0" "$?" "0"
assert_not_contains "removes the run: entry" "$(cat "$SANDBOX/.local/piw.conf")" "run:my-own"
assert_exists "keeps the layer directory" "$SANDBOX/.local/layers/my-own"
assert_contains "remove says it kept the directory" "$out" "Kept the layer directory"

printf '== layers: update reports the five drift cases\n'
UPD="$SANDBOX/layers/updatable"
git -C "$SANDBOX" checkout -- layers/updatable

# 2. No stamp: report and do nothing.
rm -rf "$SANDBOX/.local/layers/updatable"
mkdir -p "$SANDBOX/.local/layers/updatable"
printf 'alpha\n' > "$SANDBOX/.local/layers/updatable/apt"
out="$(piw layer update updatable 2>&1)"
assert_status "no stamp: exits 0" "$?" "0"
assert_contains "no stamp: reports not adopted" "$out" "was not adopted"
assert_absent "no stamp: writes nothing" "$SANDBOX/.local/layers/updatable/.piw-origin"

# 3. Identical: already up to date.
rm -rf "$SANDBOX/.local/layers/updatable"
printf '[layers]\nrun:updatable\n' > "$SANDBOX/.local/piw.conf"
piw layer add updatable >/dev/null 2>&1
out="$(piw layer update updatable 2>&1)"
assert_status "identical: exits 0" "$?" "0"
assert_contains "identical: already up to date" "$out" "already up to date"

# 4. The copy matches its stamp: apply the update.
printf 'beta\n' >> "$UPD/apt"
out="$(piw layer update updatable 2>&1)"
assert_status "matches stamp: exits 0" "$?" "0"
assert_contains "matches stamp: applies the update" "$out" "Updated layer"
assert_contains "matches stamp: copies the new content" \
  "$(cat "$SANDBOX/.local/layers/updatable/apt")" "beta"
git -C "$SANDBOX" checkout -- layers/updatable

# 5. The copy differs from its stamp: print the diff, write nothing.
rm -rf "$SANDBOX/.local/layers/updatable"
printf '[layers]\nrun:updatable\n' > "$SANDBOX/.local/piw.conf"
piw layer add updatable >/dev/null 2>&1
printf 'local-change\n' >> "$SANDBOX/.local/layers/updatable/apt"
printf 'upstream-change\n' >> "$UPD/apt"
out="$(piw layer update updatable 2>&1)"
assert_status "local change: exits 0" "$?" "0"
assert_contains "local change: prints the diff" "$out" "local-change"
assert_contains "local change: diff shows the shipped change" "$out" "upstream-change"
assert_contains "local change: names the override" "$out" "piw layer update updatable --replace"
active="$(cat "$SANDBOX/.local/layers/updatable/apt")"
assert_contains "local change: writes nothing (keeps local)" "$active" "local-change"
assert_not_contains "local change: writes nothing (no upstream)" "$active" "upstream-change"

# 5b. --replace overrides rule 5.
out="$(piw layer update updatable --replace 2>&1)"
assert_status "replace: exits 0" "$?" "0"
assert_contains "replace: applies the update" "$out" "Updated layer"
active="$(cat "$SANDBOX/.local/layers/updatable/apt")"
assert_not_contains "replace: drops the local change" "$active" "local-change"
assert_contains "replace: brings the shipped change" "$active" "upstream-change"
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
assert_contains "update pulls" "$(cat "$PIW_TEST_GIT_LOG")" "pull --ff-only"
assert_contains "update reports seeded drift" "$out" "DIFFERS from the seed"
assert_contains "update calls cmd_build" "$(log)" "build -f $SANDBOX/Dockerfile -t piw:default"
assert_contains "update runs pi update --all" "$(log)" "piw:default pi update --all"

# --force passes through to pi update.
: > "$PIW_TEST_GIT_LOG"
reset_log
out="$(piw update --force 2>&1)"
assert_status "update --force exits 0" "$?" "0"
assert_contains "update --force passes --force" "$(log)" "pi update --all --force"

# --dry-run prints the four steps and executes none.
: > "$PIW_TEST_GIT_LOG"
reset_log
out="$(piw update --dry-run 2>&1)"
status=$?
assert_status "update --dry-run exits 0" "$status" "0"
assert_contains "dry-run prints step 1" "$out" "1. Pull the harness"
assert_contains "dry-run prints step 2" "$out" "2. Seeded config drift"
assert_contains "dry-run prints step 3" "$out" "3. Rebuild"
assert_contains "dry-run prints step 4" "$out" "4. Update pi"
assert_status "dry-run invokes no docker" "$(log)" ""
assert_status "dry-run pulls nothing" "$(cat "$PIW_TEST_GIT_LOG")" ""

# A divergent pull fails loudly and stops before the build.
: > "$PIW_TEST_GIT_LOG"
reset_log
export PIW_TEST_PULL_FAIL=1
out="$(piw update 2>&1)"
status=$?
unset PIW_TEST_PULL_FAIL
assert_status "divergent pull exits 1" "$status" "1"
assert_contains "divergent pull says so" "$out" "git pull --ff-only failed"
assert_status "divergent pull invokes no build" "$(log)" ""

printf '== doctor: four checks, drift is a report\n'
rm -rf "$SANDBOX/.local/layers"
printf '[layers]\n' > "$SANDBOX/.local/piw.conf"
PIW_TEST_IMAGES="piw:default"
out="$(piw doctor 2>&1)"
assert_status "doctor exits 0 when checks 1-3 pass" "$?" "0"
assert_contains "doctor has check 1" "$out" "1. Docker"
assert_contains "doctor has check 2" "$out" "2. Image"
assert_contains "doctor has check 3" "$out" "3. Store"
assert_contains "doctor has check 4" "$out" "4. Seeds"
assert_contains "doctor states the exit code rule" "$out" "Exit code rule"

# A seeded diff is reported and does not fail.
printf '{"packages":["npm:custom"]}\n' > "$SANDBOX/.local/agent/settings.json"
out="$(piw doctor 2>&1)"
assert_status "a seeded diff does not fail doctor" "$?" "0"
assert_contains "doctor reports the seeded diff" "$out" "DIFFERS from the seed"

# Check 3: a declared tool that mise does not list fails; one that it lists
# passes. The stub prints PIW_TEST_MISE_LS for `mise ls`.
export PIW_TEST_MISE_LS=""
printf '[tools]\n"npm:typescript" = "latest"\n' > "$SANDBOX/.local/mise/config.toml"
out="$(piw doctor 2>&1)"
assert_status "a missing store tool fails doctor" "$?" "1"
assert_contains "doctor names the missing tool" "$out" "MISSING: npm:typescript"
PIW_TEST_MISE_LS="npm:typescript 7.0.2"
out="$(piw doctor 2>&1)"
assert_status "an installed store tool passes doctor" "$?" "0"
assert_contains "doctor reports the installed tool" "$out" "installed: npm:typescript"
PIW_TEST_MISE_LS=""

# Check 2: a missing image fails.
PIW_TEST_IMAGES=""
out="$(piw doctor 2>&1)"
assert_status "a missing image fails doctor" "$?" "1"
assert_contains "doctor names the missing image" "$out" "MISSING"
PIW_TEST_IMAGES=""

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
