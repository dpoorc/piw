---
id: 7
title: 'Prototype: Initialization module design'
status: open
priority: medium
labels:
    - wayfinder:prototype
    - docs
created: "2026-08-08"
updated: "2026-08-14"
---

## Question

Design the initialization module for the `documentation` skill. This is the entry point — what happens when someone (human or agent) runs the skill for the first time in a project. It should be conversation-based, similar in spirit to Matt's setup skill. Questions to resolve: What is the conversation flow for green-field (no existing docs) vs brown-field (existing docs with history)? What artifact(s) does initialization produce? What goes in the docs/meta directory/file? What format (YAML, Markdown with frontmatter)? What schema does it follow? How does the meta-component discovery happen during init (scanning for other conventions, skills, existing doc patterns)? How does init handle project scale detection?
