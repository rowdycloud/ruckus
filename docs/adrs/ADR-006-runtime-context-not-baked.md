# ADR-006: CLAUDE.md as Runtime Context, Not Baked Into Skills

**Date:** 2026-04
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

Ruckus is a plugin that works across any project and any stack. It needs project-specific context (build commands, conventions, stack details, known pitfalls) to produce good results. The question is whether this context should be baked into the skill files during setup (replacing placeholders with project-specific values) or read at runtime from a canonical location.

The predecessor workflow kit baked project-specific values into each command file during setup. This meant updating a build command required editing 4 separate files, and plugin updates couldn't automatically improve skills without re-running setup to re-bake values.

## Decision

Skills read project context from `CLAUDE.md` and `.ruckus/known-pitfalls.md` at runtime. Skills contain instructions like "read CLAUDE.md for the project's build command" rather than hardcoded `npx tsc --noEmit`. The only project-specific file the plugin's setup creates is CLAUDE.md itself (and known-pitfalls.md, .claudeignore, settings.json).

## Reasoning

When CLAUDE.md is the single source of truth for project context, updating a build command is a one-place change. (Setup writes directly to `CLAUDE.md` at the project root where Claude Code auto-loads it; there is no secondary copy.) All skills pick up the new value on their next invocation. Plugin updates (via `/plugin update`) deliver new skill logic without requiring setup to re-run — the skills read the same CLAUDE.md they always did.

This also means CLAUDE.md quality directly determines plugin quality. A weak CLAUDE.md (just "React app") produces weak results from every skill. This is an intentional trade-off: the quality bottleneck is concentrated in one file that setup enforces and that users can iteratively improve, rather than scattered across a dozen skill files that users can't easily inspect.

## Alternatives Considered

**Bake values into skills during setup.** Replace `{{BUILD_CMD}}` with `turbo run typecheck` in every skill file. This was the predecessor approach. Rejected because it creates maintenance burden (N files to update per change), blocks plugin updates from delivering improved skills, and makes it hard to tell which values are project-specific vs. plugin-standard.

**Environment variables.** Store project config in `.env` or shell config. Rejected because skills can't reliably read env vars, and the values aren't self-documenting.

## Consequences

### Positive
- One-place updates for project context
- Plugin updates improve skills without re-running setup
- CLAUDE.md is inspectable, editable, and git-committed — the project's AI context is visible to the whole team
- known-pitfalls.md accumulates over time, making every skill smarter with use

### Negative
- Skills depend on CLAUDE.md being well-structured — a missing field produces a missing capability
- Setup must enforce minimum viable content (stack, build command, type check, test command, convention, domain) to prevent a weak CLAUDE.md from degrading the entire plugin
- Every skill invocation reads CLAUDE.md, adding ~500-1000 tokens of context per run

### Neutral
- The `agent-preamble.md` file provides a canonical reference for agents to read CLAUDE.md and known-pitfalls.md, reducing duplication of the reading instruction across agent prompts

> **Note (v0.1.2):** `docs/claude/` was renamed to `.ruckus/`. Path references above reflect the updated structure.
