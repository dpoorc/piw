# Philosophy

## Why a harness instead of `npm install -g pi`?

The agent has full filesystem access. Bare-metal, it can read and write
anything your user can. Most of the time that is fine. When you provision
servers, handle credentials, or work on infrastructure, you want a boundary.

Docker is the simplest boundary that works. No micro-VMs, no policy engines,
no sandbox SDKs. A container with bind mounts is enough.

## The principles

### Isolation

The agent cannot change the host outside the paths you mount. The container
is disposable, so a bad change inside it costs nothing. The workspace is
bind-mounted, so your work survives.

### Transparency

Nothing is hidden. Skills are Markdown files you can read and edit. `piw` is
a single bash script. The Dockerfile is plain and self-contained. The
manifests are text. If something breaks, you can trace it.

### Leanness

Every tool in the default image is there because a real task needed it.
Nothing is "nice to have". If you need more, add a layer or a store tool. The
same rule applies to skills: a skill tells the agent what is specific to this
environment. It does not re-explain what the model already knows.

### Composition

Layers, store tools, skills, and agents are separate pieces. A layer that
adds Python and a layer that adds Kubernetes tools combine without changes.
A community skill drops into `skills/vendor/`. The structure supports growth
without requiring it.

When the principles conflict, the order above decides: isolation first, then
transparency, then leanness, then composition.

## Alignment before action

The workflow skill asks the agent to understand before it implements, to
propose before it executes, and to report a problem early. A clarifying
question costs less than rework.

## The workspace is independent

The harness and the workspace are separate. A user can clone the harness
once, install the CLI, and then launch it in any project. The harness
directory holds the tooling and the state. The workspace holds the work.

The harness can also run on itself. This is convenient for development and
confusing at first: the agent runs inside the tool it is changing.
