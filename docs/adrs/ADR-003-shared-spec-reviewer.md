# ADR-003: Shared Spec-Reviewer Across Build and Fix

**Date:** 2026-04
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

After each implementation subagent completes a task, the orchestrator runs a two-stage review: spec compliance ("did the task do what it said?") then code quality ("does it pass type check?"). The question arose whether the fix pipeline needs a different spec-reviewer-prompt than the build pipeline, since fix tasks have different concerns (regression testing, root cause correctness).

This was raised as a critical finding during the plugin review and resolved through a structured debate.

## Decision

A single `spec-reviewer-prompt.md` is shared between build and fix pipelines. Fix-specific criteria belong in the plan's task descriptions, not in the review prompt.

## Reasoning

The spec-reviewer asks four task-agnostic questions: (1) did the subagent modify only the listed files? (2) did the verification command pass? (3) does the implementation match the task description? (4) were there blocking questions? These questions are identical regardless of whether the task is "create a component" or "fix the elevation calculation."

Fix-specific concerns — regression testing, root cause validation, rollback safety — are encoded in the plan's task descriptions. When the spec-reviewer checks "does the implementation match the task description?" for a task that says "add regression test for the elevation bug," it's already enforcing fix-specific behavior through the plan content, not the review prompt.

A concrete test was applied during the debate: construct an example of something the shared prompt would miss on a fix task that it catches on a build task. No such example could be constructed — because the prompt is spec-agnostic by design.

## Alternatives Considered

**Separate `skills/fix/spec-reviewer-prompt.md`.** Would allow fix-specific review criteria (e.g., "verify regression test exists"). Rejected because this duplicates the prompt (two files to maintain), and the fix-specific criteria are better expressed in the plan where they're contextual rather than generic.

## Consequences

### Positive
- One file to maintain instead of two
- Review criteria stay focused on the universal question ("did the task match its spec?")
- Fix-specific rigor is enforced at the planning stage, where it's most effective

### Negative
- Contributors may perceive the shared prompt as a gap and submit PRs to fork it — this ADR explains why it's intentional

### Neutral
- A comment in the prompt file documents the sharing decision for discoverability
