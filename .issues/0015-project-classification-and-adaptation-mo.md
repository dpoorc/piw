---
id: 15
title: Project classification and adaptation model
status: closed
priority: high
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 18
        - 19
        - 20
        - 21
        - 22
created: "2026-09-29"
updated: "2026-09-29"
closed: "2026-09-29"
---

## Question

How does the skill classify a project (code, website, prose, data,
research) and adapt the scan to each type without assuming git, a
build system, or a package manager?

## Answer

### The "kind" framing is rejected

The skill does not classify projects into kinds. Abstract kinds say
nothing reliable about coverage and invite a false sense of
completeness. The skill inventories what is actually present and
scans against that inventory. The question above is kept unchanged
for history; the decision below replaces it.

### Inventory, in two parts

1. **Content inventory** - what files and carriers are present.
   Detected by three methods together: file extension as the
   baseline, directory convention, and content sniffing.
2. **Meta and hidden layers** - for example: version control (git
   present or not, plus history, branches, tags, remotes, LFS,
   submodules, hooks); CI/CD configuration; container and
   infrastructure config; dependency manifests and lockfiles;
   environment and credential stores; build outputs and caches;
   compiled binaries and their embedded strings; editor and OS
   artifacts; release and packaging artifacts; file-system metadata
   (symlinks, extended attributes, ownership).

The meta-layer list is illustrative, not exhaustive. The skill
cannot foresee all content a project may have, so the inventory is
open-ended.

### Extension baseline and verification

Extensions are the baseline. The skill verifies that content matches
the extension. A file that cannot be identified, or whose content
contradicts its extension, is itself a flag (hygiene and exposure
risk).

### Two check families

- **Content checks** run over every text-like file regardless of
  carrier - secret patterns, absolute local paths, PII patterns.
- **Carrier checks** require a carrier - EXIF for images, history
  for git, author fields for office documents.

A skipped check is recorded as skipped, not dropped silently, so the
report shows coverage.

### Adaptation semantics

Vector classes always apply. Carriers gate checks. Severity is
unchanged.

### Ambiguity

When detection cannot determine something, ask the user and state
what could not be determined. Never default silently to software.
