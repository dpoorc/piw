# Philosophy

## Why a harness instead of just `npm install -g pi`?

Because the agent has full filesystem access. Running it bare-metal
means it can read and write anything your user can. Most of the time
that's fine — but when you're provisioning servers, handling
credentials, or working on infrastructure, you want a boundary.

Docker is the simplest boundary that works. No micro-VMs, no policy
engines, no sandbox SDKs. Just a container with bind mounts.

## Lean and mean

Every tool in the container is there because someone needed it for a
real task. Nothing is "nice to have" or "might be useful someday."
If you need something new, create a variant or extend an existing one.

This applies to skills too. The workflow skill tells the agent what's
specific to this environment and this user. It does not re-explain
basic coding agent concepts — the model already knows what it is.

## Transparent over magical

- Skills are plain Markdown files you can read and edit.
- `piw` is a single bash script with no hidden logic.
- Variants are self-contained directories with their own Dockerfiles.
- The `.env` file is a plain shell script sourced at startup.

Nothing is generated, compiled, or obscured. If something breaks, you
can trace it.

## Alignment before action

The agent is encouraged (via the workflow skill) to understand before
implementing, to propose before executing, and to flag problems early.
This saves time. Rework costs more than a clarifying question.

## Composition, not monolith

Variants, skills, and docs are all designed to be composed. Need
a variant that has Python AND Kubernetes tools? Create one. Found
a great community skill? Drop it in `skills/ready/`. The structure
supports growth without requiring it.
