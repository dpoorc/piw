#!/usr/bin/env python3
"""Gated-fix ledger for pre-publication.

Every fix is proposed as an exact action first. Nothing is applied
without approval. Destructive actions need a separate confirmation and
a named backup.

The ledger is a state machine over proposed fixes. This script enforces
the transitions. The skill runs the recorded command.
"""

import argparse
import json
import os
import sys

KINDS = ("forward-fix", "history-rewrite", "rotate-credential", "add-protection")
STATUSES = ("proposed", "approved", "applied", "verified", "rejected")
LEDGER_SUBPATH = os.path.join(".local", "prepublish", "fixes.json")

REQUIRED_FIELDS = ("finding", "class", "carrier", "location", "kind", "action")


def ledger_path(project_root):
    return os.path.join(os.path.abspath(project_root), LEDGER_SUBPATH)


def load(path):
    if not os.path.exists(path):
        return {"fixes": []}
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def save(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")


def find(data, fix_id):
    for fix in data["fixes"]:
        if fix["id"] == fix_id:
            return fix
    return None


def next_id(data):
    numbers = [int(f["id"][1:]) for f in data["fixes"] if f["id"][1:].isdigit()]
    return "F%d" % (max(numbers) + 1 if numbers else 1)


def is_low_risk(fix):
    return bool(fix.get("reversible")) and not bool(fix.get("destructive"))


def cmd_add(args):
    path = ledger_path(args.project_root)
    data = load(path)
    with open(args.source, "r", encoding="utf-8") as handle:
        incoming = json.load(handle)
    if isinstance(incoming, dict):
        incoming = incoming.get("fixes", [incoming])

    added = []
    for item in incoming:
        missing = [f for f in REQUIRED_FIELDS if not item.get(f)]
        if missing:
            print("Refused: a fix is missing %s" % ", ".join(missing))
            return 1
        if item["kind"] not in KINDS:
            print("Refused: unknown kind %s" % item["kind"])
            return 1
        fix = {
            "id": item.get("id") or next_id(data),
            "finding": item["finding"],
            "class": item["class"],
            "carrier": item["carrier"],
            "location": item["location"],
            "kind": item["kind"],
            "action": item["action"],
            "command": item.get("command"),
            "reversible": bool(item.get("reversible", False)),
            "destructive": bool(item.get("destructive", False)),
            "backup": None,
            "restore": item.get("restore"),
            "status": "proposed",
        }
        data["fixes"].append(fix)
        added.append(fix["id"])

    save(path, data)
    print("Proposed: %s" % ", ".join(added))
    return 0


def cmd_list(args):
    data = load(ledger_path(args.project_root))
    fixes = data["fixes"]
    if args.format == "json":
        print(json.dumps(data, indent=2))
        return 0
    if not fixes:
        print("No fixes proposed.")
        return 0
    for fix in fixes:
        flags = []
        if fix.get("destructive"):
            flags.append("destructive")
        if fix.get("reversible"):
            flags.append("reversible")
        print("%-4s %-10s %-16s %s" % (fix["id"], fix["status"],
                                       fix["kind"], fix["location"]))
        print("     %s" % fix["action"])
        if flags:
            print("     [%s]" % ", ".join(flags))
    return 0


def cmd_approve(args):
    path = ledger_path(args.project_root)
    data = load(path)
    targets = []
    for fix_id in args.ids:
        fix = find(data, fix_id)
        if fix is None:
            print("Refused: no such fix %s" % fix_id)
            return 1
        if fix["status"] != "proposed":
            print("Refused: %s is %s, not proposed" % (fix_id, fix["status"]))
            return 1
        targets.append(fix)

    if len(targets) > 1:
        if not args.batch:
            print("Refused: approving more than one fix needs --batch")
            return 1
        unsafe = [f["id"] for f in targets if not is_low_risk(f)]
        if unsafe:
            print("Refused: batch approval is only for low-risk reversible "
                  "fixes. Approve these one at a time: %s" % ", ".join(unsafe))
            return 1

    for fix in targets:
        fix["status"] = "approved"
    save(path, data)
    print("Approved: %s" % ", ".join(f["id"] for f in targets))
    return 0


def cmd_apply(args):
    path = ledger_path(args.project_root)
    data = load(path)
    fix = find(data, args.id)
    if fix is None:
        print("Refused: no such fix %s" % args.id)
        return 1
    if fix["status"] != "approved":
        print("Refused: %s is %s, not approved" % (fix["id"], fix["status"]))
        return 1

    if fix.get("destructive"):
        if not args.confirm_destructive:
            print("Refused: %s is destructive. Pass --confirm-destructive "
                  "after a separate confirmation." % fix["id"])
            return 1
        if not args.backup:
            print("Refused: %s is destructive. Name a backup with --backup."
                  % fix["id"])
            return 1
        if not os.path.exists(args.backup):
            print("Refused: the backup path does not exist: %s" % args.backup)
            return 1
        fix["backup"] = args.backup
        if not fix.get("restore"):
            print("Refused: %s has no recorded restore command." % fix["id"])
            return 1

    fix["status"] = "applied"
    save(path, data)
    print("Applied: %s" % fix["id"])
    if fix.get("destructive"):
        print("Backup: %s" % fix["backup"])
        print("Restore: %s" % fix["restore"])
    if fix["kind"] == "rotate-credential":
        print("Hand-off: rotate the credential now. A history rewrite is "
              "not a substitute for rotation.")
    return 0


def cmd_verify(args):
    path = ledger_path(args.project_root)
    data = load(path)
    fix = find(data, args.id)
    if fix is None:
        print("Refused: no such fix %s" % args.id)
        return 1
    if fix["status"] != "applied":
        print("Refused: %s is %s, not applied" % (fix["id"], fix["status"]))
        return 1
    fix["status"] = "verified"
    save(path, data)
    print("Verified: %s" % fix["id"])
    return 0


def cmd_reject(args):
    path = ledger_path(args.project_root)
    data = load(path)
    fix = find(data, args.id)
    if fix is None:
        print("Refused: no such fix %s" % args.id)
        return 1
    fix["status"] = "rejected"
    save(path, data)
    print("Rejected: %s" % fix["id"])
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", default=".")
    sub = parser.add_subparsers(dest="command", required=True)

    p_add = sub.add_parser("add", help="propose fixes from a JSON file")
    p_add.add_argument("--from", dest="source", required=True)
    p_add.set_defaults(func=cmd_add)

    p_list = sub.add_parser("list", help="list the ledger")
    p_list.add_argument("--format", choices=("text", "json"), default="text")
    p_list.set_defaults(func=cmd_list)

    p_approve = sub.add_parser("approve", help="approve one or more fixes")
    p_approve.add_argument("ids", nargs="+")
    p_approve.add_argument("--batch", action="store_true")
    p_approve.set_defaults(func=cmd_approve)

    p_apply = sub.add_parser("apply", help="mark an approved fix as applied")
    p_apply.add_argument("id")
    p_apply.add_argument("--confirm-destructive", action="store_true")
    p_apply.add_argument("--backup", default=None)
    p_apply.set_defaults(func=cmd_apply)

    p_verify = sub.add_parser("verify", help="mark an applied fix as verified")
    p_verify.add_argument("id")
    p_verify.set_defaults(func=cmd_verify)

    p_reject = sub.add_parser("reject", help="reject a fix")
    p_reject.add_argument("id")
    p_reject.set_defaults(func=cmd_reject)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
