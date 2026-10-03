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
# frontmatter with python3 and the standard library only. A hidden skill whose
# description cannot be read is an error that names the skill. The output is
# sorted, so two runs are byte-identical.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="${1:-}"

generate() {
  python3 - "$SCRIPT_DIR" <<'PY'
import json
import os
import re
import sys

KEY = re.compile(r"^([A-Za-z0-9_-]+):[ \t]*(.*)$")
BLOCK = (">", "|", ">-", "|-", ">+", "|+")


def parse_frontmatter(text):
    """Return the frontmatter as a dict. Raise ValueError when it is broken.

    The fields are simple: `key: value`, or a folded (`>`) or literal (`|`)
    block. No third-party parser is needed.
    """
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}
    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break
    if end is None:
        raise ValueError("unterminated frontmatter")
    fields = lines[1:end]
    data = {}
    i = 0
    while i < len(fields):
        match = KEY.match(fields[i])
        if not match:
            i += 1
            continue
        key = match.group(1)
        value = match.group(2).strip()
        if value in BLOCK:
            block = []
            i += 1
            while i < len(fields) and (
                fields[i].strip() == "" or fields[i][0] in (" ", "\t")
            ):
                block.append(fields[i])
                i += 1
            indents = [len(x) - len(x.lstrip()) for x in block if x.strip()]
            trim = min(indents) if indents else 0
            parts = [x[trim:].strip() for x in block]
            value = " ".join(p for p in parts if p)
        elif len(value) >= 2 and value[0] == '"' and value[-1] == '"':
            try:
                value = json.loads(value)
            except ValueError:
                value = value[1:-1]
        elif len(value) >= 2 and value[0] == "'" and value[-1] == "'":
            value = value[1:-1]
        data[key] = value
        i += 1
    return data


def skill_files(root):
    files = []
    for base in ("system", "vendor"):
        top = os.path.join(root, base)
        if not os.path.isdir(top):
            continue
        for dirpath, _dirnames, filenames in os.walk(top):
            if "SKILL.md" in filenames:
                files.append(os.path.join(dirpath, "SKILL.md"))
    files.sort()
    return files


def main():
    root = sys.argv[1]
    entries = []
    for path in skill_files(root):
        rel = os.path.relpath(path, root)
        fallback = os.path.basename(os.path.dirname(path))
        try:
            with open(path, "r", encoding="utf-8") as handle:
                text = handle.read()
        except OSError as exc:
            sys.stderr.write(
                "ERROR: %s is unreadable: %s (%s)\n" % (fallback, exc, rel)
            )
            return 1
        try:
            data = parse_frontmatter(text)
        except ValueError as exc:
            sys.stderr.write("ERROR: %s: %s (%s)\n" % (fallback, exc, rel))
            return 1
        if str(data.get("disable-model-invocation", "")).strip().lower() != "true":
            continue
        name = data.get("name") or fallback
        description = " ".join(str(data.get("description", "")).split())
        if not description:
            sys.stderr.write(
                "ERROR: %s has no readable description (%s)\n" % (name, rel)
            )
            return 1
        entries.append((rel, name, description))

    out = sys.stdout
    out.write("# Skills catalog\n\n")
    out.write("Skills hidden from the system prompt. The system prompt shows the\n")
    out.write("other skills. Load a hidden skill with `/skill:<name>`.\n\n")
    out.write("Paths are relative to the skills root (`~/.pi/agent/skills/`).\n\n")
    for rel, name, description in entries:
        out.write("- **`%s`** - %s (`%s`)\n" % (name, description, rel))
    return 0


if __name__ == "__main__":
    sys.exit(main())
PY
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
