# LAUNCH DAY RUNBOOK — [CLIENT/PROJECT]

One page. Roles, not names. Freezes before the button: [DATE/TIME].
Owners marked `[X]` = to be filled at sanity check — guessed slots are
marked `[assumed]` — cross out anything wrong, that is the point.

## THE PRESS-THE-BUTTON ORDER

1. **CONTENT FREEZE** — final copy/images in, no edits after [TIME].
   Owner: content owner (not the client account).
2. **STAGING VERIFY** — deploy candidate staged, smoke list run,
   code-freeze label applied. Owner: deploy owner.
3. **BACKUP + SNAPSHOT** — pre-launch DB backup + server snapshot
   tagged `launch-day`. Owner: infra owner.
4. **DEPLOY** — by [pipeline name / manual steps — assumed: standard
   pipeline]. Watch [error log] live. Owner: deploy owner.
5. **MIGRATIONS** — run after deploy if flagged; verify version
   [expected version]. Owner: DB owner.
6. **FLIP** — DNS/edge to prod; TTL lowered [X] hours before.
   Owner: DNS owner.
7. **SSL + EDGE** — cert valid, cache purged, origin reachable.
   Owner: infra owner.
8. **SMOKE TESTS** — the five never-fail checks: [homepage, checkout,
   login, search, X]. Owner: QA owner.
9. **ELEVATED WATCH** — first 60 min: errors, payments, storage;
   alert on [threshold]. Owner: on-call.
10. **GO-LIVE COMMS** — client announcement + internal [channel] post
    with link + status. Owner: account owner.

## ROLLBACK — when a step fails and stays failed [X] min

- Trigger: [which failures].
- Action: revert to the step-3 snapshot, flip back, announce loudly in
  [channel]. No quiet rollbacks.
- Rule: no pushes after [X] failed attempts.

## GO / NO-GO

Max two people: [Dan],[James] say go at [time], before step 6.
Anything else is no-go, not panic.

## POST-LAUNCH WATCH

60-min check [X], 24-h check [X]. Downtime over [X] min pages
[on-call]. Status lives on [dashboard].

---
**VERIFIED:** [ ] Sanity-checked against a real launch by [Dan] +
[James] on [date]. Wrong steps crossed out here, not prettied.
