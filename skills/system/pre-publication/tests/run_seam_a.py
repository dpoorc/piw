#!/usr/bin/env python3
"""Seam A: run the pre-publication scripts against the fixture.

Seam A is the automated seam. It builds the fixture, proves every
planted finding is present, runs the scripts, and checks the output
against the declared expectations. A failure here means the fixture or
a script is wrong, not that a project is clean.

Seam B is the behavioural seam: a cold agent run of SKILL.md against
the same fixture. It is run by hand and is not automated here.
"""

import argparse
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(HERE)
SCRIPTS = os.path.join(SKILL_DIR, "scripts")
sys.path.insert(0, HERE)

import make_fixture  # noqa: E402

LARGE_FILE_MIN = 5 * 1024 * 1024
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

REPORT_SECTIONS = [
    "## Header",
    "## Declared known risks",
    "## Findings",
    "## Skipped checks",
    "## Suggested remediation plan",
    "## Non-findings",
    "## Readiness summary",
]


def read_text(path):
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return handle.read()


def git_output(root, args):
    result = subprocess.run(["git", "-C", root] + args,
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                            text=True)
    return result.stdout


def verify_secret_tree(root):
    text = read_text(os.path.join(root, "src", "settings.py"))
    return "ghp_" in text, "a token shape is present in the working tree"


def verify_secret_history(root):
    history = git_output(root, ["log", "-p", "--all"])
    in_history = make_fixture.FAKE_HISTORY_SECRET in history
    in_tree = os.path.exists(os.path.join(root, make_fixture.HISTORY_SECRET_PATH))
    if not in_history:
        return False, "the history secret is not in the git log"
    if in_tree:
        return False, "the history secret is still in the working tree"
    return True, "present in history, absent from the working tree"


def verify_pii_content(root):
    text = read_text(os.path.join(root, "docs", "contact.md"))
    return make_fixture.PII_EMAIL in text, "the example email is present"


def exiftool_tags(exiftool, path, *names):
    result = subprocess.run([exiftool, "-j"] + list(names) + [path],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                            text=True)
    try:
        return json.loads(result.stdout)[0]
    except (ValueError, IndexError):
        return {}


def verify_exif_identity(root):
    exiftool = shutil.which("exiftool")
    if not exiftool:
        return None, "exiftool is absent, EXIF was not planted"
    tags = exiftool_tags(exiftool, os.path.join(root, "photo.jpg"),
                         "-Artist", "-GPSLatitude", "-Make", "-Model",
                         "-Orientation")
    missing = [t for t in ("Artist", "GPSLatitude", "Make", "Model",
                           "Orientation") if not tags.get(t)]
    if missing:
        return False, "missing EXIF tags: %s" % ", ".join(missing)
    return True, "EXIF identity, GPS, and orientation tags are present"


def verify_remote_credential(root):
    path = os.path.join(root, ".git", "config")
    if not os.path.exists(path):
        return False, "the repository has no config"
    text = read_text(path)
    if "fixture-user:fixture-token@" in text:
        return True, "a remote URL carries an embedded credential"
    return False, "the remote credential is missing"


def verify_office_author(root):
    path = os.path.join(root, "docs", "report.docx")
    try:
        with zipfile.ZipFile(path) as archive:
            core = archive.read("docProps/core.xml").decode("utf-8")
    except (OSError, KeyError, zipfile.BadZipFile):
        return False, "the document has no core properties"
    if "<dc:creator>" not in core:
        return False, "the creator field is missing"
    return True, "the creator field is present"


def verify_stray_artifact(root):
    return os.path.exists(os.path.join(root, ".DS_Store")), "the editor artifact exists"


def verify_ignore_gap(root):
    path = os.path.join(root, ".gitignore")
    lines = [l.strip() for l in read_text(path).splitlines() if l.strip()]
    direct = [l for l in lines if not l.endswith("/") and not any(c in l for c in "*?[")]
    if not direct:
        return False, "the ignore entry is not a direct file path"
    hidden = os.path.join(root, direct[0])
    if os.path.exists(hidden):
        return True, "a direct file ignore hides %s" % direct[0]
    return False, "the ignored file is missing"


def verify_large_file(root):
    path = os.path.join(root, "big.bin")
    if not os.path.exists(path):
        return False, "the large file is missing"
    size = os.path.getsize(path)
    if size < LARGE_FILE_MIN:
        return False, "the large file is only %s bytes" % size
    tracked = "big.bin" in git_output(root, ["ls-files"]).split()
    if not tracked:
        return False, "the large file is not tracked"
    return True, "tracked at %s bytes" % size


def verify_extension_mismatch(root):
    path = os.path.join(root, "broken.png")
    with open(path, "rb") as handle:
        head = handle.read(8)
    if head.startswith(PNG_SIGNATURE):
        return False, "the file is a real PNG"
    return True, "the content contradicts the extension"


VERIFIERS = {
    "secret-tree": verify_secret_tree,
    "secret-history": verify_secret_history,
    "pii-content": verify_pii_content,
    "exif-identity": verify_exif_identity,
    "office-author": verify_office_author,
    "remote-credential": verify_remote_credential,
    "stray-artifact": verify_stray_artifact,
    "ignore-gap": verify_ignore_gap,
    "large-file": verify_large_file,
    "extension-mismatch": verify_extension_mismatch,
}


class Results:
    def __init__(self):
        self.rows = []

    def add(self, name, status, detail=""):
        self.rows.append((name, status, detail))

    def ok(self, name, detail=""):
        self.add(name, "PASS", detail)

    def fail(self, name, detail=""):
        self.add(name, "FAIL", detail)

    def skip(self, name, detail=""):
        self.add(name, "SKIP", detail)

    @property
    def failed(self):
        return [r for r in self.rows if r[1] == "FAIL"]

    def report(self):
        for name, status, detail in self.rows:
            line = "  %-4s %s" % (status, name)
            if detail:
                line += " - %s" % detail
            print(line)
        print("")
        if self.failed:
            print("Seam A FAILED: %d check(s)" % len(self.failed))
            return 1
        skipped = len([r for r in self.rows if r[1] == "SKIP"])
        print("Seam A passed: %d checks, %d skipped" % (len(self.rows), skipped))
        return 0


def check_planted_findings(root, results):
    with open(os.path.join(HERE, "expected.json"), "r", encoding="utf-8") as handle:
        expected = json.load(handle)
    for finding in expected["findings"]:
        verifier = VERIFIERS.get(finding["id"])
        if verifier is None:
            results.fail("fixture: %s" % finding["id"], "no verifier is defined")
            continue
        outcome, detail = verifier(root)
        name = "fixture: %s (%s)" % (finding["id"], finding["carrier"])
        if outcome is None:
            results.skip(name, detail)
        elif outcome:
            results.ok(name, detail)
        else:
            results.fail(name, detail)


def check_inventory(root, results):
    result = subprocess.run(
        [sys.executable, os.path.join(SCRIPTS, "inventory.py"),
         "--project-root", root, "--format", "json"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        results.fail("inventory runs", result.stderr.strip())
        return None
    data = json.loads(result.stdout)
    results.ok("inventory runs")

    layers = {m["layer"]: m["present"] for m in data["meta_layers"]}
    for layer in ("version control", "credential stores",
                  "build outputs and caches"):
        if layers.get(layer):
            results.ok("inventory finds meta layer: %s" % layer)
        else:
            results.fail("inventory finds meta layer: %s" % layer)

    skipped = data["skipped_dirs"]
    if "node_modules" in skipped:
        results.ok("inventory reports node_modules as a carrier")
    else:
        results.fail("inventory reports node_modules as a carrier",
                     "skipped_dirs=%s" % skipped)

    mismatches = [m["path"] for m in data["mismatches"]]
    if "broken.png" in mismatches:
        results.ok("inventory reports the extension mismatch")
    else:
        results.fail("inventory reports the extension mismatch",
                     "mismatches=%s" % mismatches)
    return data


def run_secrets(root, gitleaks=None):
    args = [sys.executable, os.path.join(SCRIPTS, "secrets_scan.py"),
            "--project-root", root, "--format", "json"]
    if gitleaks:
        args += ["--gitleaks", gitleaks]
    return subprocess.run(args, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True)


def check_secrets(root, results):
    # A missing required tool stops the check with a clear message.
    absent = run_secrets(root, gitleaks="/nonexistent")
    if absent.returncode == 3 and "gitleaks is required" in absent.stderr:
        results.ok("secrets: missing tool stops the check")
    else:
        results.fail("secrets: missing tool stops the check",
                     "exit %s" % absent.returncode)

    if not shutil.which("gitleaks"):
        results.skip("secrets: both fixture secrets found", "gitleaks is absent")
        return

    result = run_secrets(root)
    if result.returncode != 0:
        results.fail("secrets: scan runs", result.stderr.strip())
        return
    results.ok("secrets: scan runs")
    data = json.loads(result.stdout)
    findings = data["findings"]

    pairs = {(f["location"], f["carrier"]) for f in findings}
    if any(loc.startswith("src/settings.py") and carrier == "working tree"
           for loc, carrier in pairs):
        results.ok("secrets: tree secret found")
    else:
        results.fail("secrets: tree secret found", "locations=%s" % sorted(pairs))
    if any(loc.startswith("config/credentials.py") and carrier == "git history"
           for loc, carrier in pairs):
        results.ok("secrets: history secret found")
    else:
        results.fail("secrets: history secret found", "locations=%s" % sorted(pairs))
    if findings and all(f.get("confidence") for f in findings):
        results.ok("secrets: findings carry confidence")
    else:
        results.fail("secrets: findings carry confidence")


def run_pii(root, module=None):
    args = [sys.executable, os.path.join(SCRIPTS, "pii.py"),
            "--project-root", root, "--format", "json"]
    if module:
        args += ["--presidio-module", module]
    return subprocess.run(args, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True)


def check_pii(root, results):
    # A missing required tool stops the check with a clear message.
    absent = run_pii(root, module="nonexistent_xyz")
    if absent.returncode == 3 and "presidio is required" in absent.stderr:
        results.ok("pii: missing tool stops the check")
    else:
        results.fail("pii: missing tool stops the check",
                     "exit %s" % absent.returncode)

    if importlib.util.find_spec("presidio_analyzer") is None:
        results.skip("pii: fixture PII found", "presidio is absent")
        return

    result = run_pii(root)
    if result.returncode != 0:
        results.fail("pii: scan runs", result.stderr.strip())
        return
    results.ok("pii: scan runs")
    data = json.loads(result.stdout)
    findings = data["findings"]

    pairs = {(f["entity"], f["location"]) for f in findings}
    if any(entity == "EMAIL_ADDRESS" and loc.startswith("docs/contact.md")
           for entity, loc in pairs):
        results.ok("pii: email found")
    else:
        results.fail("pii: email found", "entities=%s" % sorted(pairs))
    if any(entity == "PHONE_NUMBER" and loc.startswith("docs/contact.md")
           for entity, loc in pairs):
        results.ok("pii: phone found")
    else:
        results.fail("pii: phone found", "entities=%s" % sorted(pairs))
    if findings and all(f.get("confidence") for f in findings):
        results.ok("pii: findings carry confidence")
    else:
        results.fail("pii: findings carry confidence")


def run_metadata(root, extra=None):
    args = [sys.executable, os.path.join(SCRIPTS, "metadata.py"), "scan",
            "--project-root", root, "--format", "json"] + (extra or [])
    return subprocess.run(args, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True)


def check_metadata(root, results):
    # Missing exiftool: the file-metadata check is skipped, the git checks run.
    absent = run_metadata(root, ["--no-exiftool"])
    if absent.returncode == 0:
        data = json.loads(absent.stdout)
        skipped = [s["check"] for s in data.get("skipped_checks", [])]
        if "file metadata" in skipped:
            results.ok("metadata: missing exiftool records a skip")
        else:
            results.fail("metadata: missing exiftool records a skip",
                         "skipped=%s" % skipped)
        if any(f["location"].startswith("remote:")
               for f in data.get("findings", [])):
            results.ok("metadata: git checks run without exiftool")
        else:
            results.fail("metadata: git checks run without exiftool")
    else:
        results.fail("metadata: missing exiftool records a skip",
                     "exit %s" % absent.returncode)

    if not shutil.which("exiftool"):
        results.skip("metadata: EXIF and office author found", "exiftool is absent")
        return

    result = run_metadata(root)
    if result.returncode != 0:
        results.fail("metadata: scan runs", result.stderr.strip())
        return
    results.ok("metadata: scan runs")
    data = json.loads(result.stdout)
    by_location = {f["location"]: f for f in data["findings"]}

    photo = by_location.get("photo.jpg", {})
    if {"Artist", "GPSLatitude", "Make", "Model"} <= set(photo.get("tags", [])):
        results.ok("metadata: EXIF identity found")
    else:
        results.fail("metadata: EXIF identity found", "tags=%s" % photo.get("tags"))
    doc = by_location.get("docs/report.docx", {})
    if "Creator" in doc.get("tags", []):
        results.ok("metadata: office author found")
    else:
        results.fail("metadata: office author found", "tags=%s" % doc.get("tags"))
    if any(f["location"].startswith("remote:") and f["severity"] == "critical"
           for f in data["findings"]):
        results.ok("metadata: remote credential found")
    else:
        results.fail("metadata: remote credential found")
    if any("mailmap" in line for line in data.get("advice", [])):
        results.ok("metadata: commit identity options presented")
    else:
        results.fail("metadata: commit identity options presented")

    import tempfile
    clean = tempfile.mkdtemp(prefix="prepublish-meta-")
    exiftool = shutil.which("exiftool")
    out_image = os.path.join(clean, "photo.jpg")
    code, _ = run_remove(root, os.path.join(root, "photo.jpg"), "--out", out_image)
    tags = exiftool_tags(exiftool, out_image, "-Orientation", "-Artist",
                         "-GPSLatitude") if code == 0 else {}
    if code == 0 and tags.get("Orientation") and not tags.get("Artist") \
            and not tags.get("GPSLatitude"):
        results.ok("metadata: selective removal keeps orientation")
    else:
        results.fail("metadata: selective removal keeps orientation",
                     "exit %s tags=%s" % (code, tags))

    out_doc = os.path.join(clean, "report.docx")
    code, _ = run_remove(root, os.path.join(root, "docs", "report.docx"),
                         "--out", out_doc)
    doc_tags = exiftool_tags(exiftool, out_doc, "-XMP:Creator",
                             "-XML:LastModifiedBy") if code == 0 else {"Creator": "?"}
    if code == 0 and not doc_tags.get("Creator") \
            and not doc_tags.get("LastModifiedBy"):
        results.ok("metadata: OOXML removal removes the author")
    else:
        results.fail("metadata: OOXML removal removes the author",
                     "exit %s tags=%s" % (code, doc_tags))

    code, out = run_remove(root, os.path.join(root, "photo.jpg"))
    if code == 1 and "destructive" in out:
        results.ok("metadata: in-place removal is gated")
    else:
        results.fail("metadata: in-place removal is gated", "exit %s" % code)
    shutil.rmtree(clean, ignore_errors=True)


def run_remove(root, path, *extra):
    args = [sys.executable, os.path.join(SCRIPTS, "metadata.py"), "remove",
            path, "--project-root", root] + list(extra)
    result = subprocess.run(args, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, text=True)
    return result.returncode, result.stdout + result.stderr


def run_hygiene(root, extra=None):
    args = [sys.executable, os.path.join(SCRIPTS, "hygiene.py"),
            "--project-root", root, "--format", "json"] + (extra or [])
    return subprocess.run(args, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True)


def check_hygiene(root, results):
    result = run_hygiene(root)
    if result.returncode != 0:
        results.fail("hygiene: scan runs", result.stderr.strip())
        return
    results.ok("hygiene: scan runs")
    findings = json.loads(result.stdout)["findings"]

    def has(location, category):
        return any(f["location"] == location and f["category"] == category
                   for f in findings)

    if has(".DS_Store", "stray file"):
        results.ok("hygiene: stray artifact found")
    else:
        results.fail("hygiene: stray artifact found")
    if any(f["location"] == ".gitignore"
           and f["remediation"] == "add-protection" and f.get("suggestion")
           for f in findings):
        results.ok("hygiene: non-resilient ignore found with a suggestion")
    else:
        results.fail("hygiene: non-resilient ignore found with a suggestion")
    big = [f for f in findings if f["location"] == "big.bin"]
    if big and big[0].get("tracked") is True and big[0]["severity"] == "high":
        results.ok("hygiene: tracked large file found")
    else:
        results.fail("hygiene: tracked large file found", "big=%s" % big)
    if has("broken.png", "extension mismatch"):
        results.ok("hygiene: extension mismatch found")
    else:
        results.fail("hygiene: extension mismatch found")
    if has("src/notes/about-damien.md", "internal-facing document"):
        results.ok("hygiene: internal-facing document found")
    else:
        results.fail("hygiene: internal-facing document found")

    import tempfile
    probe = tempfile.mkdtemp(prefix="prepublish-hyg-")
    with open(os.path.join(probe, "blob.dat"), "wb") as handle:
        handle.truncate(6 * 1024 * 1024)
    with open(os.path.join(probe, "generic.md"), "w", encoding="utf-8") as handle:
        handle.write("TODO: tidy this later\n")
    with open(os.path.join(probe, "leaky.md"), "w", encoding="utf-8") as handle:
        handle.write("TODO: see https://jira.internal/browse/ABC-1\n")
    data = json.loads(run_hygiene(probe).stdout)
    blob = [f for f in data["findings"] if f["location"] == "blob.dat"]
    if blob and blob[0]["severity"] == "medium" \
            and blob[0].get("tracked") is False:
        results.ok("hygiene: untracked large file is medium")
    else:
        results.fail("hygiene: untracked large file is medium", "blob=%s" % blob)
    data = json.loads(run_hygiene(probe, ["--large-mb", "10"]).stdout)
    if not any(f["location"] == "blob.dat" for f in data["findings"]):
        results.ok("hygiene: the large-file threshold is configurable")
    else:
        results.fail("hygiene: the large-file threshold is configurable")
    if any(f["location"] == "leaky.md" for f in data["findings"]) \
            and not any(f["location"] == "generic.md" for f in data["findings"]):
        results.ok("hygiene: only leaky TODO comments are reported")
    else:
        results.fail("hygiene: only leaky TODO comments are reported")
    shutil.rmtree(probe, ignore_errors=True)


def check_report(root, results):
    output_dir = os.path.join(root, ".local", "prepublish")
    args = [sys.executable, os.path.join(SCRIPTS, "report.py"),
            "--project-root", root,
            "--public-mode", "open source",
            "--known-risk", "a legacy token",
            "--stage", "intake", "--stage", "inventory", "--stage", "scan"]
    for name in ("secrets.json", "pii.json", "metadata.json", "hygiene.json"):
        path = os.path.join(output_dir, name)
        if os.path.exists(path):
            args += ["--findings", path]
    result = subprocess.run(
        args,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        results.fail("report runs", result.stderr.strip())
        return
    report_path = os.path.join(output_dir, "report.md")
    if not os.path.exists(report_path):
        results.fail("report writes report.md")
        return
    results.ok("report writes report.md")
    text = read_text(report_path)
    missing = [s for s in REPORT_SECTIONS if s not in text]
    if missing:
        results.fail("report has all sections", "missing: %s" % ", ".join(missing))
    else:
        results.ok("report has all sections")
    if "a legacy token" in text:
        results.ok("report carries the declared known risk")
    else:
        results.fail("report carries the declared known risk")
    if shutil.which("gitleaks"):
        if "rotate-credential" in text and "Credential rotation hand-off" in text:
            results.ok("report carries the rotation hand-off")
        else:
            results.fail("report carries the rotation hand-off")
    if importlib.util.find_spec("presidio_analyzer") is not None:
        if "personal data" in text:
            results.ok("report carries the PII findings")
        else:
            results.fail("report carries the PII findings")
    if os.path.exists(os.path.join(output_dir, "metadata.json")):
        if "Commit identity options" in text:
            results.ok("report carries the commit identity options")
        else:
            results.fail("report carries the commit identity options")
    if os.path.exists(os.path.join(output_dir, "hygiene.json")):
        if "Ignore additions" in text:
            results.ok("report carries the ignore additions")
        else:
            results.fail("report carries the ignore additions")


def check_g1(results):
    result = subprocess.run(
        [sys.executable, os.path.join(HERE, "g1_hygiene.py")],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode == 0:
        results.ok("gate G1 hygiene")
    else:
        results.fail("gate G1 hygiene", result.stdout.strip())


def run_fixes(root, args):
    result = subprocess.run(
        [sys.executable, os.path.join(SCRIPTS, "fixes.py"),
         "--project-root", root] + args,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return result.returncode, result.stdout


def check_gate(results):
    import tempfile
    gate = tempfile.mkdtemp(prefix="prepublish-gate-")
    source = os.path.join(gate, "fixes-in.json")
    with open(source, "w", encoding="utf-8") as handle:
        json.dump([
            {"finding": "secret-tree", "class": "secrets",
             "carrier": "working tree", "location": "src/settings.py",
             "kind": "forward-fix", "action": "Remove the token.",
             "reversible": True},
            {"finding": "secret-history", "class": "secrets",
             "carrier": "git history", "location": "config/credentials.py",
             "kind": "history-rewrite", "action": "Rewrite history.",
             "destructive": True, "restore": "git reset --hard backup"},
        ], handle)
    backup = os.path.join(gate, "backup.bundle")
    open(backup, "w").close()

    steps = [
        (("add", "--from", source), 0, "propose fixes"),
        (("apply", "F1"), 1, "refuse to apply an unapproved fix"),
        (("approve", "F1", "F2", "--batch"), 1,
         "refuse to batch a destructive fix"),
        (("approve", "F1", "F2"), 1, "refuse a batch without --batch"),
        (("approve", "F1"), 0, "approve a low-risk fix"),
        (("approve", "F2"), 0, "approve a destructive fix alone"),
        (("apply", "F2", "--confirm-destructive"), 1,
         "refuse a destructive fix with no backup"),
        (("apply", "F2", "--confirm-destructive", "--backup", backup), 0,
         "apply a destructive fix with a backup"),
        (("verify", "F1"), 1, "refuse to verify an unapplied fix"),
        (("apply", "F1"), 0, "apply an approved fix"),
        (("verify", "F1"), 0, "verify an applied fix"),
    ]
    for args, expected, label in steps:
        code, out = run_fixes(gate, list(args))
        if code != expected:
            results.fail("gate: %s" % label, "exit %s, expected %s" % (code, expected))
            continue
        if "--backup" in args and "Restore:" not in out:
            results.fail("gate: %s" % label, "no restore command printed")
            continue
        results.ok("gate: %s" % label)
    shutil.rmtree(gate, ignore_errors=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", default=None,
                        help="reuse or build the fixture at this path")
    args = parser.parse_args()

    target = args.target
    if target is None:
        import tempfile
        target = tempfile.mkdtemp(prefix="prepublish-seam-a-")
    make_fixture.build(target, exiftool=shutil.which("exiftool"))
    print("Fixture: %s" % target)
    print("")

    results = Results()
    check_planted_findings(target, results)
    check_inventory(target, results)
    check_secrets(target, results)
    check_pii(target, results)
    check_metadata(target, results)
    check_hygiene(target, results)
    check_report(target, results)
    check_g1(results)
    check_gate(results)
    return results.report()


if __name__ == "__main__":
    sys.exit(main())
