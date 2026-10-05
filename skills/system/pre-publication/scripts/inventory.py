#!/usr/bin/env python3
"""Inventory a project's content and meta layers for pre-publication.

Read-only. Reports what is present. Does not scan for leaks.
"""

import argparse
import json
import os
import sys

OUTPUT_SUBPATH = os.path.join(".local", "prepublish")

# Directories that are carriers in themselves. Do not recurse into them;
# report their presence instead.
HEAVY_DIRS = {
    ".git", "node_modules", "vendor", "target", "dist", "build",
    "__pycache__", ".venv", "venv", ".tox", ".mypy_cache", ".pytest_cache",
}

CATEGORY_EXT = {
    "text": {".md", ".txt", ".rst", ".adoc", ".tex", ".html", ".htm", ".css",
             ".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx", ".py", ".go", ".rs",
             ".java", ".c", ".h", ".cc", ".cpp", ".hpp", ".sh", ".bash", ".zsh",
             ".yml", ".yaml", ".json", ".toml", ".ini", ".cfg", ".conf", ".xml",
             ".rb", ".php", ".pl", ".lua", ".sql", ".env", ".properties"},
    "image": {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".tif", ".tiff",
              ".webp", ".svg", ".ico", ".heic"},
    "office": {".docx", ".doc", ".xlsx", ".xls", ".pptx", ".ppt", ".odt",
               ".ods", ".odp", ".rtf"},
    "pdf": {".pdf"},
    "data": {".csv", ".tsv", ".parquet", ".db", ".sqlite", ".sqlite3",
             ".jsonl", ".ndjson", ".arrow", ".feather", ".h5", ".hdf5"},
    "archive": {".zip", ".tar", ".gz", ".tgz", ".bz2", ".xz", ".7z", ".rar",
                ".jar", ".war"},
    "binary": {".exe", ".dll", ".so", ".dylib", ".bin", ".o", ".a", ".class",
               ".wasm", ".pdb", ".lib", ".dmg", ".iso"},
}

# Extensions whose content we expect to verify against magic bytes.
VERIFY_CATEGORIES = {"image", "office", "pdf", "archive", "binary"}

MAGIC = [
    (b"\x89PNG\r\n\x1a\n", "image"),
    (b"\xff\xd8\xff", "image"),
    (b"GIF87a", "image"),
    (b"GIF89a", "image"),
    (b"BM", "image"),
    (b"II*\x00", "image"),
    (b"MM\x00*", "image"),
    (b"%PDF", "pdf"),
    (b"PK\x03\x04", "archive"),   # zip family, includes docx/xlsx/pptx/odt/jar
    (b"\x7fELF", "binary"),
    (b"MZ", "binary"),
    (b"\x1f\x8b", "archive"),     # gzip
    (b"BZh", "archive"),
    (b"\xfd7zXZ\x00", "archive"),
]

META_LAYERS = [
    ("version control", [".git"], True),
    ("ci/cd config", [".github/workflows", ".gitlab-ci.yml", ".circleci", ".travis.yml", "Jenkinsfile", "azure-pipelines.yml"], False),
    ("container and infra", ["Dockerfile", "docker-compose.yml", "docker-compose.yaml", "compose.yml", "main.tf", "ansible", "playbook.yml"], False),
    ("dependency manifests", ["package.json", "go.mod", "Cargo.toml", "pyproject.toml", "requirements.txt", "pom.xml", "build.gradle", "Gemfile", "composer.json", "Makefile"], False),
    ("credential stores", [".env", ".envrc", ".netrc", ".npmrc", ".pypirc", ".docker/config.json", ".aws", ".ssh", ".gnupg"], False),
    ("build outputs and caches", ["dist", "build", "node_modules", "target", "__pycache__", ".venv", "venv"], True),
    ("editor and os artifacts", [".vscode", ".idea", ".DS_Store", "Thumbs.db", "desktop.ini"], True),
]


def category_for_ext(ext):
    ext = ext.lower()
    for category, exts in CATEGORY_EXT.items():
        if ext in exts:
            return category
    return None


def detect_magic(path, size=16):
    try:
        with open(path, "rb") as handle:
            head = handle.read(size)
    except OSError:
        return None
    for signature, category in MAGIC:
        if head.startswith(signature):
            return category
    # No known signature. Decodable content with no null byte is text.
    if head and b"\x00" not in head:
        try:
            head.decode("utf-8")
            return "text"
        except UnicodeDecodeError:
            return None
    return None


def path_exists(root, rel):
    return os.path.exists(os.path.join(root, rel))


def _is_within(path, parent):
    return path == parent or path.startswith(parent + os.sep)


def iter_files(root):
    """Walk the project. Return (files, skipped_dirs).

    Each file is (relpath, abspath, category). The output directory is
    excluded by exact path. Heavy directories are reported as carriers
    and not recursed into.
    """
    root = os.path.abspath(root)
    output_dir = os.path.join(root, OUTPUT_SUBPATH)
    files = []
    skipped = []

    for dirpath, dirnames, filenames in os.walk(root):
        if _is_within(os.path.abspath(dirpath), output_dir):
            dirnames[:] = []
            continue
        keep = []
        for name in dirnames:
            full = os.path.join(dirpath, name)
            if name in HEAVY_DIRS:
                skipped.append(os.path.relpath(full, root))
            else:
                keep.append(name)
        dirnames[:] = keep

        for name in filenames:
            path = os.path.join(dirpath, name)
            if _is_within(os.path.abspath(path), output_dir):
                continue
            rel = os.path.relpath(path, root)
            ext = os.path.splitext(name)[1]
            category = category_for_ext(ext) or "other"
            files.append((rel, path, category))
    return files, skipped


def text_files(root):
    """Return (relpath, abspath) for every text-like file."""
    files, _ = iter_files(root)
    return [(rel, path) for rel, path, category in files if category == "text"]


def inventory(root):
    root = os.path.abspath(root)
    files, skipped_dirs = iter_files(root)

    counts = {c: 0 for c in CATEGORY_EXT}
    counts["other"] = 0
    total = 0
    mismatches = []

    for rel, path, category in files:
        counts[category] = counts.get(category, 0) + 1
        total += 1

        if category in VERIFY_CATEGORIES:
            detected = detect_magic(path)
            if detected is None:
                mismatches.append({
                    "path": rel,
                    "expected": category,
                    "detected": None,
                    "reason": "content could not be identified",
                })
            elif detected != category:
                # zip-based office documents are legitimately zip files
                if category == "office" and detected == "archive":
                    continue
                mismatches.append({
                    "path": rel,
                    "expected": category,
                    "detected": detected,
                    "reason": "content contradicts the extension",
                })

    meta = []
    for label, candidates, _is_dir in META_LAYERS:
        found = [c for c in candidates if path_exists(root, c)]
        meta.append({"layer": label, "present": bool(found), "paths": found})

    return {
        "project_root": root,
        "total_files": total,
        "counts": counts,
        "meta_layers": meta,
        "skipped_dirs": sorted(set(skipped_dirs)),
        "mismatches": mismatches,
    }


def render_text(info):
    lines = []
    lines.append("Pre-publication inventory")
    lines.append("")
    lines.append("project root: %s" % info["project_root"])
    lines.append("total files:  %s" % info["total_files"])
    lines.append("")
    lines.append("content by category:")
    for category, count in sorted(info["counts"].items()):
        if count:
            lines.append("  %-9s %s" % (category, count))
    lines.append("")
    lines.append("meta layers:")
    for layer in info["meta_layers"]:
        mark = "present" if layer["present"] else "absent"
        detail = (" (%s)" % ", ".join(layer["paths"])) if layer["paths"] else ""
        lines.append("  %-26s %s%s" % (layer["layer"], mark, detail))
    if info["skipped_dirs"]:
        lines.append("")
        lines.append("not recursed into (reported as carriers):")
        for path in info["skipped_dirs"]:
            lines.append("  %s" % path)
    lines.append("")
    lines.append("extension and content mismatch: %s" % len(info["mismatches"]))
    for item in info["mismatches"]:
        detected = item["detected"] or "unknown"
        lines.append("  %s: expected %s, detected %s - %s"
                     % (item["path"], item["expected"], detected, item["reason"]))
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", default=".")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    args = parser.parse_args()

    info = inventory(args.project_root)
    if args.format == "json":
        print(json.dumps(info, indent=2))
    else:
        print(render_text(info))
    return 0


if __name__ == "__main__":
    sys.exit(main())
