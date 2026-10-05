#!/usr/bin/env python3
"""Build the pre-publication fixture project.

Creates a synthetic project with planted findings. The fixture is built
in a target directory (default: a temporary directory) so that no binary
assets or nested git repository are committed.

Findings planted:
  - a fake secret in the working tree
  - a fake secret that exists only in git history
  - a PII string
  - an image with EXIF identity, GPS, and orientation tags
  - an Office document with an author field
  - a remote URL with an embedded credential
  - a license mismatch and a vendored file with no notice
  - an AUTHORS file with a personal name
  - a stray editor artifact
  - a non-resilient .gitignore entry
  - a tracked large file
  - an image whose content contradicts its extension
"""

import argparse
import base64
import os
import shutil
import subprocess
import sys
import zipfile

# A valid 1x1 JPEG, used as the base for the EXIF image.
JPEG_1X1 = (
    "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0a"
    "HBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAABAAAAAAAA"
    "AAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q=="
)

# Clearly fake. Reserved example domain and a non-functional token shape.
FAKE_TREE_SECRET = "ghp_aB3dE5gH7jK9lM1nO3pQ5rS7tU9vW1xY3zA5"
FAKE_HISTORY_SECRET = "ghp_zyxwvutsrqponmlkjihgfedcba9876543210"
PII_EMAIL = "jane.doe@example.com"
PII_PHONE = "+1-202-555-0143"

HISTORY_SECRET_PATH = "config/credentials.py"


def run(args, cwd):
    subprocess.run(args, cwd=cwd, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def git(args, cwd):
    # The host may export GIT_AUTHOR_* / GIT_COMMITTER_*. Pin the fixture
    # identity so the metadata scan is deterministic.
    env = dict(os.environ)
    env.update({
        "GIT_AUTHOR_NAME": "Fixture",
        "GIT_AUTHOR_EMAIL": "fixture@example.com",
        "GIT_COMMITTER_NAME": "Fixture",
        "GIT_COMMITTER_EMAIL": "fixture@example.com",
    })
    subprocess.run(["git"] + args, cwd=cwd, check=True, env=env,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)


def make_docx(path, author):
    """Write a minimal OOXML document with a core-properties author."""
    content_types = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
        "</Types>"
    )
    rels = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        "</Relationships>"
    )
    document = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        "<w:body><w:p><w:r><w:t>Fixture document</w:t></w:r></w:p></w:body></w:document>"
    )
    core = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/">'
        "<dc:creator>%s</dc:creator><cp:lastModifiedBy>%s</cp:lastModifiedBy>"
        "</cp:coreProperties>" % (author, author)
    )
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("[Content_Types].xml", content_types)
        archive.writestr("_rels/.rels", rels)
        archive.writestr("word/document.xml", document)
        archive.writestr("docProps/core.xml", core)


def build(target, exiftool=None):
    if os.path.exists(target):
        shutil.rmtree(target)
    os.makedirs(target)
    run(["git", "init", "-q"], target)
    # A remote URL with an embedded credential. The metadata vector must
    # find it; the secret scanners do not, because `.git/config` is not in
    # the working tree.
    git(["remote", "add", "origin",
         "https://fixture-user:fixture-token@example.com/org/repo.git"], target)

    # Plain content. The README declares MIT; the LICENSE file is
    # Apache-2.0, so the declared and the actual license disagree.
    write(os.path.join(target, "README.md"),
          "# Fixture project\n\nThis project is licensed under the MIT License.\n")
    write(os.path.join(target, "LICENSE"),
          "                                 Apache License\n"
          "                           Version 2.0, January 2004\n"
          "                        http://www.apache.org/licenses/\n")
    write(os.path.join(target, "AUTHORS"),
          "Damien Fixture <damien@example.com>\n")

    # Vendored code with no license or notice beside it.
    write(os.path.join(target, "vendor", "lib", "foo.c"),
          "int foo(void) { return 0; }\n")
    write(os.path.join(target, "src", "app.py"), "def main():\n    return 0\n")
    write(os.path.join(target, "docs", "contact.md"),
          "Contact: %s, %s\n" % (PII_EMAIL, PII_PHONE))

    # A fake secret in the working tree.
    write(os.path.join(target, "src", "settings.py"),
          'API_TOKEN = "%s"\n' % FAKE_TREE_SECRET)

    # A credential store.
    write(os.path.join(target, ".env"),
          "DATABASE_URL=postgres://fixture:fixture@localhost:5432/fixture\n")

    # A non-resilient .gitignore entry, and the file it hides.
    write(os.path.join(target, ".gitignore"), "src/notes/about-damien.md\n")
    write(os.path.join(target, "src", "notes", "about-damien.md"),
          "Internal notes.\n")

    # Stray editor artifacts.
    write(os.path.join(target, ".DS_Store"), "")
    write(os.path.join(target, "notes.bak"), "draft\n")

    # A heavy directory, reported as a carrier and not recursed into.
    write(os.path.join(target, "node_modules", "pkg", "index.js"), "module.exports = 1\n")

    # An image whose content contradicts its extension.
    write(os.path.join(target, "broken.png"), "this is not a png\n")

    # An image with EXIF identity and GPS tags.
    image_path = os.path.join(target, "photo.jpg")
    with open(image_path, "wb") as handle:
        handle.write(base64.b64decode(JPEG_1X1))
    if exiftool:
        subprocess.run([exiftool, "-overwrite_original",
                        "-Artist=Damien Fixture",
                        "-GPSLatitude=51.5", "-GPSLongitude=-0.12",
                        "-Make=FixtureCam", "-Model=Model X",
                        "-Orientation#=6",
                        image_path],
                       check=False, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL)

    # An Office document with an author field.
    make_docx(os.path.join(target, "docs", "report.docx"), "Damien Fixture")

    # A tracked large file.
    big = os.path.join(target, "big.bin")
    with open(big, "wb") as handle:
        handle.truncate(6 * 1024 * 1024)

    # Commit a secret, then remove it, so it lives only in history.
    write(os.path.join(target, HISTORY_SECRET_PATH),
          'LEGACY_TOKEN = "%s"\n' % FAKE_HISTORY_SECRET)
    git(["add", "."], target)
    git(["commit", "-q", "-m", "initial commit"], target)
    git(["rm", "-q", HISTORY_SECRET_PATH], target)
    git(["commit", "-q", "-m", "remove legacy credentials"], target)

    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", default=None,
                        help="fixture directory (default: a temporary directory)")
    parser.add_argument("--exiftool", default=shutil.which("exiftool"))
    args = parser.parse_args()

    target = args.target
    if target is None:
        import tempfile
        target = tempfile.mkdtemp(prefix="prepublish-fixture-")

    build(target, exiftool=args.exiftool)
    print(target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
