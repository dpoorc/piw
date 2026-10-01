#!/usr/bin/env python3
"""Prepare the pre-publication output directory.

Creates .local/prepublish/ at the project root and reports whether that
path is gitignored. Never edits .gitignore.
"""

import argparse
import json
import os
import subprocess
import sys

OUTPUT_SUBPATH = os.path.join(".local", "prepublish")
PROPOSED_IGNORE_ENTRY = ".local"


def run_git(root, args):
    return subprocess.run(
        ["git", "-C", root] + args,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )


def is_git_repo(root):
    result = run_git(root, ["rev-parse", "--is-inside-work-tree"])
    return result.returncode == 0 and result.stdout.strip() == "true"


def is_ignored(root, path):
    # exit 0 = ignored, 1 = not ignored, 128 = not a repo
    result = run_git(root, ["check-ignore", "-q", path])
    return result.returncode == 0


def prepare(project_root):
    project_root = os.path.abspath(project_root)
    output_dir = os.path.join(project_root, OUTPUT_SUBPATH)
    created = not os.path.isdir(output_dir)
    os.makedirs(output_dir, exist_ok=True)

    git = is_git_repo(project_root)
    ignored = is_ignored(project_root, OUTPUT_SUBPATH) if git else False

    return {
        "project_root": project_root,
        "output_dir": output_dir,
        "created": created,
        "is_git_repo": git,
        "history_carrier": "git" if git else "absent",
        "output_ignored": ignored if git else None,
        "proposed_ignore_entry": None if (not git or ignored) else PROPOSED_IGNORE_ENTRY,
    }


def render_text(info):
    lines = []
    lines.append("Pre-publication output directory")
    lines.append("")
    lines.append("project root:   %s" % info["project_root"])
    lines.append("output dir:     %s" % info["output_dir"])
    lines.append("created:        %s" % ("yes" if info["created"] else "already existed"))
    lines.append("git repo:       %s" % ("yes" if info["is_git_repo"] else "no"))
    if not info["is_git_repo"]:
        lines.append("history carrier: absent - no git repository")
    elif info["output_ignored"]:
        lines.append("gitignored:     yes")
    else:
        lines.append("gitignored:     NO")
        lines.append("")
        lines.append("The output directory is not ignored. Propose this single")
        lines.append("line for .gitignore as a gated fix:")
        lines.append("")
        lines.append("    %s" % info["proposed_ignore_entry"])
        lines.append("")
        lines.append("Do not edit .gitignore without approval.")
    lines.append("")
    lines.append("Exclude this exact path from every scan:")
    lines.append("    %s" % os.path.join(".local", "prepublish"))
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", default=".")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    args = parser.parse_args()

    info = prepare(args.project_root)
    if args.format == "json":
        print(json.dumps(info, indent=2))
    else:
        print(render_text(info))
    return 0


if __name__ == "__main__":
    sys.exit(main())
