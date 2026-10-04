---
id: 59
title: 'Ancillary vectors: licensing, attribution, authorship'
status: closed
priority: medium
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 60
    depends-on:
        - 50
        - 52
created: "2026-09-29"
updated: "2026-09-30"
closed: "2026-09-30"
---

## Question

What should the skill say about licensing, attribution, authorship,
and naming? Keep it to leak-relevant advice, not license selection.

## Answer

### Licensing checks

- **Presence.** A missing license is a decision prompt, not a defect.
  Third parties can assume things when no license exists. Recommend
  either an explicit "all rights reserved" notice or a chosen
  license. License selection itself is out of scope.
- **Consistency.** Compare the declared license against the license
  text. Flag conflicting statements across files, such as a README
  that says MIT while the license file is GPL. Check SPDX identifier
  validity.
- **Excluded.** Dependency license compatibility auditing. `#50`
  ruled supply chain out.

Tools to design for, not gate on: REUSE (FSFE), scancode-toolkit,
licensee.

### Attribution checks

- Bundled or vendored third-party code, assets, fonts, and data that
  require attribution.
- Stripped or missing license headers in vendored files.
- A required `NOTICE` file, as Apache-2.0 requires.
- Credits and provenance for images, datasets, and fonts.

The skill flags. It does not author attribution text.

Compliance is not the skill's job. It flags high-level licensing
issues. Deeper exploration happens only on user request, and the
skill recommends switching to a compliance skill or workflow rather
than guiding the agent there.

### Authorship split with #55

`#55` owns the mechanics: commit identity, document author fields,
and the removal tools.

`#59` owns the advice: whether to publish personal names in `AUTHORS`,
`CONTRIBUTORS`, and source headers. Personal names are a user-defined
angle. Some projects want named attribution, some want anonymity. The
skill asks for the preference and does not assume.

When anonymity is wanted, recommend a project identity. Contribution
policy (DCO, CLA) stays out - that is governance.

### Severity and remediation

- **high** - declared license does not match the file, conflicting
  license statements, missing third-party notice or attribution.
  Legal exposure.
- **medium** - missing license (a decision), personal names in
  authorship artifacts when anonymity is wanted.
- **low** - cosmetic header and SPDX issues.

Remediation is `forward fix` (redact or correct) or `add protection`
(add `LICENSE` or `NOTICE`). Never automatic.

### Non-goals

- No license selection.
- No dependency license compatibility audit.
- No legal advice.
- No DCO or CLA setup.
- No authoring of attribution text.
- Naming stays out, as `#50` decided.
