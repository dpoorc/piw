#!/usr/bin/env bash
# generate-catalog.sh - write the catalog of hidden skills.
#
# Usage:
#   generate-catalog.sh            # write the catalog to stdout
#   generate-catalog.sh <path>     # write the catalog to <path>
#
# The script scans skills/system/ and skills/vendor/ for SKILL.md files. It
# emits only the skills marked `disable-model-invocation: true`, because pi
# already shows the visible skills in the system prompt. It reads the
# frontmatter with yq, a real YAML parser that the default image ships. A
# hidden skill whose description cannot be read is an error that names the
# skill. The output is sorted, so two runs are byte-identical.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="${1:-}"

if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq is not on PATH. The default image ships it." >&2
  exit 1
fi

# ── Print the YAML frontmatter of a SKILL.md ─────────────────────────────────
# The block sits between the first two `---` lines. A missing opener, or an
# unterminated block, is an error.
frontmatter() {
  awk '
    NR == 1 { if ($0 !~ /^---[[:space:]]*$/) exit 1; next }
    /^---[[:space:]]*$/ { found = 1; exit 0 }
    { print }
    END { if (!found) exit 1 }
  ' "$1"
}

# ── Read one frontmatter field as a string ───────────────────────────────────
yaml_field() {
  local fm="$1" key="$2"
  [[ -n "$fm" ]] || return 0
  # The key is a fixed literal from this script, so it is safe to inline.
  printf '%s\n' "$fm" | yq -r ".\"$key\" // \"\""
}

# ── Every SKILL.md under skills/system/ and skills/vendor/ ───────────────────
skill_files() {
  find "$SCRIPT_DIR/system" "$SCRIPT_DIR/vendor" -name SKILL.md -type f 2>/dev/null |
    LC_ALL=C sort
}

generate() {
  local -a names=() descs=() rels=()
  local file rel dir name fm hidden description

  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    rel="${file#"$SCRIPT_DIR"/}"
    dir="$(basename "$(dirname "$file")")"

    if ! fm="$(frontmatter "$file")"; then
      echo "ERROR: $dir has malformed or missing frontmatter ($rel)" >&2
      return 1
    fi

    if ! hidden="$(yaml_field "$fm" "disable-model-invocation")"; then
      echo "ERROR: $dir has malformed frontmatter ($rel)" >&2
      return 1
    fi
    [[ "$hidden" == "true" ]] || continue

    if ! name="$(yaml_field "$fm" "name")"; then
      echo "ERROR: $dir has malformed frontmatter ($rel)" >&2
      return 1
    fi
    [[ -n "$name" ]] || name="$dir"

    if ! description="$(yaml_field "$fm" "description")"; then
      echo "ERROR: $dir has malformed frontmatter ($rel)" >&2
      return 1
    fi
    # Collapse the description to one line, so a folded or literal scalar
    # becomes a single catalog entry.
    description="$(
      printf '%s' "$description" |
        tr '\n' ' ' |
        tr -s '[:space:]' ' ' |
        sed -e 's/^ //' -e 's/ $//'
    )"

    if [[ -z "$description" ]]; then
      echo "ERROR: $name has no readable description ($rel)" >&2
      return 1
    fi

    names+=("$name")
    descs+=("$description")
    rels+=("$rel")
  done < <(skill_files)

  printf '# Skills catalog\n\n'
  printf 'Skills hidden from the system prompt. The system prompt shows the\n'
  printf 'other skills. Load a hidden skill with `/skill:<name>`.\n\n'
  printf 'Paths are relative to the skills root (`~/.pi/agent/skills/`).\n\n'

  local i
  for i in "${!names[@]}"; do
    printf -- '- **`%s`** - %s (`%s`)\n' "${names[$i]}" "${descs[$i]}" "${rels[$i]}"
  done
}

if [[ -n "$OUTPUT" ]]; then
  tmp="${OUTPUT}.tmp.$$"
  trap 'rm -f "$tmp"' EXIT
  generate >"$tmp"
  mv "$tmp" "$OUTPUT"
  trap - EXIT
  echo "Wrote $OUTPUT" >&2
else
  generate
fi
