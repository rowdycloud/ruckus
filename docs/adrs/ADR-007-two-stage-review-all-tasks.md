# ADR-007: Two-Stage Review Kept for All Tasks

**Date:** 2026-04
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

After each implementation subagent completes a task, the orchestrator runs a two-stage review: (1) spec compliance — did the subagent do what the task described? and (2) code quality — does the type check pass? A plugin review suggested that this has diminishing returns after the first few tasks and recommended batching or dropping the spec compliance stage for later tasks.

This was resolved through a structured debate that examined the actual token cost and failure patterns.

## Decision

Full two-stage review runs after every task, regardless of task position in the plan. No batching, no dropping after task N.

## Reasoning

The review's estimated token cost was based on an incorrect assumption that spec compliance was a subagent dispatch. In the actual implementation, spec compliance is an inline orchestrator evaluation — a 4-item checklist the orchestrator checks against the subagent's return summary. This costs ~100-200 tokens per task, not the 2-3K tokens estimated.

At ~100-200 tokens per task × 8 tasks = 800-1600 tokens total, the cost of full per-task review is negligible. The value is not: file scope violations become *more* likely on later tasks (task 7 touches files already modified by tasks 1-5), and a type error in task 4 that goes unreviewed until task 8 means tasks 5-7 built on broken foundations.

A proposed "high-risk task flag" mechanism (only review flagged tasks) was rejected because agents would game it — marking everything as low-risk to avoid the review overhead.

## Alternatives Considered

**Batch review every 3 tasks.** Review tasks 1-3 as a group, then 4-6, then 7+. Lower dispatch overhead. Rejected because a failure in task 4 wouldn't be caught until after task 6, and the cost savings are minimal given inline execution.

**Drop spec review after task 3.** Keep type check (always cheap), drop the spec compliance checklist for tasks 4+. Rejected because later tasks are where scope violations are most likely — the codebase is changing under the plan's feet.

## Consequences

### Positive
- Consistent quality assurance across all tasks
- Cascading failures caught immediately rather than compounding
- Token cost is negligible (~100-200 per task inline)

### Negative
- None material — the cost argument was the only argument against, and it was based on a wrong estimate

### Neutral
- If a future refactor changes spec compliance from inline to subagent dispatch, this decision should be revisited — the cost calculation would change significantly
