#!/usr/bin/env python3
"""Content PII detection for pre-publication.

Runs presidio over text-like files and applies a bundled checksum
cross-check to structured identifiers. Emits findings that carry class,
carrier, location, severity, confidence, and remediation kind.

presidio is required. When it is absent this check stops with a clear
message. There is no weaker fallback.

Metadata PII is out of scope. The metadata vector owns it.

Read-only with respect to the project. Writes only into the output
directory.
"""

import argparse
import importlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import inventory  # noqa: E402

OUTPUT_SUBPATH = inventory.OUTPUT_SUBPATH
MAX_FILE_BYTES = 2 * 1024 * 1024

# presidio entity -> (category, severity). The category is the kind of
# personal data. The severity follows the taxonomy in the skill.
ENTITY_MAP = {
    "CREDIT_CARD": ("financial", "high"),
    "CRYPTO": ("financial", "high"),
    "IBAN_CODE": ("financial", "high"),
    "US_BANK_NUMBER": ("financial", "high"),
    "EMAIL_ADDRESS": ("contact", "medium"),
    "PHONE_NUMBER": ("contact", "medium"),
    "PERSON": ("identifiers", "high"),
    "NRP": ("identifiers", "high"),
    "LOCATION": ("geolocation", "medium"),
    "IP_ADDRESS": ("online identifiers", "medium"),
    "US_SSN": ("identifiers", "critical"),
    "US_ITIN": ("identifiers", "high"),
    "US_PASSPORT": ("identifiers", "high"),
    "US_DRIVER_LICENSE": ("identifiers", "high"),
    "MEDICAL_LICENSE": ("health", "critical"),
}
DEFAULT_ENTITY = ("identifiers", "medium")

# The entities the scan asks presidio for. URL and DATE_TIME are left out:
# they are not personal data on their own, and they add noise.
DEFAULT_ENTITIES = [
    "CREDIT_CARD", "CRYPTO", "IBAN_CODE", "US_BANK_NUMBER",
    "EMAIL_ADDRESS", "PHONE_NUMBER", "PERSON", "NRP", "LOCATION",
    "IP_ADDRESS", "US_SSN", "US_ITIN", "US_PASSPORT",
    "US_DRIVER_LICENSE", "MEDICAL_LICENSE",
]

# Entities that only NER can find. Their score sets the confidence.
NER_ENTITIES = ("PERSON", "NRP", "LOCATION")

# Recognizers with a high false-positive rate. Report them at `possible`.
LOW_PRECISION_ENTITIES = ("NRP",)

NER_LIKELY_SCORE = 0.6


def luhn_valid(value):
    digits = [int(c) for c in value if c.isdigit()]
    if not (12 <= len(digits) <= 19):
        return False
    total = 0
    for index, digit in enumerate(reversed(digits)):
        if index % 2 == 1:
            digit *= 2
            if digit > 9:
                digit -= 9
        total += digit
    return total % 10 == 0


def iban_valid(value):
    compact = "".join(c for c in value if c.isalnum()).upper()
    if not (15 <= len(compact) <= 34):
        return False
    rearranged = compact[4:] + compact[:4]
    try:
        digits = "".join(str(int(c, 36)) for c in rearranged)
    except ValueError:
        return False
    return int(digits) % 97 == 1


def ssn_plausible(value):
    digits = "".join(c for c in value if c.isdigit())
    if len(digits) != 9:
        return False
    area, group, serial = digits[:3], digits[3:5], digits[5:]
    if area in ("000", "666") or area[0] == "9":
        return False
    return group != "00" and serial != "0000"


def confidence_for(entity, value, score):
    """Return a confidence, or None to suppress a false positive."""
    if entity == "CREDIT_CARD":
        return "certain" if luhn_valid(value) else None
    if entity == "IBAN_CODE":
        return "certain" if iban_valid(value) else None
    if entity == "US_SSN":
        return "likely" if ssn_plausible(value) else None
    if entity in LOW_PRECISION_ENTITIES:
        return "possible"
    if entity in NER_ENTITIES:
        return "likely" if score >= NER_LIKELY_SCORE else "possible"
    if entity in ("EMAIL_ADDRESS", "PHONE_NUMBER"):
        return "likely"
    return "likely" if score >= NER_LIKELY_SCORE else "possible"


def output_dir(project_root):
    return os.path.join(os.path.abspath(project_root), OUTPUT_SUBPATH)


def presidio_version():
    try:
        from importlib.metadata import version
        return version("presidio-analyzer")
    except Exception:
        return "unknown"


def build_engine(module_name):
    """Import presidio and build an analyzer. Return (engine, error)."""
    try:
        analyzer = importlib.import_module(module_name)
        nlp_module = importlib.import_module(module_name + ".nlp_engine")
    except ImportError as exc:
        return None, ("presidio is required and was not found (%s). "
                      "Content PII detection did not run." % exc)
    try:
        configuration = {
            "nlp_engine_name": "spacy",
            "models": [{"lang_code": "en", "model_name": "en_core_web_sm"}],
        }
        provider = nlp_module.NlpEngineProvider(nlp_configuration=configuration)
        engine = analyzer.AnalyzerEngine(nlp_engine=provider.create_engine(),
                                         supported_languages=["en"])
    except Exception as exc:  # model missing or an incompatible install
        return None, "presidio could not start (%s)." % exc
    return engine, None


def read_text(path):
    try:
        if os.path.getsize(path) > MAX_FILE_BYTES:
            return None
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            return handle.read()
    except OSError:
        return None


def scan_file(engine, rel, path):
    text = read_text(path)
    if not text:
        return []
    results = engine.analyze(text=text, language="en",
                             entities=DEFAULT_ENTITIES)
    findings = []
    seen = set()
    for result in results:
        value = text[result.start:result.end]
        key = (result.entity_type, result.start, result.end)
        if key in seen:
            continue
        seen.add(key)
        confidence = confidence_for(result.entity_type, value, result.score)
        if confidence is None:
            continue
        category, severity = ENTITY_MAP.get(result.entity_type, DEFAULT_ENTITY)
        line = text.count("\n", 0, result.start) + 1
        findings.append({
            "class": "personal data",
            "category": category,
            "carrier": "working tree",
            "location": "%s:%d" % (rel, line),
            "severity": severity,
            "confidence": confidence,
            "remediation": "forward-fix",
            "entity": result.entity_type,
            "value": value,
            "score": round(result.score, 3),
        })
    return findings


def scan(project_root, engine):
    findings = []
    errors = []
    for rel, path in inventory.text_files(project_root):
        try:
            findings.extend(scan_file(engine, rel, path))
        except Exception as exc:
            errors.append("%s: %s" % (rel, exc))
    for index, finding in enumerate(findings, start=1):
        finding["id"] = "pii-%d" % index
    return findings, errors


def skipped_result(reason):
    return {
        "vector": "pii",
        "status": "skipped",
        "reason": reason,
        "tool": {"name": "presidio", "path": None, "version": None},
        "findings": [],
        "errors": [],
    }


def render_text(result):
    lines = ["Pre-publication content PII scan", ""]
    if result["status"] == "skipped":
        lines.append("SKIPPED: %s" % result["reason"])
        return "\n".join(lines)
    lines.append("tool: %s %s" % (result["tool"]["name"],
                                  result["tool"].get("version") or ""))
    lines.append("findings: %d" % len(result["findings"]))
    for finding in result["findings"]:
        lines.append("  [%s] %s | %s | %s | confidence: %s"
                     % (finding["severity"], finding["category"],
                        finding["carrier"], finding["location"],
                        finding["confidence"]))
        lines.append("      entity: %s" % finding["entity"])
    if result["errors"]:
        lines.append("")
        lines.append("errors:")
        for error in result["errors"]:
            lines.append("  %s" % error)
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", default=".")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parser.add_argument("--out", default=None,
                        help="findings JSON path (default: output dir)")
    parser.add_argument("--presidio-module", default="presidio_analyzer",
                        help="module name to import (default: presidio_analyzer)")
    parser.add_argument("--stdout", action="store_true",
                        help="also print the JSON payload")
    args = parser.parse_args()

    project_root = os.path.abspath(args.project_root)
    out_dir = output_dir(project_root)
    os.makedirs(out_dir, exist_ok=True)
    out_path = args.out or os.path.join(out_dir, "pii.json")

    engine, error = build_engine(args.presidio_module)
    if engine is None:
        result = skipped_result(error)
        with open(out_path, "w", encoding="utf-8") as handle:
            json.dump(result, handle, indent=2)
            handle.write("\n")
        print("SKIPPED: %s" % error, file=sys.stderr)
        return 3

    findings, errors = scan(project_root, engine)
    result = {
        "vector": "pii",
        "status": "ok",
        "reason": None,
        "tool": {"name": "presidio", "path": args.presidio_module,
                 "version": presidio_version()},
        "findings": findings,
        "errors": errors,
    }
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
        handle.write("\n")

    if args.format == "json":
        print(json.dumps(result, indent=2))
    else:
        print(render_text(result))
    if args.stdout and args.format != "json":
        print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
