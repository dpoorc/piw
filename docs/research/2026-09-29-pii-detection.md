# PII detection research

Date: 2026-09-29
Status: Research complete
Supports: ticket #20 (PII detection approach), map #12

Research for the pre-publication sterilization skill. Scope: what
counts as PII in a project, how an agent should detect it, and how to
control false positives.

Constraints: procedure-first and tool-assisted; no dedicated tool may
be assumed; works offline; runs across text-like files, office
documents, images, and data files; findings carry confidence
`certain`, `likely`, or `possible`.

## 1. Definitions

PII is defined by identifiability, not by a fixed list. Definitions
differ by regime and are not interchangeable.

### GDPR

- Article 4(1): "any information relating to an identified or
  identifiable natural person ... in particular by reference to an
  identifier such as a name, an identification number, location
  data, an online identifier or to one or more factors specific to
  the physical, physiological, genetic, mental, economic, cultural
  or social identity of that natural person".
- Article 9(1) special categories: racial or ethnic origin,
  political opinions, religious or philosophical beliefs, trade
  union membership, genetic data, biometric data for unique
  identification, health data, sex life or sexual orientation.
  Processing is prohibited unless an exception applies.
- Article 4(5) pseudonymisation: data that cannot be attributed to a
  subject without separately kept extra information.

### CCPA / CPRA

- California Civil Code 1798.140(v)(1): information that
  "identifies, relates to, describes, is reasonably capable of being
  associated with, or could reasonably be linked, directly or
  indirectly, with a particular consumer or household". It excludes
  publicly available information.
- 1798.140(ae) sensitive personal information: SSN, driver's
  license, state ID, passport number; account credentials;
  precise geolocation; and more.

### NIST SP 800-122

- PII is "any information about an individual ... (1) any
  information that can be used to distinguish or trace an
  individual's identity ... and (2) any other information that is
  linked or linkable to an individual".
- Examples: financial transactions, medical history, criminal and
  employment history, name, SSN, passport number, driver's license
  number, credit card number, vehicle registration, x-ray, patient
  ID, biometric data.
- Sensitivity is contextual: "The context of use factor may cause
  the same types of PII to be assigned different PII confidentiality
  impact levels in different instances."
- Definitions across laws "are not interchangeable".

**Design implication:** do not hardcode one regime's definition as
universal. Use the identifiability test. Treat special categories as
high severity. Let context change severity, and let co-occurring
fields raise it.

## 2. Taxonomy for a repo scan

| Category | Examples | Suggested severity |
|----------|----------|--------------------|
| Identifiers | name, SSN, passport, driver's license, national ID | high to critical |
| Contact | email, phone, postal address | medium |
| Financial | card number, IBAN, account number | high |
| Credentials | logins, passwords, tokens | critical |
| Health and special | medical, biometric, genetic | critical |
| Geolocation | GPS coordinates, precise location | high |
| Online identifiers | IP address, device ID, cookie ID, UUID tied to a person | medium |
| Household and device | CCPA household and device identifiers | medium |

Sensitivity rises when fields combine: NIST names name plus credit
card number as more sensitive than either alone.

## 3. Detection methods

| Method | Strength | Confidence it can justify |
|--------|----------|---------------------------|
| Checksum or structural validation | strongest, deterministic | `certain` |
| Pattern match plus context words | strong | `likely` |
| Bare pattern match | weak | `possible` |
| NER (statistical) | needed for names and addresses | `likely` at best |

Presidio's own table marks CREDIT_CARD "Pattern match and checksum",
IBAN_CODE "Pattern match, context and checksum", US_SSN "Pattern
match and context", and several national IDs as checksum. A
`certain` tier is justified only for checksum or structurally
validated IDs.

## 4. Tooling matrix

| Tool | Offline | License | Notes |
|------|---------|---------|-------|
| Presidio | Yes, with local models | MIT | Leading offline PII toolkit. Ships with spaCy `en_core_web_lg`. |
| spaCy | Yes, after model download | MIT | 70+ languages. Models are separate downloads and need network once. |
| Regex and checksum fallback | Yes | n/a | Bounded but reliable for structured formats. |
| Google Cloud DLP | No | hosted | Strong, but online only. |
| Amazon Macie | No | hosted | S3 analysis, online only. |
| Azure AI Language PII | No | hosted | Explicitly cloud-based. |

## 5. Metadata channels

Images and documents carry identity separately from content:

- EXIF: `Artist`, `Copyright`, `OwnerName`, `SerialNumber`, `Make`,
  `Model`, `Software`, `CreateDate`.
- GPS: `GPSLatitude`, `GPSLongitude`, `GPSPosition`.
- XMP and IPTC groups.
- Office OOXML core properties (`docProps/core.xml`): `creator`
  (author), `lastModifiedBy`, `created`, `modified`. `lastModifiedBy`
  may be a name, email, or employee ID.
- PDF information dictionary and XMP: `Author`, `Creator`,
  `Producer`, `Title`, `Subject`, `Keywords`, `CreationDate`,
  `ModDate`.

`exiftool` reads and deletes these: `exiftool -all= dst.jpg` deletes
all metadata. exiftool 12.57 is present in this environment.

## 6. False-positive control

- **Checksum validation.** Domain rules: `ISO/IEC 7812-1` for
  payment cards, `ISO 13616` / ISO/IEC 7064 MOD 97-10 for IBAN,
  national ID checksums, and SSA POMS RM 10201.035 for invalid
  SSNs. Invalid values must be suppressed, not reported.
- **Context scoring.** Presidio's `ContextAwareEnhancer` raises a
  score when context words occur. Presidio's German postal-code
  recognizer is documented as "High false-positive risk - only
  reliable with address-context words present; base confidence is
  0.05".
- **Configurable thresholds.** Presidio's example config sets a
  default score threshold of 0.4 and 0.7 for CREDIT_CARD.
- **Allow lists.** Project-local known non-PII terms, and deny lists
  for known false positives.
- **Likelihood tiers.** Google DLP's Likelihood enum gives a usable
  scale: `POSSIBLE` (one or more signals, weak context), `LIKELY`
  (checksums, strong context, unique formatting), `VERY_LIKELY`
  (many strong signals).

## 7. No-tool fallback

With only `rg`, `jq`, `yq`, `gpg`, and `exiftool`, the detectable set
is structural:

- Email - RFC 5322 dot-atom or quoted-string plus domain.
- UUID - RFC 9562 ABNF (8-4-4-4-12 hex).
- IP and MAC addresses.
- URLs.
- Phone numbers (E.164-ish).
- IBAN - MOD 97-10 checksum.
- Payment cards - Luhn checksum.
- National IDs with published formats and checksums.
- SSN - pattern plus SSA invalid-value suppression.
- Metadata via `exiftool`.

Names and postal addresses cannot be reliably detected by regex.
They need NER, context, or a project allow list. Report them at low
confidence or not at all.

## 8. Confidence mapping (design proposal)

- **certain** - checksum-validated or structurally validated
  identifier.
- **likely** - pattern match with supporting context, or a
  high-precision format without checksum.
- **possible** - bare weak pattern, or no context.

## 9. Gaps

- Presidio's numeric score thresholds were not read from engine
  source. Only the commented example was confirmed.
- spaCy English model F1 figures were not extracted. Do not quote a
  number.
- ISO clause numbers could not be fetched (website challenge). Treat
  them as unverified.
- exiftool.org returned HTTP 403. The Debian man page and the local
  binary were used instead.
- No measured false-positive rates exist for a regex-only pipeline.

Environment confirmed absent: `presidio_analyzer`, `spacy`,
`pandas`, `openpyxl`, `PIL`, `pdfinfo`, `qpdf`, `libreoffice`,
`tesseract`. Present: `exiftool` 12.57, `rg`, `jq`, `yq`, `gpg`,
`python3`, `unzip`.

## Sources

- GDPR Article 4 and Article 9 - https://www.legislation.gov.uk/eur/2016/679/article/4/adopted?view=plain
- California Civil Code 1798.140 - https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=CIV&sectionNum=1798.140
- NIST SP 800-122 - https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-122.pdf
- Microsoft Presidio - https://github.com/microsoft/presidio (supported entities, decision process, languages)
- spaCy - https://github.com/explosion/spaCy and https://spacy.io/models/en
- Google Sensitive Data Protection likelihood - https://cloud.google.com/sensitive-data-protection/docs/likelihood
- Azure PII entity categories - https://learn.microsoft.com/en-us/azure/ai-services/language-service/personally-identifiable-information/concepts/entity-categories
- Amazon Macie managed data identifiers - https://docs.aws.amazon.com/macie/latest/user/managed-data-identifiers.html
- SSA POMS RM 10201.035 - https://secure.ssa.gov/poms.nsf/lnx/0110201035
- RFC 5322 - https://www.rfc-editor.org/rfc/rfc5322.txt
- RFC 9562 - https://www.rfc-editor.org/rfc/rfc9562.html
- exiftool man page - https://manpages.debian.org/bookworm/libimage-exiftool-perl/exiftool.1.en.html
- python-docx core properties (cites ISO/IEC 29500 Part 2 Section 11) - https://python-docx.readthedocs.io/en/stable/dev/analysis/features/coreprops.html
