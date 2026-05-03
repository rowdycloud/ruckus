# Architecture Decision Records

ADRs capture the reasoning behind significant design decisions in Roughly. They exist so contributors can understand *why* the code is structured a certain way — not just *how*.

## Numbering

`ADR-NNN-short-slug.md` — sequential, zero-padded to three digits. Never reuse a number; deprecated ADRs keep their number and get a `Deprecated` status.

## Status Vocabulary

- **Accepted** — current and enforced
- **Deprecated** — no longer applies; kept for historical context
- **Superseded by ADR-NNN** — replaced by a newer decision

## What Warrants an ADR

Write an ADR when a decision:
- Changes the pipeline stage structure (number, order, or gating behavior)
- Changes how subagents are dispatched, scoped, or coordinated
- Changes what `disable-model-invocation: true` applies to
- Removes or fundamentally alters a review/verification mechanism
- Would surprise a contributor who read the existing ADRs

Bug fixes, template improvements, documentation changes, and new agent definitions do *not* need ADRs unless they alter the behaviors above.

## Current ADRs

- [ADR-001](ADR-001-verify-plan-as-subagent.md) — Review-plan dispatched as blocking subagent, not skill invocation
- [ADR-002](ADR-002-subagent-per-task.md) — Fresh subagent per implementation task; orchestrator coordinates only
- [ADR-003](ADR-003-shared-spec-reviewer.md) — Spec-reviewer checklist shared between build and fix pipelines
- [ADR-004](ADR-004-ui-conditional-not-forked.md) — UI work detected per-task via flag, not a separate command
- [ADR-005](ADR-005-versioned-maturity-checks.md) — Maturity check IDs are versioned; declined checks re-offered on version bump
- [ADR-006](ADR-006-runtime-context-not-baked.md) — CLAUDE.md read at runtime by agents, not baked into skill text
- [ADR-007](ADR-007-two-stage-review-all-tasks.md) — Two-stage review (spec compliance + quality) runs after every task
- [ADR-008](ADR-008-opus-for-epic-reviewer-only.md) — Opus reserved for epic-reviewer only; all other agents use Sonnet
- [ADR-009](ADR-009-plan-mode-detection.md) — Plan-mode auto-detection via UserPromptSubmit hook + preamble update
