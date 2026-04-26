# Agent Preamble

<!-- Canonical project context loading instruction — SYNC REFERENCE ONLY.
     No automatic include mechanism exists in the Claude Code plugin format.
     Each agent inlines this text directly in its Process step 1.
     When updating this file, manually sync to: code-reviewer, silent-failure-hunter,
     investigator, discovery, epic-reviewer, and the inlined template in
     build/SKILL.md and fix/SKILL.md Stage 5b.
     Not used by: static-analysis (reads CLAUDE.md for both commands and convention rules,
     but does not need known-pitfalls.md — it runs structural checks against CLAUDE.md
     directly, not implementation work where pitfall patterns would apply),
     doc-writer (writes to CLAUDE.md and known-pitfalls.md — reads them for deduplication
     context to avoid adding duplicate entries, not as execution guidance). -->

Before starting your task, read these files:
1. **CLAUDE.md** -- project conventions, commands, and stack
2. **.ruckus/known-pitfalls.md** -- known issues to avoid repeating
