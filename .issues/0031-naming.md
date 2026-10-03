---
id: 31
title: Naming
status: closed
priority: low
labels:
    - wayfinder:grilling
relations:
    blocks:
        - 30
    related-to:
        - 13
created: "2026-10-01"
updated: "2026-10-03"
closed: "2026-10-03"
---

## Question

Is the project pi-harness or piw?

Decide the repo name, the binary name, the package name, and how the docs and
install instructions read. Small, but it blocks the docs rewrite.

## Findings

1. **The repository is already named `piw`.** The remote is
   `git@github.com:dpoorc/piw.git`. Only the local checkout directory is called
   `pi-harness`.
2. **The split was documented as a known thing.**
   `docs/publishing.md:79` reads "Current split: repo is `pi-harness`, CLI tool
   is `piw`".
3. **The counts are lopsided.** In tracked files, `piw` appears 449 times and
   `pi-harness` 72.
4. **`pi-harness` did real work in one place**: the Docker image prefix,
   `pi-harness:default` and `pi-harness:local`.
5. **There is no package manifest.** No `package.json`, `pyproject.toml`,
   `Cargo.toml`, or `go.mod`, and no `install.sh`. `piw` is a single bash
   script.
6. **The README's quick start was stale.** It used `piw --install`, which
   **CLI surface** replaced with `piw link`.

## Answer

### `piw` everywhere

Repository, binary, images, and docs. `pi-harness` stops being a name and
survives only as a description, as in "a portable harness for the pi coding
agent".

The split was reasonable when the project was a set of images and the tool was
a script that built them. Now the tool is the product. A reader who clones
`piw` and runs `piw` should not have to learn a second name, and the remote
already agreed.

**The image prefix becomes `piw`**: `piw:default` and `piw:local`. This is free
today and expensive later, which is exactly why **Naming** blocked the docs
rewrite. Nothing is published yet, so no user holds an image under the old
name.

### No package

`piw` is one script, installed by cloning and running `piw link`. No npm
package, no Homebrew formula.

A package would add a publishing pipeline and a version to keep in sync for a
single script, and an npm package would require node on the host, which is not
guaranteed. The property that matters here is that the project is
self-contained: clone it, run a couple of commands, and it works. A package
channel would trade that for a dependency.

If a channel is wanted later, the name is already decided, and it is `piw`.

### The install instructions

```bash
git clone https://github.com/dpoorc/piw.git
cd piw
./piw link          # puts `piw` on PATH
piw ~/my-project    # launches pi in the project
```

### One caveat for the docs

**The local directory name is not the repo name.** Renaming an existing
checkout would orphan pi's session directory, which is keyed to the path
(`--home-<user>-Projekt-pi-harness--`). So the docs say `cd piw` as the
conventional name without implying that an existing checkout must be renamed.

## Consequences

- **Docs rewrite for publishing** writes everything as `piw`. Its own blocker
  is now cleared.
- **Migrate paths into the `.local` namespace** renames `IMAGE_PREFIX` and
  clears the remaining `pi-harness` references in live files.
- **`docs/publishing.md`'s "Current split" line is obsolete** and goes with the
  docs rewrite.
- **`.issues/` is not rewritten.** It is the decision log, and each file is a
  dated record. The image prefix it names as `pi-harness:` is superseded here,
  by the amending ticket, which is how the other amendments are recorded too.
