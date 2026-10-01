---
id: 19
title: Secrets detection approach
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

Which patterns and tools detect secrets in the working tree and in
git history, and how does the skill control false positives?

## Answer

Resolved by a research subagent. Findings captured in
[docs/research/2026-09-29-secret-detection.md](../../docs/research/2026-09-29-secret-detection.md)
(subagent report; written by the driving session).

Headline results:

- Layer detection: anchored provider-prefixed regex first, Shannon
  entropy second, context keywords and file path third. This is
  what gitleaks, detect-secrets, and trufflehog converge on.
- Cover both the working tree and git history. gitleaks scans
  history through `git log -p` and sees additions only.
  detect-secrets deliberately skips history.
- Control false positives with four mechanisms: path and content
  allowlists, baselines, inline annotations, and
  verification-as-filter.
- Default live verification off. It needs network, sends secrets to
  a third party, and needs authorization.
- Confidence mapping proposal: `certain` for verified credentials,
  PEM private keys, and checksum-valid tokens; `likely` for
  prefixed regex with context; `possible` for entropy-only or
  contextless matches.
- Licensing: gitleaks rules are MIT, detect-secrets Apache-2.0,
  git-secrets Apache-2.0. Do not bundle trufflehog detector code
  (AGPL-3.0).

Full detail, sources, and gaps are in the research file.

## Revision (2026-09-30, by #23)

The resolution above described a no-scanner playbook. That is
superseded for the shipped skill: `gitleaks` is required, and it
scans both the working tree and history. The playbook and the research
file remain useful for understanding detection and for the
false-positive controls. The confidence mapping still stands. Live
verification stays off by default.

Optional enhancers when the inventory calls for them: `trufflehog`
(invoke only, AGPL-3.0) for archives, binaries, and live
verification, or Kingfisher and Titus (Apache-2.0).
