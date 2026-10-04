# Roadmap

## Now

- **Documentation skill.** The `doc-writing` skill is a work in progress. It
  needs a full design: a structure-discovery procedure, stage contracts, and
  a versioning mechanism. The research is in `docs/research/`.

## Next

- **A setup command.** `piw setup` would gather facts, build the image,
  install packages, write a log, and then launch pi with a prompt that loads
  a setup skill. The skill would read the log and guide the remaining steps.
- **A confidence statement.** Define how the agent flags a low-confidence
  claim and gives an estimate for a research result. The criteria are
  settled. The mechanism needs a skill section or an APPEND_SYSTEM.md line.
- **CONTRIBUTING.md.** Document the alignment-before-action workflow, so a
  contributor understands the proposal step before opening a pull request.

## Later

- **Session pruning.** Session logs grow without limit. Three approaches are
  recorded in `docs/research/session-file-management.md`. Pick one, then add
  a `piw` subcommand or keep the pruning manual.
- **A guard around the store install.** A mise failure inside `piw build`
  aborts the command before the summary. The install step should report the
  failure and reach the summary.
- **The `build/archives/` directory.** The shipped layer fetches its
  archives itself with a checksum, so the directory is unused. Remove it, or
  keep it for a layer that copies a manual download.

## Deferred

- **MCP integration.** Needs upstream MCP bridge work.
- **CodeGraph integration.** A heavy dependency. Wait for the MCP bridge.
- **Context-mode.** Needs the OpenClaw gateway and an Elastic-licensed
  dependency.
- **Sub-agent packages.** Three packages are evaluated in
  `docs/research/tools-evaluation.md`. All wait for an actual need.

## Done

- **The portable harness.** The repository has one gitignored state
  namespace (`.local/`), one install path (mise, inside the container), and
  two images (`piw:default` and `piw:local`). The old variants, the
  `extensions.txt` manifest, and the root `.pi/` directory are gone. A layer
  replaces a variant, and a store tool survives an image rebuild.
- **The workstation layer.** The compilers, the infrastructure tools, and
  the security and forensics tools from the old workstation variant ship as
  the first layer.
- **A hermetic test suite and CI.** The suite drives the real `piw` against
  a stub `docker`. CI runs the suite and shellcheck.
- **The permission modes.** Three modes (`permissive`, `restricted`,
  `readonly`) gate the agent, with anchored secrets rules.
- **The skill catalog.** The catalog lists the skills that the system prompt
  hides. The generator uses `yq`, and its output is reproducible.
