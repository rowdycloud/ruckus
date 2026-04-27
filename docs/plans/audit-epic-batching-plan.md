# Implementation Plan: E01.S6 — Audit-epic Token Budget Batching

## Context

For epics with 10+ stories, the audit-epic skill dispatches all per-story review subagents in parallel. Each report is 3-5K tokens — a 12-story epic accumulates 36-60K tokens before cross-cutting analysis begins, risking context pressure and quality degradation. This change adds conditional batching: groups of 5 for large epics, preserving current parallel behavior for smaller ones.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `skills/audit-epic/SKILL.md` | Modify | T1, T2 |
| `docs/plans/audit-epic-batching-plan.md` | Create | T0 |

## Tasks

### T0: Save plan file (~1 min)
**Files:** `docs/plans/audit-epic-batching-plan.md`
**Action:** Copy this plan to the project's plan directory
**Details:** Save this plan to `docs/plans/audit-epic-batching-plan.md` for pipeline traceability.
**Verify:** File exists at path
**UI:** no

### T1: Add conditional batching to STEP 3 dispatch (~3 min)
**Files:** `skills/audit-epic/SKILL.md`
**Action:** Replace the single dispatch instruction (line 56) with a conditional that batches for 10+ stories
**Details:**
Replace line 56:
```
Dispatch review subagents in parallel (one per story, model: `sonnet`). Each receives:
```
With:
```
**If fewer than 10 stories:** Dispatch review subagents in parallel (one per story, model: `sonnet`). Each receives the prompt below.

**If 10 or more stories:** Batch per-story reviews in groups of 5:
1. Dispatch the first batch (up to 5 stories) in parallel, model: `sonnet`. Each receives the prompt below.
2. When the batch returns, summarize findings: key themes, critical issues (PARTIALLY MET / NOT MET items), affected story IDs.
3. Compact context. Preserve: epic title, full story ID list, batch summary (themes + critical issues + affected stories), remaining story list.
4. Dispatch the next batch. Repeat until all stories are reviewed.

Each subagent receives:
```

The subagent prompt template (lines 59-85) remains unchanged.

**Verify:** Line count stays under 300. Read the file and confirm the conditional is well-formed.
**UI:** no

### T2: Update STEP 3 compaction and STEP 4 consumption for batch summaries (~3 min)
**Files:** `skills/audit-epic/SKILL.md`
**Action:** Update the post-STEP-3 compaction (line 87) and STEP 4 intro (line 93) to handle both paths
**Details:**
Replace line 87 (current compaction directive):
```
Compact context after all per-story subagents return. Preserve: epic title, story ID list, per-story AC status table (MET/PARTIALLY MET/NOT MET per AC), quality flags and missing coverage notes. Full evidence citations and file:line references from subagent reports are NOT needed for cross-cutting analysis — the status verdicts carry the signal.
```
With:
```
**After all stories are reviewed** (whether via single parallel dispatch or batched):

Compact context. Preserve: epic title, story ID list, per-story AC status table (MET/PARTIALLY MET/NOT MET per AC), quality flags, missing coverage notes. For batched epics, also preserve the batch summaries (themes and critical issues). Full evidence citations and file:line references are NOT needed for cross-cutting analysis — status verdicts and batch summaries carry the signal.
```

Update STEP 4 intro (line 93) from:
```
After all per-story reviews return, perform a cross-cutting analysis:
```
To:
```
After all per-story reviews complete (and context is compacted), perform a cross-cutting analysis using the AC status table and any batch summaries:
```

**Verify:** Read STEP 4 to confirm it references batch summaries. Total line count under 300.
**UI:** no

## Blast Radius
- Do NOT modify: any file outside `skills/audit-epic/SKILL.md` and `docs/plans/audit-epic-batching-plan.md`
- Watch for: line count creep (spec targets ~141, cap is 300)

## Conventions
- ADR-002: Subagent-per-task pattern — batching is orchestration, not a change to the per-task model
- ADR-008: Sonnet for all non-epic-reviewer agents — unchanged
- Compaction pattern: `"Compact context. Preserve: [explicit list]."` — matches build/fix skills
- Conditionals use bold-text branching (`**If X:**`) consistent with existing skill formatting

## Verification
1. Read `skills/audit-epic/SKILL.md` after changes — confirm line count is ~141-145 (under 300)
2. Confirm the conditional branches are clear and unambiguous
3. Confirm STEP 4 references batch summaries for 10+ story path
4. Run `cubic review --json` on uncommitted changes — address any findings
