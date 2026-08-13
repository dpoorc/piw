# Research: Generic Documentation Organization Methods

Date: 2026-08-11
Purpose: Understand how documentation organization can be modeled generically, independent of medium, project type, or retrieval method. Inform the design of a documentation meta-skill whose primary output is a structure description.

---

## Existing Generic Models

### Information Architecture (Rosenfeld & Morville)

Rosenfeld and Morville's "Information Architecture for the World Wide Web" (3rd ed., O'Reilly) defines **four systems** that constitute the information architecture of any information environment:

1. **Organization systems** — How content is categorized (e.g., by subject, by chronology, by audience, by task).
2. **Labeling systems** — How categories are represented (terms, icons, abbreviations).
3. **Navigation systems** — How users browse or move through content (hierarchies, site maps, breadcrumbs, guides).
4. **Search systems** — How users search (query formulation, result presentation, filtering).

The **organization system** is the one most relevant here. Rosenfeld and Morville distinguish:

- **Organization schemes** (how you group content):
  - *Exact schemes:* Alphabetical, chronological, geographical.
  - *Ambiguous schemes:* Topical (by subject), task-oriented, audience-specific, metaphorical (metaphor-driven), hybrid.
- **Organization structures** (how content relates spatially):
  - *Hierarchy* (top-down, strict parent-child).
  - *Hypertext / Network* (nodes and links, organic connections).
  - *Relational database model* (structured records, query-response).
  - *Sequence / Linear* (step-by-step, linear flow).

**Key insight:** A single project may use multiple organization schemes simultaneously. A reference manual might organize chapters topically (by subject) and sub-chapters alphabetically (by command name). The four systems are not mutually exclusive — they coexist.

**Practical example:**
> An aircraft maintenance manual uses an exact scheme (ATA chapter numbering — chronological by system number) as the primary navigation, but augments it with a topical scheme (fault-based troubleshooting tables) and a search system (full-text search of data modules).

### Faceted Classification (Ranganathan, Denton)

**Colon Classification (S. R. Ranganathan, 1930s):** The foundational theory of faceted classification. Ranganathan's **PMEST** facets:

- **Personality** — The primary subject/breadth of the document.
- **Matter** — The physical properties, material, or substance.
- **Energy** — The action, process, or operation.
- **Space** — The geographic location.
- **Time** — The temporal period.

Each facet is an orthogonal dimension. A document's classification is a combination of facet values. The Colon Classification uses a colon (:) to separate facets in the notation.

**Denton's "Faceted Classification in the Wild" (2003):** A practical survey of faceted classification on the modern web. Key findings:

- Facets are a natural way of organizing — they correspond to how people think about attributes: "I want a red shirt, size large, in cotton."
- Each facet is a controlled vocabulary with its own hierarchy.
- Facets are independent — selecting a value in one facet should not affect values in another facet (orthogonality).
- Facets can handle large collections well because they offer multiple entry points.

**Practical example:**
> An e-commerce product catalog: Color facet (Red, Blue, Green), Size facet (Small, Medium, Large), Material facet (Cotton, Polyester, Wool), Price facet ($0-25, $25-50, $50+). Each facet is independent. A user can start from any facet.

**How this applies to documentation:**
> Documentation could be faceted along: Document Type (specification, manual, report), Subject (system, component), Audience (operator, maintainer, trainer), Lifecycle Phase (design, production, operations), Security Classification. The user traverses the collection by selecting values in any facet.

### Topic Maps (ISO 13250)

ISO 13250 defines Topic Maps as a model for representing knowledge structures and associating them with information resources. Core concepts:

- **Topics** — Representations of subjects (concepts, entities, topics). Each topic has one or more names (base name, display name, sort name).
- **Associations** — Relationships between topics (e.g., "is-a", "part-of", "written-by"). Associations are typed and can carry roles.
- **Occurrences** — Links from topics to information resources (documents, web pages, data records) that are relevant to the topic.

**Key design feature:** Topic Maps are **completely independent of the navigation structure**. A Topic Map is a knowledge overlay that exists on top of the document collection. The same document collection can be traversed through different Topic Maps for different purposes (by subject, by chronology, by audience).

Topic Maps support:
- **Scope** — A topic's name or occurrence can be scoped to a context (e.g., a name is valid only in "English" or "for maintenance personnel").
- **Merging** — Topic Maps from different sources can be merged if they refer to the same subjects.
- **Multiple hierarchies** — The same topic can appear in multiple parent-child relationships in different hierarchies.

**Practical example:**
> A software project has a topic "Authentication API". Its occurrences include: the API reference docs, the security review document, the integration test plan, and the release notes. Associations link it to "OAuth 2.0" (implements-standard), "Login Module" (part-of), and "Alice (lead developer)" (authored-by). A user can find all documentation about authentication regardless of where the files live.

**Status:** Topic Maps (ISO 13250, later ISO 19756 — TMCL for constraint language) are less implemented today than SKOS or OWL. But the model — topics + associations + occurrences — is the cleanest separation of "knowledge organization" from "content storage" in any standard.

### Records Management (ISO 15489, MoReq)

**ISO 15489-1:2016** — Information and documentation, Records management, Part 1: Concepts and principles. Defines:

- **Records** — Information created, received, and maintained as evidence and as an asset by an organization.
- **Classification** — The systematic identification and arrangement of business activities and/or records into categories according to logically structured conventions, methods, and procedural rules.
- **Metadata** — Structured or semi-structured information that enables the creation, management, and use of records through time and across domains.

ISO 15489 defines a **classification scheme** (also called a "file plan") that records management systems implement:

- A classification scheme is a hierarchy of **classes** (top level: business functions) → **sub-classes** (activities) → **files/case files** (specific activities).
- Each record is assigned to a class/file. The classification determines retention, access, and disposition.
- Classification is based on **function** (what the organization does), not organizational structure (who does it). A function-based scheme survives reorganizations.

**MoReq (Model Requirements for Records Management):** Defines requirements for electronic records management systems.

- **Classification scheme (MoReq §3.1):** A hierarchy of **Classes** and **Files**. Each class has a unique code, title, description, and potentially sub-classes. Files are the lowest level — they contain records (or volumes).
- **Security categories:** Each class/file can have access rules (who can read, who can write), audit requirements, and disposal details.
- **Vital records indicator:** Marks records that are essential for business continuity.
- **Disposal schedule:** Each class/file has a defined retention period and disposal action (destroy, transfer to archive, review).
- **Event history:** Every action on a record is logged.

**Practical example:**
> A company's records classification scheme:
> ```
> FIN (Finance) — Top Level Class by Function
> ├── FIN-ACC (Accounting)
> │   ├── FIN-ACC-001 (General Ledger)
> │   ├── FIN-ACC-002 (Accounts Payable)
> │   └── FIN-ACC-003 (Accounts Receivable)
> ├── FIN-TAX (Tax)
> │   └── FIN-TAX-001 (Corporate Tax Returns)
> └── FIN-AUD (Audit)
>     └── FIN-AUD-001 (Annual External Audit)
> ```
> Each file has a retention policy (e.g., FIN-ACC-001 retained 7 years, then destroyed) and access rules (Finance staff read-only, Finance Manager read-write).

**How this differs from software documentation models:** Records management treats classification as a **function** that determines **retention and disposition**. This is fundamentally different from "document tree" thinking where classification is about where a file lives on disk. The classification scheme is a separate layer that controls lifecycle, not just navigation.

### SKOS / OWL — Knowledge Organization Systems

**SKOS (Simple Knowledge Organization System):** W3C standard (2009) for representing thesauri, classification schemes, subject heading systems, and taxonomies as Linked Data.

- **Concepts** — Abstract ideas or meanings, identified by URIs.
- **Labels** — Preferred (skos:prefLabel), alternative (skos:altLabel), and hidden (skos:hiddenLabel).
- **Semantic relationships:**
  - skos:broader — A is broader than B (hierarchical)
  - skos:narrower — A is narrower than B (hierarchical)
  - skos:related — A is related to B (associative)
- **Concept schemes** — A set of concepts, optionally with top concepts.
- **Collections** — Groups of concepts (labels, ordered, or unstructured).
- **Notation** — A numeric or alphabetic code assigned to a concept (e.g., "03 30 00" for Cast-in-Place Concrete in MasterFormat).

**OWL (Web Ontology Language):** More expressive than SKOS. Supports formal semantics, restrictions, axioms, and reasoning. Used when you need inference (if A is a subclass of B, and X is an instance of A, then X is by inference an instance of B).

**Key difference from our current design:** SKOS and OWL model the *conceptual structure* independently from the *document structure*. A concept (e.g., "Concrete Finishing") exists in the taxonomy regardless of which document describes it. Documents are linked to concepts via occurrences. This separation allows the taxonomy to survive reorganization.

**Practical example:**
> A SKOS concept scheme for construction specifications:
> ```
> :concrete a skos:Concept ;
>   skos:prefLabel "Concrete"@en ;
>   skos:narrower :cast-in-place-concrete, :precast-concrete .
> :cast-in-place-concrete a skos:Concept ;
>   skos:prefLabel "Cast-in-Place Concrete"@en ;
>   skos:notation "03 30 00" ;
>   skos:broader :concrete .
> ```
> This taxonomy is independent of the filesystem. Documents in any folder can be tagged with `:cast-in-place-concrete`.

### Key Takeaway

The common thread across all these models is **separation of concerns**. Every successful generic model separates:
1. **Content collection** (what you have) from
2. **Conceptual structure** (what it means / how it's classified) from
3. **Navigation/presentation** (how users find/traverse it) from
4. **Lifecycle management** (how it ages, who can access it, when it's destroyed).

Our current design conflates these into the `file_tree`. The industry-standard models never do this.

---

## How Specific Projects Handle the Abstraction

### S1000D (Data Modules vs Publication Sets)

S1000D is the international specification for technical publications (aviation/aerospace primarily, but used in defense, heavy equipment, etc.). Its central architectural insight is the separation of content from publication context.

**Core concepts:**

- **Data Module (DM):** The smallest self-contained unit of technical information. Each DM has a unique **Data Module Code (DMC)** — a 17-42 character string encoding: system number, subsystem, sub-subsystem, assembly, information type, technical context, language, and variant.
- **Common Source Database (CSDB):** A single repository of all DMs, illustrations, and metadata. The CSDB holds *all* content. Nothing is organized here — it is a flat pool of DMs.
- **Publication Sets:** A publication (e.g., an Aircraft Maintenance Manual for a specific operator) is defined as a set of DMs with:
  - A reference to the CSDB content pool.
  - Filtering rules for which DMs to include (by aircraft variant, operator, language, etc.).
  - Ordering rules (sequence of DMs).
  - Presentation formatting (page layout, styling).
- **DMRL (Data Module Requirements List):** The list of DMs required for a specific publication.
- **BREX (Business Rules Exchange):** A set of project-specific constraints on the S1000D standard. Defines which optional features are used, which metadata values are valid, and what rules must be followed.

**The key organizational innovation:** A DM is completely unaware of which publication(s) it belongs to. It does not know its position in any hierarchy. The position is determined by the publication set's DMRL and ordering rules. The same DM can appear in:
- Multiple publication sets (e.g., an AMM and an IPC).
- Different positions in different publications (foreword DM in one, appendix in another).
- Different languages simultaneously (different language-tagged DMs, same DMC base).

**How this compares to our current design:**
> Our `file_tree` assumes every document has one place. S1000D explicitly rejects this — a DM is in the CSDB and is "placed" only when a publication set applies filters and ordering. One document, many organizational contexts. The file tree is an artifact of publication assembly, not of document storage.

### FRBR (Work → Expression → Manifestation → Item)

FRBR (Functional Requirements for Bibliographic Records, IFLA 1998) defines a four-level entity model for the bibliographic universe:

1. **Work** — A distinct intellectual or artistic creation (abstract entity).
   - Example: *Hamlet* by William Shakespeare.
2. **Expression** — The intellectual or artistic realization of a work.
   - Example: Shakespeare's original English text, or a French translation, or a film adaptation.
3. **Manifestation** — The physical embodiment of an expression.
   - Example: The 2005 Folio Society hardcover edition, or the 2010 Penguin paperback edition, or the Project Gutenberg HTML file.
4. **Item** — A single exemplar of a manifestation.
   - Example: Copy #42 of the 2005 Folio Society edition, signed by the illustrator.

**Key design features:**

- **WEMI is a hierarchy:** A work has one or more expressions. An expression has one or more manifestations. A manifestation has one or more items.
- **Attributes at each level:** A work has attributes like "form" (novel, poem, play). An expression has attributes like "language", "form" (text, audio). A manifestation has attributes like "publisher", "date", "format" (print, digital). An item has attributes like "location", "barcode", "condition".
- **FRBR is descriptive, not prescriptive:** It describes how bibliographic entities relate. It does not prescribe how to implement a system.

**OpenWEMI (Dublin Core / DCMI):** An RDF vocabulary that implements FRBR's WEMI in a machine-actionable form. Enables linked data across library catalogs.

**How this compares to our current design:**
> Our design likely treats a document as a single entity with a revision history. In FRBR terms, this conflates Expression and Manifestation (and sometimes Work). The WEMI model forces explicit decisions: "Is the Japanese translation a new Expression of the same Work, or a new Work?" "Is the PDF a different Manifestation of the same Expression, or a different Expression?"

**Practical example for documentation:**
> ```
> Work: "API Reference for Auth Service"
>   Expression: English (original) — authored by dev team
>     Manifestation: HTML version (published on doc site)
>     Manifestation: PDF version (published for offline)
>   Expression: Japanese (translation) — translated by localization team
>     Manifestation: HTML version
>   Expression: English v2 (updated for API redesign)
>     Manifestation: HTML version
> ```
> This separation matters because an organization may need to update only the translation (Expression level) or fix a formatting bug (Manifestation level) without changing the Work.

### OAIS (SIP / AIP / DIP)

The OAIS Reference Model (ISO 14721) defines a framework for digital preservation archives. It introduces three types of **Information Packages** that model how content flows through an archive:

1. **Submission Information Package (SIP):** Content delivered by a Producer to the archive. Contains:
   - Content Data Object (the digital content).
   - Representation Information (how to interpret the content — format specs, encoding).
   - Preservation Description Information (provenance, context, fixity, access rights).
   - Packaging Information (how the package is structured).
2. **Archival Information Package (AIP):** The package stored in the archive. Additional metadata added by the archive:
   - Archival Information Collection links (related AIPs).
   - Full Preservation Description Information.
   - The AIP may differ from the SIP (ingest may transform, normalize, or validate).
3. **Dissemination Information Package (DIP):** The package delivered to a Consumer. May be a different aggregation or format than the AIP (e.g., consumer requests a subset of records in a different format).

**Key design features:**

- **Packages are containers that separate content from delivery.** A SIP becomes an AIP becomes a DIP — the content may be preserved in one form and delivered in another.
- **Preservation Description Information** is the key to long-term understandability: provenance (who created it, what was done to it), context (why it exists, how it relates to other records), fixity (checksums, authenticity), and access rights (who can see it when).
- **Representation Information** ensures future users can interpret the data — format identification, software specs, even the conceptual model.
- **Archival Information Package** is the preservation unit, not the publication unit. An archive may store a collection of related files as one AIP while publishing them as separate DIPs.

**Practical example:**
> A scientific research institution deposits raw sensor data:
> ```
> SIP: Raw sensor files (CSV) + format description + creator name + checksums
>   → Archive validates, transforms to HDF5 canonical format
> AIP: HDF5 files + full preservation metadata + related experiment AIP link
>   → Consumer requests surface readings from 2020
> DIP: CSV export of selected columns + metadata subset
> ```
> The content organized one way for preservation (by experiment, in canonical format), delivered another way (by date range, in requested format).

**How this compares to our current design:**
> Our design likely assumes "the document on disk is the document delivered to users." OAIS shows that preservation packaging and delivery packaging are different concerns. The SIP/AIP/DIP pipeline decouples *storage format* from *delivery format*. This is especially relevant for documentation that needs to span years or decades.

### DITA (Topics and Maps)

Darwin Information Typing Architecture (DITA) is an OASIS standard for topic-based, modular technical documentation. Its core architectural insight is the separation of **content** from **organization** via two constructs:

**1. Topics — Content units:**

- **Concept:** Definitional information (what is it?).
- **Task:** Procedural information (how to do it?).
- **Reference:** Factual information (parameters, properties, commands).
- Each topic has a unique ID. Topics are designed to be standalone and reusable.

**2. Maps — Organization structures:**

A **ditamap** aggregates topics into a navigable hierarchy. The map is just references (topicref elements), not content. Key features:

- **Multiple maps:** The same topic can appear in multiple maps in different positions. For example, a topic about "Authentication" could appear in a "Getting Started" map (as step 3) and in an "API Reference" map (as a reference).
- **Topicref hierarchy:** Map elements define parent-child relationships among topics. `topicref navtitle="Chapter 2"` → `topicref href="installation.dita"` / `topicref href="configuration.dita"`.
- **Conditional processing (profiling):** Topics and elements carry attributes like `@audience`, `@platform`, `@product`, `@rev`. When a map is rendered, a **ditaval** file specifies which values to include/exclude. The same map produces different outputs for different audiences from the same source topics.
- **Branch filtering:** Different branches of a map can use different filtering profiles, allowing a single map to hold content for multiple product variants.
- **Key scopes:** Enable different subsets of keys (topic references, variable definitions) for different branches of a map. A large omnibus document can be decomposed into independent sections within a single map.
- **Content referencing (conref/conkeyref):** Topics can reference (include) content from other topics. This enables reuse at the paragraph or sentence level, across files.
- **Subject scheme maps:** A separate type of map that defines controlled values for metadata attributes. Subject scheme maps can define taxonomies (skos:broader / narrower hierarchies), bind controlled values to attributes, and associate subjects with topics. This provides taxonomic classification *independent* of the navigation map.

**The key organizational innovation:** DITA cleanly separates three concerns:
- **Content (Topics):** What is being communicated.
- **Navigation (Maps):** How topics are ordered and grouped for a specific output.
- **Taxonomy (Subject Scheme Maps):** What subjects topics belong to (classification), independent of where they appear in any navigation.

A topic can simultaneously:
- Live in one file location on disk.
- Appear in multiple maps (different positions, different contexts).
- Be classified by subject (concept A, concept B) via subject scheme maps.
- Be filtered for different audiences via ditaval profiles.

**How this compares to our current design:**
> DITA's architecture is directly comparable to what we're trying to build. Our `file_tree` is like DITA's filesystem folder structure — a single organizational context. DITA shows that maps (navigation hierarchies), subject schemes (classifications), and filesystem paths are three different things, and they should be kept independent. A documentation structure description should include all three.

### Key Takeaway

All five models (S1000D, FRBR, OAIS, DITA) share a common pattern: **content is authored once and organized in multiple ways for different purposes.** The organization is not inherent to the content. The organization is a separate layer.

This is the fundamental flaw in making `file_tree` the primary output of our structure discovery procedure: it assumes one organization scheme (a hierarchy) applied in one context (the filesystem).

---

## Primitives for Describing Organization

### Types of Arrangement

Documentation organization can be described using a small set of **primitive arrangement types**. These types describe how documents relate to each other in an organization structure:

**1. Hierarchy (Tree)**
- **Definition:** A strict parent-child relationship with a single root. Each node (except the root) has exactly one parent.
- **Examples:** Filesystem folders, MasterFormat divisions, ATA chapter numbers, Dewey Decimal notation.
- **Properties:** Breadth (children per level) and depth (levels from root). Trees can be balanced or unbalanced, narrow or wide.
- **Use cases:** Primary navigation, system decomposition, classification by subcategory.
- **Important distinction:** A hierarchy can be **strict** (every item has one place, no exceptions) or **lax** (items can appear in multiple places but have a primary location). Both are hierarchies; they differ in whether they permit aliases/copies.

**2. Sequence (Linear Order)**
- **Definition:** A total or partial ordering of documents. Each document has a position relative to others.
- **Examples:** Reading order in a book, page numbers, step-by-step procedural sequences, chronological document logs.
- **Properties:** Start and end points; predecessor/successor relationships; branching (alternate paths).
- **Use cases:** Tutorials, workflows, reading guides, procedural manuals.
- **Important distinction:** A sequence can be **ordered** (strict total order: document A before B before C) or **semi-ordered** (partial order: A before B, but C can be anywhere relative to A and B).

**3. Network (Graph)**
- **Definition:** An arbitrary set of nodes connected by relationships. No root, no single parent requirement.
- **Examples:** Wikipedia hyperlinks, cross-referenced standards, FRBR relationships, Topic Maps associations.
- **Properties:** Directionality (directed/undirected), edge types (typed relationships), density (how many connections per node).
- **Use cases:** Knowledge bases, cross-references between standards, "related content" sections.
- **Important distinction:** A network can be **typed** (edges have semantic meaning — "depends-on", "supersedes", "describes") or **untyped** (generic "related to" links). Typed networks are more informative.

**4. Flat (Set / List)**
- **Definition:** A collection with no ordering or hierarchical relationship among items.
- **Examples:** A tag cloud, a file registry, a list of all documents by title (alphabetically sorted but not hierarchically related).
- **Properties:** Size, membership criteria.
- **Use cases:** Index pages, master document registries, backup inventories.
- **Important distinction:** A **pure flat list** has no internal structure, but most flat lists are actually sequences (alphabetical is a sequence). True flatness is rare — it typically means "no organizational principle has been applied."

**5. Matrix (Multi-Axis Grid)**
- **Definition:** Documents organized by two or more orthogonal axes, forming cells at the intersection.
- **Examples:** A spreadsheet where rows = document type and columns = lifecycle phase; Ranganathan's faceted classification with multiple independent facets.
- **Properties:** Number of axes, orthogonality (whether axes are truly independent).
- **Use cases:** Faceted browsing, traceability matrices, compliance matrices.
- **Important distinction:** A matrix can be fixed (all cells defined in advance) or dynamic (facets selected at query time).

### Cross-Cutting Concerns

These are not arrangement types but modifiers that can be applied to any arrangement:

**1. Tagging (Folksonomy / Informal Tags)**
- Arbitrary labels assigned to documents. Not hierarchical.
- Can coexist with any primary arrangement.
- Tags may be uncontrolled (user-defined) or controlled (from a defined list).
- **Limitation:** Tags alone cannot replace hierarchy for large collections (the "too many tags" problem).

**2. Faceting**
- Multiple orthogonal classifications applied simultaneously.
- Each facet is itself usually hierarchical internally.
- The power of faceting is in combining facets: "Show me all operator-level manuals for the landing gear system."
- Requires well-defined facet definitions and facet values.

**3. Full-Text Search**
- The retrieval method that requires the least organizational structure.
- Works alongside any arrangement — content is in one place, search finds it regardless.
- **Limitation:** Search is only as good as the content quality. Terminology drift, synonyms, and poor writing make search unreliable.
- **Important pattern:** In large documentation collections, search is the fallback when navigation fails. Both must be designed.

**4. Metadata / Filtering**
- Structured attribute-value pairs on documents.
- Enable filtered views of any arrangement: "Show only documents in Division 03 with approval status 'Approved'."
- DITA's conditional processing is a powerful example — the same map generates different filtered views.

**5. Authority Control**
- Standardized identifiers for entities (people, products, concepts).
- Not an arrangement type, but essential for cross-referencing across arrangements.
- Without authority control, the same entity may appear under different names in different parts of the collection.

### Finding vs Living — the Retrieval/Authoring Distinction

This is the most important concept in the research. It is rarely articulated explicitly, but it surfaces in every standard:

- **Where a document *lives*** is where authors put it for maintenance, versioning, and workflow.
- **Where a document *is found*** is where users look for it during retrieval.

These are often different things.

**Concrete examples:**

| Industry | Living (Authoring) | Finding (Retrieval) |
|---|---|---|
| Aviation (S1000D) | CSDB — flat pool of DMs | Publication set — filtered, ordered DM list |
| Libraries (FRBR) | On shelves by call number (classification) | Card catalog / search — by author, title, subject |
| Construction | Drawing set folders by discipline | Sheet index by drawing number (A-101) + spec section cross-reference |
| Military (MIL-STD) | ASSIST database — by document ID | TM number — encodes system, type, volume |
| DITA authoring | Filesystem folders (useful for version control) | Maps — multiple, context-specific topic aggregations |

**The key design implication:** A structure description must describe both the *authoring organization* (how do authors arrange documents for maintenance?) and the *retrieval organization* (how do users find documents?), and must make clear that these are different layers.

Our current `file_tree` describes only the authoring organization. It says nothing about retrieval.

### Key Takeaway

There are exactly **five primitive arrangement types**: hierarchy, sequence, network, flat, and matrix. There are **five cross-cutting modifiers** that can be applied to any arrangement: tagging, faceting, full-text search, metadata/filtering, and authority control. And there is a **fundamental distinction** between authoring organization and retrieval organization.

A documentation structure description should be able to represent any combination of these.

---

## Gaps in Our Current Design

### What We Have (Current Design Output)

From the research request description, our current design output includes:

1. **file_tree** — A hierarchical filesystem path description.
2. **taxonomy** — A classification scheme (presumably hierarchical categories).
3. **navigation** — How users traverse the documentation.
4. **lifecycle** — Document states and transitions.
5. **cross-references** — Relationships between documents.

These five elements already show awareness that file_tree is not sufficient. But the research reveals several gaps:

### What's Missing

**1. No distinction between authoring and retrieval organization.**
The current design treats `file_tree` as the primary structure and `navigation` as an add-on. In real systems, the filesystem path may be irrelevant to retrieval (e.g., S1000D CSDB is a flat pool; the publication set determines retrieval). The design should treat authoring and retrieval as equally important, and potentially independent, structures.

**2. No concept of "document lives in multiple organizational contexts."**
The design assumes one file per one path. Real systems need: one document → many publication sets / many maps / many organizational contexts. The design lacks a concept of "virtual placement" — a document referenced but not copied into multiple organizational containers.

**3. No primitive arrangement types.**
The design has `file_tree` (hierarchy) and `cross-refs` (network) but does not describe sequence, flat collection, or matrix. A procedural guide needs sequence. A faceted browse needs matrix. A document registry needs flat collection. The design cannot currently describe these.

**4. No separation of content, structure, and presentation (CSP model).**
DITA separates these into topics (content), ditamaps + subject schemes (structure), and ditaval + XSLT (presentation). S1000D separates into DMs (content), DMRL (structure), and publication configuration (presentation). FRBR separates into Work/Expression (structure), Manifestation (presentation format), and Item (presence). The current design conflates content and structure in the file_tree.

**5. No taxonomy primitive independent of hierarchy.**
The design has `taxonomy` but the research shows taxonomies can be hierarchical (SKOS broader/narrower), faceted (multiple independent hierarchies), or associative (thesaurus relationships). The model needs to represent different taxonomy types, not just "category hierarchy."

**6. No cross-cutting modifier model.**
Tags, facets, metadata filtering, and full-text search are cross-cutting — they apply to any arrangement but are not arrangements themselves. The design lacks a way to say "this hierarchy is also filterable by audience attribute" or "this sequence is also taggable."

**7. No concept of numbering scheme as a first-class primitive.**
Numbering schemes (MIL-STD TM number, ATA chapter, MasterFormat code, DDC notation) are not hierarchies, though they look like them. A numbering scheme is a flat code space that *encodes* hierarchy or subject or position. The code is standalone — you can look up a TM number, a DMC, or a MasterFormat code without navigating a tree. The design needs a "numbering scheme" primitive.

**8. No concept of "organizing principle.**
Rosenfeld and Morville distinguish exact schemes (alphabetical, chronological, geographical) from ambiguous schemes (topical, task-oriented, audience-specific). The organizing principle determines *why* documents are grouped together. The design currently describes *what* groups exist (file_tree folders) but not *why* (the organizing principle).

**9. No multi-axis audience model linked to structure.**
The research from the previous deliverable shows audiences are multi-axis (role × clearance × phase × language × variant). The documentation structure should be able to indicate which segments of the structure apply to which audience axes. DITA does this with `@audience` attributes on topics and ditaval filtering. The design needs a similar capability.

**10. No variant/effectivity model.**
Many industries need to describe "this document applies to Product V1, not V2" or "this document applies to aircraft serial numbers 1000-5000." This is different from document versioning — it describes the scope of applicability, not the revision history. The design needs an effectivity primitive.

**11. No handover or boundary model.**
The structure of documentation at handover (from designer to builder, from manufacturer to operator) may differ from the internal structure. The design needs to describe "handover packaging" — what the receiver gets, in what structure.

### Recommended Minimum Primitive Set

Based on the research, the following primitives should be the minimum set for describing documentation organization:

**Core structural primitives:**

| Primitive | Description | Examples |
|---|---|---|
| `hierarchy` | Parent-child document relationship | Filesystem folders, book chapters |
| `sequence` | Ordered document position | Step-by-step, reading order |
| `network` | Typed relationships among documents | Cross-references, dependency maps |
| `flat_set` | Unordered collection | Document registry, index list |
| `matrix` | Multi-axis classification | Faceted browse, traceability matrix |
| `numbering_scheme` | Enumerated code space | ATA chapters, MasterFormat, DDC |

**Cross-cutting primitives:**

| Primitive | Description |
|---|---|
| `tagging` | Uncontrolled labels |
| `faceting` | Controlled orthogonal categories |
| `metadata_filtering` | Attribute-value filtering |
| `full_text_search` | Unstructured search |
| `authority_control` | Standard identifiers |

**Organization delivery primitives:**

| Primitive | Description |
|---|---|
| `authoring_layout` | How authors maintain documents (usually single hierarchy) |
| `retrieval_views` | How users find documents (may be multiple, independent of authoring) |
| `handover_packaging` | Structure for delivery across organizational boundaries |

**Lifecycle integration primitives:**

| Primitive | Description |
|---|---|
| `state_machine` | Document lifecycle states and transitions |
| `effective_dating` | Scheduled activation of revisions |
| `audience_filtering` | Which audience axes apply to which structural segments |
| `effectivity` | Which product versions/configurations a document applies to |
| `retention_disposition` | How long documents are kept and when destroyed |

The design should allow **any combination** of these primitives. A project may use only hierarchy + sequence (a book). Another may use hierarchy + faceting + numbering_scheme (a standards library). Another may use flat_set + tagging + full_text_search (a wiki). The primitives should not prescribe which combination is valid.

---

## Recommendations for the Documentation Skill

1. **Replace `file_tree` as the primary output** with a generic `organization` descriptor that supports all seven core structural primitives. The structure discovery procedure should ask "which arrangement types does this project use?" not "what folders do you have?"

2. **Model authoring organization and retrieval organization as separate concerns.** The discovery procedure should ask two separate sets of questions: "How do you maintain documents?" and "How do users find documents?" If the answers are different, both must be captured.

3. **Introduce "numbering scheme" as a first-class primitive.** Not all document IDs are paths. Many projects use numbering schemes that encode information. The procedure should detect and capture encoding rules.

4. **Adopt DITA's CSP model** (Content / Structure / Presentation) as the organizing framework for the skill:
   - **Content:** Documents as authored units (topics, data modules, files).
   - **Structure:** Maps, publication sets, classification schemes, taxonomies.
   - **Presentation:** Formatting, medium, output-specific styling.
   The skill should describe all three layers and their relationships.

5. **Define a taxonomy type system** that distinguishes:
   - Hierarchical taxonomy (SKOS broader/narrower).
   - Faceted taxonomy (orthogonal dimensions).
   - Thesaurus taxonomy (associative relationships).
   - Flat controlled vocabulary (no hierarchy).
   The discovery procedure should determine which type(s) apply.

6. **Introduce "virtual placement"** — the concept that a document can appear in multiple organizational contexts without being copied. Model this as references (topicref in DITA, DMRL in S1000D), not as paths.

7. **Make "audience" a multi-axis attribute** linked to structural segments. Each segment or filter rule in the organization can declare which audience axes it addresses. DITA's `@audience` attribute on topicrefs and conditional processing is the pattern to follow.

8. **Incorporate FRBR's WEMI model** as the version/identity framework:
   - Work: The document's permanent identity.
   - Expression: The language/version-specific variant.
   - Manifestation: The format-specific output.
   - Item: The specific copy.
   The skill should distinguish these when describing versioning.

9. **Model effectivity (applicability) separately from versioning.** A document applies to a set of product versions/configurations. This scope may change across revisions. The model should track both what changed and what it applies to.

10. **Design the structure discovery procedure as a series of "axis questions"** :
    - What arrangement type(s) do you use? (hierarchy/sequence/network/flat/matrix)
    - What is the organizing principle? (exact: alphabetical/chronological/geographical OR ambiguous: topical/task/audience)
    - How many audiences do you segment by? (role/clearance/phase/language/variant?)
    - Is authoring organization different from retrieval organization?
    - Do you use a numbering scheme? What does the code encode?
    - Is there a single taxonomic hierarchy or multiple facets?
    - How does content get assembled into output? (single document, multiple delivery formats, variant-specific publications)

11. **Provide template configurations** for common patterns discovered in the research:
    - **Software docs:** hierarchy (filesystem) + sequence (tutorials) + tagging (metadata) + search.
    - **Regulated engineering:** numbering scheme + hierarchy + effectivity + audience filtering + lifecycle states.
    - **Knowledge base:** flat_set + tagging + full_text_search + network (links).
    - **Library catalog:** taxonomy (classification) + faceting (author/subject/date) + authority control.
    - **Construction project:** hierarchy (disciplines) + sequence (sheets) + cross-refs (drawings ↔ specs) + numbering scheme (MasterFormat/Uniformat).

12. **Document the primitive set as part of the skill output.** When the procedure generates a documentation structure, it should include a section that documents which organizational primitives were selected, how they relate, and where the *authoring* organization differs from the *retrieval* organization. This self-description is essential for handover.
