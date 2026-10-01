#!/usr/bin/env python3
"""Gate G1: no decision-tracking references in the skill artifact.

The shipped skill must read as a finished procedure. It must not carry
planning residue such as ticket numbers, batch names, or option letters.
"""

import argparse
import os
import re
import sys

PATTERNS = [
    (r"#\d+", "ticket or issue reference"),
    (r"\b(?:batch|wave|round|iteration)\s+\d+\b", "batch reference"),
    (r"\b(?:option|choice|approach)\s+[A-D]\b", "option letter"),
    (r"\bTG-?\d+\b", "task-group reference"),
    (r"\bissue\s+#?\d+\b", "issue reference"),
    (r"\bdecision\s+\d+\b", "decision reference"),
    (r"\bas discussed\b", "conversation reference"),
    (r"\bas agreed\b", "conversation reference"),
    (r"\bper the plan\b", "planning reference"),
    (r"\bTODO\b", "todo marker"),
    (r"\bFIXME\b", "fixme marker"),
    (r"\bXXX\b", "stray marker"),
]

SKIP_DIRS = {".git", "__pycache__"}
SCAN_SUFFIXES = {".md", ".py", ".json", ".sh"}


def artifact_files(skill_dir):
    for dirpath, dirnames, filenames in os.walk(skill_dir):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in sorted(filenames):
            if os.path.splitext(name)[1] in SCAN_SUFFIXES:
                yield os.path.join(dirpath, name)


def scan(skill_dir):
    violations = []
    for path in artifact_files(skill_dir):
        rel = os.path.relpath(path, skill_dir)
        # The gate covers the shipped skill, not the test harness.
        if rel.split(os.sep)[0] == "tests":
            continue
        try:
            with open(path, "r", encoding="utf-8") as handle:
                lines = handle.readlines()
        except (OSError, UnicodeDecodeError):
            continue
        for number, line in enumerate(lines, 1):
            for pattern, label in PATTERNS:
                if re.search(pattern, line):
                    violations.append((rel, number, label, line.strip()))
    return violations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skill-dir", default=None)
    args = parser.parse_args()

    skill_dir = args.skill_dir or os.path.dirname(
        os.path.dirname(os.path.abspath(__file__)))
    violations = scan(skill_dir)

    if violations:
        print("G1 FAIL: decision-tracking references found")
        for rel, number, label, text in violations:
            print("  %s:%s: %s - %s" % (rel, number, label, text))
        return 1
    print("G1 PASS: no decision-tracking references")
    return 0


if __name__ == "__main__":
    sys.exit(main())
