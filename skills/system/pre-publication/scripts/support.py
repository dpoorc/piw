#!/usr/bin/env python3
"""Shared helpers for the pre-publication scripts.

Standard library only. The vector scripts import this module. It holds
the output path, the severity order, the text reader, the git helpers,
and the finding builder. This is the single source for each.
"""

import os
import subprocess

OUTPUT_SUBPATH = os.path.join(".local", "prepublish")
SEVERITY_RANK = {"critical": 4, "high": 3, "medium": 2, "low": 1}
READ_LIMIT = 2 * 1024 * 1024


def output_dir(project_root):
    return os.path.join(os.path.abspath(project_root), OUTPUT_SUBPATH)


def read_text(path, limit=READ_LIMIT):
    try:
        if os.path.getsize(path) > limit:
            return None
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            return handle.read()
    except OSError:
        return None


def run_git(root, args):
    return subprocess.run(["git", "-C", root] + args,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          text=True)


def is_git_repo(root):
    # A worktree has a .git file, not a directory. Ask git instead.
    result = run_git(root, ["rev-parse", "--is-inside-work-tree"])
    return result.returncode == 0 and result.stdout.strip() == "true"


def make_finding(class_name, category, location, severity, remediation,
                 carrier="working tree", confidence="likely", **extra):
    item = {
        "class": class_name,
        "category": category,
        "carrier": carrier,
        "location": location,
        "severity": severity,
        "confidence": confidence,
        "remediation": remediation,
    }
    item.update(extra)
    return item
