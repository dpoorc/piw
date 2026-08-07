# Skills catalog

All available skills in this harness, organized by source and theme.
Invoke any skill with `/skill:<name>`.

## System (built-in)

- **`browser-tools`** — Interactive browser automation via Chrome DevTools Protocol. Use when you need to interact with web pages, test frontends, or when user interaction with a visible browser is required. *(user-invoked)*
- **`doc-writing`** — Document a project using a consistent directory structure, file naming conventions, and writing style. WIP — subject to review.  *(model-activated)*
- **`git-workflow`** — Git conventions for projects developed inside the pi-harness. Covers commit format, branch strategy, and integration with the alignment-before-action workflow. A global skill that gives way to project-local conventions.  *(model-activated)*
- **`handoff`** — Request and receive handoffs from other pi sessions. Use when transitioning between sessions, collecting context, or delegating work. A handoff transfers findings, WIP, and roadmap context.  *(model-activated)*
- **`ste-writing`** — Write prose (docs, READMEs, PR descriptions, error messages, release notes, comments — never code) in ASD-STE100 Simplified Technical English to remove "AI slop". Defaults to STE-flavored mode for general technical prose. Use strict mode for procedures, runbooks, and safety text.  *(model-activated)*
- **`workflow`** — pi-harness workflow — interaction model, patterns, and environment context for working inside this Docker-based coding harness. Read this before taking any action and after every compaction.  *(user-invoked)*

## Vendor: mattpocock

### engineering

- **`ask-matt`** — Ask which skill or flow fits your situation. A router over the skills in this repo. *(user-invoked ⚠ needs tracker)*
- **`code-review`** — Review the changes since a fixed point (commit, branch, tag, or merge-base) along two axes — Standards (does the code follow this repo's documented coding standards?) and Spec (does the code match what the originating issue/spec asked for?). Runs both reviews in parallel sub-agents and reports them side by side. Use when the user wants to review a branch, a PR, work-in-progress changes, or asks to "review since X". *(model-activated ⚠ needs tracker)*
- **`codebase-design`** — Shared vocabulary for designing deep modules. Use when the user wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, make code more testable or AI-navigable, or when another skill needs the deep-module vocabulary. *(model-activated)*
- **`diagnosing-bugs`** — Diagnosis loop for hard bugs and performance regressions. Use when the user says "diagnose"/"debug this", or reports something broken/throwing/failing/slow. *(model-activated)*
- **`domain-modeling`** — Build and sharpen a project's domain model. Use when the user wants to pin down domain terminology or a ubiquitous language, record an architectural decision, or when another skill needs to maintain the domain model. *(model-activated)*
- **`grill-with-docs`** — A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go. *(user-invoked)*
- **`implement`** — Implement a piece of work based on a spec or set of tickets. *(user-invoked)*
- **`improve-codebase-architecture`** — Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick. *(user-invoked)*
- **`prototype`** — Build a throwaway prototype to answer a design question. Use when the user wants to sanity-check whether a state model or logic feels right, or explore what a UI should look like. *(model-activated)*
- **`research`** — Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent. *(model-activated)*
- **`resolving-merge-conflicts`** — Use when you need to resolve an in-progress git merge/rebase conflict. *(model-activated)*
- **`setup-matt-pocock-skills`** — Configure this repo for the engineering skills — set up its issue tracker, triage label vocabulary, and domain doc layout. Run once before first use of the other engineering skills. *(user-invoked ⚠ needs tracker)*
- **`tdd`** — Test-driven development. Use when the user wants to build features or fix bugs test-first, mentions "red-green-refactor", or wants integration tests. *(model-activated)*
- **`to-spec`** — Turn the current conversation into a spec and publish it to the project issue tracker — no interview, just synthesis of what you've already discussed. *(user-invoked ⚠ needs tracker)*
- **`to-tickets`** — Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published to the configured tracker — edges as text in one file per ticket locally, or native blocking links on a real tracker. *(user-invoked ⚠ needs tracker)*
- **`triage`** — Move issues and external PRs through a state machine of triage roles — categorise, verify, grill if needed, and write agent-ready briefs. *(user-invoked ⚠ needs tracker)*
- **`wayfinder`** — Plan a huge chunk of work — more than one agent session can hold — as a shared map of decision tickets on your issue tracker, and resolve them one at a time until the way to the destination is clear. *(user-invoked ⚠ needs tracker)*
- **`wizard`** — Generate an interactive bash wizard that walks a human through steps only they can perform. Use when provisioning infrastructure, setting up credentials or CI secrets, walking an unfamiliar third-party dashboard, or running a one-off migration or cutover. Don't invoke this for steps the agent can perform itself. *(model-activated)*

### productivity

- **`grill-me`** — A relentless interview to sharpen a plan or design. *(user-invoked)*
- **`grilling`** — Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases. *(model-activated)*
- **`handoff`** — Compact the current conversation into a handoff document for another agent to pick up. *(user-invoked)*
- **`teach`** — Teach the user a new skill or concept, within this workspace. *(user-invoked)*
- **`to-questionnaire`** — Turn a decision you can't fully answer into a questionnaire for someone else to fill in. *(user-invoked)*
- **`wait-what`** — Stop. That last message did not land — re-pitch it. *(user-invoked)*
- **`writing-for-agents`** — Writing documents for agents. Use when creating or editing skills, or modifying AGENTS.md or CLAUDE.md. *(model-activated)*

