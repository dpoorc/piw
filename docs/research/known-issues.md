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
   in pi-web-access — the function was a `const` defined inside the
   `try` block but called from the `catch` block (separate scope).

**Status: FIXED** (2026-07-29)

**Patch applied:** in-image pi-web-access (`index.ts`):
1. Moved `sendCuratorFallbackUpdate` function definition from inside
   the `try` block to function scope (before `try`).
2. Wrapped `openInBrowser` call in its own try-catch so browser-open
   failures don't fall through to the outer catch.
3. Outer catch now only handles setup errors (curator server startup
   etc.) and closes the curator cleanly.

**Workaround (still valid for other sessions without the patch):**

Use `web_search` with `workflow: "none"` or `workflow: "auto-summary"`
to skip the browser curator entirely:

```
web_search(query="..." workflow="auto-summary")
```
