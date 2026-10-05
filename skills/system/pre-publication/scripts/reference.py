#!/usr/bin/env python3
"""Build and use the sensitive-information reference.

The reference is an optional, multi-round detection aid. It holds
project-specific terms: codenames, internal hostnames, personal names,
and other strings that the generic checks miss.

Round 1 is built from the declared known risks, the vector findings,
and a project-supplied term list. Later rounds add terms that the agent
and the user find by reading the flagged files together. A round stops
when it adds nothing new.

The reference lives in the output directory (`.local/prepublish/`),
which the scan excludes. It carries sensitive terms. Never share it,
and never copy it into a sanitized export.
"""

import argparse
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import inventory  # noqa: E402
import support  # noqa: E402

REFERENCE_NAME = "sensitive-info.json"
REPORT_NAME = "reference.json"
MARKDOWN_NAME = "sensitive-info.md"
VERSION = 1
MIN_TERM_LENGTH = 3
MAX_HITS_PER_TERM = 100
HISTORY_REV_LIMIT = 500

QUOTED_RE = re.compile(r"[`'\"]([^`'\"]{3,})[`'\"]")
EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
HOST_RE = re.compile(r"\b[a-zA-Z0-9-]+\.(?:corp|internal|local|lan|intranet)\b")


def reference_path(root):
    return os.path.join(support.output_dir(root), REFERENCE_NAME)


def load_json(path):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def load_reference(root):
    path = reference_path(root)
    if not os.path.exists(path):
        return {"version": VERSION, "rounds": [], "terms": [], "notes": []}
    return load_json(path)


def save_reference(root, data):
    os.makedirs(support.output_dir(root), exist_ok=True)
    with open(reference_path(root), "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, sort_keys=True)
        handle.write("\n")


def term_key(term):
    return term.strip().lower()


def terms_from_risk(text):
    """Extract candidate terms from one known-risk statement."""
    found = QUOTED_RE.findall(text)
    found += EMAIL_RE.findall(text)
    found += HOST_RE.findall(text)
    return found


def terms_from_findings(findings):
    """Extract candidate terms from vector findings.

    A secret value is never stored. Only the host of a URL-shaped
    secret is kept. A person name and an email domain are kept. A phone
    number and a low-precision NRP are not useful search terms, so they
    are left out.
    """
    terms = []
    for finding in findings:
        entity = finding.get("entity") or ""
        value = finding.get("value") or ""
        if entity == "PERSON" and value:
            terms.append((value, "person"))
        elif entity == "EMAIL_ADDRESS" and value:
            terms.append((value, "email"))
            if "@" in value:
                terms.append((value.split("@", 1)[1], "domain"))
        elif finding.get("class") == "secrets" and "://" in value:
            host = value.split("://", 1)[1].split("/", 1)[0]
            if host:
                terms.append((host, "host"))
    return terms


class Adder:
    def __init__(self, data, round_no):
        self.data = data
        self.round_no = round_no
        self.existing = {term_key(item["term"]) for item in data["terms"]}
        self.added = []

    def add(self, term, kind, source):
        term = (term or "").strip()
        if len(term) < MIN_TERM_LENGTH:
            return
        key = term_key(term)
        if key in self.existing:
            return
        self.existing.add(key)
        self.data["terms"].append({
            "term": term,
            "kind": kind,
            "source": source,
            "round": self.round_no,
        })
        self.added.append(term)


def scan_tree(root, terms):
    """Return (term, location, line) for every working-tree match."""
    hits = []
    files = inventory.text_files(root)
    for rel, path in files:
        text = support.read_text(path)
        if text is None:
            continue
        lines = text.splitlines()
        lower_lines = [line.lower() for line in lines]
        for term in terms:
            needle = term_key(term["term"])
            count = 0
            for line_no, line in enumerate(lower_lines, start=1):
                if needle in line:
                    hits.append((term, "%s:%d" % (rel, line_no)))
                    count += 1
                    if count >= MAX_HITS_PER_TERM:
                        break
    return hits


def scan_history(root, terms):
    """Return (term, location) for every history match.

    History scanning is expensive. It is capped at HISTORY_REV_LIMIT
    revisions.
    """
    hits = []
    revs = support.run_git(root, ["rev-list", "--all"]).stdout.split()
    revs = revs[:HISTORY_REV_LIMIT]
    if not revs:
        return hits
    for term in terms:
        proc = subprocess.run(
            ["git", "-C", root, "grep", "-I", "-n", "-i", "-F", "-e",
             term["term"]] + revs,
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        for line in proc.stdout.splitlines()[:MAX_HITS_PER_TERM]:
            parts = line.split(":", 2)
            if len(parts) == 3:
                hits.append((term, "history %s:%s" % (parts[0], parts[2])))
    return hits


def findings_from_hits(hits, carrier):
    findings = []
    for index, (term, location) in enumerate(hits, start=1):
        findings.append(support.make_finding(
            "sensitive reference", "reference", location, "medium",
            "forward-fix", carrier=carrier, confidence="likely",
            id="reference-%d" % index, rule=term["term"], value=term["term"]))
    return findings


def write_report(root, findings, advice):
    path = os.path.join(support.output_dir(root), REPORT_NAME)
    os.makedirs(support.output_dir(root), exist_ok=True)
    data = {
        "vector": "reference",
        "tool": {"name": "reference", "version": str(VERSION)},
        "findings": findings,
        "advice": advice,
    }
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, sort_keys=True)
        handle.write("\n")
    return path


def render_markdown(data):
    lines = [
        "# Sensitive-information reference",
        "",
        "Local only. This file carries sensitive terms. Do not share it,",
        "and do not copy it into a sanitized export.",
        "",
        "%d term(s), %d round(s)." % (len(data["terms"]), len(data["rounds"])),
        "",
        "## Terms",
        "",
    ]
    if not data["terms"]:
        lines.append("None.")
    for item in data["terms"]:
        lines.append("- `%s` - %s - from %s - round %s"
                     % (item["term"], item["kind"], item["source"],
                        item.get("round", "?")))
    lines.append("")
    lines.append("## Rounds")
    lines.append("")
    if not data["rounds"]:
        lines.append("None.")
    for item in data["rounds"]:
        lines.append("- Round %s (%s): added %d term(s), %d new occurrence(s)"
                     % (item.get("round", "?"), item.get("source", "?"),
                        len(item.get("added", [])),
                        item.get("occurrences", 0)))
    lines.append("")
    if data.get("notes"):
        lines.append("## Notes")
        lines.append("")
        for note in data["notes"]:
            lines.append("- %s" % note)
        lines.append("")
    return "\n".join(lines)


def save_markdown(root, data):
    path = os.path.join(support.output_dir(root), MARKDOWN_NAME)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(render_markdown(data))
    return path


def cmd_build(args):
    root = os.path.abspath(args.project_root)
    data = load_reference(root)
    adder = Adder(data, round_no=1)
    for risk in args.known_risk or []:
        candidates = terms_from_risk(risk)
        if not candidates:
            data["notes"].append("Known risk with no extractable term: %s"
                                 % risk)
        for token in candidates:
            adder.add(token, "risk", "known-risk")
    for path in args.findings or []:
        try:
            payload = load_json(path)
        except (OSError, ValueError) as exc:
            print("Skipped findings file %s: %s" % (path, exc))
            continue
        for term, kind in terms_from_findings(payload.get("findings", [])):
            adder.add(term, kind, "finding")
    for term in args.term or []:
        adder.add(term, "supplied", "project")
    if args.terms_file:
        for line in support.read_text(args.terms_file, limit=1 << 20).splitlines():
            adder.add(line, "supplied", "project")

    data["rounds"].append({"round": 1, "source": "seed",
                           "added": adder.added, "occurrences": 0})
    save_reference(root, data)
    save_markdown(root, data)
    print("Reference built: %d term(s)." % len(data["terms"]))
    for term in adder.added:
        print("  + %s" % term)
    if not adder.added:
        print("No seed term was found. Add terms with `expand` after the "
              "file-level review.")
    return 0


def cmd_scan(args):
    root = os.path.abspath(args.project_root)
    data = load_reference(root)
    if not data["terms"]:
        print("The reference is empty. Run `build` first.")
        return 1
    hits = scan_tree(root, data["terms"])
    carrier = "working tree"
    if args.history:
        history_hits = scan_history(root, data["terms"])
        hits += history_hits
        carrier = "working tree and git history"
    findings = findings_from_hits(hits, carrier)
    advice = [{"topic": "sensitive-information reference",
               "lines": [
                   "Review each match in the working tree.",
                   "The reference is local only. Never share it.",
               ]}]
    path = write_report(root, findings, advice)
    if args.format == "json":
        print(json.dumps({"findings": findings}, indent=2))
    else:
        print("Reference scan: %d match(es)." % len(findings))
        for finding in findings:
            print("  [%s] %s" % (finding["severity"], finding["location"]))
        print("Findings written to %s" % path)
    return 0


def cmd_expand(args):
    root = os.path.abspath(args.project_root)
    data = load_reference(root)
    round_no = len(data["rounds"]) + 1
    adder = Adder(data, round_no)
    for term in args.term or []:
        adder.add(term, args.kind, args.source)
    if args.terms_file:
        for line in support.read_text(args.terms_file, limit=1 << 20).splitlines():
            adder.add(line, args.kind, args.source)
    if not adder.added:
        print("No new term. This round adds nothing new. Stop.")
        return 0

    hits = scan_tree(root, data["terms"])
    added_keys = {term_key(term) for term in adder.added}
    new_hits = [hit for hit in hits if term_key(hit[0]["term"]) in added_keys]
    data["rounds"].append({"round": round_no, "source": args.source,
                           "added": adder.added, "occurrences": len(new_hits)})
    save_reference(root, data)
    save_markdown(root, data)
    findings = findings_from_hits(hits, "working tree")
    write_report(root, findings, [{"topic": "sensitive-information reference",
                                   "lines": [
                                       "Review each match in the working tree.",
                                       "The reference is local only. Never "
                                       "share it.",
                                   ]}])
    print("Round %d: added %d term(s), %d new occurrence(s)."
          % (round_no, len(adder.added), len(new_hits)))
    for term in adder.added:
        print("  + %s" % term)
    if not new_hits:
        print("This round adds nothing new. Stop.")
    return 0


def cmd_show(args):
    root = os.path.abspath(args.project_root)
    data = load_reference(root)
    print("Sensitive-information reference: %d term(s), %d round(s)."
          % (len(data["terms"]), len(data["rounds"])))
    for item in data["terms"]:
        print("  %-10s %s (from %s, round %s)"
              % (item["kind"], item["term"], item["source"],
                 item.get("round", "?")))
    for item in data["rounds"]:
        print("  round %s (%s): +%d, %d new occurrence(s)"
              % (item.get("round", "?"), item.get("source", "?"),
                 len(item.get("added", [])), item.get("occurrences", 0)))
    print("Markdown: %s" % os.path.join(support.output_dir(root),
                                        MARKDOWN_NAME))
    return 0


def add_terms(parser):
    parser.add_argument("--term", action="append", default=[],
                        help="a term to add; repeatable")
    parser.add_argument("--terms-file", default=None,
                        help="a file with one term per line")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_build = sub.add_parser("build", help="seed the reference")
    p_build.add_argument("--project-root", default=".")
    p_build.add_argument("--known-risk", action="append", default=[])
    p_build.add_argument("--findings", action="append", default=[])
    add_terms(p_build)
    p_build.set_defaults(func=cmd_build)

    p_scan = sub.add_parser("scan", help="find occurrences of the terms")
    p_scan.add_argument("--project-root", default=".")
    p_scan.add_argument("--history", action="store_true")
    p_scan.add_argument("--format", choices=("text", "json"), default="text")
    p_scan.set_defaults(func=cmd_scan)

    p_expand = sub.add_parser("expand", help="add terms and rescan")
    p_expand.add_argument("--project-root", default=".")
    add_terms(p_expand)
    p_expand.add_argument("--kind", default="codename")
    p_expand.add_argument("--source", default="judgment")
    p_expand.set_defaults(func=cmd_expand)

    p_show = sub.add_parser("show", help="print the reference")
    p_show.add_argument("--project-root", default=".")
    p_show.set_defaults(func=cmd_show)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
