#!/usr/bin/env python3
"""Report required and optional tool availability for pre-publication.

Read-only. Never installs anything.
"""

import argparse
import importlib.util
import json
import shutil
import sys

# kind:
#   required    - always needed for the skill to run its full procedure
#   conditional - needed only when the named condition holds
#   optional    - a coverage enhancer
TOOLS = [
    {
        "name": "gitleaks",
        "kind": "required",
        "when": "always",
        "check": ("cmd", "gitleaks"),
        "purpose": "secret detection in the working tree and git history",
        "install": "add the pre-publish layer: piw layer add pre-publish",
    },
    {
        "name": "exiftool",
        "kind": "conditional",
        "when": "metadata carriers are present",
        "check": ("cmd", "exiftool"),
        "purpose": "file, document, and media metadata",
        "install": "apt install libimage-exiftool-perl",
    },
    {
        "name": "git-filter-repo",
        "kind": "conditional",
        "when": "a git history rewrite is chosen",
        "check": ("cmd", "git-filter-repo"),
        "purpose": "git history rewrite",
        "install": "pip install git-filter-repo",
    },
    {
        "name": "presidio",
        "kind": "conditional",
        "when": "content PII checks run",
        "check": ("module", "presidio_analyzer"),
        "purpose": "content PII detection",
        "install": "add the pre-publish layer: piw layer add pre-publish",
    },
    {
        "name": "trufflehog",
        "kind": "optional",
        "when": "archives, binaries, or live verification are wanted",
        "check": ("cmd", "trufflehog"),
        "purpose": "archive and binary coverage, live verification",
        "install": "https://github.com/trufflesecurity/trufflehog",
    },
    {
        "name": "kingfisher",
        "kind": "optional",
        "when": "an Apache-2.0 secret scanner is preferred",
        "check": ("cmd", "kingfisher"),
        "purpose": "alternative secret scanner",
        "install": "https://github.com/mongodb/kingfisher",
    },
    {
        "name": "titus",
        "kind": "optional",
        "when": "an Apache-2.0 secret scanner is preferred",
        "check": ("cmd", "titus"),
        "purpose": "alternative secret scanner",
        "install": "https://github.com/praetorian-inc/titus",
    },
]


def present(spec):
    kind, value = spec
    if kind == "cmd":
        return shutil.which(value) is not None
    if kind == "module":
        return importlib.util.find_spec(value) is not None
    raise ValueError("unknown check kind: %s" % kind)


def collect():
    rows = []
    for tool in TOOLS:
        row = dict(tool)
        row["present"] = present(tool["check"])
        row.pop("check")
        rows.append(row)
    return rows


def render_text(rows):
    lines = []
    lines.append("Pre-publication tool check")
    lines.append("")
    for kind in ("required", "conditional", "optional"):
        group = [r for r in rows if r["kind"] == kind]
        if not group:
            continue
        lines.append("%s:" % kind)
        for r in group:
            mark = "present" if r["present"] else "MISSING"
            lines.append("  %-16s %-8s  %s" % (r["name"], mark, r["purpose"]))
            if not r["present"]:
                lines.append("      when needed: %s" % r["when"])
                lines.append("      install:     %s" % r["install"])
        lines.append("")
    missing_required = [r["name"] for r in rows if r["kind"] == "required" and not r["present"]]
    if missing_required:
        lines.append("Required tools missing: %s" % ", ".join(missing_required))
        lines.append("Each missing required tool stops its check. There is no weaker fallback.")
    else:
        lines.append("All required tools are present.")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--format", choices=("text", "json"), default="text")
    args = parser.parse_args()

    rows = collect()
    if args.format == "json":
        payload = {
            "tools": rows,
            "missing_required": [r["name"] for r in rows if r["kind"] == "required" and not r["present"]],
            "missing_conditional": [r["name"] for r in rows if r["kind"] == "conditional" and not r["present"]],
            "missing_optional": [r["name"] for r in rows if r["kind"] == "optional" and not r["present"]],
        }
        print(json.dumps(payload, indent=2))
    else:
        print(render_text(rows))
    return 0


if __name__ == "__main__":
    sys.exit(main())
