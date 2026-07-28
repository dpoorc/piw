# rtk — Rust Token Killer

rtk is a CLI proxy that reduces shell output tokens by 60–90% for
common dev operations. It's integrated into the harness via the
`rtk-pi` extension, which automatically rewrites eligible commands.

## How It Works

The `rtk-pi` extension intercepts shell commands and checks if rtk
has an optimizer subcommand for them. If yes, the command is transparently
rewritten. For example, `git status` becomes `rtk git status`, producing
a compressed summary instead of verbose output.

Commands already prefixed with `rtk`, rtk meta commands, interactive
commands, heredocs, and unsupported commands are left unchanged.

## Meta Commands

These always run through rtk directly (bypassing the extension):

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze history for missed optimization opportunities
rtk session           # Show RTK adoption across recent sessions
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
rtk rewrite <cmd>     # Show how RTK would rewrite a raw command
```

## Debugging

To see if rtk is active and working:

```bash
# Check rtk version
rtk --version

# See how a command would be rewritten
rtk rewrite git status

# Compare raw vs optimized output
rtk proxy git status    # raw, unfiltered output
git status              # rtk-optimized (via extension)
```

## Savings Profile

Typical savings by command type:

| Command | Savings | Reason |
|---------|---------|--------|
| `git status` | ~80–90% | Diffs, branch info summarized |
| `git log` | ~70–85% | Commit details condensed |
| `docker ps` | ~60–75% | Table columns filtered |
| `npm list` | ~70–80% | Dependency tree summarized |

Actual savings depend on repository size, output volume, and command
frequency.

## Verification

Run `piw doctor` to confirm rtk is installed in the Docker image:
it checks `rtk --version` inside each variant's image.
