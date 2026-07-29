# Known Issues

Issues that have been encountered in practice and need a fix. This is
not a tracker — just a place to record what broke so it doesn't get
forgotten between sessions.

---

## pi-web-access browser curator crash

**Observed:** 2026-07-27, session with DeepSeek V4 Flash (Fireworks)

**Symptoms:**

```
Failed to open curator UI: Failed to open browser (exit code 1)
...
pi exiting due to uncaughtException:
ReferenceError: sendCuratorFallbackUpdate is not defined
    at openCuratorBrowser (.../pi-web-access/index.ts:1188:9)
```

**Root cause (two independent bugs):**

1. **No browser in container** — `web_search` defaults to opening a
   browser-based curator UI for interactive review. The container
   has no browser installed (no xdg-open, chromium, firefox, etc.),
   so the attempt fails immediately.

2. **Missing fallback handler** — When the browser fails to open,
   pi-web-access tries to call `sendCuratorFallbackUpdate` which
   is not defined in scope at that point. This is a reference error
   in pi-web-access — the function either wasn't imported or wasn't
   declared before use.

**Workaround:**

Use `web_search` with `workflow: "none"` or `workflow: "auto-summary"`
to skip the browser curator entirely:

```
web_search(query="..." workflow="auto-summary")
```

**Fix needed (one or both):**
- Add a browser to the core/devops variants (xdg-utils + a lightweight
  browser? overkill for a CLI tool)
- Patch or upstream a fix for pi-web-access to handle the browser
  failure gracefully (catch the error, fall back to no-curator mode
  automatically)
