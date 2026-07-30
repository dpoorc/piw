# Session File Management

> **PROPOSAL** — Ideas for managing accumulated session log files
> in `.pi/agent/sessions/`. Not implemented. Just a record of the
> discussion and possible approaches.

## Background

Session files accumulate in `.pi/agent/sessions/<workspace-hash>/`
as JSONL files. Each session produces one file (50KB–2MB typical).
Over time this grows without bound — the pi-harness workspace alone
had 9 files totaling ~5.5MB before cleanup.

The `.pi/` directory is gitignored so session files never pollute
version control, but they take up space on disk and make `ls` output
noisy.

## Current behavior

- pi does not rotate or prune session files
- No built-in retention policy
- The only cleanup mechanism is manual deletion

## Use cases for keeping session files

| Use case | Value | Retention need |
|----------|-------|---------------|
| Session resume (`piw -r`) | Resume in-progress work | Active sessions only |
| `rtk discover` / `rtk gain --history` | Token optimization analytics | Recent sessions (7-30 days) |
| Post-hoc reference | Check what happened in an earlier session | Until task is complete |
| Audit trail | Know what the agent did | Project lifetime |

## Proposals

### A — piw subcommand: prune

```bash
piw prune-sessions [--keep-days 30] [--keep-count 10] [--workspace <hash>]
```

- Default: keep sessions from the last 30 days
- `--keep-count`: keep the N most recent regardless of age
- `--workspace`: target a specific workspace only
- Dry-run mode: `piw prune-sessions --dry-run` (show what would be
  deleted without deleting)

### B — githook / cron

- A post-hoc cleanup script that prunes on `piw update`
- Or a systemd timer on the host

### C — Do nothing / manual only

- Current approach. Works fine if the user remembers to clean up
  occasionally (which they just did).
- Adds no complexity, no maintenance burden.

## Recommendation

Start with **C** (manual only). If the accumulation becomes annoying
again, implement **A** with a simple find-based prune in piw.

## Cost (if implemented as A)

- ~20 lines of bash in piw
- Uses `find` with `-mtime` for age-based pruning, no new dependencies
