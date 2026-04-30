# ADR-008: Opus Reserved for Epic-Reviewer Only

**Date:** 2026-04
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

Ruckus dispatches multiple subagents across its pipeline — implementation agents, review agents, investigation agents, discovery agents, and the epic-reviewer. Each subagent can be routed to a different model. The question is which agents justify the cost and latency of Opus vs. Sonnet.

## Decision

All agents use Sonnet except the epic-reviewer, which uses Opus. This is specified in each agent's YAML frontmatter (`model: sonnet` or `model: opus`).

## Reasoning

The epic-reviewer is the only agent that must reason across multiple stories simultaneously — understanding that Story 3's migration depends on Story 1's schema, that a pattern introduced in Story 5 contradicts Story 2's approach, that the PRD says one thing but the story spec says another. This cross-story, cross-document reasoning is where Opus measurably outperforms Sonnet.

Every other agent operates on a bounded scope: one task (implementation), one diff (code review), one issue (investigation), one feature (discovery). Sonnet handles bounded, focused analysis well. The cost difference is significant — Opus is roughly 5× Sonnet's price per token — so using it on every subagent dispatch would make the plugin prohibitively expensive for routine development work.

## Alternatives Considered

**Opus for all agents.** Better quality across the board. Rejected because the cost scales linearly with task count — an 8-task build would cost 5× more for marginal quality improvement on focused tasks.

**Opus for investigation and epic-review.** Investigation sometimes requires tracing complex execution paths across multiple files. Considered but rejected because the investigator's file list is explicitly bounded (3-5 files from the issue description), which constrains the reasoning scope enough for Sonnet.

**Haiku for simple implementation tasks.** A future optimization where tasks marked as low-complexity could be routed to Haiku. Not adopted in v0.1.0 because the plan format doesn't yet include a complexity flag, and Sonnet's cost is acceptable for the quality guarantee.

## Consequences

### Positive
- Predictable cost per pipeline run — most token spend is at Sonnet rates
- Epic reviews get the deep cross-story reasoning they need
- Model selection is visible in agent frontmatter, not hidden in orchestrator logic

### Negative
- Investigation quality on complex, multi-file bugs may be lower than Opus would produce
- Contributors may want to add Opus to other agents for "better results" — this ADR explains why the cost trade-off doesn't justify it

### Neutral
- Model assignments can be overridden per-session by the user (`claude --model opus`) if they want Opus for a specific run

> **Note (v0.1.4):** The plugin was renamed from `ruckus` to `roughly`. Slash commands now use the `/roughly:*` namespace; the plugin-installed dotdir is `.roughly/`. Original identifiers above reflect the original naming.
