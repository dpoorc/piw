#!/usr/bin/env python3
"""Render the pre-publication report.

Writes report.md to the output directory. Reads optional JSON from the
inventory and tool-check scripts. Never mutates the project.
"""

import argparse
import datetime
import json
import os
import sys

OUTPUT_SUBPATH = os.path.join(".local", "prepublish")


def load_json(path):
    if not path:
        return None
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def render_header(project_root, public_mode, inventory, tools):
    lines = ["## Header", ""]
    lines.append("- Project root: `%s`" % project_root)
    lines.append("- Date: %s" % datetime.date.today().isoformat())
    lines.append("- Public mode: %s" % public_mode)
    if inventory:
        lines.append("- Files: %s" % inventory.get("total_files", "unknown"))
        present = [k for k, v in inventory.get("counts", {}).items() if v]
        lines.append("- Content categories: %s" % (", ".join(sorted(present)) or "none"))
        layers = [m["layer"] for m in inventory.get("meta_layers", []) if m.get("present")]
        lines.append("- Meta layers: %s" % (", ".join(layers) or "none"))
        lines.append("- Mismatches: %s" % len(inventory.get("mismatches", [])))
    if tools:
        missing = tools.get("missing_required", [])
        if missing:
            lines.append("- Required tools missing: %s" % ", ".join(missing))
        else:
            lines.append("- Required tools: all present")
    return lines


def render_known_risks(known_risks):
    lines = ["## Declared known risks", ""]
    if not known_risks:
        lines.append("None declared.")
        return lines
    for item in known_risks:
        lines.append("- [ ] %s - not checked" % item)
    return lines


def render_findings():
    return [
        "## Findings",
        "",
        "None yet. Findings are grouped by severity, each with class,",
        "carrier, location, confidence, and remediation kind.",
    ]


def render_skipped(ran_stages):
    lines = ["## Skipped checks", ""]
    lines.append("Stages that ran: %s" % ", ".join(ran_stages))
    lines.append("")
    lines.append("Carrier checks are skipped when their carrier is absent.")
    lines.append("No skipped check is dropped silently.")
    return lines


def render_plan():
    return [
        "## Suggested remediation plan",
        "",
        "None. Each fix is proposed as an exact action once findings exist.",
    ]


def render_non_findings():
    return [
        "## Non-findings",
        "",
        "Recorded as the scan stages run.",
    ]


def render_readiness(known_risks):
    lines = ["## Readiness summary", ""]
    lines.append("- Blocking findings open: 0")
    lines.append("- Declared known risks: 0 found, 0 not found, %d not checked"
                 % len(known_risks))
    lines.append("")
    lines.append("This is a readiness summary, not a verdict. The skill")
    lines.append("reports coverage and risk. It does not certify a project")
    lines.append("as safe to publish.")
    return lines


def render(project_root, public_mode, known_risks, inventory, tools, ran_stages):
    parts = ["# Pre-publication report", ""]
    parts += render_header(project_root, public_mode, inventory, tools)
    parts.append("")
    parts += render_known_risks(known_risks)
    parts.append("")
    parts += render_findings()
    parts.append("")
    parts += render_skipped(ran_stages)
    parts.append("")
    parts += render_plan()
    parts.append("")
    parts += render_non_findings()
    parts.append("")
    parts += render_readiness(known_risks)
    parts.append("")
    return "\n".join(parts)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", default=".")
    parser.add_argument("--output-dir", default=None)
    parser.add_argument("--public-mode", default="open source")
    parser.add_argument("--known-risk", action="append", default=[])
    parser.add_argument("--inventory", default=None, help="inventory JSON file")
    parser.add_argument("--tools", default=None, help="tool-check JSON file")
    parser.add_argument("--stage", action="append", default=[],
                        help="a stage that ran (repeatable)")
    parser.add_argument("--stdout", action="store_true")
    args = parser.parse_args()

    project_root = os.path.abspath(args.project_root)
    output_dir = args.output_dir or os.path.join(project_root, OUTPUT_SUBPATH)
    os.makedirs(output_dir, exist_ok=True)

    inventory = load_json(args.inventory)
    tools = load_json(args.tools)
    stages = args.stage or ["intake"]

    text = render(project_root, args.public_mode, args.known_risk,
                  inventory, tools, stages)

    report_path = os.path.join(output_dir, "report.md")
    with open(report_path, "w", encoding="utf-8") as handle:
        handle.write(text)

    if args.stdout:
        print(text)
    else:
        print("Wrote %s" % report_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
