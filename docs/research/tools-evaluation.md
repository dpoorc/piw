# Tools evaluation

> **REFERENCE** — Evaluations of third-party tools and packages for
> potential integration into pi-harness. Items here are either
> documented for future consideration or were evaluated but not
> integrated at this time.

---

## Sub-agent capabilities

Three pi packages provide sub-agent functionality — delegating work to
specialized child processes with isolated context windows. All work by
spawning `pi --mode json -p --no-session` subprocesses.

### pi-sub-agent (mazli)

| Attribute | Value |
|-----------|-------|
| Package | `npm:pi-sub-agent` |
| Downloads | ~256/mo |
| Size | 119KB |
| Version | 0.1.5 |
| License | MIT |

**Features:**
- Single, parallel, and chain execution modes
- 9 built-in agent types: scout, planner, worker, reviewer, debugger,
  verifier, security-auditor, docs-writer, refactorer
- Discovers user agents from `~/.pi/agent/agents/*.md`
- Minimal dependency footprint

**Verdict:** Lightweight but immature (v0.1.5, low adoption).

### @tintinweb/pi-subagents (tintinweb)

| Attribute | Value |
|-----------|-------|
| Package | `npm:@tintinweb/pi-subagents` |
| Downloads | ~39.9K/mo |
| Size | 875KB |
| Version | 0.14.2 |
| License | MIT |

**Features:**
- Claude Code-style autonomous sub-agents
- Planning and scoping before execution
- Shutdown and restart of sub-agents
- Most mature option (v0.14.2, highest adoption)

**Verdict:** Strongest candidate. Mature, well-adopted, feature-rich.
Recommended for evaluation when sub-agents are needed.

### pi-subagents (Nico Bailon)

| Attribute | Value |
|-----------|-------|
| Package | `npm:pi-subagents` |
| Downloads | ~28.2K/wk |
| Size | 2.3MB |
| Version | — |
| License | MIT |

**Features:**
- Async subagent delegation with truncation
- Artifact sharing between parent and child sessions
- TUI clarification prompts
- Integrates with pi-intercom for supervisor communication
- 147 files, 2 dependencies

**Verdict:** Popular and actively developed. Heavier footprint but
tighter pi-intercom integration. Author also maintains pi-web-access
and pi-intercom (known quantity).

---

## Context-mode

| Attribute | Value |
|-----------|-------|
| Package | `npm:context-mode` |
| Stars | ~19K (GitHub) |
| Type | OpenClaw gateway plugin + native pi extension |
| License | Elastic |

**What it does:**
- Sandboxes tool output (claims 98% reduction in context usage)
- Persists session memory across sessions
- Enforces routing across platforms
- Native pi extension via OpenClaw plugin API (8 lifecycle hooks)

**Why deferred:**
- Requires the OpenClaw gateway plugin as a dependency layer
- Elastic License (not MIT/Apache — potential restrictions)
- 98% reduction claim is impressive but needs real-world validation
- Better suited for teams with high token usage than individual dev

---

## CodeGraph

| Attribute | Value |
|-----------|-------|
| Repository | `codegraph-ai/CodeGraph` |
| Type | MCP server + CLI |
| Languages | 38 parsers |
| Storage | RocksDB (persistent) |

**What it does:**
- Builds a semantic graph of your codebase (functions, classes,
  imports, call chains)
- Exposes 42 MCP tools for querying the graph
- Persistent memory layer across sessions
- Auto-syncs on code changes

**Why deferred:**
- MCP-based integration requires the MCP bridge (deferred)
- Heavy dependency: Rust kernel, RocksDB, 38 parsers
- Overkill for most pi-harness use cases
- More valuable for large unfamiliar codebases than day-to-day work
