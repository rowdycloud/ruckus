# Fix Plan: E01 Audit Findings + Upgrade Agent Installation Bug

## Root Cause

The upgrade skill's STEP 1 (line 39) unconditionally inventories plugin `agents/` files against `.claude/agents/`, causing STEP 2 to classify all 7 agents as "New" when no `.claude/agents/` directory exists. STEP 5 then offers to install them. This is incorrect — agents ship with the plugin and are invoked via `subagent_type` (e.g., `ruckus:code-reviewer`). They should never be copied to projects. Separately, the E01 epic doc has stale status tracking for S5-S8.

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `skills/upgrade/SKILL.md` | Modify | T1 |
| `docs/planning/epics/E01-directory-rename-pipeline-hardening.md` | Modify | T2 |

## Tasks

### T1: Fix upgrade agent inventory to skip installation offers (~3 min)
**Files:** `skills/upgrade/SKILL.md`
**Action:** Rewrite line 39 to explicitly prevent agent files from being inventoried for installation
**Details:**

Current text at line 39:
```
Also check for agent files in `.claude/agents/` that may need updates against plugin `agents/` directory.
```

Replace with:
```
**Agent files are plugin-shipped** — they are loaded via `subagent_type` (e.g., `ruckus:code-reviewer`) directly from the plugin cache. Do NOT inventory plugin `agents/` for installation to `.claude/agents/` — never classify agent files as "New" in STEP 2 and never offer to create them in STEP 5.
```

This ensures:
- Agents are never classified as "New" in STEP 2 or offered for installation in STEP 5
- The preamble drift check on line 41 continues to handle `.claude/agents/` drift detection independently for projects that have pre-existing agent files
- No duplication of `.claude/agents/` handling between line 39 and line 41

**Verify:** `grep -c "Do NOT inventory" skills/upgrade/SKILL.md` returns 1; `wc -l skills/upgrade/SKILL.md` reports ≤130 lines
**UI:** no

### T2: Update E01 epic doc status for S5-S8 (~3 min)
**Files:** `docs/planning/epics/E01-directory-rename-pipeline-hardening.md`
**Action:** Mark S5-S8 as merged with dates and check all AC boxes
**Details:**

Update these 4 story headers:

1. Line 332 — S5: Add `✅` marker
   `### S5: Agent preamble drift documentation and detection` →
   `### S5: Agent preamble drift documentation and detection ✅`
   Add below: `**Status:** Merged (2026-04-27)`

2. Line 396 — S6: Add `✅` marker
   `### S6: Audit-epic token budget batching` →
   `### S6: Audit-epic token budget batching ✅`
   Add below: `**Status:** Merged (2026-04-27)`

3. Line 435 — S7: Add `✅` marker
   `### S7: Setup and upgrade hardening` →
   `### S7: Setup and upgrade hardening ✅`
   Add below: `**Status:** Merged (2026-04-27)`

4. Line 500 — S8: Add `✅` marker
   `### S8: Documentation accuracy` →
   `### S8: Documentation accuracy ✅`
   Add below: `**Status:** Merged (2026-04-27)`

Check all AC boxes for S5 (lines 389-392), S6 (lines 428-431), S7 (lines 492-496), S8 (lines 561-566): change `- [ ]` to `- [x]`.

Do NOT check exit criteria boxes (lines 572-581) — those were verified by the E01 audit report (`E01-directory-rename-pipeline-hardening-audit.md`), not by this plan. Leave them for a separate housekeeping pass or manual confirmation.

**Verify:** `grep -c "\- \[ \]" docs/planning/epics/E01-directory-rename-pipeline-hardening.md` returns 10 (only exit criteria remain unchecked; all story ACs are checked)
**UI:** no

## Blast Radius
- Do NOT modify: any skill files other than `skills/upgrade/SKILL.md`, any agent files, README.md, CHANGELOG.md
- Watch for: line 41 (preamble drift check) depends on line 39's agent inventory — ensure the drift check still works for projects that DO have `.claude/agents/`
