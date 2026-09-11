# ANSWERS — the five questions

The five that come up over and over. Written once, from the hundred
times they've been answered. If something here is wrong, cross it out
and fix it — this file survives because it gets used, not because it
gets filed.

---

**1. "How do I even install this on Windows?"**

Yes, it's in the README. The short version, three steps:
1. [step 1 — the install command]
2. [step 2 — the setup step]
3. [step 3 — the verify step]

If one of these fails, say *which step* failed — that's the fastest
way to actually get help, and you WILL get helped.

---

**2. "Does this work with the current Python?"**

Tested against [versions]. The dependency that usually matters is
[dep name]. If you're on a version outside the tested list, the
one-line check is: [compat check]. That's the whole compat story —
no trailing "it depends."

---

**3. "Can it do X?"**

Probably — and it's in the docs, just under [section], or via the
[flag] flag that isn't obvious. Before asking, one search of this
project's docs for X: if it's there, you found it in the time it
would've taken to write the question. If it's genuinely not there,
ask — and you're likely suggesting a feature, which is a gift.

---

**4. "Why is it slow on my big file?"**

It's not slow — it's O(n), and your file is huge. The two-line
recipe: [chunking recipe]. That fixes the real case. (The old answer
was just shrugging and saying O(n); the new answer gives you the
recipe — use the new one, it's the one that helps.)

---

**5. "Is this project dead?" / "Can I use this commercially?"**

The twin questions. The honest answers, once:
- Last commit: [date]. The repo has [X] commits in the last [N]
  months.
- License: [license name] — read [license file]. That file is the
  commercial answer. If it says what it says and that works for you,
  it works; if it doesn't, it doesn't — but it's a one-file read,
  not a judgment call.

Dead means the date above got old. Check the date; that's the answer.

---

**The rule:** these five get asked forever. The answers now live in
one place. When one gets asked again, the answer is "line [N] of
ANSWERS.md" — and the file stays true because it keeps getting
opened.
