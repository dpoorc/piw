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
# Call a piw function directly, without running a command. The source guard in
# piw stops before main, so only the definitions load.
piw_fn() { (source "$SANDBOX/piw"; "$@"); }
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

printf '== starters seed once\n'
rm -f "$SANDBOX/.local/piw.conf" "$SANDBOX/.local/mise/config.toml"
piw --install "$WORK/bin-seed" >/dev/null 2>&1
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
piw --install "$WORK/bin-seed2" >/dev/null 2>&1
assert_contains "keeps an edited piw.conf" "$(cat "$SANDBOX/.local/piw.conf")" "run:mine"
assert_contains "keeps an edited mise config" "$(cat "$SANDBOX/.local/mise/config.toml")" "# edited by the user"

# Launch seeds the same two files.
rm -f "$SANDBOX/.local/piw.conf" "$SANDBOX/.local/mise/config.toml"
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
