# Implementation Plan: E01.S1 — Rename `docs/claude/` to `.ruckus/`

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `agents/agent-preamble.md` | Edit | T1 |
| `agents/code-reviewer.md` | Edit | T1 |
| `agents/discovery.md` | Edit | T1 |
| `agents/epic-reviewer.md` | Edit | T1 |
| `agents/investigator.md` | Edit | T1 |
| `agents/silent-failure-hunter.md` | Edit | T1 |
| `agents/doc-writer.md` | Edit | T2 |
| `skills/build/implementer-prompt.md` | Edit | T3 |
| `skills/build/SKILL.md` | Edit | T3 |
| `skills/fix/SKILL.md` | Edit | T3 |
| `skills/review/SKILL.md` | Edit | T4 |
| `skills/review-epic/SKILL.md` | Edit | T4 |
| `skills/setup/SKILL.md` | Edit | T5 |
| `skills/setup/templates/CLAUDE.md.template` | Edit | T5 |
| `skills/upgrade/SKILL.md` | Edit | T6 |
| `README.md` | Edit | T7 |
| `CLAUDE.md` | Edit | T7 |
| `docs/adrs/ADR-005-versioned-maturity-checks.md` | Edit | T8 |
| `docs/adrs/ADR-006-runtime-context-not-baked.md` | Edit | T8 |

## Tasks

### T1: Rename paths in 6 preamble-consuming agents (~3 min)
**Files:** `agents/agent-preamble.md`, `agents/code-reviewer.md`, `agents/discovery.md`, `agents/epic-reviewer.md`, `agents/investigator.md`, `agents/silent-failure-hunter.md`
**Action:** Replace `docs/claude/known-pitfalls.md` with `.ruckus/known-pitfalls.md` in all 6 files (preamble reference + 5 agent inlines)
**Details:**
- `agent-preamble.md` line 14: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- `code-reviewer.md` line 18: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- `discovery.md` line 22: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- `epic-reviewer.md` line 18: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- `investigator.md` line 22: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- `silent-failure-hunter.md` line 18: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
Each file has exactly 1 occurrence. Simple string replacement.
**Verify:** `grep -r "docs/claude/" agents/` returns zero matches
**UI:** no

### T2: Update doc-writer agent write targets (~2 min)
**Files:** `agents/doc-writer.md`
**Action:** Update both write target paths — pitfalls and CLAUDE.md
**Details:**
- Line 22: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- Line 23: `docs/claude/CLAUDE.md` → `CLAUDE.md` (root — no subdirectory prefix; doc-writer should write directly to root CLAUDE.md since the secondary copy is eliminated)
**Verify:** `grep "docs/claude/" agents/doc-writer.md` returns zero matches
**UI:** no

### T3: Rename paths in build/fix pipeline skills + implementer prompt (~5 min)
**Files:** `skills/build/SKILL.md`, `skills/fix/SKILL.md`, `skills/build/implementer-prompt.md`
**Action:** Replace all `docs/claude/` references. Handle `.workflow-upgrades` dual rename carefully.
**Details:**
**`skills/build/implementer-prompt.md`** (1 reference):
- Line 20: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`

**`skills/build/SKILL.md`** (6 references):
- Line 142: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- Line 226: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- Line 232: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 249: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 251: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 254: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`

**`skills/fix/SKILL.md`** (7 references):
- Line 40: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 151: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- Line 231: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- Line 237: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 254: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 256: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 259: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`

**CRITICAL:** `.workflow-upgrades` references need a dual rename — both the directory AND the leading dot on the filename. `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades` (NOT `.ruckus/.workflow-upgrades`).
**Verify:** `grep -r "docs/claude/" skills/build/ skills/fix/` returns zero matches
**UI:** no

### T4: Rename paths in review and review-epic skills (~2 min)
**Files:** `skills/review/SKILL.md`, `skills/review-epic/SKILL.md`
**Action:** Replace `docs/claude/known-pitfalls.md` references
**Details:**
**`skills/review/SKILL.md`** (3 references):
- Line 28: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- Line 38: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- Line 71: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`

**`skills/review-epic/SKILL.md`** (1 reference):
- Line 34: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
**Verify:** `grep "docs/claude/" skills/review/SKILL.md skills/review-epic/SKILL.md` returns zero matches
**UI:** no

### T5: Restructure setup skill + template (~5 min)
**Files:** `skills/setup/SKILL.md`, `skills/setup/templates/CLAUDE.md.template`
**Action:** Change directory creation, write targets, detection logic, and summary to use `.ruckus/` instead of `docs/claude/`. Eliminate secondary CLAUDE.md.
**Details:**
**`skills/setup/SKILL.md`** (9 references):
- Line 31: `docs/claude/` → `.ruckus/` in existing directory detection
- Line 39: `docs/claude/CLAUDE.md` → `.ruckus/` directory in Step 2 detection. Change to: `If .ruckus/ or .claude/ already exists:`
- Line 81: `docs/claude/` → `.ruckus/` in directory creation
- Line 93: `docs/claude/CLAUDE.md` → root `CLAUDE.md` as write destination. Setup now writes CLAUDE.md directly to project root — no secondary copy.
- Line 95: Remove instruction about `docs/claude/CLAUDE.md` being canonical and root copy being refreshed. Replace with: `CLAUDE.md is the canonical project context file, read by all Ruckus agents.`
- Line 98: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- Line 120: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 143: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Lines 155-157: Update summary paths:
  - `docs/claude/CLAUDE.md` → `CLAUDE.md` (root)
  - `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
  - `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`

**`skills/setup/templates/CLAUDE.md.template`** (1 reference):
- Line 33: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`

**IMPORTANT:** The secondary CLAUDE.md elimination means:
- Setup no longer creates `docs/claude/CLAUDE.md` + root copy
- Setup writes directly to root `CLAUDE.md`
- The "edit canonical, root copy refreshed by upgrade" pattern is removed
**Verify:** `grep -r "docs/claude/" skills/setup/` returns zero matches
**UI:** no

### T6: Update upgrade skill with migration step (~5 min)
**Files:** `skills/upgrade/SKILL.md`
**Depends on:** T5 (setup must be updated first so the two skills are consistent)
**Action:** Update mapping table, add migration step, update all path references
**Details:**
**`skills/upgrade/SKILL.md`** (6 references + new migration block):
- Line 16: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 19: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 27: `docs/claude/CLAUDE.md` → `CLAUDE.md` (root) in mapping table
- Line 28: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md` in mapping table
- Line 32: `docs/claude/` → `.ruckus/` in infer-path instruction
- Line 81: Remove the special case for `docs/claude/CLAUDE.md` → root copy. Since CLAUDE.md is now written directly to root, upgrade writes directly to root `CLAUDE.md`. No copy step needed.
- Line 94: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`

**New migration step** — add at the start of STEP 1 (before version check):
```
**Migration check:** If `docs/claude/` directory exists in the project:
> "Ruckus v0.1.2 renamed `docs/claude/` to `.ruckus/`. Migrate existing files? (yes / skip)"
If yes: move `docs/claude/known-pitfalls.md` to `.ruckus/known-pitfalls.md`, move `docs/claude/.workflow-upgrades` to `.ruckus/workflow-upgrades`, delete `docs/claude/CLAUDE.md` (root copy is authoritative), remove empty `docs/claude/` directory. If any file doesn't exist, skip that move silently. Then update root `CLAUDE.md`: replace any remaining `docs/claude/known-pitfalls.md` with `.ruckus/known-pitfalls.md` and `docs/claude/.workflow-upgrades` with `.ruckus/workflow-upgrades`.
```
**Verify:** `grep "docs/claude/" skills/upgrade/SKILL.md` returns zero matches (except inside the migration check block which intentionally references the old path for detection)
**UI:** no

### T7: Update README and CLAUDE.md documentation (~3 min)
**Files:** `README.md`, `CLAUDE.md`
**Action:** Update project structure tables and all path references
**Details:**
**`README.md`** (7 references):
- Line 26: `docs/claude/CLAUDE.md` row → `.ruckus/` directory row (CLAUDE.md is now at root, so this row describes the `.ruckus/` directory contents)
- Line 27: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- Line 28: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 31: Remove or update the "root copy" row — root `CLAUDE.md` is now the sole copy, not a mirror. Update to indicate `CLAUDE.md` is the primary project context file.
- Line 70: `docs/claude/CLAUDE.md` and `docs/claude/known-pitfalls.md` → `CLAUDE.md` and `.ruckus/known-pitfalls.md`
- Line 224: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Line 267: `docs/claude/CLAUDE.md` → `CLAUDE.md`

**`CLAUDE.md`** (0 direct references, but structure table needs update):
- The structure table row `docs/claude/` needs to become `.ruckus/` with updated description

**Verify:** `grep "docs/claude/" README.md CLAUDE.md` returns zero matches
**UI:** no

### T8: Add ADR footnotes (~2 min)
**Files:** `docs/adrs/ADR-005-versioned-maturity-checks.md`, `docs/adrs/ADR-006-runtime-context-not-baked.md`
**Action:** Update path references inline and add a footnote at the bottom of each ADR
**Details:**
**`ADR-005`** (1 reference):
- Line 17: `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades`
- Add footnote at end: `> **Note (v0.1.2):** \`docs/claude/\` was renamed to \`.ruckus/\`. Path references above reflect the updated structure.`

**`ADR-006`** (2 references):
- Line 17: `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
- Line 21: `docs/claude/CLAUDE.md` → `CLAUDE.md` (root). Update surrounding text to reflect that setup writes directly to root.
- Add footnote at end: `> **Note (v0.1.2):** \`docs/claude/\` was renamed to \`.ruckus/\`. Path references above reflect the updated structure.`

**Verify:** `grep "docs/claude/" docs/adrs/ADR-005* docs/adrs/ADR-006*` returns zero matches
**UI:** no

## Blast Radius
- Do NOT modify: `.claude-plugin/plugin.json`, `docs/planning/` files, ADR-001 through ADR-004, ADR-007, ADR-008, `skills/verify-all/SKILL.md`, `skills/review-plan/SKILL.md`, `skills/audit-epic/SKILL.md`
- Watch for: `.workflow-upgrades` dual rename (directory + leading dot removal), implementer-prompt.md is reference-only (runtime copies are inlined in build/fix), agent-preamble.md is sync reference (runtime copies are inlined in each agent)

## Conventions
- ADR-003: Agent preamble is manually synced — update all inline copies, not just the reference file
- ADR-006: Skills read context at runtime — this rename changes WHERE, not HOW
- ADR-007: Build/fix implementer prompt has inline + reference copies — both must be updated
- CLAUDE.md conventions: `{{PLACEHOLDER}}` markers must not be introduced; this is string replacement only

## Final Verification
After all tasks complete, run:
```bash
grep -r "docs/claude/" agents/ skills/ README.md CLAUDE.md skills/setup/templates/ docs/adrs/ADR-005* docs/adrs/ADR-006*
```
Expected: zero matches (except intentional old-path references in the upgrade migration check block).
