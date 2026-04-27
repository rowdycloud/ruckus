# Fix Plan: E01.S7 — Setup and Upgrade Hardening

## Root Cause

Four behavioral gaps in `setup/SKILL.md` and `upgrade/SKILL.md` where instructions are either missing or too vague for an LLM orchestrator to enforce reliably. The setup skill lacks an explicit gate between required-field collection and optional-field collection, defines "enrich mode gaps" ambiguously, buries the formatter row removal instruction, and the upgrade skill doesn't mention hook preservation during settings.json merges.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `skills/setup/SKILL.md` | Modify | T1, T2, T3 |
| `skills/upgrade/SKILL.md` | Modify | T4 |
| `docs/plans/fix-E01-S7-setup-upgrade-hardening-plan.md` | Create | T0 (this file) |

## Tasks

### T1: Add required-field enforcement gate (~2 min)
**Files:** `skills/setup/SKILL.md`
**Action:** Insert an explicit gate between Step 3 and Step 4 (after line 68, before the `---` separator at line 69)
**Details:** Add the following block after the last question in Step 3 (line 68) and before the `---` separator at line 69:

```markdown

**Gate:** Confirm all 6 required fields have non-empty, non-placeholder values. If any field is missing or contains only "TBD", "TODO", "skip", or similar placeholders, loop back to that specific question. Do not proceed to Step 4 until all 6 fields have substantive answers.
```

**Verify:** Read `skills/setup/SKILL.md` and confirm the gate text exists between Step 3's last question and the `---` before Step 4.
**UI:** no

### T2: Define enrich mode gaps (~2 min)
**Files:** `skills/setup/SKILL.md`
**Action:** Replace the vague enrich mode instruction on line 45
**Details:** Replace:
```
If enriching, read existing files and identify gaps to fill.
```
With:
```
If enriching, read existing files and identify gaps: any of the 6 required fields (Step 3) that are missing, empty, or contain placeholder text ("TBD", "TODO", "None", template markers like `{{...}}`). Only prompt for gap fields — preserve all existing non-gap content.
```

**Verify:** Read `skills/setup/SKILL.md` line 45 and confirm the new text is present with the specific gap definition.
**UI:** no

### T3: Add explicit formatter row removal instruction (~2 min)
**Files:** `skills/setup/SKILL.md`
**Action:** Add an explicit instruction after the placeholder replacement list in Step 5a (after line 94)
**Details:** After line 94 (the last `{{PLACEHOLDER}}` replacement bullet), add:

```markdown

**If no formatter was provided:** Remove the entire `| Format | ... |` row from the Commands table. Do not leave a row with an empty command.
```

**Verify:** Read `skills/setup/SKILL.md` and confirm the formatter removal instruction exists as a standalone bold instruction after the placeholder list.
**UI:** no

### T4: Add upgrade hook preservation instruction (~2 min)
**Files:** `skills/upgrade/SKILL.md`
**Action:** Add hook preservation instruction to Step 4 (after line 87, the "Verify the merged file is valid" line)
**Details:** After the numbered merge steps (line 87: "3. Verify the merged file is valid"), add:

```markdown

**For settings.json:** Preserve all existing hook entries. Only add or update hooks defined in the plugin template. Never remove or overwrite user-added hooks — they may be from other plugins or custom workflows.
```

**Verify:** Read `skills/upgrade/SKILL.md` Step 4 and confirm the hook preservation instruction is present after the merge steps.
**UI:** no

## Blast Radius
- Do NOT modify: any file outside `skills/setup/SKILL.md` and `skills/upgrade/SKILL.md` (and this plan file)
- Watch for: line count limits — setup/SKILL.md is currently 169 lines (limit 300), upgrade/SKILL.md is currently 124 lines (limit 300). All additions are small (2-3 lines each), well within budget.

## Verification
1. Read both modified files end-to-end and confirm each change matches the epic spec's target behavior
2. Confirm line counts remain under the 300-line skill body limit
3. Verify no existing behavior changed for users who provide all required fields (all changes are additive gates/instructions)
4. Run `cubic review --json` on uncommitted changes
