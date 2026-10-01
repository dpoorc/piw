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


def verify_exif_identity(root):
    exiftool = shutil.which("exiftool")
    if not exiftool:
        return None, "exiftool is absent, EXIF was not planted"
    result = subprocess.run(
        [exiftool, "-j", "-Artist", "-GPSLatitude", "-Make", "-Model",
         os.path.join(root, "photo.jpg")],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    try:
        tags = json.loads(result.stdout)[0]
    except (ValueError, IndexError):
        return False, "exiftool returned no tags"
    missing = [t for t in ("Artist", "GPSLatitude", "Make", "Model")
               if not tags.get(t)]
    if missing:
        return False, "missing EXIF tags: %s" % ", ".join(missing)
    return True, "EXIF identity and GPS tags are present"


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


def check_report(root, results):
    output_dir = os.path.join(root, ".local", "prepublish")
    result = subprocess.run(
        [sys.executable, os.path.join(SCRIPTS, "report.py"),
         "--project-root", root,
         "--public-mode", "open source",
         "--known-risk", "a legacy token",
         "--stage", "intake", "--stage", "inventory"],
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


def check_g1(results):
    result = subprocess.run(
        [sys.executable, os.path.join(HERE, "g1_hygiene.py")],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode == 0:
        results.ok("gate G1 hygiene")
    else:
        results.fail("gate G1 hygiene", result.stdout.strip())


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
    check_report(target, results)
    check_g1(results)
    return results.report()


if __name__ == "__main__":
    sys.exit(main())
