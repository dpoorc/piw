#!/usr/bin/env python3
"""Licensing, attribution, and authorship vector for pre-publication.

Read-only. Flags license presence and consistency, third-party notices
and attribution, and the authorship preference. Writes `licensing.json`
to the output directory.

The check is high-level. It does not select a license, does not audit
dependency compatibility, and does not author legal text. A deeper
audit is a hand-off to a compliance workflow, on request.
"""

import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import inventory  # noqa: E402
import support  # noqa: E402

OUTPUT_SUBPATH = support.OUTPUT_SUBPATH

LICENSE_FILENAMES = (
    "LICENSE", "LICENSE.md", "LICENSE.txt", "LICENSE.rst", "LICENCE",
    "LICENCE.md", "LICENCE.txt", "COPYING", "COPYING.md", "COPYING.txt",
    "LICENSE-APACHE", "LICENSE-MIT", "UNLICENSE",
)
NOTICE_FILENAMES = ("NOTICE", "NOTICE.md", "NOTICE.txt")
AUTHORSHIP_FILES = ("AUTHORS", "AUTHORS.md", "AUTHORS.txt", "CONTRIBUTORS",
                    "CONTRIBUTORS.md", "CONTRIBUTORS.txt", "CREDITS",
                    "MAINTAINERS", "MAINTAINERS.md")
README_NAMES = ("README", "README.md", "README.rst", "README.txt")
MANIFEST_NAMES = ("package.json", "pyproject.toml", "Cargo.toml",
                  "composer.json", "setup.py", "setup.cfg", "Gemfile",
                  "pom.xml", "build.gradle", "go.mod")

VENDOR_DIRS = ("vendor", "third_party", "third-party", "deps", "external",
               "subprojects")

# License fingerprints. The first match on the license file text wins.
LICENSE_FINGERPRINTS = (
    ("Apache-2.0", re.compile(r"Apache License,?\s*Version 2\.0")),
    ("MIT", re.compile(r"Permission is hereby granted, free of charge"
                       r"|MIT License")),
    ("AGPL-3.0", re.compile(r"GNU AFFERO GENERAL PUBLIC LICENSE")),
    ("GPL-3.0", re.compile(r"GNU GENERAL PUBLIC LICENSE\s+Version 3")),
    ("GPL-2.0", re.compile(r"GNU GENERAL PUBLIC LICENSE\s+Version 2")),
    ("LGPL-3.0", re.compile(r"GNU LESSER GENERAL PUBLIC LICENSE\s+Version 3")),
    ("LGPL-2.1", re.compile(r"GNU LESSER GENERAL PUBLIC LICENSE\s+Version 2\.1")),
    ("MPL-2.0", re.compile(r"Mozilla Public License Version 2\.0")),
    ("ISC", re.compile(r"Permission to use, copy, modify, and/or distribute"
                       r" this software")),
    ("Unlicense", re.compile(r"free and unencumbered software released into"
                             r" the public domain")),
    ("CC0-1.0", re.compile(r"CC0 1\.0 Universal")),
    ("BSD-3-Clause", re.compile(r"Neither the name of.*nor the names of its"
                                r" contributors", re.DOTALL)),
    ("BSD-2-Clause", re.compile(r"Redistribution and use in source and binary"
                                r" forms")),
)

# Declared license names. Match the SPDX identifier or the common name.
DECLARED_PATTERNS = (
    ("Apache-2.0", re.compile(r"\bApache(?: License)?(?:,? Version)? 2\.0\b")),
    ("MIT", re.compile(r"\bMIT\b")),
    ("AGPL-3.0", re.compile(r"\bAGPL(?:v?3|-3\.0)\b")),
    ("GPL-3.0", re.compile(r"\bGPL(?:v?3|-3\.0)\b")),
    ("GPL-2.0", re.compile(r"\bGPL(?:v?2|-2\.0)\b")),
    ("LGPL-3.0", re.compile(r"\bLGPL(?:v?3|-3\.0)\b")),
    ("MPL-2.0", re.compile(r"\bMPL-2\.0\b|\bMozilla Public License\b")),
    ("ISC", re.compile(r"\bISC License\b|\bISC\b")),
    ("Unlicense", re.compile(r"\bUnlicense\b")),
    ("CC0-1.0", re.compile(r"\bCC0\b")),
    ("CC-BY-4.0", re.compile(r"\bCC[- ]BY[- ]4\.0\b")),
    ("BSD-3-Clause", re.compile(r"\bBSD-3-Clause\b|\b3-clause BSD\b")),
    ("BSD-2-Clause", re.compile(r"\bBSD-2-Clause\b|\b2-clause BSD\b")),
)

SPDX_LINE_RE = re.compile(r"SPDX-License-Identifier:\s*([A-Za-z0-9.+-]+)")
SPDX_SHAPE_RE = re.compile(r"^[A-Za-z0-9.+-]+$")
KNOWN_SPDX = {
    "0BSD", "AGPL-3.0-only", "AGPL-3.0-or-later", "Apache-2.0", "Artistic-2.0",
    "BSD-2-Clause", "BSD-3-Clause", "BSL-1.0", "CC-BY-4.0", "CC-BY-SA-4.0",
    "CC0-1.0", "EPL-2.0", "GPL-2.0-only", "GPL-2.0-or-later", "GPL-3.0-only",
    "GPL-3.0-or-later", "ISC", "LGPL-2.1-only", "LGPL-2.1-or-later",
    "LGPL-3.0-only", "LGPL-3.0-or-later", "MIT", "MPL-2.0", "PostgreSQL",
    "Python-2.0", "Unlicense", "WTFPL", "X11", "Zlib",
}

read_text = support.read_text


def finding(category, location, severity, remediation, value, **extra):
    """Build one licensing finding. The carrier is the working tree."""
    return support.make_finding("licensing", category, location, severity,
                                remediation, value=value, **extra)


def license_files(root):
    found = []
    for name in LICENSE_FILENAMES:
        path = os.path.join(root, name)
        if os.path.isfile(path):
            found.append((name, path))
    return found


def notice_files(root):
    return [name for name in NOTICE_FILENAMES
            if os.path.isfile(os.path.join(root, name))]


def identify_license(text):
    for license_id, pattern in LICENSE_FINGERPRINTS:
        if pattern.search(text):
            return license_id
    return None


def declared_licenses(root):
    """Return {file: {line: {ids}}} for license names in prose and manifests."""
    declared = {}
    candidates = list(README_NAMES) + list(MANIFEST_NAMES)
    for name in candidates:
        path = os.path.join(root, name)
        if not os.path.isfile(path):
            continue
        text = read_text(path)
        if text is None:
            continue
        per_line = {}
        for number, line in enumerate(text.splitlines(), 1):
            ids = [license_id for license_id, pattern in DECLARED_PATTERNS
                   if pattern.search(line)]
            if ids:
                per_line[number] = sorted(set(ids))
        if per_line:
            declared[name] = per_line
    return declared


def scan_license_presence(root):
    files = license_files(root)
    if files:
        return []
    return [finding(
        "license presence", ".", "medium", "add-protection",
        "no license file; choose a license or add an explicit "
        "all-rights-reserved notice", suggestion="LICENSE")]


def scan_license_consistency(root):
    findings = []
    files = license_files(root)
    actual = None
    for name, path in files:
        text = read_text(path)
        if text is None:
            continue
        found = identify_license(text)
        if found:
            actual = found
            break

    declared = declared_licenses(root)
    declared_ids = {i for per_line in declared.values()
                    for ids in per_line.values() for i in ids}

    if actual and declared_ids and not (declared_ids & {actual}):
        sources = ", ".join(sorted(declared))
        findings.append(finding(
            "license consistency", files[0][0] if files else "LICENSE",
            "high", "forward-fix",
            "the license file is %s, but %s declares %s"
            % (actual, sources, ", ".join(sorted(declared_ids)))))

    # Two files that declare different licenses.
    per_file = {name: {i for ids in per_line.values() for i in ids}
                for name, per_line in declared.items()}
    distinct = {i for ids in per_file.values() for i in ids}
    if len(per_file) > 1 and len(distinct) > 1:
        findings.append(finding(
            "license consistency", ", ".join(sorted(per_file)),
            "high", "forward-fix",
            "conflicting declarations: %s" % ", ".join(sorted(distinct))))
    return findings


def scan_spdx(root, files):
    findings = []
    for rel, path, category in files:
        if category != "text":
            continue
        text = read_text(path)
        if text is None:
            continue
        for identifier in set(SPDX_LINE_RE.findall(text)):
            if identifier in KNOWN_SPDX:
                continue
            if not SPDX_SHAPE_RE.match(identifier):
                findings.append(finding(
                    "SPDX", rel, "medium", "forward-fix",
                    "malformed SPDX identifier: %s" % identifier))
            else:
                findings.append(finding(
                    "SPDX", rel, "low", "forward-fix",
                    "unrecognized SPDX identifier: %s (verify)" % identifier))
    return findings


def scan_vendored(root):
    findings = []
    present = [name for name in VENDOR_DIRS
               if os.path.isdir(os.path.join(root, name))]
    for name in present:
        vendored = os.path.join(root, name)
        has_notice = False
        for dirpath, _dirnames, filenames in os.walk(vendored):
            for filename in filenames:
                upper = filename.upper()
                if (upper.startswith("LICENSE") or upper.startswith("COPYING")
                        or upper.startswith("NOTICE") or upper.endswith(".LICENSE")):
                    has_notice = True
                    break
            if has_notice:
                break
        if not has_notice:
            findings.append(finding(
                "attribution", name + "/", "high", "add-protection",
                "vendored code with no license or notice beside it",
                suggestion="%s/LICENSE (or NOTICE)" % name))
    return findings


def scan_apache_notice(root):
    if notice_files(root):
        return []
    for name, path in license_files(root):
        text = read_text(path)
        if text and identify_license(text) == "Apache-2.0":
            return [finding(
                "attribution", name, "medium", "add-protection",
                "Apache-2.0 requires a NOTICE file; none was found",
                suggestion="NOTICE")]
    return []


def scan_authorship(root, preference):
    if preference == "named":
        return [], []
    if preference == "ask":
        advice = [{
            "topic": "Authorship preference",
            "lines": [
                "Choose named attribution or anonymity for the project.",
                "Named: keep personal names in AUTHORS, CONTRIBUTORS, and "
                "headers.",
                "Anonymous: replace personal names with a project identity.",
                "Re-run with `--authorship named` or `--authorship anonymous`.",
            ],
        }]
        return [], advice

    findings = []
    for name in AUTHORSHIP_FILES:
        path = os.path.join(root, name)
        if os.path.isfile(path):
            findings.append(finding(
                "authorship", name, "medium", "forward-fix",
                "personal names in an authorship file; anonymity is wanted"))
    for name in MANIFEST_NAMES:
        path = os.path.join(root, name)
        text = read_text(path) if os.path.isfile(path) else None
        if not text:
            continue
        if re.search(r'"(?:author|maintainers?)"\s*:', text) \
                or re.search(r"^\s*(?:author|maintainers?)\s*=", text, re.M):
            findings.append(finding(
                "authorship", name, "medium", "forward-fix",
                "a personal author field; anonymity is wanted"))
    return findings, []


def scope_advice(missing_license):
    lines = [
        "This is a high-level flag, not legal advice.",
        "The skill does not select a license, audit dependency "
        "compatibility, or write legal text.",
        "For a full audit, switch to a compliance workflow.",
    ]
    if missing_license:
        lines.insert(0, "A missing license is a decision. Choose a license, "
                        "or add an explicit all-rights-reserved notice.")
    return [{"topic": "Licensing scope", "lines": lines}]


def scan(root, authorship):
    files, _skipped = inventory.iter_files(root)

    findings = []
    missing = scan_license_presence(root)
    findings += missing
    findings += scan_license_consistency(root)
    findings += scan_spdx(root, files)
    findings += scan_vendored(root)
    findings += scan_apache_notice(root)
    authorship_findings, authorship_advice = scan_authorship(root, authorship)
    findings += authorship_findings

    for index, item in enumerate(findings, start=1):
        item["id"] = "lic-%d" % index
    advice = scope_advice(bool(missing)) + authorship_advice
    return findings, advice


def render_text(result):
    lines = ["Pre-publication licensing scan", ""]
    lines.append("findings: %d" % len(result["findings"]))
    for item in result["findings"]:
        lines.append("  [%s] %s | %s | %s"
                     % (item["severity"], item["category"], item["location"],
                        item["remediation"]))
        lines.append("      %s" % item["value"])
    for block in result.get("advice", []):
        lines.append("")
        lines.append("%s:" % block["topic"])
        for line in block["lines"]:
            lines.append("  - %s" % line)
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", default=".")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parser.add_argument("--out", default=None,
                        help="findings JSON path (default: output dir)")
    parser.add_argument("--authorship", choices=("ask", "named", "anonymous"),
                        default="ask",
                        help="authorship preference (default: ask)")
    args = parser.parse_args()

    root = os.path.abspath(args.project_root)
    out_dir = os.path.join(root, OUTPUT_SUBPATH)
    os.makedirs(out_dir, exist_ok=True)
    out_path = args.out or os.path.join(out_dir, "licensing.json")

    findings, advice = scan(root, args.authorship)
    result = {
        "vector": "licensing",
        "status": "ok",
        "reason": None,
        "tool": {"name": None, "path": None, "version": None},
        "findings": findings,
        "advice": advice,
        "errors": [],
    }
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
        handle.write("\n")

    if args.format == "json":
        print(json.dumps(result, indent=2))
    else:
        print(render_text(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
