# Known Pitfalls

Project: Ruckus
Domain: Ruckus is a Claude Code plugin that implements gated development pipelines with subagent-per-task execution.

Pitfalls discovered through development. Updated by `/ruckus:build` and `/ruckus:fix` wrap-up stages.

---

## Domain-Specific

- **Agent files are plugin-shipped, not project-installed.** All 7 agents are loaded via `subagent_type` (e.g., `ruckus:code-reviewer`) from the plugin cache. The upgrade skill must never classify agent files as "New" or offer to copy them to `.claude/agents/`. The only valid agent-related check during upgrade is preamble drift on pre-existing `.claude/agents/` files.

- **Plan mode (Claude Code's built-in) hijacks the build/fix pipeline.** When `/roughly:build` or `/roughly:fix` runs with plan mode active, plan-mode's workflow (Phase 1–5 → ExitPlanMode) substitutes for the build skill's Stages 1–4. The build skill's preamble warns about this, but it can still happen via auto-engagement at SessionStart. Most common silent failure: Stage 4 (`/roughly:review-plan` dispatch) gets skipped because plan-mode's generic `Plan` subagent looks like it fulfills the design-review step — it does NOT. The `Plan` agent designs implementations; `/roughly:review-plan` returns a structured PASS/NEEDS REVISION verdict against the codebase. If plan mode is active when invoking a Roughly pipeline, exit plan mode and re-invoke; or explicitly dispatch `/roughly:review-plan` to recover.

## Data & State

- **CLAUDE.md as the source of truth for verify-all commands has two known failure modes.** Teams with mandated CLAUDE.md formats may not permit Roughly's Commands table, and third-party agents (claude-mem and others) that rewrite CLAUDE.md programmatically can clobber it. Session-length compaction is *not* a failure mode — skills explicitly `Read` CLAUDE.md at runtime per ADR-006, so the disk file is authoritative regardless of what was autoloaded. If breakage is reported, the clean fix is an additive `.roughly/commands.md` fallback that skills check first, falling back to CLAUDE.md — strictly additive, no migration. Stay on CLAUDE.md until that happens to avoid a two-source-of-truth mental model.

## Integration

<!-- Pitfalls related to APIs, third-party services, cross-system communication -->

## Build & Deploy

- **Pre-implementation review (review-epic, review-plan) catches design issues but not always execution bugs.** A spec can pass two `/roughly:review-epic` iterations and a `/roughly:review-plan` pass yet still contain logic bugs that only execution-tracing catches in code review. Example: the S2.2 v0.1.4 migration step had "marker write before conflict check" ordering that made the conflict-prompt branch unreachable on first run — pre-implementation reviewers read the steps as a bullet list; only the Stage 6 code-reviewer noticed by tracing execution order. Don't treat spec-faithfulness as a substitute for code review. Stage 6 catches what Stages 2–4 miss.

- **Grep-based ACs are authoritative over a spec's line-enumeration tables.** When an epic specifies "zero `\bRuckus\b` matches in skills/" alongside an enumerated list of lines to edit, the AC is the contract — the line list is a (sometimes incomplete) implementation hint. Plans should reconcile the AC against `rg -n` output during plan-write and add any missing lines to the substitution table. S2.2 had two reconciled gaps: setup/SKILL.md L40 (mixed-content line, caught by plan-reviewer) and L3 frontmatter descriptions (caught at plan-write time). Pattern: trust the regex, not the line number.

## Testing

<!-- Pitfalls related to test reliability, test data, flaky tests -->
