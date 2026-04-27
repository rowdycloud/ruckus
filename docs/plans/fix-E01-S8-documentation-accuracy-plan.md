# Fix Plan: E01.S8 — Documentation Accuracy

## Root Cause

Six documentation inaccuracies were identified in the E01 epic audit. Three are already resolved (Change 3 covered by existing troubleshooting entry, Change 5 completed by S1, Change 6 already present). Three remain: missing compaction note in token table, missing review vs review-plan callout, and misleading "Self-upgrades" wording in two files.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `README.md` | Modify | T1, T2, T3 |
| `skills/fix/SKILL.md` | Modify | T3 |

## Tasks

### T1: Add compaction savings note to token usage table (~2 min)
**Files:** `README.md`
**Action:** Add compaction note to build and fix rows in the Token Usage table
**Details:**
- Line 232: Change `build` notes from `Scales with task count (~8-12K per task)` to `Scales with task count (~8-12K per task). Includes 3 compaction points that reduce peak context.`
- Line 233: Change `fix` notes from `Usually fewer tasks than build` to `Usually fewer tasks than build. Includes 3 compaction points that reduce peak context.`
**Verify:** Read lines 229-239 of README.md and confirm both rows mention compaction
**UI:** no

### T2: Add review vs review-plan relationship callout (~2 min)
**Files:** `README.md`
**Action:** Add a blockquote callout after the Skills Reference table explaining the distinction
**Details:**
- After line 117 (end of Skills Reference table, before the `## Pipeline: /ruckus:build` heading at line 119), insert:
```
> **review vs review-plan:** `review-plan` verifies the implementation plan against the codebase *before* implementation starts (dispatched as a blocking subagent by build/fix Stage 4). `review` evaluates the implemented code *after* implementation completes (Stage 6).
```
- Add a blank line before and after the blockquote
**Verify:** Read the Skills Reference section and confirm the callout is present between the table and the Pipeline heading
**UI:** no

### T3: Fix "Self-upgrades" wording in fix/SKILL.md and README.md (~2 min)
**Files:** `skills/fix/SKILL.md`, `README.md`
**Action:** Change "Self-upgrades" to "Offers to create" in both files
**Details:**
- `skills/fix/SKILL.md` line 3: Change `Self-upgrades investigator agent when project reaches 50+ files.` to `Offers to create investigator agent when project reaches 50+ files.`
- `README.md` line 146: Change `- Self-upgrades: offers to create investigator agent when project reaches 50+ files` to `- Offers to create investigator agent when project reaches 50+ files`
**Verify:** `grep -n "Self-upgrades" README.md skills/fix/SKILL.md` should return no results
**UI:** no

## Blast Radius
- Do NOT modify: any skill files other than `skills/fix/SKILL.md`, any agent files, any ADR files
- Watch for: line number shifts in README.md after T2 insertion — T1 and T3 reference pre-insertion line numbers, so execute T2 last or adjust accordingly
- Changes 3, 5, 6 from the epic spec are confirmed already addressed — do not duplicate them

## Execution Order
T1 → T3 → T2 (T2 inserts lines, which would shift T1/T3 line numbers if done first)
