---
id: 20
title: PII detection approach
status: closed
priority: high
labels:
    - wayfinder:research
relations:
    blocks:
        - 23
    depends-on:
        - 14
        - 15
created: "2026-09-29"
updated: "2026-09-29"
closed: "2026-09-29"
---

## Question

What counts as PII in a project, which tools and patterns detect it,
and how does the skill control false positives?

## Answer

Resolved by a research subagent. Findings captured in
[docs/research/2026-09-29-pii-detection.md](../../docs/research/2026-09-29-pii-detection.md)
(subagent report; written by the driving session).

Headline results:

- PII is defined by identifiability, not by a fixed list. Definitions
  differ by regime and are not interchangeable (GDPR Article 4(1) and
  Article 9, CCPA/CPRA 1798.140(v) and (ae), NIST SP 800-122). The
  skill must not hardcode one regime.
- Detection combines three signals by strength: checksum or
  structural validation (the only path to `certain`), pattern match,
  and context words.
- Names and postal addresses need NER. With no dedicated tool, report
  them at low confidence or not at all.
- False positives are controlled by checksum validation, context
  scoring, thresholds, and project allow lists.
- PII also sits in metadata: EXIF and GPS, Office core properties
  (`creator`, `lastModifiedBy`), and PDF info dictionaries.
- `exiftool` 12.57 is present. Presidio and spaCy are not installed.

Full detail, sources, and gaps are in the research file.

## Revision (2026-09-30, by #23)

The resolution above leaned on a no-tool fallback. That is superseded:
`presidio` is required for content PII detection, because names and
addresses are core leaks and regex cannot find them. A small bundled
checksum layer remains as a deterministic cross-check. The research
file remains the reference for definitions, detection methods, and
false-positive controls.
