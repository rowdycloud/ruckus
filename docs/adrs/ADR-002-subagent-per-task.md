# ADR-002: Subagent-Per-Task Implementation

**Date:** 2026-04
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

The implementation stage of the build pipeline executes a plan consisting of multiple discrete tasks (typically 5-15 tasks per feature). The question is whether the orchestrator should implement all tasks itself within a single context, or dispatch a fresh subagent for each task.

Early versions of the workflow used monolithic implementation — the orchestrator read the plan and executed it file by file in its own context. This worked for small features but degraded on larger ones: by task 8, the orchestrator's context was loaded with conversation history from tasks 1-7, reducing the quality of later implementations and increasing the risk of "context overflow" errors that would abort the entire session.

## Decision

Each task in the plan is dispatched to a fresh implementation subagent. The orchestrator coordinates — it reads the plan, tracks progress via TodoWrite, dispatches subagents, runs two-stage review after each, and handles failures. It does not write code itself.

This pattern is adapted from the Superpowers plugin's "subagent-driven development" approach.

## Reasoning

A fresh subagent per task gets a clean context window containing only: the task description, CLAUDE.md, known-pitfalls.md, and any design skill (if UI work). It doesn't carry the accumulated history of previous tasks, the discovery report, the plan verification findings, or the review results from earlier tasks. This means task 8 gets the same quality of context as task 1.

The orchestrator's context does grow across tasks (it accumulates subagent result summaries), but it's carrying coordination data, not implementation detail. The ratio of useful context to noise stays healthy.

## Alternatives Considered

**Monolithic implementation (orchestrator does everything).** Simpler, fewer subagent dispatches, lower total token cost. But context quality degrades predictably on plans with more than 5-6 tasks, and a single context overflow error loses all progress.

**Batched implementation (subagent per 3-4 tasks).** A middle ground — fewer dispatches than per-task, more context isolation than monolithic. Rejected because task dependencies within a batch create ordering complexity, and a failure in task 2 of a batch requires re-dispatching the entire batch.

**Parallel subagents (multiple tasks simultaneously).** Dispatching independent tasks in parallel for speed. Not adopted in v0.1.0 because task independence is hard to guarantee — even "independent" tasks often touch shared types or imports. Candidate for future versions with explicit dependency analysis.

## Consequences

### Positive
- Implementation quality is consistent across all tasks regardless of plan size
- A subagent failure on task N doesn't lose progress on tasks 1 through N-1
- The orchestrator's context stays lean enough to reach Stage 8 (wrap-up) without compaction issues
- Each subagent can be routed to the appropriate model (Sonnet for most, potentially Haiku for simple tasks)

### Negative
- Higher total token cost than monolithic — each subagent re-reads CLAUDE.md and known-pitfalls.md
- More elapsed time — subagent startup adds ~2-3 seconds per task
- The two-stage review after each task adds further token and time cost
- Plan quality matters more — a vague task description that a human orchestrator could interpret becomes a failed subagent dispatch

### Neutral
- Plans must be written at task-level granularity (2-5 minutes per task) for this pattern to work. This is a constraint on the planning stage, not the implementation stage.
