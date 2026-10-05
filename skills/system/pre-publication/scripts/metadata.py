#!/usr/bin/env python3
"""Metadata vector for pre-publication.

`scan` reads file, document, and media metadata with exiftool, checks the
repository metadata with git, and collects the commit identities. It is
read-only and writes `metadata.json` to the output directory.

`remove` strips identity and location metadata from one file. It selects
the tags by default, keeps functional tags such as Orientation, and
re-reads the file to confirm. It refuses an in-place edit without
`--confirm-destructive`. It writes out of place with `--out`.

exiftool cannot write OOXML. For OOXML the script rewrites the identity
parts with the Python standard library `zipfile` module.

Copyright and licensor fields belong to the licensing vector, not here.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import inventory  # noqa: E402
import support  # noqa: E402

OUTPUT_SUBPATH = support.OUTPUT_SUBPATH
FILE_CARRIERS = {"image", "office", "pdf"}
OOXML_EXTS = {".docx", ".docm", ".xlsx", ".xlsm", ".pptx", ".pptm",
              ".odt", ".ods", ".odp"}

# Identity and device tags. The exiftool group prefix is stripped before
# the match. GPS tags are matched by name prefix.
IDENTITY_TAGS = {
    "Artist", "OwnerName", "SerialNumber", "Creator", "LastModifiedBy",
    "Author", "By-line", "By-lineTitle", "Credit", "Source",
    "Company", "Manager",
}
DEVICE_TAGS = {"Make", "Model", "Software", "CreatorTool"}
GROUP_OVERRIDES = {("PDF", "Creator"): "device"}

KIND_SEVERITY = {"location": "high", "identity": "high", "device": "medium"}

# OOXML identity elements. app.xml and custom.xml carry unprefixed names.
OOXML_PARTS = ("docProps/core.xml", "docProps/app.xml", "docProps/custom.xml")
OOXML_IDENTITY = ("dc:creator", "cp:lastModifiedBy", "cp:lastPrinted",
                  "Manager", "Company")

CREDENTIAL_URL = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*://([^/@\s]+)@")
CREDENTIAL_IN_TEXT = re.compile(r"[a-zA-Z][a-zA-Z0-9+.-]*://([^/@\s]+)@")
ABSOLUTE_PATH = re.compile(r"(/home/|/Users/|/root/|[A-Za-z]:\\|~/)")
GIT_DESCRIPTION_DEFAULT = ("Unnamed repository; edit this file 'description' "
                           "to name the repository.")


# ---- Shared helpers ----------------------------------------------------------

def output_dir(project_root):
    return os.path.join(os.path.abspath(project_root), OUTPUT_SUBPATH)


def severity_of(kinds):
    order = sorted(kinds, key=lambda k: support.SEVERITY_RANK[KIND_SEVERITY[k]])
    return KIND_SEVERITY[order[-1]]


def mask_url(url):
    return re.sub(r"://([^/@:]+):([^/@]+)@", r"://\1:***@", url)


def classify_tag(group, name):
    if (group, name) in GROUP_OVERRIDES:
        return GROUP_OVERRIDES[(group, name)]
    if name.startswith("GPS"):
        return "location"
    if name in IDENTITY_TAGS:
        return "identity"
    if name in DEVICE_TAGS:
        return "device"
    return None


run_git = support.run_git
is_git_repo = support.is_git_repo


def git_path(root, name):
    """Resolve a path inside the git directory, worktree safe."""
    proc = run_git(root, ["rev-parse", "--git-path", name])
    path = proc.stdout.strip()
    if not path:
        return None
    if not os.path.isabs(path):
        path = os.path.join(root, path)
    return path


# ---- File metadata (exiftool) ------------------------------------------------

def exiftool_version(exiftool):
    try:
        proc = subprocess.run([exiftool, "-ver"], stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, text=True)
        return proc.stdout.strip() or None
    except OSError:
        return None


def read_exiftool(exiftool, paths):
    records = []
    for start in range(0, len(paths), 100):
        batch = paths[start:start + 100]
        proc = subprocess.run(
            [exiftool, "-json", "-G", "-a", "-charset", "UTF8"] + batch,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if proc.stdout:
            records.extend(json.loads(proc.stdout))
    return records


def carriers(root):
    files, _ = inventory.iter_files(root)
    return [(rel, path, category) for rel, path, category in files
            if category in FILE_CARRIERS]


def scan_file_metadata(exiftool, carrier_list):
    by_path = {}
    for rel, path, category in carrier_list:
        by_path[path] = (rel, category)
        by_path[os.path.abspath(path)] = (rel, category)
    findings = []
    errors = []
    try:
        records = read_exiftool(exiftool, [p for _, p, _ in carrier_list])
    except (OSError, ValueError) as exc:
        return [], ["exiftool: %s" % exc]
    for record in records:
        source = record.get("SourceFile", "")
        rel, category = by_path.get(source, (source, "image"))
        tags = {}
        kinds = set()
        for key, value in record.items():
            if key == "SourceFile":
                continue
            group, _, name = key.partition(":")
            kind = classify_tag(group, name)
            if kind is not None:
                tags[name] = kind
                kinds.add(kind)
        if not tags:
            continue
        carrier = "document metadata" if category == "office" else "file metadata"
        findings.append({
            "class": "metadata",
            "category": "identity and location",
            "carrier": carrier,
            "location": rel,
            "severity": severity_of(kinds),
            "confidence": "certain",
            "remediation": "forward-fix",
            "tags": sorted(tags),
        })
    return findings, errors


# ---- Repository metadata (git) -----------------------------------------------

def finding(location, severity, remediation, value,
            carrier="repository metadata", revocation=None):
    """Build one repository-metadata finding."""
    extra = {"value": value}
    if revocation:
        extra["revocation"] = revocation
    return support.make_finding("metadata", "repository metadata", location,
                                severity, remediation, carrier=carrier,
                                confidence="certain", **extra)


def host_of(url):
    try:
        return url.split("://", 1)[1].split("@", 1)[1].split("/", 1)[0]
    except IndexError:
        return "the git host"


def scan_repository(root):
    findings = []
    if not is_git_repo(root):
        return findings

    proc = run_git(root, ["remote", "-v"])
    seen_remotes = set()
    for line in proc.stdout.splitlines():
        parts = line.split()
        if len(parts) < 2:
            continue
        name, url = parts[0], parts[1]
        if (name, url) in seen_remotes:
            continue
        seen_remotes.add((name, url))
        match = CREDENTIAL_URL.match(url)
        if match and ":" in match.group(1):
            findings.append(finding(
                "remote:%s" % name, "critical", "rotate-credential",
                mask_url(url),
                revocation="the account on %s" % host_of(url)))

    proc = run_git(root, ["config", "--list", "--show-origin"])
    for line in proc.stdout.splitlines():
        _origin, _, entry = line.partition("\t")
        key, _, value = entry.partition("=")
        if not value:
            continue
        if key == "credential.helper":
            findings.append(finding(
                "git config", "medium", "forward-fix",
                "credential.helper=%s" % value))
        elif ABSOLUTE_PATH.search(value):
            findings.append(finding(
                "git config", "medium", "forward-fix",
                "%s=%s" % (key, value)))

    gitmodules = os.path.join(root, ".gitmodules")
    if os.path.exists(gitmodules):
        with open(gitmodules, "r", encoding="utf-8", errors="replace") as handle:
            for line in handle:
                line = line.strip()
                if not line.lower().startswith("url"):
                    continue
                _key, _, url = line.partition("=")
                match = CREDENTIAL_URL.match(url.strip())
                if match and ":" in match.group(1):
                    findings.append(finding(
                        ".gitmodules", "critical", "rotate-credential",
                        mask_url(url.strip()),
                        revocation="the account on %s" % host_of(url.strip())))

    proc = run_git(root, ["stash", "list"])
    if proc.stdout.strip():
        findings.append(finding(
            "git stash", "medium", "forward-fix",
            "%d stash entry" % len(proc.stdout.splitlines())))

    proc = run_git(root, ["notes", "list"])
    if proc.stdout.strip():
        findings.append(finding(
            "git notes", "low", "forward-fix",
            "%d note" % len(proc.stdout.splitlines())))

    proc = run_git(root, [
        "for-each-ref", "refs/tags",
        "--format=%(objecttype)\t%(refname:short)"])
    annotated = [line.split("\t")[1] for line in proc.stdout.splitlines()
                 if line.startswith("tag\t")]
    if annotated:
        findings.append(finding(
            "git tags", "low", "history-rewrite",
            "annotated: %s" % ", ".join(annotated)))

    proc = run_git(root, ["reflog", "--all"])
    if proc.stdout.strip():
        findings.append(finding(
            "git reflog", "low", "forward-fix",
            "%d reflog entries; old commits stay reachable until the reflog "
            "expires" % len(proc.stdout.splitlines())))

    hooks_dir = git_path(root, "hooks")
    if hooks_dir and os.path.isdir(hooks_dir):
        hooks = [name for name in os.listdir(hooks_dir)
                 if not name.endswith(".sample")]
        if hooks:
            findings.append(finding(
                ".git/hooks", "low", "forward-fix",
                ", ".join(sorted(hooks))))
        for name in sorted(hooks):
            path = os.path.join(hooks_dir, name)
            if not os.path.isfile(path):
                continue
            text = support.read_text(path) or ""
            match = CREDENTIAL_IN_TEXT.search(text)
            if match and ":" in match.group(1):
                findings.append(finding(
                    ".git/hooks/%s" % name, "medium", "rotate-credential",
                    mask_url(match.group(0)),
                    revocation="the account on %s" % host_of(match.group(0))))
            elif ABSOLUTE_PATH.search(text):
                findings.append(finding(
                    ".git/hooks/%s" % name, "low", "forward-fix",
                    "contains a local path"))

    description = git_path(root, "description")
    if description and os.path.exists(description):
        text = (support.read_text(description) or "").strip()
        if text and text != GIT_DESCRIPTION_DEFAULT:
            findings.append(finding(
                ".git/description", "low", "forward-fix", text))

    return findings


def identity_advice(root):
    if not is_git_repo(root):
        return []
    proc = run_git(root, ["log", "--all", "--format=%an <%ae>"])
    identities = sorted({line.strip() for line in proc.stdout.splitlines()
                         if line.strip()})
    advice = []
    if identities:
        advice.append("Identities in history: %s." % ", ".join(identities))
    advice.append("Future commits: set a project identity with "
                  "`git config user.name \"...\"` and `git config user.email "
                  "\"...\"`.")
    advice.append("Past commits: rewrite author and committer identity with "
                  "`git-filter-repo`, under the destructive gate. This "
                  "rewrites history.")
    advice.append("Display only: add a `.mailmap` to remap identities in logs "
                  "and shortlog. It removes nothing.")
    return advice


# ---- Removal -----------------------------------------------------------------

def exiftool_delete_args(strip_all):
    if strip_all:
        return ["-all="]
    args = ["-%s=" % tag for tag in sorted(IDENTITY_TAGS | DEVICE_TAGS)]
    args.append("-GPS:all=")
    return args


def strip_exiftool(exiftool, path, out=None, strip_all=False):
    args = [exiftool]
    if out:
        args += ["-o", out]
    else:
        args += ["-overwrite_original"]
    args += exiftool_delete_args(strip_all)
    args.append(path)
    proc = subprocess.run(args, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "exiftool failed")
    return ["all metadata"] if strip_all else ["the identity and location tag set"]


def strip_ooxml_part(name, data, strip_all):
    text = data.decode("utf-8", errors="replace")
    removed = []
    if strip_all and name == "docProps/core.xml":
        text = re.sub(r"(<cp:coreProperties\b[^>]*>).*?(</cp:coreProperties>)",
                      r"\1\2", text, flags=re.DOTALL)
        return text.encode("utf-8"), ["core.xml:all"]
    for tag in OOXML_IDENTITY:
        pattern = re.compile(
            r"<%s(?:\s[^>]*)?>.*?</%s>|<%s(?:\s[^>]*)?/>"
            % (re.escape(tag), re.escape(tag), re.escape(tag)), re.DOTALL)
        text, count = pattern.subn("", text)
        if count:
            removed.append(tag)
    if strip_all and name == "docProps/custom.xml":
        text = re.sub(r"<property\b.*?</property>", "", text, flags=re.DOTALL)
        text = re.sub(r"<property\b[^>]*/>", "", text)
        removed.append("custom.xml:all")
    return text.encode("utf-8"), removed


def strip_ooxml(path, out=None, strip_all=False):
    target = out or path
    directory = os.path.dirname(os.path.abspath(target)) or "."
    fd, tmp = tempfile.mkstemp(suffix=".zip", dir=directory)
    os.close(fd)
    removed = []
    try:
        with zipfile.ZipFile(path, "r") as src:
            with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as dst:
                for item in src.infolist():
                    data = src.read(item.filename)
                    if item.filename in OOXML_PARTS:
                        data, tags = strip_ooxml_part(item.filename, data,
                                                      strip_all)
                        removed += ["%s:%s" % (item.filename, t) for t in tags]
                    new = zipfile.ZipInfo(item.filename,
                                          date_time=item.date_time)
                    new.compress_type = item.compress_type
                    new.external_attr = item.external_attr
                    new.internal_attr = item.internal_attr
                    new.create_system = item.create_system
                    dst.writestr(new, data)
        shutil.move(tmp, target)
    except Exception:
        if os.path.exists(tmp):
            os.remove(tmp)
        raise
    return removed


def remaining_exiftool(exiftool, path):
    records = read_exiftool(exiftool, [path])
    if not records:
        return []
    record = records[0]
    return sorted(name for key in record if key != "SourceFile"
                  for group, _, name in [key.partition(":")]
                  if classify_tag(group, name) is not None)


def remaining_ooxml(path):
    remaining = []
    with zipfile.ZipFile(path, "r") as archive:
        for name in OOXML_PARTS:
            if name not in archive.namelist():
                continue
            text = archive.read(name).decode("utf-8", errors="replace")
            for tag in OOXML_IDENTITY:
                if re.search(r"<%s\b" % re.escape(tag), text):
                    remaining.append("%s:%s" % (name, tag))
    return remaining


# ---- Commands ----------------------------------------------------------------

def cmd_scan(args):
    root = os.path.abspath(args.project_root)
    out_dir = output_dir(root)
    os.makedirs(out_dir, exist_ok=True)
    out_path = args.out or os.path.join(out_dir, "metadata.json")

    exiftool = None if args.no_exiftool else (args.exiftool or shutil.which("exiftool"))
    carrier_list = carriers(root)
    skipped = []
    findings = []
    errors = []

    if carrier_list and not exiftool:
        skipped.append({
            "check": "file metadata",
            "reason": "exiftool is required when metadata carriers exist, "
                      "and it was not found",
            "tool": "exiftool",
        })
    elif carrier_list:
        file_findings, file_errors = scan_file_metadata(exiftool, carrier_list)
        findings.extend(file_findings)
        errors.extend(file_errors)

    findings.extend(scan_repository(root))
    advice_lines = identity_advice(root)
    advice = [{"topic": "Commit identity options", "lines": advice_lines}] \
        if advice_lines else []

    for index, item in enumerate(findings, start=1):
        item["id"] = "meta-%d" % index

    result = {
        "vector": "metadata",
        "status": "ok",
        "reason": None,
        "tool": {"name": "exiftool", "path": exiftool,
                 "version": exiftool_version(exiftool) if exiftool else None},
        "findings": findings,
        "advice": advice,
        "skipped_checks": skipped,
        "errors": errors,
    }
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
        handle.write("\n")

    if args.format == "json":
        print(json.dumps(result, indent=2))
    else:
        print(render_text(result))
    return 0


def render_text(result):
    lines = ["Pre-publication metadata scan", ""]
    tool = result["tool"]
    lines.append("tool: %s %s" % (tool["name"], tool.get("version") or "absent"))
    lines.append("findings: %d" % len(result["findings"]))
    for item in result["findings"]:
        lines.append("  [%s] %s | %s | %s"
                     % (item["severity"], item["carrier"],
                        item["location"], item["remediation"]))
        if item.get("tags"):
            lines.append("      tags: %s" % ", ".join(item["tags"]))
        if item.get("value"):
            lines.append("      value: %s" % item["value"])
    for item in result.get("skipped_checks", []):
        lines.append("SKIPPED: %s - %s" % (item["check"], item["reason"]))
    for block in result.get("advice", []):
        lines.append("")
        lines.append("%s:" % block["topic"])
        for line in block["lines"]:
            lines.append("  - %s" % line)
    if result.get("errors"):
        lines.append("")
        lines.append("errors:")
        for error in result["errors"]:
            lines.append("  %s" % error)
    return "\n".join(lines)


def cmd_remove(args):
    root = os.path.abspath(args.project_root)
    path = args.file if os.path.isabs(args.file) else os.path.join(root, args.file)
    if not os.path.exists(path):
        print("Refused: no such file: %s" % path)
        return 1
    if not args.out and not args.confirm_destructive:
        print("Refused: an in-place edit is destructive. Pass "
              "--confirm-destructive, or write out of place with --out.")
        return 1
    if args.strip_all:
        print("WARNING: --strip-all removes functional tags too, including "
              "Orientation. The image can rotate.")

    if args.backup:
        shutil.copy2(path, args.backup)

    extension = os.path.splitext(path)[1].lower()
    exiftool = args.exiftool or shutil.which("exiftool")
    try:
        if extension in OOXML_EXTS:
            removed = strip_ooxml(path, out=args.out, strip_all=args.strip_all)
        elif exiftool:
            removed = strip_exiftool(exiftool, path, out=args.out,
                                     strip_all=args.strip_all)
        else:
            print("Refused: exiftool is required to remove metadata from %s"
                  % path)
            return 1
    except (OSError, RuntimeError, zipfile.BadZipFile) as exc:
        print("Failed: %s" % exc)
        return 1

    target = args.out or path
    if extension in OOXML_EXTS:
        remaining = remaining_ooxml(target)
    else:
        remaining = remaining_exiftool(exiftool, target)

    print("Removed: %s" % (", ".join(removed) if removed else "nothing"))
    if remaining:
        print("Still present: %s" % ", ".join(remaining))
        return 1
    print("Confirmed: the identity and location tags are gone.")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_scan = sub.add_parser("scan", help="scan metadata and write metadata.json")
    p_scan.add_argument("--project-root", default=".")
    p_scan.add_argument("--format", choices=("text", "json"), default="text")
    p_scan.add_argument("--out", default=None,
                        help="findings JSON path (default: output dir)")
    p_scan.add_argument("--exiftool", default=None,
                        help="exiftool path (default: search PATH)")
    p_scan.add_argument("--no-exiftool", action="store_true",
                        help="treat exiftool as absent (test seam)")
    p_scan.set_defaults(func=cmd_scan)

    p_remove = sub.add_parser("remove", help="strip identity and location tags")
    p_remove.add_argument("file")
    p_remove.add_argument("--project-root", default=".")
    p_remove.add_argument("--strip-all", action="store_true",
                          help="remove all metadata, including functional tags")
    p_remove.add_argument("--out", default=None,
                          help="write out of place (non-destructive)")
    p_remove.add_argument("--confirm-destructive", action="store_true")
    p_remove.add_argument("--backup", default=None,
                          help="copy the original here before an in-place edit")
    p_remove.add_argument("--exiftool", default=None)
    p_remove.set_defaults(func=cmd_remove)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
