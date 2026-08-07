#!/usr/bin/env bash
# generate-catalog.sh — scan all skills and produce skills/catalog.md
#
# Usage:
#   ./skills/generate-catalog.sh            # regenerate catalog.md
#   ./skills/generate-catalog.sh <path>      # write to <path> instead
#
# Scans skills/system/ and skills/vendor/ for SKILL.md files,
# extracts frontmatter metadata, and writes a unified catalog.
#
# Future: wire into piw build (piw generate-catalog) and/or git hooks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CATALOG="${1:-$SCRIPT_DIR/catalog.md}"

# ── helpers ──────────────────────────────────────────────────────────────────

# Extract a frontmatter field from a SKILL.md using Python YAML parser.
# Handles folded (>), literal (|), and plain scalar values.
_yaml_field() {
  local file="$1" field="$2"
  python3 -c "
import yaml, sys
with open('$file') as f:
    content = f.read()
parts = content.split('---', 2)
if len(parts) >= 2:
    data = yaml.safe_load(parts[1])
    val = data.get('$field', '')
    if val:
        print(str(val).replace(chr(10), ' '))
" 2>/dev/null || echo ""
}

# Check if a skill file has disable-model-invocation: true
_is_hidden() {
  local file="$1"
  grep -q 'disable-model-invocation: *true' "$file" 2>/dev/null
}

# Determine if a skill references setup-matt-pocock-skills (needs a tracker)
_needs_tracker() {
  local file="$1"
  grep -q 'setup-matt-pocock-skills' "$file" 2>/dev/null
}

# ── write catalog header ────────────────────────────────────────────────────

cat > "$CATALOG" << 'HEADER'
# Skills catalog

All available skills in this harness, organized by source and theme.
Invoke any skill with `/skill:<name>`.

HEADER

# ── scan system/ skills (built-in) ──────────────────────────────────────────

echo "## System (built-in)" >> "$CATALOG"
echo "" >> "$CATALOG"

has_system=false
for skill_dir in "$SCRIPT_DIR"/system/*/; do
  skill_file="${skill_dir}SKILL.md"
  [[ -f "$skill_file" ]] || continue

  name="$(_yaml_field "$skill_file" "name")"
  desc="$(_yaml_field "$skill_file" "description")"
  hidden=$(_is_hidden "$skill_file" && echo "user-invoked" || echo "model-activated")

  [[ -z "$name" ]] && name="$(basename "$skill_dir")"

  echo "- **\`$name\`** — $desc *($hidden)*" >> "$CATALOG"
  has_system=true
done

if [[ "$has_system" == "false" ]]; then
  echo "*(none)*" >> "$CATALOG"
fi
echo "" >> "$CATALOG"

# ── scan vendor/ skills (external collections) ──────────────────────────────

for vendor_dir in "$SCRIPT_DIR"/vendor/*/; do
  vendor_name="$(basename "$vendor_dir")"
  vendor_skills="$vendor_dir/skills"

  if [[ ! -d "$vendor_skills" ]]; then
    # Some vendors may have skills at a different path — skip
    continue
  fi

  echo "## Vendor: $vendor_name" >> "$CATALOG"
  echo "" >> "$CATALOG"

  # Only include skills from promoted buckets. Non-promoted buckets
  # (in-progress, misc, deprecated) are filtered out.
  # To configure per vendor, create vendor/<name>/.promoted-buckets
  # with one bucket name per line.
  promoted_file="$vendor_dir/.promoted-buckets"
  if [[ -f "$promoted_file" ]]; then
    mapfile -t buckets < "$promoted_file"
  else
    # Default: Matt Pocock's convention
    buckets=(engineering productivity)
  fi

  has_vendor=false
  for bucket in "${buckets[@]}"; do
    bucket_dir="$vendor_skills/$bucket"
    [[ ! -d "$bucket_dir" ]] && continue

    echo "### $bucket" >> "$CATALOG"
    echo "" >> "$CATALOG"

    while IFS= read -r -d '' skill_file; do
      name="$(_yaml_field "$skill_file" "name")"
      desc="$(_yaml_field "$skill_file" "description")"
      hidden=$(_is_hidden "$skill_file" && echo "user-invoked" || echo "model-activated")
      tracker=$(_needs_tracker "$skill_file" && echo " ⚠ needs tracker" || echo "")

      [[ -z "$name" ]] && name="$(basename "$(dirname "$skill_file")")"

      echo "- **\`$name\`** — $desc *(${hidden}${tracker})*" >> "$CATALOG"
      has_vendor=true
    done < <(find "$bucket_dir" -name 'SKILL.md' -print0)

    echo "" >> "$CATALOG"
  done

  if [[ "$has_vendor" == "false" ]]; then
    echo "*(none)*" >> "$CATALOG"
    echo "" >> "$CATALOG"
  fi
done

# ── done ────────────────────────────────────────────────────────────────────

entry_count=$(grep -c '^- \*\*' "$CATALOG" 2>/dev/null || echo 0)
section_count=$(grep -c '^## ' "$CATALOG" 2>/dev/null || echo 0)
section_count=$((section_count))
echo "Wrote $CATALOG"
echo "  Skills: $entry_count across $section_count sections"
