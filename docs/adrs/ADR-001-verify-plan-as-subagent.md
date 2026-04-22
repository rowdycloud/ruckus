# ADR-001: Verify-Plan Dispatched as Subagent

**Date:** 2026-04
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

The build and fix pipelines include a plan verification stage that challenges the implementation plan against the actual codebase before any code is written. Early versions invoked verify-plan as a Skill tool call from the orchestrator. In practice, agents frequently skipped this step — they'd interpret the plan as "good enough" and proceed directly to implementation, bypassing the verification entirely.

This was observed across multiple projects: the verify-plan stage was the most-skipped gate in the pipeline, despite being the gate most likely to catch structural problems before they became expensive implementation failures.

## Decision

Verify-plan is dispatched as a blocking subagent, not invoked as a Skill tool call. The orchestrator dispatches the subagent and waits for its return. It cannot proceed to implementation until the subagent returns a structured verdict (PASS or NEEDS REVISION).

## Reasoning

When a skill is invoked via the Skill tool, the orchestrating agent retains discretion over whether to actually call it. The LLM can decide the plan "looks fine" and skip the invocation — there's no mechanical enforcement. By contrast, a subagent dispatch is a blocking operation: the orchestrator sends a message and waits for a response. The orchestrator cannot "decide" to skip it because it's waiting on I/O, not making a judgment call.

This is the same principle as making a network call vs. checking a local cache — the network call forces the round trip, the cache check is optional by nature.

## Alternatives Considered

**Skill tool invocation with stronger prompt language.** Adding "MANDATORY" and "DO NOT SKIP" markers to the skill invocation. This improved compliance but didn't eliminate skipping — agents under context pressure would still occasionally skip, especially in longer sessions.

**Hook-based enforcement.** Using a PreToolUse or Stop hook to block implementation unless verify-plan had been called. This would work mechanistically but adds brittle coupling between the hook system and the pipeline's internal stage tracking.

## Consequences

### Positive
- Verify-plan cannot be skipped — the mechanical structure prevents it
- The orchestrator's context stays clean — verification runs in an isolated context window
- The pattern is self-documenting: a subagent dispatch in the skill file is visibly a blocking operation

### Negative
- Subagent dispatch has startup overhead (~2-3 seconds) compared to inline skill invocation
- The verify-plan subagent needs to re-read files the orchestrator has already read (CLAUDE.md, the plan file), adding some token redundancy
- Contributors may try to "optimize" this back to a skill invocation for speed — this ADR exists to explain why that's wrong

### Neutral
- The same pattern (subagent dispatch for critical gates) could be extended to other stages if skipping becomes a problem elsewhere
