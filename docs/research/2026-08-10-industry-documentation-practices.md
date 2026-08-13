# Research: Documentation Practices by Industry

Date: 2026-08-10
Purpose: Inform design of a general-purpose documentation meta-skill by surveying documentation practices in non-software industries.

---

## Military / Defense

### Structure

Military documentation uses a rigid hierarchical numbering system governed by standards such as MIL-STD-961 (defense and program-unique specifications) and MIL-STD-40051 (preparation of digital technical information for page-based Technical Manuals).

Document types fall into distinct categories with separate specifications:

- **Specifications (MIL-STD-961):** A, B, C, D types — General, System/Subsystem, Item, and Critical Item specifications. Each follows a prescribed outline (scope, applicable documents, requirements, verification, packaging, notes).
- **Technical Manuals (MIL-STD-40051):** Operator manuals, maintenance manuals (organizational, intermediate, depot), Illustrated Parts Breakdowns (IPBs per MIL-DTL-15014 and MIL-DTL-81928), and training manuals.
- **Engineering drawings:** Governed by ASME Y14.100 and DoD standards. Each drawing has a unique number, revision letter, and title block.

The document **numbering system** encodes information directly. For example, a TM number might encode: weapon system, manual type, volume, and security classification. MIL-STD-961 uses a master numbering register (part of ASSIST — the Acquisition Streamlining and Standardization Information System).

### Audiences

Military documentation separates audiences by multiple axes simultaneously:

- **Role:** Operator (how to use), Maintainer (how to fix, broken into organizational/intermediate/depot levels), Trainer (instructor guides), Logistics (supply data).
- **Security classification:** Unclassified, Confidential, Secret, Top Secret. Different audiences see different document versions. Classification markings are mandated at document, page, paragraph, and figure level (per DoD 5200.1-PH and ISOO marking guides).
- **Geographic/theater:** US vs coalition partner access levels.
- **Lifecycle phase:** Design/development documentation vs production vs fielded system vs disposal.

### Findability at Scale

Findability is achieved through:

- **ASSIST database** (https://quicksearch.dla.mil) — the central DoD repository for specifications and standards. Searchable by document number, title, FSC (Federal Supply Class), and keyword.
- **Standardized document numbering** — a document number is a locator. Anyone trained in the system can deduce the document's domain from its number.
- **Cross-reference lists** in every specification — "applicable documents" sections explicitly list related specs.
- **TM numbering system** — The TM number encodes the weapon system, manual type (operator/maintenance/IPB), and volume. If you know the weapon system and need the operator manual, you can derive the number.
- **SNS (Standard Numbering System)** for parts identification — hierarchical numbering of assemblies and subassemblies.

### Versioning / Lifecycle

- **Revision letters** (A, B, C...) appended to the document number. Some documents use change notices or amendments between revisions.
- **Lifecycle states:** Active, Inactive, Rescinded, Cancelled. Each state serves a specific purpose:
  - Active: Current and usable.
  - Inactive: Not recommended for new design but existing use permitted.
  - Rescinded: Withdrawn, no longer valid for any purpose.
  - Cancelled: Never issued or approved.
- **Change tracking:** Each revision has a change summary. Interim changes use Change Notices (CNs).
- **Obsolescence management:** When a revision is rescinded, users must migrate to the superseding document. The ASSIST system tracks supersession chains.
- **Configuration management:** TMs must reflect the exact configuration of the weapon system. Changes to hardware trigger documentation changes through Engineering Change Proposals (ECPs).

### Unique Constraints

- **Classification handling** requires systems that can manage multiple security levels — a single document may exist in classified and unclassified versions.
- **Distribution restrictions** (export control, ITAR, proprietary information) further segment access.
- **Interoperability with allied forces** drives adoption of common numbering and content standards (e.g., NATO STANAGs).
- **Multiple media delivery:** TMs must be printable (paper), viewable on displays (PDF/HTML), and sometimes available as Interactive Electronic Technical Manuals (IETMs).
- **Contractual tail:** Documentation requirements are written into contracts (DD Forms 1423, Contract Data Requirements Lists). Deliverables are contract line items.

### Transferable Patterns

- **Number-as-locator** — A document ID that carries encoding about document type, system, and audience. This enables retrieval even without a search engine.
- **Hierarchical audience separation** — Not a flat role list but multiple separation axes (role × clearance × lifecycle phase).
- **Lifecycle state machine** — Active/Inactive/Rescinded/Cancelled with defined transition rules.
- **Supersession tracking** — Explicit tracking of which document supersedes which, with change summaries.
- **Cross-reference discipline** — Every document explicitly lists its dependencies (applicable documents section). This is machine-actionable.
- **Configuration-aware documentation** — Documents are tied to a specific system configuration, not authored independently.

### Blind Spots for Our Design

- Software tools rarely handle **multi-level security** (same document, different classified versions for different audiences).
- We assume **universal search** is available. In deployed military settings, search may be unavailable or bandwidth-limited. Number-based retrieval matters.
- We assume **documents are independent artifacts**. Military docs are tightly coupled to system configuration baselines.
- We assume **one document = one revision chain**. Classified vs unclassified versions of the same document may have parallel revision histories.

---

## Data Archival / Libraries / Museums

### Structure

Library and archival documentation uses metadata standards that separate intellectual content from physical carriers:

- **FRBR (Functional Requirements for Bibliographic Records):** A four-level entity model — Work (abstract idea) → Expression (version/language) → Manifestation (published format) → Item (single physical copy). This decouples what a document *is* from its physical *carriers*.
- **MARC (Machine-Readable Cataloging):** The exchange format for bibliographic metadata. Uses numerical tags (010 = LCCN, 245 = Title, 650 = Subject, etc.) with subfield codes. Each record has leader, directory, and variable fields.
- **Dublin Core:** Simplified 15-element metadata set (Title, Creator, Subject, Description, Publisher, Contributor, Date, Type, Format, Identifier, Source, Language, Relation, Coverage, Rights). Used for cross-domain resource discovery.
- **Classification systems:**
  - **Dewey Decimal Classification (DDC):** Hierarchical numeric notation — three-digit base class with decimal extensions. 600 = Technology, 620 = Engineering, 621 = Mechanical engineering, etc. The hierarchy encodes subject relationships in the notation itself.
  - **Library of Congress Classification (LCC):** Alpha-numeric — T = Technology, TJ = Mechanical engineering and machinery, TK = Electrical engineering. Better suited for deep research collections.
  - **Dewey Decimal Classification (DDC)** also for archives: 025.4 = Subject analysis and classification.
- **Finding aids (EAD — Encoded Archival Description):** XML-based standard for describing archival collections. Hierarchical structure: Collection → Series → Subseries → File → Item. Each level can have its own description, dates, and extent.
- **OAIS Reference Model (ISO 14721):** The archival preservation framework. Defines functional entities: Ingest, Archival Storage, Data Management, Administration, Preservation Planning, Access. Defines information packages: SIP (Submission), AIP (Archival), DIP (Dissemination).

### Audiences

- **Public vs researcher vs staff** — Different levels of access and metadata detail. Public sees simplified records; researchers see full finding aids; staff see acquisition and preservation metadata.
- **By institution type:** Public library (general browsing), academic library (research depth), special library (domain focus), archive (provenance focus), museum (object focus).
- **FRBR levels correspond to user needs:** A user looking for "Hamlet" (the Work) is different from one looking for a specific 1623 Folio edition (Manifestation/Item).
- **Provenance-based separation** — Archives are organized by creator (who made the records), not by subject. Different researcher communities need creator-level or subject-level access.

### Findability at Scale

- **Authority control:** Standardized headings for names, subjects, and titles. Eliminates the "Shakespeare or Shakespeare?" problem. Uses authority files (LOC Name Authority File, OCLC Virtual International Authority File).
- **Controlled vocabularies & thesauri:** Library of Congress Subject Headings (LCSH), Medical Subject Headings (MeSH), Art & Architecture Thesaurus (AAT). Hierarchical broader/narrower/related term relationships.
- **Cross-references (see/see also):** "See" redirects from non-preferred to preferred terms. "See also" shows related terms at the same level.
- **Union catalogs (WorldCat / OCLC):** Aggregates records from thousands of libraries. A single search across holdings from all member institutions. Each record shows which libraries hold the item.
- **Linked data:** Libraries are transitioning from MARC to BIBFRAME and linked data models. This enables cross-institution discovery without central aggregation.
- **Consistent record structure:** Every catalog record has the same core fields (title, author, subject, call number). Users learn one pattern.
- **Call number as shelf locator:** DDC and LCC numbers encode both subject and shelf position. Browsing related books is physical browsing of the classification hierarchy.

### Versioning / Lifecycle

- **OAIS Preservation Lifecycle:** Ingest (receive and validate) → Archival Storage (bit-level preservation) → Data Management (metadata maintenance) → Access (delivery to consumers). Covers the entire chain from creator to consumer.
- **Preservation planning** handles format obsolescence:
  - **Migration:** Moving content from obsolete formats to current ones (e.g., WordPerfect → DOCX → PDF/A).
  - **Emulation:** Running old software/hardware to access original formats.
  - **Normalization:** Converting all incoming content to a small set of preservation formats (TIFF for images, WAV for audio, PDF/A for documents).
- **Fixity checking:** Regular checksums to detect bit rot. Automated re-ingest when corruption is found.
- **Versioning of metadata:** When catalog records are updated, the original record may be retained as a historical version. Some institutions keep full revision history in MARC fields 005 (date/time of last transaction) and changed fields.
- **Deaccessioning:** Formal process for removing items from a collection. Documented reason, approval chain, and disposition (return, transfer, destroy).

### Unique Constraints

- **Heterogeneous media:** Books, manuscripts, photographs, maps, sound recordings, film, digital files, born-digital, and physical objects. Each has different preservation needs.
- **Scale:** The Library of Congress holds over 175 million items. WorldCat aggregates over 500 million records from 70,000+ libraries. This is a different scale problem from most software documentation.
- **Provenance is non-negotiable:** In archives, the chain of custody must be documented. Who had the item, when, and how was it transferred.
- **Format obsolescence is existential:** Unlike software docs (which can be regenerated), archival content may become permanently inaccessible if the format dies.
- **Orphan works:** Content with unknown copyright status — hard to make accessible but hard to destroy.
- **Institutional autonomy vs interoperability:** Each library catalogs independently but benefits from shared standards (MARC, OCLC, Z39.50). The standards must permit local variation within a common framework.
- **Long time horizons:** Preservation commitments can span centuries. The documentation system must be understandable by future archivists who may not speak the original cataloger's language.

### Transferable Patterns

- **FRBR work/expression/manifestation/item model** — Separating the abstract *document* from its *versions*, *formats*, and *physical copies*. This is directly applicable to software documentation (e.g., API docs as Work, language-specific versions as Expressions, HTML/PDF as Manifestations, local copies as Items).
- **Authority control** — Standardized identifiers for entities (people, teams, products, concepts). Eliminates duplicates and ambiguity.
- **Controlled vocabularies with hierarchical relationships** — Not just tagging, but a thesaurus with broader/narrower/related terms.
- **Finding aid hierarchy** — Collection → Series → File → Item is a natural hierarchy for many real-world documentation sets (e.g., Project → Phase → Document → Section).
- **Union catalog pattern** — Aggregating distributed documentation collections while respecting local ownership and metadata practices.
- **Fixity checking + migration + emulation** — A three-layer preservation strategy for any long-lived documentation that must survive platform changes.
- **call number as shelf locator: subject + position** — The idea that a document's ID tells you both what it is about and where it lives physically.

### Blind Spots for Our Design

- We assume **documents exist in one format**. Real archives manage works across many formats with different preservation needs.
- We assume **documentation is "active"** (currently useful). Archives handle dormant, obsolete, and culturally/historically valuable documentation that is never "used" in the operational sense.
- We assume **a single authoritative version**. Libraries manage multiple editions, translations, reprints, and copies of the same work, none of which is "the" version.
- We assume **content can be recreated**. Preservation strategies assume content may be irreplaceable and plan for bit-level perfect preservation.
- We assume **users search**. In physical archives, users browse shelf-adjacent items — classification order is navigated, not searched.
- We assume **metadata stays constant**. Catalog records change as new information emerges (e.g., a rediscovered author identity updates all related records). Our versioning model needs to handle retrospective metadata corrections.

---

## Construction / Engineering

### Structure

Construction documentation is organized by discipline, phase, and purpose. Several standards govern structure:

- **CSI MasterFormat:** The industry standard for organizing construction specifications. Uses 6-digit numbering with 48 divisions (expanded to 50 in MasterFormat 2026):
  - Division 00 — Procurement and Contracting Requirements
  - Division 01 — General Requirements
  - Division 02 — Existing Conditions
  - Division 03 — Concrete
  - Division 04 — Masonry
  - Division 05 — Metals
  - ...
  - Division 33 — Utilities
  - Sub-numbers extend: 03 30 00 = Cast-in-Place Concrete, 03 30 53 = Miscellaneous Cast-in-Place Concrete.
  - MasterFormat 2026 introduces new divisions for sustainability (Division 02 reconfigured as Site Sustainability), digital construction (Division 01 content expanded), and other modern topics.
- **Uniformat:** Elemental classification based on building systems (A = Substructure, B = Shell, C = Interiors, D = Services, etc.). Used for cost estimating and BIM.
- **Drawing sets:** Organized as a consistent sheet sequence — cover sheet, civil, architectural, structural, MEP (mechanical/electrical/plumbing), landscape. Each sheet has a discipline prefix (A = Architectural, S = Structural, M = Mechanical, E = Electrical, P = Plumbing, C = Civil) and sheet number (A-101, A-102, etc.).
- **Specification sections** cross-reference drawings. A specification says "See Drawing A-101 for location" and a drawing says "See Section 03 30 00 for concrete specs."
- **BIM (Building Information Modeling):** Standardized under ISO 19650 series. Information organized in a Common Data Environment (CDE) with defined states: Work in Progress → Shared → Published → Archived.
- **RFC (Request for Clarification), RFI (Request for Information), Submittals, Transmittals, and Change Orders** each have their own numbering sequences, approval workflows, and tracking registers.
- **Document registers:** Centralized lists cataloging every document on a project with its status, revision, and transmittal history.

### Audiences

- **Discipline-based:** Architects, structural engineers, civil engineers, MEP engineers, landscape architects, interior designers. Each discipline produces and consumes different documents.
- **Role-based:**
  - **Owner/Client:** High-level (schedules, budgets, design intent). Needs the "as-built" record at handover.
  - **Design team:** Detailed technical specifications and drawings during design and construction.
  - **Contractor/Subcontractor:** Construction details, sequences, shop drawings, product data. Needs field-ready documents.
  - **Inspector/Commissioning agent:** Code compliance, testing procedures, acceptance criteria.
  - **Facilities manager:** As-built documentation, O&M manuals, warranty info, spare parts lists. Needs this at handover, typically 5+ years after design.
- **Phase-based:** Pre-design, schematic design, design development, construction documents, bidding/negotiation, construction administration, closeout. Different audiences are active in each phase.

### Findability at Scale

- **Drawing sheet numbering:** The discipline prefix + sequential number convention is universal. Any construction professional can navigate a drawing set.
- **MasterFormat numbering:** If you know the material (concrete) you can go to Division 03. If you know it's cast-in-place, you go to 03 30 00. The number is the findability mechanism.
- **Specification vs drawing cross-references:** Every specification section lists related drawings. Every drawing title block has the spec section number.
- **BIM object metadata:** IFC (Industry Foundation Classes) and COBie (Construction-Operations Building Information Exchange) provide structured data for objects within models. Each object has a GUID, type, material, fire rating, warranty info, etc.
- **Document registers (submittal registers):** Track every submittal by number, title, status (Submitted, Reviewed, Approved, Rejected), revision, and dates.
- **RFI logs:** Centralized tracking of questions and answers. Each RFI has a unique number, status, and linked drawing/spec reference.
- **O&M manuals at handover:** Structured by MasterFormat division, then by equipment type. Each equipment item has product data, installation instructions, warranty, and maintenance schedule.

### Versioning / Lifecycle

- **Revision clouds/deltas:** Drawings use clouded revision triangles around changed areas. Each revision gets a sequential number or letter and a description of the change.
- **Permit set / IFC (Issued for Construction) / As-Built:**
  - Permit Set: The drawing version that goes for regulatory review.
  - IFC: The issued-for-construction version. Contractor builds from this.
  - As-Built: The version marked up with all field changes. Delivered at closeout.
  - Record Drawings: Clean, drafted version of as-built changes. The final deliverable.
- **BIM version control (ISO 19650):** The Common Data Environment manages revs. Each container (model/drawing) has a version number. Status transitions require gatekeeping (e.g., a checker must approve before WIP → Shared).
- **Submittal workflow:** Subcontractor submits → GC reviews → Engineer/AIA reviews → Returns (Approved/Approved as Noted/Revise & Resubmit/Rejected). Each status is tracked with dates.
- **Transmittal log:** Governs who gets which document revision. Proof of distribution for contractual purposes.
- **O&M revision at handover:** Final O&M documentation is produced once, at closeout. But warranty and commissioning documentation may be revised during the life of the building.

### Unique Constraints

- **Regulatory permitting:** Documents must be sealed (signed and stamped) by a licensed professional engineer or architect. This creates a signature/review bottleneck that is legally required.
- **Interdependent documents:** A change to the architectural drawing (wall moved) cascades to structural (beam relocation), MEP (duct rerouting), and specs (updated room schedule). The interdependency graph is dense and must be tracked manually.
- **Large project scale:** A hospital project can have 5000+ drawings, 200+ specification sections, 5000+ submittals, 1500+ RFIs. The documentation system must handle this volume.
- **Field conditions:** What is designed and what is built may differ. As-built documentation captures this delta. It is often incomplete due to time pressure.
- **Handover gap:** The documentation needed for operations (O&M, warranties, as-builts) is produced during construction but used years later by a different organization. Information is often lost or incomplete at this boundary.
- **Contractual hierarchy:** In case of conflict, documents have a contractual precedence order (e.g., Agreements > Specifications > Drawings > Schedules). The documentation system must represent this priority.
- **BIM interoperability:** Different software tools (Revit, ArchiCAD, Tekla, Navisworks) need to exchange information via IFC. The standard is imperfect; data loss at exchange boundaries is common.

### Transferable Patterns

- **Discipline-prefixed numbering** (A-101, S-101) — A simple, learnable convention for separating documentation streams.
- **Cross-reference discipline** — Every spec section lists related drawings and vice versa. This bidirectional referencing is a practice software documentation could adopt more rigorously.
- **Status state machines with gatekeeping** — WIP → Shared → Published → Archived with defined approval gates. ISO 19650's CDE states are cleanly defined.
- **Submittal register pattern** — A central register tracking all incoming/outgoing document versions with status, reviewer, and dates. More structured than typical "latest version" thinking.
- **Drawing revision clouds** — Visual indication of changed regions. Software docs rarely highlight deltas visually.
- **Contractual precedence ordering** — Explicitly stating which document type takes priority when there's a conflict. Useful for any multi-document system.
- **As-built capture workflow** — A planned delta-capture process (field markups → record drawings). Most software projects don't plan for documenting what was *actually* implemented vs what was *specified*.

### Blind Spots for Our Design

- We assume **documents are independent**. Construction documents are deeply interdependent — a change in one requires changes in many others. Our design needs an impact analysis mechanism.
- We assume **one tool ecosystem**. Construction uses multiple software tools that exchange data imperfectly. Cross-tool documentation is the norm.
- We assume **the document author and consumer are from the same organization**. Handover at project boundaries is a major point of failure.
- We assume **documentation is used during the creation phase**. Construction docs are used during construction AND during operations (years later by different people). The second use case is poorly supported by most systems.
- We assume **revision is continuous**. In construction, some documents are revised continuously (design), others once (permit set), others never (O&M manuals produced at closeout). A single revision model doesn't fit.
- We assume **search**. Field crews often don't have search — they navigate by discipline prefix, sheet number, and spec section.

---

## Medical / Pharma

### Structure

Medical device and pharmaceutical documentation is structured around regulated lifecycle requirements. Three key document sets are required:

- **Design History File (DHF):** Contains all design control documentation — design plans, design inputs, design outputs, design reviews, verification/validation, design transfer, design changes. Documents the entire design history of a device.
- **Device Master Record (DMR):** Contains the specifications, drawings, and procedures for manufacturing the device. Includes assembly drawings, component specs, manufacturing procedures, quality assurance procedures, packaging/labeling specs.
- **Device History Record (DHR):** Contains production records for each manufactured unit or batch. Shows that each unit was built according to the DMR.

These are required under:
- **21 CFR Part 820** (US FDA Quality System Regulation) — the central US regulation for medical device quality documentation.
- **ISO 13485:2016** — the international quality management system standard for medical devices.
- **EU MDR 2017/745 Annex II** — Technical documentation requirements for EU market access.
- **ISO 14971:2019** — Risk management documentation for medical devices.

Documentation is structured by:

- **Risk classification** (Class I / IIa / IIb / III in EU, Class I / II / III in US). Higher risk classes require more documentation and deeper scrutiny. Class III devices require PMA (Pre-Market Approval) with full clinical data.
- **Design controls (21 CFR 820.30):** Design and Development Planning → Design Input → Design Output → Design Review → Design Verification → Design Validation → Design Transfer → Design Changes. Each stage produces specific documents.
- **CAPA (Corrective and Preventive Actions):** The formal process for addressing quality issues. Root cause analysis → action plan → verification of effectiveness. Documents all quality corrections.
- **Template-driven:** Most documents (SOPs, work instructions, protocols, reports) follow mandatory templates. The template structure is itself a controlled document.

### Audiences

- **By role with defined access profiles:**
  - **R&D/Design engineers:** Create DHF content. Need design control templates.
  - **Quality assurance:** Review and approve DHF/DMR changes. Gatekeepers of document release.
  - **Regulatory affairs:** Compile technical documentation for submissions (510(k), PMA, CE marking). Need submission-ready exports.
  - **Manufacturing:** Work from DMR documents (work instructions, inspection procedures). Need clean, approved, current versions.
  - **Field/Clinical:** Service manuals, complaint handling procedures, clinical evaluation reports.
  - **Auditors (internal and external):** Need to inspect any document, verify approval chains, review CAPA records. Need read-only access to everything.
- **By security level:** Some documents are proprietary (design specs, trade secrets). Some are public-facing (instructions for use, labeling). Some are submission-only (regulatory). Access controls must support all three.
- **Signatory workflows:** Approval is not "anyone can approve" — specific roles must sign (e.g., Design Engineer, QA Reviewer, Medical Director). Electronic signature requirements under 21 CFR Part 11 are stringent.

### Findability at Scale

- **Document numbering systems:** Typically encode document type (SOP, Protocol, Report, Drawing), department, and sequence number. E.g., SOP-QA-042 or ENG-DRW-001234.
- **Controlled document lists:** Master lists of all active documents with status (Draft, Under Review, Approved, Obsolete), revision, and effective date.
- **Document management systems (DMS):** Specialized regulated DMS platforms (e.g., MasterControl, Qualio, Greenlight Guru) with full audit trails, electronic signatures, template enforcement, and lifecycle workflows.
- **Part number cross-references:** DMR documents reference component part numbers. Part number lookup returns all related DMR documents.
- **Regulatory submission mapping:** Traceability matrices link design inputs → verification tests → risk controls → clinical evidence. Structured traceability ensures nothing is missed for submissions.

### Versioning / Lifecycle

- **Regulated lifecycle states:** Draft → Under Review → Approved → Effective → Obsolete. Transitions require documented approval and signatures.
- **Effective date:** The date when a new revision becomes active. Old revision stays in effect until the effective date. No "rolling updates" — scheduled effective dates are common.
- **Audit trail:** Every action on every document is logged: who, what, when. This is a legal requirement (21 CFR Part 11 for electronic records).
- **Obsolete document retention:** Obsolete documents are not deleted. They are marked obsolete and retained as records. Auditors may ask to see superseded versions.
- **Periodic review:** Documents have a review frequency (e.g., annually, biennially). If not reviewed on schedule, the document may be flagged or temporarily suspended.
- **CAPA document lifecycle:** A CAPA is a document that itself goes through a lifecycle: Opened → Investigation → Root Cause → Action Plan → Implementation → Verification → Closed. Each step generates sub-documents.
- **Design change control:** Changes to a released design (after DHF is baselined) require a formal Design Change Notice/Order with impact assessment, re-verification/re-validation as needed, and regulatory notification if the change affects safety or performance.

### Unique Constraints

- **Regulatory audit readiness:** Any document can be requested by an FDA inspector or Notified Body auditor at any time. The system must support instantaneous retrieval of current and historical documents.
- **Part 11 compliance:** Electronic signatures must be unique to each person, must include name, date, and meaning of signature, and must be linked to the document with an audit trail.
- **Labeling is regulated:** Labels and instructions for use are regulated documents. Changes require regulatory notification or approval depending on materiality.
- **Multi-regulatory submissions:** A device sold in the US (FDA), EU (MDR), Japan (PMDA), and elsewhere has separate technical documentation for each jurisdiction. These are different versions of similar content.
- **Template enforcement:** Free-form documentation is not permitted for regulated content. Templates must be used and the templates themselves must be controlled.
- **Risk file (ISO 14971):** Risk management documentation is kept as a "risk file" — separate from but cross-referenced to the DHF. Hazards, harms, risk controls, and residual risk are tracked.
- **Post-market surveillance:** Documentation doesn't stop at market release. Complaint handling, adverse event reporting, PMS (Post-Market Surveillance), and PMCF (Post-Market Clinical Follow-up) generate ongoing documentation indefinitely.
- **Shelf-life documentation:** For sterile devices or products with expiration dates, documentation must cover stability testing and expiration dating.

### Transferable Patterns

- **Three-tier document hierarchy (DHF / DMR / DHR):** Separating *what we designed* (DHF), *how to build it* (DMR), and *what we actually built* (DHR). This maps directly to software: Spec → Build Instructions → Build Records.
- **Template-driven authoring with template governance:** Constrained authoring eliminates structural drift. Templates themselves are version-controlled.
- **Effective dating** — A scheduled cutover from old to new revision. Not everyone adopts immediately; the effective date coordinates the transition.
- **Periodic review requirement** — Forced re-evaluation of every document at a defined interval. Prevents documentation rot.
- **Audit trail on every action** — Not just who changed what, but who reviewed, approved, effective-dated, and obsoleted. Named action types.
- **Traceability matrix** — Bidirectional mapping between requirements, implementation, tests, and risks. Shows coverage and gaps.
- **Obsolete-as-state, not delete** — Old versions are retained as a matter of record. The system manages state, not existence.
- **Signatory workflow** — Each document type defines which roles must sign, and the document cannot advance without the correct signatories.

### Blind Spots for Our Design

- We assume **documentation is unregulated**. In medical, the documentation system itself is subject to regulatory audit. The system must handle being audited.
- We assume **anyone can create a document**. Template enforcement restricts creation to authorized structures.
- We assume **approval is a single step**. Medical approval is a multi-role, multi-stage workflow with mandatory signatures from specific roles.
- We assume **effective dating is flexible**. Medical documents have scheduled cutovers. Our design needs to support deferred activation of new revisions.
- We assume **documents can be freely revised**. Design changes in medical require formal change control with impact assessment and re-verification.
- We assume **documents are independent artifacts**. The traceability matrix links requirements, design, verification, and risk across document boundaries. Removing or changing one document without updating the trace matrix breaks compliance.
- We assume **documentation lifecycle ends at "final" or "archived"**. Medical documentation continues through post-market surveillance indefinitely.
- We assume **the most recent version is always the correct one**. In medical, the "approved" and "effective" dates determine which version is currently active, not creation date or version number.

---

## Aviation / Aerospace

### Structure

Aviation documentation is governed by a family of standards designed for modular, variant-aware, multilingual technical content:

- **ATA Spec 100 / iSpec 2200:** The industry standard for aircraft maintenance documentation structure. Defines:
  - ATA numbering system: A hierarchical chapter-system numbering — Chapter 27 (Flight Controls), Section 27-10 (Aileron), Subject 27-10-00 (Aileron General), etc. Every aircraft system has a permanent ATA chapter number that is consistent across all aircraft types.
  - Document structure: Front matter → List of Effective Pages → Chapter content → Appendices. Each page has the chapter number and revision date in the page header.
  - Publication sets: Separate manuals for different purposes — AMM (Aircraft Maintenance Manual), IPC (Illustrated Parts Catalog), WDM (Wiring Diagram Manual), SRM (Structural Repair Manual), CMM (Component Maintenance Manual), etc.
- **S1000D:** The international standard for technical publications using Common Source Database (CSDB) and modular data:
  - **Data Module (DM):** The smallest self-contained unit of technical information. Each DM has a unique Data Module Code (DMC) — a 17-42 character code encoding system, subsystem, sub-subsystem, assembly/disassembly, information type, technical context, and language.
  - **Common Source Database (CSDB):** A single repository of all data modules, illustrations, and metadata. The DMRL (Data Module Requirements List) defines which DMs are needed for a specific publication.
  - **BREX (Business Rules Exchange):** Defines which S1000D features are used, which optional fields are required, and what values are valid. Project-specific business rules that constrain the standard.
  - **Publication sets:** DMs are assembled into publications (an AMM, an IPC) by applying filtering rules (aircraft variant, operator, language). The same DM can appear in multiple publication sets.
- **Airworthiness Directives (ADs):** Regulatory documents issued by airworthiness authorities (FAA, EASA) mandating inspections, modifications, or inspections. Each AD references specific aircraft models and serial numbers.
- **Service Bulletins (SBs):** Manufacturer recommendations for modifications or inspections. Operator decides whether to comply. If complied with, the SB becomes part of the aircraft's configuration.

### Audiences

- **By operator role:**
  - **Maintenance technicians:** Need AMM, IPC, WDM. Need clear, error-proof procedures. May work in a noisy hangar with dirty hands.
  - **Engineering / Planning:** Need SBs, ADs, modification drawings. Plan maintenance schedules.
  - **Flight crew:** Need the Flight Manual (AFM/FCOM), cockpit checklists, MEL (Minimum Equipment List).
  - **Quality / Safety:** Need AD compliance records, SB embodiment records, reliability data.
  - **Regulatory authorities:** Need AD compliance evidence, continuing airworthiness records.
- **By language:** Aircraft may be operated globally. Documents must be available in multiple languages. S1000D supports multilingual DMs with language tag in the DMC.
- **By aircraft variant:** The same base aircraft type (e.g., Boeing 737-800) has variant configurations per operator (cabin layout, engine type, avionics suite). Maintenance procedures differ per variant. S1000D uses "product definition" metadata (model, variant, serial number range) to filter DMs.
- **By security/government:** Military aircraft documentation follows military classification (SECRET, etc.) and ITAR restrictions. Civil aircraft documentation is unclassified but proprietary.

### Findability at Scale

- **ATA chapter numbering:** The universal starting point. Chapter 27 means Flight Controls on any aircraft, any manufacturer, any year. A technician know the chapter system from day one of training.
- **ATA Numbering System (Chapters 5-114):** Allocated across structure (5-19), systems (20-49), power plant (50-89), and structures (90-114). Sub-numbers add specificity: 27-10 = Aileron, 27-20 = Rudder, 27-30 = Elevator.
- **S1000D Data Module Code (DMC):** The DMC encodes enough information to uniquely identify a data module without a title. Search can be by DMC pattern (e.g., "27-10-00*" = all aileron DMs).
- **Interactive Electronic Technical Manuals (IETMs):** S1000D content rendered as interactive HTML with navigation trees, cross-linked DMs, and (in advanced implementations) 3D interactive graphics.
- **Commonality across aircraft types:** A licensed A&P (Airframe & Powerplant) mechanic can walk onto any Boeing aircraft and navigate the maintenance manual — the ATA chapter structure is identical.
- **AD compliance database:** Each operator maintains a register of applicable ADs per tail number, with compliance status, method, and due date. Part of the continuing airworthiness record.
- **Part number cross-reference from IPC:** The IPC maps assembly hierarchies (next higher assembly, components) with illustrated views. A part number search returns the IPC page and all higher assemblies containing it.

### Versioning / Lifecycle

- **Publication revision cycles:** AMMs are revised periodically (often every 4-6 weeks for active aircraft) with change pages. IPC revisions follow parts changes. Operators must stay current with the manufacturer's revision service.
- **Manual revision page system:** Each page in a printed AMM has a revision date and a list of effective pages in the front matter. The operator updates by replacing changed pages — a holdover from paper-based revision.
- **Effectivity codes:** Each DM or IPC illustration has an effectivity code specifying which aircraft serial numbers or variant configurations it applies to. The same procedure may have multiple effectivity-coded DMs for different configurations.
- **AD/SB embodiment tracking:** When an AD or SB is applied to an aircraft, the configuration record is updated. The AMM/IPC must reflect the post-modification configuration. This creates version dependencies between regulatory actions and maintenance documentation.
- **Obsolescence management:** When an aircraft type is phased out (e.g., Boeing 747 in commercial service), documentation enters a "sustaining" phase — no major updates, only critical corrections. Eventually, documentation is retired.
- **Derivative management:** A new variant (737-8 vs 737-9) inherits most DMs from the base type but adds variant-specific DMs. S1000D handles this through the product definition metadata.
- **Revision of "unchanged" content:** Even if a DM's technical content hasn't changed, metadata (e.g., affected serial numbers) may change. The DM revision still increments, with a change note saying "effectivity updated."

### Unique Constraints

- **Safety-critical documentation:** Errors in maintenance documentation can cause accidents. The ATA numbering system, S1000D DM structure, and review processes are designed to eliminate ambiguity.
- **Regulatory recognition requirement:** Documentation standards (ATA Spec 100, S1000D) must be recognized by aviation authorities. The FAA and EASA accept documentation prepared to these standards as meeting regulatory requirements.
- **Paper-to-digital transition legacy:** Many operators still have paper manuals. S1000D IETMs are the modern standard but paper-based revision pages (List of Effective Pages, change page replacement) are still in use.
- **Multi-operator distribution:** A manufacturer publishes documentation once but distributes to hundreds of operators worldwide, each with different variant configurations. The system must support single-source → multi-variant delivery.
- **Configuration management coupling:** Aircraft documentation is coupled to aircraft configuration. When an operator modifies an aircraft (e.g., interior retrofit), their documentation must diverge from the manufacturer's baseline and track operator-specific changes.
- **Illustration management:** IPCs heavily depend on illustrated parts breakdowns. Illustrations must be managed as revision-controlled assets alongside text content. S1000D manages illustrations (graphic data modules) in the CSDB.
- **Regulatory traceability of every component:** Every part on an aircraft must be traceable to a part number, manufacturer, and compliance document. This traceability is maintained through the IPC and related documentation.
- **Language rigor:** Translations must be accurate (mistranslations can cause maintenance errors). S1000D supports multilingual DMs but translation quality assurance is a separate process.

### Transferable Patterns

- **Permanent numbering scheme (ATA chapters):** A universal, unchanging numbering system that transcends any single project. All maintenance personnel learn it once and use it forever. Software could adopt this for error codes, API status codes, or domain concepts.
- **Data module (S1000D DM):** A self-contained information unit with a unique code, clear scope, single responsibility, and reusability across multiple publications. The DMC encodes content type, system, and language.
- **Publication sets as filtered views:** DMs are not organized into "the manual" — they are assembled into publication sets by applying filtering rules. Any DM can appear in multiple publications.
- **Effectivity (variant filtering):** Metadata about which versions/products a document applies to. Documentation follows configuration, not the other way around.
- **Common Source Database (CSDB) + Business Rules (BREX):** A single source of truth augmented by project-specific rules about how to constrain the standard. This pattern prevents standards from being too rigid or too permissive.
- **Single-source multi-language:** One DM per language, sharing a common DMC base with language suffix. Translations are parallel documents, not variants of a single source.
- **Change page legacy for print-friendly delta delivery:** Even in digital-first systems, supporting "what changed since last revision" as a standalone output is valuable.
- **List of Effective Pages:** A machine-verifiable index of which pages/documents are current. Essential when not all content is under continuous revision.

### Blind Spots for Our Design

- We assume **one-to-one mapping between document and product**. In aviation, one aircraft type (737) produces thousands of documentation variants (per operator, per variant, per tail number). Documentation is an N-to-M mapping.
- We assume **revisions are monotonically improving**. In aviation, a DM may be revised to change the affected serial numbers without changing technical content. Version number does not equal content change.
- We assume **content is consumed in a single context**. A DM can appear in multiple publication sets (an AMM and an IPC may share DMs). Our design needs shared content without duplication.
- We assume **documents live on connected systems**. Operators in remote locations may use offline IETM viewers with periodic data syncs.
- We assume **illustrations are embedded in documents**. Aviation manages illustrations as separate revision-controlled assets that are referenced, not embedded.
- We assume **the documentation system ends at publication**. In aviation, documentation distribution, updating, and compliance tracking are ongoing services.
- We assume **a document hierarchy is stable and predictable**. The ATA system's stability is its main feature — chapter 27 was assigned 60+ years ago and is still valid. Our design doesn't plan for numbering stability across time.

---

## Cross-Cutting Patterns

### Patterns Shared Across Multiple Industries

**1. Number-as-locator (Military, Aviation, Construction, Libraries)**

All four industries use hierarchical numbering as the primary retrieval mechanism. The number encodes: subject/system, document type, and position in a hierarchy. This works even without search engines. The software assumption that "users always search" is false in many field settings (hangars, construction sites, classified facilities).

**2. Multi-axis audience separation (Military, Medical, Aviation, Construction)**

Documentation separates audiences not on a single axis (role) but on multiple axes simultaneously: role × security level × lifecycle phase × geography. Flat role labels are insufficient.

**3. Document lifecycle state machines (Military, Medical, Aviation)**

All three regulated industries define formal document lifecycle states (Draft → Review → Approved → Effective → Obsolete) with defined transitions, gatekeepers, and audit trails. State machines, not version numbers, control document validity.

**4. Cross-referencing as a discipline (All five industries)**

Every surveyed industry maintains explicit cross-references between related documents (specs-to-drawings, design-to-risk, data module-to-publication set). Cross-references are treated as first-class structured data, not as hyperlinks in narrative text.

**5. Template-driven authoring (Medical, Military, Aviation)**

Regulated industries enforce document structure through templates. Templates are themselves controlled documents with their own revision histories. The structure of a document is as important as its content.

**6. Configuration-aware documentation (Military, Aviation, Medical, Construction)**

Documents describe specific configurations of systems (weapon system baseline, aircraft tail number, device revision level, building phase). Documentation drifts when configuration changes without document updates. All four industries have formal processes for this coupling.

**7. Obsolete-as-state, not deletion (All five industries)**

No surveyed industry deletes old documents. Superseded versions are marked as obsolete and retained with the supersession link intact. Legal/regulatory requirements demand historical record preservation.

**8. Audit trail as requirement (Medical, Military, Aviation)**

Documenting who did what, when, and why is not optional — it's a regulatory or contractual requirement. The documentation system must log all actions with named action types, not just "changed" timestamps.

**9. Single-source multi-output (Aviation S1000D, Construction BIM, Military IETM)**

All three create content once and produce multiple outputs (different audiences, formats, languages) from the same source. This is practiced more systematically in these industries than in typical software documentation.

**10. Handover as a documented process (Construction, Medical, Military, Aviation)**

The boundary between "creating documentation" and "using documentation" is often a formal handover event (building closeout, device transfer to manufacturing, aircraft delivery to operator). The documentation structure must support this transition.

### Gaps in Our Current Design Exposed by This Research

1. **No numbering scheme concept:** Our design likely assumes documents have a path/filename but not a hierarchical number that encodes type, subject, and audience. This is a fundamental findability mechanism in every surveyed industry.

2. **No multi-axis audience model:** We likely model audience as a simple role label. Real documentation systems separate audiences by role × clearance × lifecycle × language × variant.

3. **No document state machine with gatekeeping:** We likely treat documents as "draft" or "published" with a single approval step. Regulated industries require multi-role, multi-stage gatekeeping with defined states and transitions.

4. **No configuration coupling:** Our design likely treats documents as independent artifacts about a (static) product. Real documentation systems track what configuration a document applies to and flag drift.

5. **No cross-reference as first-class data:** We likely support hyperlinks. Real documentation systems maintain structured cross-reference matrices that are verifiable and reportable.

6. **No effective date support:** We likely activate documents immediately upon approval. Many industries require scheduled effective dates with the ability to defer activation.

7. **No template governance:** We likely recommend "use consistent formatting" rather than enforcing document structure through governed templates.

8. **No handover process:** Our design likely assumes a single team creates and consumes documentation. Real documentation spans organizational boundaries with formal handover events.

9. **No variant management (N-to-M mapping):** We likely assume one document per product version. Aviation demonstrates that one product variant generates N publication variants and one document (DM) appears in M publication sets.

10. **No preservation strategy:** We likely assume documents remain accessible in their current format indefinitely. Archives demonstrate that format obsolescence requires explicit migration and emulation planning.

### Recommendations for the Documentation Skill

1. **Build the structure discovery procedure around the "number-as-locator" pattern.** The first question for any project should be: what is your document numbering scheme? This forces explicit thinking about hierarchy, document types, and audience separation.

2. **Model audiences as multi-axis filters, not flat roles.** Document audience = Role × Security level × Phase × Language × Variant. Allow projects to define their own axes.

3. **Include a document state machine primitive.** Draft → Review → Approved → Effective → Obsolete is a reasonable default. Allow projects to customize the states and transitions. Include multi-role gatekeeping.

4. **Make cross-references a first-class concept.** Support bidirectional "see also" and "depends on" relationships. Provide impact analysis: "If Document A changes, which documents must be updated?"

5. **Provide template governance as a tiered concept:**
   - Tier 0: No enforced structure (personal notes)
   - Tier 1: Recommended structure (guidelines)
   - Tier 2: Enforced templates (fields, sections)
   - Tier 3: Regulated templates (templates are controlled documents, require change management)

6. **Include configuration-coupling metadata.** Each document should be able to declare which product version/configuration/state it describes. Documentation drift detection: "Document X describes Product V1 but no revision has been made since V1 → V2 transition."

7. **Support effective dating.** A document revision should have an effective date, not just an approval date. The current version is the one approved AND effective.

8. **Include audit trail as a core primitive.** Every action on a document (create, review, approve, activate, obsolete) should be logged with actor, action type, timestamp, and contextual comment.

9. **Plan for handover boundaries.** The structure should be self-describing enough that a receiving team can understand the documentation system without hand-holding. This means documenting the documentation system itself.

10. **Provide a "retirement" pattern.** Documents should not be deleted. The system should support an explicit "obsolete" state with supersession links. Include periodic review reminders.

11. **Support numbering stability.** Once allocated, a document number or category should not be reassigned. The system should prevent number reuse even after a document is obsoleted.

12. **Incorporate the FRBR model for version management.** Separate Work (the document's identity) → Expression (language/format variant) → Manifestation (specific file format) → Item (a particular copy). This handles the multi-variant, multi-format reality that software documentation also faces.
