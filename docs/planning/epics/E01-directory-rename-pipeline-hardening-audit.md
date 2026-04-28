# Epic Audit: E01 — Directory Rename + Pipeline Hardening

**Date:** 2026-04-28
**Stories audited:** 8
**Acceptance criteria:** 45 — 42 MET, 3 PARTIAL, 0 NOT MET

## Summary

E01 is substantively complete. All 8 stories have been implemented and merged to main. 42 of 45 acceptance criteria are fully met. The 3 PARTIALLY MET items are all cosmetic — two are false positives from intentional legacy-path references in migration code (S1 AC1 and AC2), the other is a minor formatting variance in an inline definition (S8 AC6). No behavioral gaps, regressions, or unmet functional requirements were found. The epic's exit criteria are met: plugin.json is at v0.1.2, tag v0.1.2 is pushed, CHANGELOG is comprehensive, line budgets are within limits (build: 294, fix: 299), and cross-references are valid.

## Per-Story Results

### S1: Rename `docs/claude/` to `.ruckus/` — 10 MET, 2 PARTIAL

| AC | Status | Notes |
|----|--------|-------|
| Zero `docs/claude/` references in agents/, skills/, CLAUDE.md, README.md, templates/ | PARTIALLY MET | grep returns 6 matches — all in upgrade/SKILL.md and setup/SKILL.md as intentional legacy-detection/migration logic, not stale references |
| Verification grep returns zero matches | PARTIALLY MET | Same as above — grep returns non-zero due to intentional migration-logic references |
| `.ruckus/known-pitfalls.md` path in all agents and skills | MET | |
| `.ruckus/workflow-upgrades` path in build, fix, setup, upgrade | MET | |
| Root `CLAUDE.md` is sole copy | MET | |
| Setup creates `.ruckus/` directory | MET | |
| Setup writes root `CLAUDE.md` directly | MET | |
| Upgrade has migration step detecting `docs/claude/` | MET | |
| Upgrade mapping table points to root CLAUDE.md and `.ruckus/` | MET | |
| ADR-005 and ADR-006 have footnotes | MET | |
| README structure tree shows `.ruckus/` | MET | |
| CLAUDE.md structure table shows `.ruckus/` | MET | |

**Quality note:** The AC1/AC2 PARTIAL is an AC wording gap, not an implementation bug. The migration code correctly references `docs/claude/` to detect and move legacy installations — it would be a bug if those references were removed.

### S2: Pipeline loop caps — 4 MET

| AC | Status | Notes |
|----|--------|-------|
| Stage 4 says "2 total" not "2 consecutive" | MET | build:100, fix:109 |
| Stage 5c has 2-attempt cap with human escalation | MET | build:170, fix:179 |
| Stage 6 review-fix loop has 2-cycle cap | MET | build:197, fix:202 |
| Stage 6 gate is unambiguous | MET | "list warnings to address [then re-review once]" |

### S3: Compaction preserve lists and re-validation — 4 MET

| AC | Status | Notes |
|----|--------|-------|
| Stage 5 re-validates plan file path after compaction | MET | build:116, fix:125 |
| Stage 5d preserve list includes "task ID list" | MET | build:187, fix:194 |
| Compaction between Stage 7 and Stage 8 | MET | build:212-213, fix:218-219 |
| Post-Stage 7 compaction preserves required fields | MET | |

### S4: Error handling disambiguation — 6 MET

| AC | Status | Notes |
|----|--------|-------|
| Quality check distinguishes task-owned from external failures | MET | |
| Auto-fix capped at 2 attempts | MET | |
| Review-plan returns NEEDS REVISION when CLAUDE.md missing | MET | review-plan:19 |
| Review-plan notes missing known-pitfalls.md as informational | MET | |
| Spec-reviewer reference verified clean | MET | Zero matches in skills/ |
| fix/SKILL.md at or under 300 lines | MET | 299 lines |

### S5: Agent preamble drift documentation and detection — 4 MET

| AC | Status | Notes |
|----|--------|-------|
| agent-preamble.md explains WHY exceptions differ | MET | Lines 9-13 |
| implementer-prompt.md has sync comment | MET | Line 20 |
| Upgrade STEP 1 checks for preamble drift | MET | Line 41 |
| Drift check excludes exception agents | MET | "excluding exceptions: static-analysis, doc-writer" |

### S6: Audit-epic token budget batching — 4 MET

| AC | Status | Notes |
|----|--------|-------|
| 10+ stories batch in groups of 5 | MET | SKILL.md:58-62 |
| Intermediate batch summaries with compaction | MET | SKILL.md:61-63 |
| <10 stories dispatch in parallel (unchanged) | MET | SKILL.md:56 |
| Cross-cutting receives batch summaries | MET | SKILL.md:97, 103 |

### S7: Setup and upgrade hardening — 5 MET

| AC | Status | Notes |
|----|--------|-------|
| Setup gate prevents Step 4 until fields validated | MET | setup:69 |
| Enrich mode defines "gap" precisely | MET | setup:45 |
| Format row removed when no formatter | MET | setup:94, 98 |
| Upgrade preserves user-added hooks | MET | upgrade:89 |
| No behavior change for users providing all fields | MET | Gate passes through on substantive answers |

### S8: Documentation accuracy — 5 MET, 1 PARTIAL

| AC | Status | Notes |
|----|--------|-------|
| Token usage table notes compaction savings | MET | README:234-235 |
| Review vs review-plan explained | MET | README:119 |
| Context management troubleshooting entry | MET | README:245-251 |
| fix/SKILL.md says "Offers to create" | MET | fix/SKILL.md:3 |
| Quick Start uses `.ruckus/` paths | MET | README:28-29 |
| "maturity" has inline definition | PARTIALLY MET | Definition present but uses slash-separated format ("greenfield/scaffolded/established") instead of the AC's comma-separated em-dash format |

## Exit Criteria

| Criterion | Status | Evidence |
|-----------|--------|----------|
| All 8 stories complete | MET | All 8 have merge commits on main |
| CLAUDE.md updated for `.ruckus/` | MET | Structure table row present |
| README.md updated | MET | Paths, corrections, troubleshooting all present |
| CHANGELOG.md updated | MET | Comprehensive v0.1.2 entry with all 8 stories |
| Cross-references valid | MET | No dangling references found |
| plugin.json version 0.1.2 | MET | Confirmed |
| fix/SKILL.md ≤ 300 lines | MET | 299 lines |
| build/SKILL.md ≤ 300 lines | MET | 294 lines |
| Zero `docs/claude/` in active files | MET | Only migration-logic references remain (intentional) |
| Tag v0.1.2 pushed | MET | Tag exists |

## Cross-Cutting Findings

1. **Consistency — build/fix symmetry is strong.** S2, S3, and S4 all modified both build/SKILL.md and fix/SKILL.md with identical patterns. The subagent audits confirmed consistent wording across both files with appropriate context-specific variations (e.g., fix uses "issue summary with root cause" where build uses "feature summary").

2. **Integration — dependency ordering was respected.** S1 (path rename) was implemented first. S5 and S7, which depend on renamed paths, correctly reference `.ruckus/`. The upgrade migration step (S1) and the setup legacy-detection (S7) work together — setup detects `docs/claude/` and directs users to `/ruckus:upgrade`.

3. **No gaps found.** Every AC across all 8 stories has an implementing commit. The three PARTIAL items are cosmetic, not functional.

4. **No regressions detected.** S2-S4's pipeline changes are additive caps and disambiguation — no existing behavior paths were removed. S7's setup gate only triggers on missing/placeholder values, leaving normal flow intact.

5. **Epic doc status tracking is stale.** S5-S8 acceptance criteria boxes are unchecked in the epic file despite all being implemented and merged. S5-S8 status headers are missing the "✅" marker and merge date that S1-S4 have.

## Recommendations

1. **Low priority — Update epic doc status.** Mark S5-S8 as complete in the epic file with merge dates and check all AC boxes. This is housekeeping only.

2. **No action needed — S1 AC1/AC2 grep result.** The `docs/claude/` references in upgrade/setup migration logic are correct behavior. Consider adding an AC exception note in the epic doc for future reference.

3. **No action needed — S8 AC6 formatting.** The slash-separated maturity definition is functionally equivalent to the comma-separated AC spec. Not worth a code change.
