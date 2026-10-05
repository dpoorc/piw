#!/usr/bin/env python3
"""Hygiene vector for pre-publication.

Read-only. Finds strays, large binaries, internal references, leaky
TODO-type comments, internal-facing documents, `.gitignore` gaps, and
extension and content mismatch. Writes `hygiene.json` to the output
directory.

The check list is open-ended. Generic patterns are always reported.
TODO, FIXME, and HACK comments are reported only when the line carries
leaky content. A file that reads like an internal-facing document is
treated as one.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import inventory  # noqa: E402
import support  # noqa: E402

OUTPUT_SUBPATH = support.OUTPUT_SUBPATH
DEFAULT_LARGE_MB = 5
DEFAULT_HARD_MB = 50

# Stray files and directories. (pattern, severity, label).
STRAY_PATTERNS = [
    (re.compile(r"(^|/)\.DS_Store$"), "low", "editor artifact"),
    (re.compile(r"(^|/)Thumbs\.db$"), "low", "editor artifact"),
    (re.compile(r"(^|/)desktop\.ini$"), "low", "editor artifact"),
    (re.compile(r"~$"), "low", "backup file"),
    (re.compile(r"\.(bak|orig|rej|swp|swo)$"), "low", "backup or swap file"),
    (re.compile(r"(^|/)\.#[^/]+$"), "low", "editor lock file"),
    (re.compile(r"\.(log|tmp|temp|cache|dmp|stackdump)$"), "low", "local artifact"),
    (re.compile(r"(^|/)(core|core\.\d+)$"), "low", "crash dump"),
    (re.compile(r"\.(sqlite|sqlite3|db)$"), "medium", "local database"),
    (re.compile(r"(^|/)(\.vscode|\.idea|\.vs)(/|$)"), "low", "editor directory"),
    (re.compile(r"(^|/)(scratch|tmp|temp|sandbox|playground)(/|$)"), "low",
     "scratch directory"),
]

# Local artifacts and the resilient ignore to recommend. (pattern,
# suggestion).
ARTIFACT_IGNORES = [
    (re.compile(r"(^|/)\.DS_Store$"), ".DS_Store"),
    (re.compile(r"(^|/)Thumbs\.db$"), "Thumbs.db"),
    (re.compile(r"(^|/)desktop\.ini$"), "desktop.ini"),
    (re.compile(r"(^|/)node_modules(/|$)"), "node_modules/"),
    (re.compile(r"(^|/)\.venv(/|$)"), ".venv/"),
    (re.compile(r"(^|/)__pycache__(/|$)"), "__pycache__/"),
    (re.compile(r"(^|/)\.pytest_cache(/|$)"), ".pytest_cache/"),
    (re.compile(r"(^|/)\.mypy_cache(/|$)"), ".mypy_cache/"),
    (re.compile(r"(^|/)\.env$"), ".env"),
    (re.compile(r"(^|/)dist(/|$)"), "dist/"),
    (re.compile(r"(^|/)build(/|$)"), "build/"),
    (re.compile(r"\.log$"), "*.log"),
    (re.compile(r"(^|/)\.vscode(/|$)"), ".vscode/"),
    (re.compile(r"(^|/)\.idea(/|$)"), ".idea/"),
]

HOME_PATH_RE = re.compile(
    r"(/home/[A-Za-z0-9_.-]+/|/Users/[A-Za-z0-9_.-]+/"
    r"|[A-Za-z]:\\Users\\[^\\\s]+\\|~/[A-Za-z0-9_.-]+/)")
SCHEME = r"[a-z][a-z0-9+.-]*://"
PRIVATE_URL_RE = re.compile(
    SCHEME + r"(localhost|127\.0\.0\.1|0\.0\.0\.0"
    r"|10\.\d{1,3}\.\d{1,3}\.\d{1,3}"
    r"|192\.168\.\d{1,3}\.\d{1,3}"
    r"|172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})[:/\s]")
INTERNAL_HOST_RE = re.compile(
    SCHEME + r"[A-Za-z0-9.-]+\.(internal|corp|lan|intranet|local)\b")
TICKET_URL_RE = re.compile(
    SCHEME + r"[^\s]*(jira|confluence|linear\.app|notion\.so|asana\.com"
    r"|trello\.com)[^\s]*")

TODO_RE = re.compile(r"\b(TODO|FIXME|HACK|XXX)\b")
LEAKY_RE = re.compile(
    r"(internal|confidential|do not (publish|share|distribute)"
    r"|not for public|private|proprietary|\bNDA\b|https?://"
    r"|@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|/home/|/Users/|[A-Z]{2,10}-\d+)",
    re.IGNORECASE)

INTERNAL_DOC_NAME_RE = re.compile(
    r"(internal|confidential|private|handoff|postmortem|incident|retro"
    r"|draft|wip|notes|personal|journal|diary|ideas)", re.IGNORECASE)
INTERNAL_DOC_MARKER_RE = re.compile(
    r"(internal use only|for internal use|not for public"
    r"|do not (publish|distribute|share|make public)|confidential"
    r"|proprietary|under NDA)", re.IGNORECASE)

DATE_RE = re.compile(r"\d{4}[-_]\d{2}[-_]\d{2}")

def finding(class_name, category, carrier, location, severity, confidence,
            remediation, **extra):
    """Build one hygiene finding. Every key is required."""
    return support.make_finding(class_name, category, location, severity,
                                remediation, carrier=carrier,
                                confidence=confidence, **extra)


def git_output(root, args):
    return support.run_git(root, args).stdout


is_git_repo = support.is_git_repo
read_text = support.read_text


def tracked_files(root):
    if not is_git_repo(root):
        return set()
    return set(git_output(root, ["ls-files"]).splitlines())


def is_ignored(root, rel):
    if not is_git_repo(root):
        return False
    result = subprocess.run(["git", "-C", root, "check-ignore", "-q", "--", rel],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return result.returncode == 0


# ---- Checks ----------------------------------------------------------------

def scan_strays(files):
    findings = []
    seen = set()
    for rel, path, _category in files:
        for pattern, severity, label in STRAY_PATTERNS:
            match = pattern.search(rel)
            if not match:
                continue
            key = (label, match.group(0))
            if key in seen:
                continue
            seen.add(key)
            findings.append(finding(
                "hygiene", "stray file", "working tree", rel, severity,
                "certain", "forward-fix", value=label))
            break
        else:
            if os.path.islink(path) and not os.path.exists(path):
                findings.append(finding(
                    "hygiene", "stray file", "working tree", rel, "low",
                    "certain", "forward-fix", value="broken symlink"))
            elif os.path.isfile(path) and os.path.getsize(path) == 0:
                findings.append(finding(
                    "hygiene", "stray file", "working tree", rel, "low",
                    "certain", "forward-fix", value="empty file"))
    return findings


def scan_large(files, tracked, large_bytes, hard_bytes):
    findings = []
    for rel, path, _category in files:
        if not os.path.isfile(path):
            continue
        size = os.path.getsize(path)
        if size < large_bytes:
            continue
        is_tracked = rel in tracked
        if size >= hard_bytes or is_tracked:
            severity = "high"
        else:
            severity = "medium"
        remediation = "history-rewrite" if is_tracked else "forward-fix"
        findings.append(finding(
            "hygiene", "large file", "working tree", rel, severity, "certain",
            remediation, value="%.1f MB" % (size / (1024 * 1024)),
            tracked=is_tracked))
    return findings


def scan_internal_references(files):
    findings = []
    for rel, path, category in files:
        if category != "text":
            continue
        text = read_text(path)
        if text is None:
            continue
        kinds = {}
        for line in text.splitlines():
            if HOME_PATH_RE.search(line):
                kinds["absolute home path"] = "medium"
            if PRIVATE_URL_RE.search(line):
                kinds["private URL"] = "medium"
            if INTERNAL_HOST_RE.search(line):
                kinds["internal host"] = "high"
            if TICKET_URL_RE.search(line):
                kinds["internal ticket link"] = "high"
        if kinds:
            severity = max(kinds.values(),
                           key=lambda s: support.SEVERITY_RANK.get(s, 0))
            findings.append(finding(
                "internal reference", "internal reference", "working tree",
                rel, severity, "likely", "forward-fix",
                tags=sorted(kinds)))
    return findings


def scan_todos(files):
    findings = []
    for rel, path, category in files:
        if category != "text":
            continue
        text = read_text(path)
        if text is None:
            continue
        hits = []
        for number, line in enumerate(text.splitlines(), 1):
            if TODO_RE.search(line) and LEAKY_RE.search(line):
                hits.append(number)
        if hits:
            findings.append(finding(
                "hygiene", "leaky comment", "working tree", rel, "medium",
                "likely", "forward-fix",
                value="line %s" % ", ".join(str(n) for n in hits)))
    return findings


def scan_internal_documents(files):
    findings = []
    for rel, path, category in files:
        if category != "text":
            continue
        name_hit = bool(INTERNAL_DOC_NAME_RE.search(rel))
        text = read_text(path)
        if text is None:
            continue
        marker = INTERNAL_DOC_MARKER_RE.search(text)
        if not name_hit and not marker:
            continue
        reason = "filename" if name_hit else "content"
        if name_hit and marker:
            reason = "filename and content"
        findings.append(finding(
            "doc hygiene", "internal-facing document", "working tree", rel,
            "high", "likely", "forward-fix", value="reads as internal (%s)" % reason))
    return findings


def resilient_suggestion(entry):
    if "/" in entry:
        return entry.rsplit("/", 1)[0] + "/"
    globbed = DATE_RE.sub("*", entry)
    return globbed if globbed != entry else None


def scan_ignore_entries(root):
    path = os.path.join(root, ".gitignore")
    if not os.path.exists(path):
        return []
    text = read_text(path)
    if text is None:
        return []
    findings = []
    for entry in text.splitlines():
        entry = entry.strip()
        if not entry or entry.startswith("#") or entry.startswith("!"):
            continue
        if any(c in entry for c in "*?[]"):
            continue
        # A directory entry with more than one segment names one
        # directory. It is not resilient. A top-level directory is fine.
        bare = entry[:-1] if entry.endswith("/") else entry
        if "/" not in bare and not DATE_RE.search(bare):
            continue
        suggestion = resilient_suggestion(bare)
        if not suggestion or suggestion == entry:
            continue
        findings.append(finding(
            "hygiene", "ignore gap", "working tree", ".gitignore", "medium",
            "certain", "add-protection", value=entry, suggestion=suggestion))
    return findings


def scan_ignore_gaps(root, files, skipped_dirs):
    findings = []
    candidates = [(rel, path) for rel, path, _ in files]
    for rel in skipped_dirs:
        candidates.append((rel, os.path.join(root, rel)))
    for rel, path in candidates:
        for pattern, suggestion in ARTIFACT_IGNORES:
            if not pattern.search(rel):
                continue
            if is_ignored(root, rel):
                break
            findings.append(finding(
                "hygiene", "ignore gap", "working tree", rel, "medium",
                "certain", "add-protection", value="not ignored",
                suggestion=suggestion))
            break
    return findings


def scan_mismatches(info):
    findings = []
    for item in info.get("mismatches", []):
        # A binary file with no known signature is not a mismatch.
        if item.get("detected") is None and item["expected"] == "binary":
            continue
        findings.append(finding(
            "hygiene", "extension mismatch", "working tree", item["path"],
            "medium", "certain", "forward-fix",
            value="expected %s, detected %s"
                  % (item["expected"], item.get("detected") or "unknown")))
    return findings


def scan(root, large_bytes, hard_bytes):
    files, skipped_dirs = inventory.iter_files(root)
    info = inventory.inventory(root)
    tracked = tracked_files(root)

    findings = []
    findings += scan_strays(files)
    findings += scan_large(files, tracked, large_bytes, hard_bytes)
    findings += scan_internal_references(files)
    findings += scan_todos(files)
    findings += scan_internal_documents(files)
    findings += scan_ignore_entries(root)
    findings += scan_ignore_gaps(root, files, skipped_dirs)
    findings += scan_mismatches(info)

    for index, item in enumerate(findings, start=1):
        item["id"] = "hyg-%d" % index
    return findings


def render_text(result):
    lines = ["Pre-publication hygiene scan", ""]
    lines.append("findings: %d" % len(result["findings"]))
    for item in result["findings"]:
        lines.append("  [%s] %s | %s | %s"
                     % (item["severity"], item["category"], item["location"],
                        item["remediation"]))
        if item.get("value"):
            lines.append("      %s" % item["value"])
        if item.get("suggestion"):
            lines.append("      suggest: %s" % item["suggestion"])
        if item.get("tracked") is not None:
            lines.append("      tracked: %s"
                         % ("yes" if item["tracked"] else "no"))
    return "\n".join(lines)


def cmd_scan(args):
    root = os.path.abspath(args.project_root)
    out_dir = os.path.join(root, OUTPUT_SUBPATH)
    os.makedirs(out_dir, exist_ok=True)
    out_path = args.out or os.path.join(out_dir, "hygiene.json")

    findings = scan(root, args.large_mb * 1024 * 1024,
                    args.hard_mb * 1024 * 1024)
    result = {
        "vector": "hygiene",
        "status": "ok",
        "reason": None,
        "tool": {"name": "git", "path": shutil.which("git"),
                 "version": None},
        "findings": findings,
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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", default=".")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parser.add_argument("--out", default=None,
                        help="findings JSON path (default: output dir)")
    parser.add_argument("--large-mb", type=int, default=DEFAULT_LARGE_MB,
                        help="large-file threshold in MB (default: 5)")
    parser.add_argument("--hard-mb", type=int, default=DEFAULT_HARD_MB,
                        help="hard-flag threshold in MB (default: 50)")
    args = parser.parse_args()
    return cmd_scan(args)


if __name__ == "__main__":
    sys.exit(main())
