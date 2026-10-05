#!/usr/bin/env python3
"""Render the pre-publication report.

Writes report.md to the output directory. Reads optional JSON from the
inventory and tool-check scripts. Never mutates the project.
"""

import argparse
import datetime
import json
import os
import re
import sys

OUTPUT_SUBPATH = os.path.join(".local", "prepublish")

SEVERITY_ORDER = ("critical", "high", "medium", "low")


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


def load_findings(paths):
    """Read findings files. Return (findings, skipped_checks, advice)."""
    findings = []
    skipped = []
    advice = []
    for path in paths:
        data = load_json(path)
        if not data:
            continue
        if data.get("status") == "skipped":
            skipped.append({
                "check": data.get("vector", path),
                "reason": data.get("reason", "skipped"),
                "tool": (data.get("tool") or {}).get("name", "unknown"),
            })
        skipped.extend(data.get("skipped_checks", []))
        advice.extend(data.get("advice", []))
        findings.extend(data.get("findings", []))
    return findings, skipped, advice


def render_findings(findings):
    lines = ["## Findings", ""]
    if not findings:
        lines.append("None found by the checks that ran.")
        return lines
    lines.append("%d finding(s)." % len(findings))
    lines.append("")
    for severity in SEVERITY_ORDER:
        group = [f for f in findings if f.get("severity") == severity]
        if not group:
            continue
        lines.append("### %s (%d)" % (severity.capitalize(), len(group)))
        for finding in group:
            lines.append(
                "- **%s** - carrier: %s - location: `%s` - confidence: %s - "
                "remediation: %s"
                % (finding.get("class", "?"), finding.get("carrier", "?"),
                   finding.get("location", "?"), finding.get("confidence", "?"),
                   finding.get("remediation", "?")))
            if finding.get("rule"):
                lines.append("  - rule: `%s`" % finding["rule"])
            if finding.get("entity"):
                lines.append("  - entity: `%s`" % finding["entity"])
            if finding.get("tags"):
                lines.append("  - tags: %s" % ", ".join(finding["tags"]))
            if finding.get("tracked") is not None:
                lines.append("  - tracked: %s"
                             % ("yes" if finding["tracked"] else "no"))
            if finding.get("value"):
                lines.append("  - value: `%s`" % finding["value"])
            if finding.get("commit"):
                lines.append("  - commit: `%s`" % finding["commit"][:12])
        lines.append("")
    return lines


def render_skipped(ran_stages, skipped_checks):
    lines = ["## Skipped checks", ""]
    lines.append("Stages that ran: %s" % ", ".join(ran_stages))
    lines.append("")
    if skipped_checks:
        for item in skipped_checks:
            lines.append("- %s: %s" % (item["check"], item["reason"]))
    else:
        lines.append("No check was skipped by a missing carrier or tool.")
    lines.append("")
    lines.append("Carrier checks are skipped when their carrier is absent.")
    lines.append("No skipped check is dropped silently.")
    return lines


def render_plan(findings):
    lines = ["## Suggested remediation plan", ""]
    rotation = [f for f in findings if f.get("remediation") == "rotate-credential"]
    if rotation:
        lines.append("### Credential rotation hand-off")
        lines.append("")
        lines.append("Rotate each credential before publication. A history "
                     "rewrite is not a substitute for rotation.")
        lines.append("")
        grouped = {}
        for finding in rotation:
            key = finding.get("value") or (finding.get("rule"),
                                           finding.get("location"))
            entry = grouped.setdefault(key, {
                "rule": finding.get("rule", "?"),
                "revocation": finding.get("revocation", "the provider"),
                "locations": [],
            })
            entry["locations"].append(finding.get("location", "?"))
        for entry in grouped.values():
            locations = ", ".join("`%s`" % loc for loc in entry["locations"])
            lines.append("- %s (%s)" % (locations, entry["rule"]))
            lines.append("  - revoke at: %s" % entry["revocation"])
        lines.append("")
        lines.append("Confirmation step: make a test request with the old "
                     "credential and confirm it fails. Publication stays "
                     "blocked until each rotation is confirmed.")
        lines.append("")
    protection = [f for f in findings
                  if f.get("remediation") == "add-protection"]
    if protection:
        lines.append("### Ignore additions")
        lines.append("")
        lines.append("Add these resilient patterns to `.gitignore`:")
        lines.append("")
        for finding in protection:
            suggestion = finding.get("suggestion") or finding.get("value") or "?"
            lines.append("- `%s` (for `%s`)"
                         % (suggestion, finding.get("location", "?")))
        lines.append("")
    if not findings:
        lines.append("None. Each fix is proposed as an exact action once "
                     "findings exist.")
        return lines
    lines.append("Ordered by severity. Each fix is proposed as an exact "
                 "action and applied only after approval.")
    return lines


def render_advice(advice):
    if not advice:
        return []
    lines = ["## Commit identity options", ""]
    for line in advice:
        lines.append("- %s" % line)
    return lines


def render_non_findings(findings):
    lines = ["## Non-findings", ""]
    if findings:
        lines.append("Recorded as the scan stages run.")
    else:
        lines.append("The checks that ran reported no findings.")
    return lines


def render_readiness(known_risks, findings):
    blocking = [f for f in findings
                if f.get("severity") in ("critical", "high")]
    lines = ["## Readiness summary", ""]
    lines.append("- Blocking findings open: %d" % len(blocking))
    lines.append("- Declared known risks: 0 found, 0 not found, %d not checked"
                 % len(known_risks))
    lines.append("")
    lines.append("This is a readiness summary, not a verdict. The skill")
    lines.append("reports coverage and risk. It does not certify a project")
    lines.append("as safe to publish.")
    return lines


def render(project_root, public_mode, known_risks, inventory, tools, ran_stages,
           findings, skipped_checks, advice):
    parts = ["# Pre-publication report", ""]
    parts += render_header(project_root, public_mode, inventory, tools)
    parts.append("")
    parts += render_known_risks(known_risks)
    parts.append("")
    parts += render_findings(findings)
    parts.append("")
    parts += render_skipped(ran_stages, skipped_checks)
    parts.append("")
    parts += render_plan(findings)
    parts.append("")
    advice_lines = render_advice(advice)
    if advice_lines:
        parts += advice_lines
        parts.append("")
    parts += render_non_findings(findings)
    parts.append("")
    parts += render_readiness(known_risks, findings)
    parts.append("")
    return re.sub(r"\n{3,}", "\n\n", "\n".join(parts))


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
    parser.add_argument("--findings", action="append", default=[],
                        help="a findings JSON file (repeatable)")
    parser.add_argument("--stdout", action="store_true")
    args = parser.parse_args()

    project_root = os.path.abspath(args.project_root)
    output_dir = args.output_dir or os.path.join(project_root, OUTPUT_SUBPATH)
    os.makedirs(output_dir, exist_ok=True)

    inventory = load_json(args.inventory)
    tools = load_json(args.tools)
    stages = args.stage or ["intake"]
    findings, skipped_checks, advice = load_findings(args.findings)

    text = render(project_root, args.public_mode, args.known_risk,
                  inventory, tools, stages, findings, skipped_checks, advice)

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
