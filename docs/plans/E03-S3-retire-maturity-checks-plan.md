# Implementation Plan: E03.S3 — Retire test-verify-v1 and pitfalls-organized-v1

**Story:** [docs/planning/epics/E03-trust-and-ergonomics.md](../planning/epics/E03-trust-and-ergonomics.md) lines 226-261

**Goal:** Retire the `pitfalls-organized-v1` and `test-verify-v1` maturity checks from `/roughly:build` and `/roughly:fix` Stage 8 wrap-up, and migrate their value into the `doc-writer` agent's known-pitfalls write path. Update README.md and ROADMAP.md to reflect retirement.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| `skills/build/SKILL.md` | Modify (delete L260-266) | T1 |
| `skills/fix/SKILL.md` | Modify (delete L263-269) | T1 |
| `agents/doc-writer.md` | Modify (insert post-write suggestions step) | T2 |
| `docs/adrs/ADR-005-versioned-maturity-checks.md` | Modify (append footnote) | T3 |
| `README.md` | Modify (delete two table rows) | T4 |
| `docs/ROADMAP.md` | Modify (mark item 3 complete) | T5 |

## Tasks

### T1: Remove retired maturity-check blocks from build + fix skills (~3 min)

**Files:** `skills/build/SKILL.md`, `skills/fix/SKILL.md`

**Action:** Delete the `pitfalls-organized-v1` and `test-verify-v1` maturity-check blocks from both skill files.

**Details:**

In `skills/build/SKILL.md`, delete lines 260-266 inclusive. The exact text to remove (verify by Read first; line numbers may have shifted slightly):

```
**Check: pitfalls-organized-v1:**
If `.roughly/known-pitfalls.md` > 80 lines AND no `pitfalls-organized-v1` within last 30 days:
> "known-pitfalls.md has grown to [N] lines. Deduplicate and organize?"

**Check: test-verify-v1:**
If test config exists AND verify-all test step is placeholder AND not declined:
> "A test suite is configured. Add test execution to verify-all?"

```

The result is that the `**Check: investigator-v1:**` block (ending at the line before line 260) is followed directly by a blank line and then `**Check: stop-hook-v1:**`. Preserve exactly one blank line between the two surviving check blocks (no extra whitespace).

Repeat the same deletion in `skills/fix/SKILL.md` (currently lines 263-269). The block contents are identical between the two files; only the line numbers differ. Use `Edit` with `old_string` set to the full multi-line block including surrounding context (leading blank line + the two `**Check:` blocks), and `new_string` set to a single blank line.

Do NOT modify any other line in these files. Do NOT touch the `investigator-v1` or `stop-hook-v1` blocks.

**Verify:**
```
wc -l skills/build/SKILL.md skills/fix/SKILL.md
```
Both must be ≤ 300. Expected: build → ~289, fix → ~292.

Also run:
```
grep -n "pitfalls-organized-v1\|test-verify-v1" skills/build/SKILL.md skills/fix/SKILL.md
```
Must return zero hits.

**UI:** no

---

### T2: Add post-write suggestions to doc-writer agent (~5 min)

**Files:** `agents/doc-writer.md`

**Action:** Insert a new Process step (between current step 4 "Write concisely" and current step 5 "Deduplicate") that performs two conditional post-write suggestions when writing to `.roughly/known-pitfalls.md`.

**Details:**

The current Process section is at lines 26-33. Renumber the existing step 5 "Deduplicate" to step 6, and insert a new step 5 with the following content:

```
5. **Post-write suggestions (only when writing to `.roughly/known-pitfalls.md`)**:
   - **Organize suggestion:** Run `wc -l .roughly/known-pitfalls.md` after writing. If the post-write line count exceeds 80, append a single one-line note to your return summary: `Note: known-pitfalls.md is now [N] lines — consider reorganizing or deduplicating in a future session.` Do not modify the file further; the suggestion goes only in the return summary.
   - **Test-integration suggestion:** If a test config is present (any of: `package.json` with a `scripts.test` field whose value is not the npm-init default `"echo \"Error: no test specified\" && exit 1"`; `pytest.ini`; `pyproject.toml` containing `[tool.pytest]`; any `jest.config.*`) AND CLAUDE.md's Commands table Test row value is `none`, `none yet`, blank, or the un-replaced `{{TEST_COMMAND}}` placeholder, append a single one-line note to your return summary: `Note: project has test config but verify-all skips tests — consider updating CLAUDE.md Commands table Test row.` Do not modify CLAUDE.md.
```

After insertion, the current "5. **Deduplicate**" line becomes "6. **Deduplicate**". Adjust the numbering accordingly.

**Important constraints:**
- Both suggestions are **conditional**: they fire only when the trigger condition is met. Silent on miss.
- Both suggestions are **return-summary additions**, NOT file modifications. The doc-writer must not write the note into known-pitfalls.md or CLAUDE.md.
- Detection uses tools the agent already has (`Read`, `Glob`, `Grep`, `Bash`). The frontmatter `tools:` line at line 4 lists `Glob, Grep, Read, Write, Edit` — `Bash` is NOT currently granted. Use `Glob` to test for file presence and `Read` to inspect contents. Do NOT add `Bash` to the tools line. The line-count check must use `Read` (count lines in the result) instead of `wc`.
- Word budget: the agent file is currently 291 words against a 500-word cap (CLAUDE.md). The additions above must keep the file ≤ 500 words. After editing, run `wc -w agents/doc-writer.md` and confirm.

**Verify:**
```
wc -w agents/doc-writer.md
```
Must be ≤ 500. Also confirm the file still has valid YAML frontmatter and the Process section retains numbered steps in correct order (1, 2, 3, 4, 5, 6).

**UI:** no

---

### T3: Append v0.1.5 retirement footnote to ADR-005 (~2 min)

**Files:** `docs/adrs/ADR-005-versioned-maturity-checks.md`

**Action:** Append a new `> **Note (v0.1.5):**` blockquote at the bottom of the file, after the existing v0.1.4 note.

**Details:**

The file currently ends at line 54 with:
```
> **Note (v0.1.4):** The plugin was renamed from `ruckus` to `roughly`. Slash commands now use the `/roughly:*` namespace; the plugin-installed dotdir is `.roughly/`. Original identifiers above reflect the original naming.
```

Use `Edit` (NOT `Write`) per `.roughly/known-pitfalls.md` lines 36-37 (Edit-only for append-safety). Set `old_string` to the entire current last line above. Set `new_string` to the same line plus a blank line plus the new footnote:

```
> **Note (v0.1.4):** The plugin was renamed from `ruckus` to `roughly`. Slash commands now use the `/roughly:*` namespace; the plugin-installed dotdir is `.roughly/`. Original identifiers above reflect the original naming.

> **Note (v0.1.5):** `pitfalls-organized-v1` and `test-verify-v1` were retired. Retirement is a third disposition (alongside add/decline/version-bump) used when a check's value migrates elsewhere — here, into the `doc-writer` agent's post-write suggestions for `.roughly/known-pitfalls.md`. Existing `*-declined` entries in user `.roughly/workflow-upgrades` files become inert but are not auto-removed.
```

**Verify:**

Re-Read the file and confirm:
1. The new footnote is present at the end
2. The v0.1.4 footnote is unchanged
3. No other content was modified

**UI:** no

---

### T4: Remove retired rows from README upgrade-checks table (~2 min)

**Files:** `README.md`

**Action:** Delete the `test-verify-v1` and `pitfalls-organized-v1` rows from the "Upgrade Checks" table.

**Details:**

The table is at README.md lines 228-233. Current state:
```
| Check ID | Trigger | Offers |
| -------- | ------- | ------ |
| `investigator-v1` | 50+ source files, no investigator agent | Create investigator agent |
| `test-verify-v1` | Test config exists, verify-all test step is placeholder | Add test execution |
| `stop-hook-v1` | verify-all has 2+ meaningful checks, no Stop hook | Add Stop hook |
| `pitfalls-organized-v1` | known-pitfalls.md > 80 lines | Deduplicate and organize |
```

Use `Edit` to remove the two retired rows. Final state should be:
```
| Check ID | Trigger | Offers |
| -------- | ------- | ------ |
| `investigator-v1` | 50+ source files, no investigator agent | Create investigator agent |
| `stop-hook-v1` | verify-all has 2+ meaningful checks, no Stop hook | Add Stop hook |
```

Also check the surrounding prose:
- Line 222 mentions `pitfalls-organized` (without the `-v1` suffix) in the "Established" maturity-tier description: `"\`pitfalls-organized\` check activates when known-pitfalls.md exceeds 80 lines."` This sentence is now factually wrong post-retirement. Replace this clause with: `"The doc-writer agent suggests reorganization when known-pitfalls.md exceeds 80 lines."` Keep the rest of the sentence intact.

Do not modify any other content in README.md.

**Verify:**
```
grep -n "pitfalls-organized\|test-verify-v1" README.md
```
Must return zero hits.

**UI:** no

---

### T5: Mark roadmap item 3 as complete in ROADMAP.md (~1 min)

**Files:** `docs/ROADMAP.md`

**Action:** Update line 55 of `docs/ROADMAP.md` to flag item 3 ("Retire test-verify-v1 and pitfalls-organized-v1") as complete in v0.1.5.

**Details:**

Current line 55:
```
3. **Retire test-verify-v1 and pitfalls-organized-v1.** Fold triggers into known-pitfalls writes.
```

Replace with:
```
3. **Retire test-verify-v1 and pitfalls-organized-v1.** ✅ Done — triggers folded into doc-writer's known-pitfalls write path (E03.S3).
```

Do not modify any other line. Other roadmap items in this section (1, 2, 4, 5, 6, 7, 8, 9, 10) remain unchanged.

**Verify:**

Re-Read the line and confirm the ✅ marker and "Done" wording are present.

**UI:** no

---

## Blast Radius

**Do NOT modify:**
- `docs/planning/archive/**` — historical archive, leave references intact
- `docs/planning/epics/complete/**` — completed epics, immutable
- `docs/planning/epics/E03-trust-and-ergonomics.md` — the story spec itself; the epic checkboxes will be checked by the human at wrap-up, not by implementation
- `docs/planning/epics/E03-trust-and-ergonomics-review.md` — historical review doc
- `docs/planning/prompts/roughly-pm-agent-v0.1.5.md` — PM agent prompt unrelated
- `.roughly/workflow-upgrades` — historical record per AC5; existing entries for retired check IDs are NOT auto-cleaned
- `.claude/hooks/verify-all.sh` — the dogfood Stop hook is unrelated to this story
- `agents/agent-preamble.md` — doc-writer is not a preamble consumer; preamble sync note at L14 references doc-writer L22 only for path-string drift, which we are not changing

**Watch for:**
- `skills/fix/SKILL.md` is at 299 lines (1 below the 300 cap). T1 removes 7 lines, giving 292 — relief, not risk. But until T1 lands, any whitespace mistake during the edit could push it over.
- ADR-005 footnote is **append-only**. Use `Edit` (not `Write`) to guarantee no upstream content is touched. See `.roughly/known-pitfalls.md` L36-37.
- `agents/doc-writer.md` is at 291 words. T2 must stay ≤ 500.
- The `doc-writer` agent does not currently have `Bash` in its tools list. T2's line-count check must use `Read` (count lines in result), not shell `wc`.
- The `agent-preamble.md` sync header (L14) flags `doc-writer L22` as a sync point for known-pitfalls.md path strings only. T2 inserts content well below L22; this does NOT trigger a sync.

## Conventions

- **Skill body cap:** 300 lines per `CLAUDE.md`. `wc -l` enforced by `verify-all.sh` Stop hook.
- **Agent prompt cap:** 500 words per `CLAUDE.md`. `wc -w` for verification.
- **ADR append style:** `> **Note (vX.Y.Z):**` blockquote, separated by one blank line. See ADR-005's existing v0.1.2 and v0.1.4 notes.
- **Edit-only for append:** `.roughly/known-pitfalls.md` L36-37 — use `Edit` with current last line as `old_string`, never `Write` (which clears file).
- **Maturity check format:** `**Check: <id>:**` followed by trigger condition and prompt blockquote. Surviving blocks for `investigator-v1` and `stop-hook-v1` define the canonical format — preserve the surrounding whitespace pattern (one blank line between blocks).
- **Versioning:** retirement is NOT a version bump per ADR-005. The story explicitly notes "formal retirement, not a version bump per the ADR's reasoning."
- **Cross-reference scope:** `skills/`, `agents/`, `README.md`, `docs/ROADMAP.md`, `docs/adrs/` are in-scope for retired-check-ID cleanup. Archive and complete-epic dirs are out-of-scope (historical).

## Out of Scope

- Replacing `.claude/hooks/verify-all.sh` (dogfood-specific)
- Bumping `investigator-v1` or `stop-hook-v1` versions
- Adding new maturity checks to replace the retired ones
- Cleaning up historical `*-declined` entries in user `.roughly/workflow-upgrades` files
- Cross-platform Stop hook support
- Modifying `agent-preamble.md`

## Verification (post-implementation, runs in Stage 7)

```bash
# Line caps
wc -l skills/build/SKILL.md skills/fix/SKILL.md
# Both must be ≤ 300

# Agent word cap
wc -w agents/doc-writer.md
# Must be ≤ 500

# Cross-reference sweep
grep -rn "pitfalls-organized-v1\|test-verify-v1" skills/ agents/ README.md docs/adrs/ docs/ROADMAP.md
# Expected: 3 hits in ADR-005 (L17 and L21 are existing Decision-section examples, intentional; the new T3 footnote also matches). All hits in skills/, agents/, README.md, and docs/ROADMAP.md must be zero.
```
