#!/usr/bin/env python3
"""Git history rewrite for pre-publication.

A destructive, user-approved step. It is never automatic, and it is
never a substitute for credential rotation.

`plan` is read-only. It prints the backup ref, the bundle, the restore
command, and the exact `git-filter-repo` command.

`run` takes a backup ref and a verified `git bundle`, prints the restore
command, rewrites the local branches and tags, expires the reflog, and
garbage collects. It refuses without `--confirm-destructive`.

`verify` re-scans the rewritten refs to confirm the target is gone.

The rewrite never pushes. Forks, clones, CI artifacts, pull-request
refs, and host-side caches keep the old history until each is dealt
with.

The backup ref and the bundle keep the old history on purpose. `verify`
checks the rewritten refs, not the backup.
"""

import argparse
import datetime
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import support  # noqa: E402

REPLACEMENT = "***REMOVED***"
BACKUP_PREFIX = "refs/backup/prepublish-"


def output_dir(project_root):
    return support.output_dir(project_root)


def filter_repo_path():
    return shutil.which("git-filter-repo")


def target_label(args):
    if args.path:
        return "path `%s`" % args.path
    return "literal `%s`" % args.replace


def stamp():
    return datetime.datetime.now().strftime("%Y%m%d-%H%M%S")


def names(project_root, when):
    return {
        "ref": "refs/backup/prepublish-%s" % when,
        "bundle": os.path.join(output_dir(project_root),
                               "prepublish-%s.bundle" % when),
    }


def restore_commands(project_root, backup):
    return [
        "git clone %s %s-restored" % (backup["bundle"], project_root),
        "git reset --hard %s" % backup["ref"],
    ]


def rewritten_refs(root):
    """Every local ref, except the backup ref.

    The backup ref is deliberately excluded, so it survives the rewrite.
    A glob such as `refs/heads/*` does not work here; filter-repo passes
    it to `git rev-list` unchanged. Resolve the names first.
    """
    proc = support.run_git(root, ["for-each-ref", "--format=%(refname)"])
    return [ref for ref in proc.stdout.split()
            if not ref.startswith(BACKUP_PREFIX)]


def filter_repo_command(args, refs):
    parts = ["git", "filter-repo"]
    if args.path:
        parts += ["--path", args.path, "--invert-paths"]
    else:
        parts += ["--replace-text", "<replace-text-file>"]
    parts += ["--refs"] + refs + ["--force"]
    return " ".join(parts)


def validate_target(args):
    if args.replace is not None:
        if not args.replace:
            return "Refused: --replace needs a non-empty literal."
        if "\n" in args.replace or "==>" in args.replace:
            return ("Refused: --replace must not contain a newline or the "
                    "sequence `==>`.")
    if args.path is not None and not args.path:
        return "Refused: --path needs a non-empty path."
    return None


def require_repo(root):
    if not support.is_git_repo(root):
        print("Refused: not a git repository: %s" % root)
        return False
    return True


def require_tool():
    path = filter_repo_path()
    if path is None:
        print("Refused: git-filter-repo is required and was not found. "
              "Install it, then run this command again.")
        return None
    return path


def cmd_plan(args):
    root = os.path.abspath(args.project_root)
    if not require_repo(root):
        return 1
    if require_tool() is None:
        return 1
    problem = validate_target(args)
    if problem:
        print(problem)
        return 1
    refs = rewritten_refs(root)
    if not refs:
        print("Refused: no local branch or tag to rewrite.")
        return 1
    backup = names(root, stamp())
    lines = ["Rewrite plan", ""]
    lines.append("- target: %s" % target_label(args))
    lines.append("- refs: %s" % ", ".join(refs))
    lines.append("- backup ref: %s" % backup["ref"])
    lines.append("- bundle: %s" % backup["bundle"])
    for command in restore_commands(root, backup):
        lines.append("- restore: %s" % command)
    lines.append("- command: %s" % filter_repo_command(args, refs))
    lines.append("")
    lines.append("Warnings:")
    lines.append("- This rewrites local history. It never pushes.")
    lines.append("- The rewrite removes the origin remote to prevent an "
                 "accidental push.")
    lines.append("- Forks, clones, CI artifacts, PR refs, and host caches "
                 "keep the secret.")
    lines.append("- Rotation is separate. A rewrite does not revoke a "
                 "credential.")
    lines.append("- The backup ref and the bundle keep the old history on "
                 "purpose.")
    print("\n".join(lines))
    return 0


def write_replace_file(root, literal):
    handle, path = tempfile.mkstemp(prefix="prepublish-replace-", suffix=".txt",
                                    dir=output_dir(root))
    with os.fdopen(handle, "w", encoding="utf-8") as stream:
        stream.write("%s==>%s\n" % (literal, REPLACEMENT))
    return path


def cmd_run(args):
    root = os.path.abspath(args.project_root)
    if not require_repo(root):
        return 1
    tool = require_tool()
    if tool is None:
        return 1
    problem = validate_target(args)
    if problem:
        print(problem)
        return 1
    if not args.confirm_destructive:
        print("Refused: a history rewrite is destructive. Pass "
              "--confirm-destructive after the user approves the plan.")
        return 1
    refs = rewritten_refs(root)
    if not refs:
        print("Refused: no local branch or tag to rewrite.")
        return 1
    os.makedirs(output_dir(root), exist_ok=True)
    backup = names(root, stamp())
    if os.path.exists(backup["bundle"]):
        print("Refused: the bundle already exists: %s" % backup["bundle"])
        return 1

    # Take both backups before any rewrite.
    support.run_git(root, ["update-ref", backup["ref"], "HEAD"])
    created = support.run_git(root, ["bundle", "create", backup["bundle"], "--all"])
    if created.returncode != 0:
        print("Failed: could not write the bundle: %s"
              % (created.stderr.strip() or "unknown error"))
        return 1
    verified = support.run_git(root, ["bundle", "verify", backup["bundle"]])
    if verified.returncode != 0:
        print("Failed: the bundle did not verify: %s"
              % (verified.stderr.strip() or "unknown error"))
        return 1
    print("Backup ref: %s" % backup["ref"])
    print("Bundle: %s (verified)" % backup["bundle"])
    for command in restore_commands(root, backup):
        print("Restore: %s" % command)

    replace_file = None
    command = [tool]
    if args.path:
        command += ["--path", args.path, "--invert-paths"]
    else:
        replace_file = write_replace_file(root, args.replace)
        command += ["--replace-text", replace_file]
    command += ["--refs"] + refs + ["--force"]
    try:
        result = subprocess.run(command, cwd=root, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True)
    finally:
        if replace_file and os.path.exists(replace_file):
            os.remove(replace_file)
    if result.returncode != 0:
        print("Failed: git-filter-repo exited %s. Restore from the bundle."
              % result.returncode)
        detail = result.stdout.strip().splitlines()
        if detail:
            print(detail[-1])
        return 1
    print("Rewrote the local refs.")

    remotes = support.run_git(root, ["remote"]).stdout.split()
    if "origin" in remotes:
        support.run_git(root, ["remote", "remove", "origin"])
        print("Removed the origin remote to prevent an accidental push. "
              "Re-add it if you push.")

    support.run_git(root, ["reflog", "expire", "--expire=now", "--all"])
    support.run_git(root, ["gc", "--prune=now"])
    print("Expired the reflog and ran garbage collection.")
    print("Next: run `verify` to confirm the target is gone from the "
          "rewritten refs.")
    return 0


def history_has_path(root, path):
    proc = support.run_git(root, ["log", "--branches", "--tags", "--oneline",
                                  "--", path])
    return bool(proc.stdout.strip())


def history_has_literal(root, literal):
    proc = support.run_git(root, ["rev-list", "--branches", "--tags"])
    for rev in proc.stdout.split():
        grep = subprocess.run(
            ["git", "-C", root, "grep", "-q", "-e", literal, rev],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if grep.returncode == 0:
            return True
    return False


def cmd_verify(args):
    root = os.path.abspath(args.project_root)
    if not require_repo(root):
        return 1
    problem = validate_target(args)
    if problem:
        print(problem)
        return 1
    if args.path:
        present = history_has_path(root, args.path)
    else:
        present = history_has_literal(root, args.replace)
    if present:
        print("Present: %s is still reachable from the rewritten refs."
              % target_label(args))
        return 1
    print("Gone: %s is not reachable from the rewritten refs."
          % target_label(args))
    print("The backup ref and the bundle keep the old history on purpose. "
          "Delete them when you no longer need the backup.")
    return 0


def add_target(parser):
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--path", default=None,
                       help="remove a path from all history")
    group.add_argument("--replace", default=None,
                       help="replace a literal string in all history")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_plan = sub.add_parser("plan", help="print the rewrite plan (read-only)")
    p_plan.add_argument("--project-root", default=".")
    add_target(p_plan)
    p_plan.set_defaults(func=cmd_plan)

    p_run = sub.add_parser("run", help="back up, then rewrite history")
    p_run.add_argument("--project-root", default=".")
    add_target(p_run)
    p_run.add_argument("--confirm-destructive", action="store_true")
    p_run.set_defaults(func=cmd_run)

    p_verify = sub.add_parser("verify", help="confirm the target is gone")
    p_verify.add_argument("--project-root", default=".")
    add_target(p_verify)
    p_verify.set_defaults(func=cmd_verify)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
