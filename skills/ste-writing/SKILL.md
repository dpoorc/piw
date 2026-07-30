---
name: ste-writing
description: >
  Write prose (docs, READMEs, PR descriptions, error messages, release notes,
  comments — never code) in ASD-STE100 Simplified Technical English to remove
  "AI slop". Defaults to STE-flavored mode for general technical prose. Use
  strict mode for procedures, runbooks, and safety text.
---

# STE Writing

Write prose using rules adapted from ASD-STE100 Simplified Technical English.
This applies to documentation, READMEs, pull-request text, error messages,
release notes, and comments. It does not apply to code, identifiers, command
syntax, or Dockerfiles.

Default mode is **STE-flavored** (relaxed dictionary, full sentence/paragraph
discipline). Switch to **strict** for procedures, runbooks, error messages,
and safety-critical text.

## Rules

### WORDS
- Use one name for one thing. Do not call the same item by two different names.
- Use the short common word: **start** (not begin/commence/initiate), **use** (not utilize/leverage), **help** (not facilitate), **make sure** (not ensure), **before** (not prior to), **after** (not subsequent to), **about** (not regarding/concerning), **get** (not obtain/acquire), **show** (not demonstrate), **also** (not additionally/furthermore/moreover), **need** (not require).
- Give each word one meaning. "fall" means to move down, not to decrease.
- No marketing adjectives: seamless, robust, powerful, cutting-edge, effortless, world-class, next-generation, revolutionary, game-changing.
- No AI filler vocabulary: delve, leverage, navigate (metaphorical), realm, landscape, tapestry, seamless, holistic, paradigm, journey,赋能 (just kidding), robust, ecosystem, granular, actionable, deep dive, pivot, scalable (when vague).
- American spelling.

### VERBS
- Active voice. "The parser reads the file", not "the file is read by the parser".
- Use a verb for an action. "analyze the log", not "perform an analysis of the log".
- No stacked auxiliaries. Not "it is important to note that this may help to improve". Write "this improves X".
- No "-ing" main verb where a simple tense works.
- Imperative mood for instructions. "Run the command", not "you should run the command" or "the command should be run".

### SENTENCES
- One instruction per sentence. Max 20 words (instruction), max 25 (descriptive).
- No contractions. Use articles: a, an, the, this, these.
- No semicolons. Write two sentences.

### STRUCTURE
- One topic per paragraph, max six sentences.
- For steps, use a numbered vertical list, one action per item, imperative form.
- Put a condition before its command.
- No preamble or closing remarks. Write only the requested text.

## Modes

| Mode | When | Rules |
|------|------|-------|
| **STE-flavored** (default) | General prose — docs, READMEs, PR descriptions, comments | Apply sentence, paragraph, active-voice, and no-phrasal-verb discipline. Relax the ~900-word dictionary lockdown so the text keeps enough range to read naturally. |
| **strict** | Procedures, runbooks, safety text, error messages | Apply every rule including both length caps and full vocabulary restriction. |

## Self-lint (run before returning text)

1. Any sentence over 20 words (instruction) or 25 words (descriptive)? Split it.
2. Any semicolon? Replace with a period.
3. Any contraction? Expand it.
4. Any passive voice with a known actor? Make it active.
5. Any "-ing" main verb, nominalization ("perform an analysis"), or phrasal verb ("spin up")? Replace with a plain verb.
6. Same thing named two ways? Pick one name and stick with it.
7. Any marketing or AI filler vocabulary? Replace with plain language.
8. Any preamble or meta-commentary ("Let's look at how...", "In this section, we will...")? Delete it — just say what needs saying.

The mechanical rules above are lintable and are what removes slop. Full STE also needs human judgment (the right technical noun, whether a sentence "makes good sense") — a checker cannot certify that, and slop is not about that. This skill fixes the **form** of slop. It cannot make a hollow paragraph true.

Free official standard (do not paste it in full; it is copyrighted): https://asd-ste100.org
