# Great Documentation Examples

Research note for wayfinder ticket #3 (Finding great documentation examples).
Findings compiled from research conducted by documentation-intercom-1.

---

## Cross-Cutting Patterns

Before the individual examples, the patterns that recur across every excellent
documentation set:

1. **Consistent templates per page/guide type** — every excellent example has
   them (MDN, Blender, GNOME, Rails, Godot).
2. **Docs-as-code workflow** — Markdown in Git, CI-tested examples, peer
   review (Kedro, Rails, Rust).
3. **Progressive disclosure** — tutorial → how-to → reference → explanation
   (Django/Diátaxis, Vue, Rust).
4. **Explicit writing/style guide** — the doc skill should reference or embed
   one (Rails, FreeBSD, Arch Wiki, Blender).
5. **Domain-modeled navigation** — organize around user concepts, not
   implementation details (Stripe objects, Terraform resources, Blender UI).
6. **Executable/verified examples** — test them in CI (Rust doc-tests, Django,
   Kedro bake examples from code).
7. **Version discipline** — maintain old versions, label clearly (PostgreSQL
   back 20 years, Django back to 1.0).
8. **Audience segmentation** — beginner-to-expert path or tutorial/reference
   split (Kedro TOC praised for this).

---

## 1. Stripe API Docs — docs.stripe.com/api

**Domain:** Payments API (commercial, massive scale)

**What makes it excellent:**
- Object-first navigation (Customers, Charges, Invoices) not HTTP-method
  grouping — models docs around the domain, not the protocol.
- Three-column layout with code samples scrolling in lockstep with reference
  prose. This requires curated examples per language per endpoint — the
  authoring discipline matters more than the CSS.
- Language switcher with persistence — each example is idiomatic for the
  language, not a translated curl command.
- Personalized test keys injected server-side into code samples when logged
  in — collapses read-to-execute from an hour to seconds.
- Inline "Try it" panels that return real JSON responses without leaving the
  page.
- Error reference as a first-class page — errors get editorial priority
  matching the time developers spend debugging.
- Guides-vs-reference split (two separate sites with different information
  architectures).

**Universal truths:** Findability (object nav), navigability, teachability
(executable examples), minimality of friction.

**What the skill can learn:** Authoring discipline matters more than layout
tricks; errors deserve first-class treatment; minimize steps between reading
and executing; domain-modeled navigation beats protocol-modeled.

---

## 2. Rails Guides — guides.rubyonrails.org

**Domain:** Web framework (large community, long-running)

**What makes it excellent:**
- Strict style guide enforced over decades — prologue format, heading
  hierarchy, NOTE/TIP/WARNING conventions, link style rules (no "here" links).
- Consistent structure per guide — each starts with prologue (motivation +
  what you will learn).
- API-to-guide cross-linking that auto-resolves to the correct version.
- Markdown-as-code philosophy — written in GF Markdown, built with Rake,
  validated in CI.
- 93-column column-width standard.

**Universal truths:** Teaching (narrative guides), navigability (consistent
structure), findability (cross-references), versioning.

**What the skill can learn:** Enforce a writing style guide strictly; make
structural conventions explicit and checkable; treat docs as build artifacts
with CI.

---

## 3. Vue.js Docs — vuejs.org/guide

**Domain:** Frontend framework (medium-large community)

**What makes it excellent:**
- Progressive disclosure — the writing guide explicitly says "documentation is
  an exercise in empathy"; concepts introduced from simple to complex.
- Writing guide for contributors that governs tone, voice, and structure.
- Crisp separation of concerns: Tutorial → Guide → Examples → API Reference.
  Each section serves a different reading mode.
- Consistent example format — every feature shown with a runnable code snippet
  in context.

**Universal truths:** Teaching (progressive disclosure), navigability (clear
section roles), findability.

**What the skill can learn:** Progressive disclosure is a deliberate authoring
choice, not an accident; separate tutorial from reference from cookbook; make
the learning path explicit.

---

## 4. MDN Web Docs — developer.mozilla.org

**Domain:** Web platform reference (encyclopedic, multi-organization)

**What makes it excellent:**
- Page type templates — API landing page, API reference page, guide page each
  have a rigid template with required sections.
- Consistent sidebar navigation per technology area.
- Browser compatibility tables integrated into every feature page.
- "Learn web development" → "Reference" → "Guides" three-layer structure.
- Living standard tracking — docs update as specs evolve.
- Community contribution model with review gates.

**Universal truths:** Findability (templates + consistent nav), navigability,
teachability (learning path), versioning (spec tracking).

**What the skill can learn:** Template-based authoring at scale; separate
learning paths from reference; compatibility/status metadata is essential for
trust.

---

## 5. PostgreSQL Manual — postgresql.org/docs

**Domain:** Database (long-running, infrastructure)

**What makes it excellent:**
- Single authoritative source — written by the core developers in parallel with
  the code.
- Deep technical depth — covers SQL syntax, admin, internals, replication,
  performance tuning in one unified manual.
- Versioned docs back to PostgreSQL 7.1 (two decades).
- Reference + tutorial + admin manual in one coherent book structure.
- Consistent cross-references within and across chapters.

**Universal truths:** Versioning, depth, minimality (one authoritative source).

**What the skill can learn:** Long-term version maintenance discipline; deep
technical docs can be single-source if structured well; developer-authored docs
carry unique authority.

---

## 6. FreeBSD Handbook — docs.freebsd.org/en/books/handbook

**Domain:** Operating system (long-running, infrastructure)

**What makes it excellent:**
- Continuously maintained for decades — the Handbook is the canonical reference
  for the entire OS.
- Rigid typographic conventions (specific use of bold/monospace/italics for
  different purposes).
- The FreeBSD Documentation Project Primer defines the writing and structural
  conventions explicitly.
- AsciiDoc-based — structured markup with semantic elements.
- Task-oriented structure (install → configure → network → security →
  advanced).

**Universal truths:** Navigability (task-oriented), findability, versioning,
minimality.

**What the skill can learn:** Make the writing conventions themselves a
deliverable (the Primer); task-oriented organization scales across decades;
document the documentation process.

---

## 7. Kedro Docs — docs.kedro.org

**Domain:** Data/ML pipelines (medium, award-winning)

**What makes it excellent:**
- Winner of UK Technical Communication Awards 2023 (overall winner).
- Docs-as-code workflow — Markdown in Git, CI-tested, peer-reviewed, same
  process as code.
- Clear beginner-to-expert progression in the table of contents — judges
  praised this specifically.
- Simple, friendly, functional voice — consistent tone enforced across all
  contributors.
- Usage analytics and user research drives prioritization.
- Blog complements docs for insights and updates.

**Universal truths:** Minimality, teachability, navigability.

**What the skill can learn:** Awards criteria are worth analyzing as design
constraints; docs-as-code is a proven process model; user analytics should
drive doc improvements.

---

## 8. Arch Linux Wiki — wiki.archlinux.org

**Domain:** Linux distribution (community-driven, encyclopedic)

**What makes it excellent:**
- Strict style conventions enforced by the community — article templates,
  category system, naming conventions.
- "No stopping point" philosophy — every article links outward to related
  topics; readers can always find more.
- Category-based navigation over search-first — articles are cross-categorized.
- Living document — updated continuously by the community as packages change.
- Package-specific pages with installation, configuration, troubleshooting per
  tool.

**Universal truths:** Findability (category system + cross-links), navigability,
minimality (no duplication).

**What the skill can learn:** Community wiki conventions at scale; category
taxonomies are a navigation superpower; "no stopping point" linking philosophy
keeps readers in the flow.

---

## 9. Django Docs — docs.djangoproject.com

**Domain:** Web framework (large community, long-running)

**What makes it excellent:**
- Famous "first tutorial" (the Polls app) — walks through building a real app
  end-to-end before any reference.
- Clear four-part structure: Tutorial → Topic Guides → Reference → How-To
  Guides (inspired by Diátaxis).
- Versioned back to Django 1.0.
- "Writing documentation" internal guide — explicit standards for contributors.
- Extensive code examples that are tested as part of CI.

**Universal truths:** Teaching (tutorial-first), navigability (Diátaxis
structure), versioning, minimality.

**What the skill can learn:** The Diátaxis model
(Tutorial/How-To/Reference/Explanation) is a proven information architecture;
test code examples in CI.

---

## 10. Godot Engine Docs — docs.godotengine.org

**Domain:** Game engine (medium, rapidly growing)

**What makes it excellent:**
- Class reference in XML — parsed and rendered to HTML, keeps API docs in sync
  with engine source.
- Step-by-step tutorials for every engine subsystem (2D, 3D, audio, physics,
  GDScript).
- Consistent template for every class — description, properties, methods,
  signals, enums.
- Version selector for three major versions.
- Contributor guide separate from user docs.
- Covers both beginner game dev and engine internals.

**Universal truths:** Versioning, navigability (consistent templates),
teachability.

**What the skill can learn:** Auto-generated reference docs from source plus
hand-written tutorials is a powerful hybrid; XML-in-source guarantees reference
accuracy.

---

## 11. Rust Docs (The Book + Rust by Example) — doc.rust-lang.org

**Domain:** Systems programming language (large, active community)

**What makes it excellent:**
- "The Book" — a narrative tutorial that teaches ownership/borrowing/lifetimes
  conceptually before syntax.
- "Rust by Example" — companion collection of runnable examples, each
  illustrating one concept.
- Interactive "Rust Playground" embedded in docs — every code sample is
  runnable.
- Brown University version adds interactive questions and visualizations.
- `cargo doc` auto-generates API docs from code comments (doc-tests).
- Strict formatting enforced by rustfmt on doc examples.

**Universal truths:** Teaching (dual narrative + example paths), findability,
minimality.

**What the skill can learn:** Two parallel learning paths (narrative +
example-driven) cover different reader personalities; doc-tests keep examples
honest; interactive playground is a force multiplier.

---

## 12. SQLite Docs — sqlite.org/docs

**Domain:** Database library (small team, iconic)

**What makes it excellent:**
- Single-page architecture — the entire SQL reference is one HTML page (search
  with Ctrl+F).
- No JavaScript framework, no build pipeline — hand-written, static HTML.
- Extraordinary depth per page — the C API page documents every function, flag,
  and return code.
- Version history back to 2000.
- Testing documentation — famously 100x more test code than library code, and
  the testing methodology is documented.

**Universal truths:** Minimality (no tooling, no JavaScript), depth, versioning.

**What the skill can learn:** Less tooling can mean better docs; single-page
works for reference material when the domain is bounded; radical minimalism can
be a feature, not a bug.

---

## 13. Blender Manual — docs.blender.org/manual

**Domain:** 3D creation suite (large, complex, visual)

**What makes it excellent:**
- "Functional description" of every feature, tool, and option — exhaustive
  coverage.
- Visual documentation — heavy use of annotated screenshots and UI callouts.
- Templates for every page type (tool reference, operator, panel, preference).
- Markup guide defines exact reStructuredText conventions.
- Structured to match the application UI — the manual tree mirrors Blender's
  menus and panels.
- Translation-friendly — `.po` files alongside `.rst`.

**Universal truths:** Findability (mirrored UI structure), navigability,
teachability (visual), minimality.

**What the skill can learn:** Mirroring the application UI hierarchy in the doc
navigation is powerful for complex tools; visual docs require different
authoring skills than code docs; templates ensure coverage completeness.

---

## 14. Terraform Docs (HashiCorp) — developer.hashicorp.com/terraform

**Domain:** Infrastructure-as-Code (commercial, ecosystem)

**What makes it excellent:**
- Provider design principles as a guide — docs organized around the
  provider/resource/data-source model.
- Layered structure: Tutorials → Guides → Provider docs → Plugin framework
  docs.
- Registry-integrated — Terraform Registry auto-generates docs from provider
  schema, keeping reference in perfect sync.
- Quickstart tutorials designed to produce a real resource, not a toy example.
- Code examples in multiple languages/approaches (HCL + JSON + CLI).

**Universal truths:** Versioning (registry sync), navigability (provider model),
teachability (real quickstarts).

**What the skill can learn:** Schema-generated reference docs solve the
staleness problem; organize docs around the user mental model (resources), not
the implementation (protocols).

---

## 15. GNOME Human Interface Guidelines — developer.gnome.org/hig

**Domain:** Desktop UI design guidelines (open source, long-running)

**What makes it excellent:**
- Pattern-based organization — navigation patterns, control patterns, feedback
  patterns.
- Each pattern has a consistent format: description, when to use, when not to
  use, how to implement, related patterns.
- Design rationale included — explains why a pattern works, not just how.
- Linked to widget implementation — every pattern maps to a GTK widget.
- Accessible design guidance baked into every pattern.

**Universal truths:** Findability (pattern format), navigability (consistent
template), teachability (rationale alongside guidance).

**What the skill can learn:** A pattern library format is reusable across
domains; including "when not to use" is as important as "when to use";
rationale builds trust.
