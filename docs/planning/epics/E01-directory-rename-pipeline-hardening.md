# E01: Directory Rename + Pipeline Hardening

**Status:** In Progress
**Plugin Version:** 0.1.2
**Dependencies:** v0.1.1 (tagged, current)
**Validated:** 2026-04-24

---

## Objective

Ruckus v0.1.2 delivers a breaking directory rename (`docs/claude/` to `.ruckus/`) while user count is zero, fixes four pipeline correctness issues that could cause infinite loops or lost context during builds, and addresses high-priority maintenance items. Driven by the [post-Phase 5 review findings](../review-ruckus-plugin-v2.md) and [v0.1.2 issues list](../prompts/ruckus-v0.1.2-issues.md).

---

## Stories

### S1: Rename `docs/claude/` to `.ruckus/` ✅

**Status:** Merged (2026-04-25)
**Priority:** P0 (breaking change — must be first)

**Files:**
- `agents/agent-preamble.md` — update path reference (line 14)
- `agents/code-reviewer.md` — update path reference
- `agents/discovery.md` — update path reference
- `agents/epic-reviewer.md` — update path reference
- `agents/investigator.md` — update path reference
- `agents/silent-failure-hunter.md` — update path reference
- `agents/doc-writer.md` — update path references + change canonical CLAUDE.md write target
- `skills/build/SKILL.md` — update 6 path references (lines 142, 226, 232, 249, 251, 254)
- `skills/fix/SKILL.md` — update 7 path references (lines 40, 151, 231, 237, 254, 256, 259)
- `skills/setup/SKILL.md` — restructure file creation (lines 31, 39, 80-98, 117-128, 143, 154-158)
- `skills/upgrade/SKILL.md` — update mappings + add migration step (lines 16-32, 81, 94, 99)
- `skills/review/SKILL.md` — update 3 path references (lines 28, 38, 71)
- `skills/review-epic/SKILL.md` — update 1 path reference (line 34)
- `skills/build/implementer-prompt.md` — update path reference
- `skills/setup/templates/CLAUDE.md.template` — update path reference (line 33)
- `README.md` — update 11 path references
- `CLAUDE.md` — update structure table and pitfalls section
- `docs/adrs/ADR-005-versioned-maturity-checks.md` — add footnote (see decision below)
- `docs/adrs/ADR-006-runtime-context-not-baked.md` — add footnote (see decision below)

**Context:**

The current `docs/claude/` directory name is ambiguous for an open-source plugin — it could clash with other tools and doesn't communicate Ruckus ownership. With zero users, this is the ideal time for the breaking change.

The rename involves three structural changes:
1. **Path rename:** `docs/claude/known-pitfalls.md` becomes `.ruckus/known-pitfalls.md`. `docs/claude/.workflow-upgrades` becomes `.ruckus/workflow-upgrades` (drop the leading dot since it's already in a dotdir).
2. **Eliminate the secondary CLAUDE.md:** Currently setup creates `docs/claude/CLAUDE.md` (canonical) and copies to root `CLAUDE.md`. After this change, root `CLAUDE.md` is the only copy. Setup writes directly to root. The doc-writer agent must update its write target from `docs/claude/CLAUDE.md` to root `CLAUDE.md`.
3. **Upgrade migration:** The upgrade skill needs a new migration step at the top of STEP 1: detect `docs/claude/` in existing user projects and offer to move files to `.ruckus/`.

**Current behavior (agent-preamble.md line 14):**
```
2. **docs/claude/known-pitfalls.md** -- known issues to avoid repeating
```

**Target behavior:**
```
2. **.ruckus/known-pitfalls.md** -- known issues to avoid repeating
```

**Current behavior (setup/SKILL.md lines 80-95):**
- Creates `docs/claude/` directory
- Writes `docs/claude/CLAUDE.md` as canonical copy
- Creates root `CLAUDE.md` as a copy
- Writes `docs/claude/known-pitfalls.md`
- Creates `docs/claude/.workflow-upgrades`

**Target behavior (setup/SKILL.md):**
- Creates `.ruckus/` directory
- Writes root `CLAUDE.md` as the sole copy (no `docs/claude/CLAUDE.md`)
- Writes `.ruckus/known-pitfalls.md`
- Creates `.ruckus/workflow-upgrades`
- Step 2 detection changes from `docs/claude/CLAUDE.md` to checking for `.ruckus/` directory
- Step 7 summary updates all file paths

**Current behavior (upgrade/SKILL.md lines 25-32):**
```
| `CLAUDE.md.template` | `docs/claude/CLAUDE.md` |
| `known-pitfalls.md.template` | `docs/claude/known-pitfalls.md` |
```

**Target behavior (upgrade/SKILL.md):**
```
| `CLAUDE.md.template` | `CLAUDE.md` (root) |
| `known-pitfalls.md.template` | `.ruckus/known-pitfalls.md` |
```
Plus new migration step at the start of STEP 1:
```
**Migration check:** If `docs/claude/` directory exists in the project:
> "Ruckus v0.1.2 renamed `docs/claude/` to `.ruckus/`. Migrate existing files? (yes / skip)"
If yes: move `docs/claude/known-pitfalls.md` to `.ruckus/known-pitfalls.md`, move `docs/claude/.workflow-upgrades` to `.ruckus/workflow-upgrades`, delete `docs/claude/CLAUDE.md` (root copy is authoritative), remove empty `docs/claude/` directory. If any file doesn't exist, skip that move silently. Then update root `CLAUDE.md`: replace any remaining `docs/claude/known-pitfalls.md` with `.ruckus/known-pitfalls.md` and `docs/claude/.workflow-upgrades` with `.ruckus/workflow-upgrades`.
```

**Current behavior (doc-writer.md):**
References `docs/claude/CLAUDE.md` and `docs/claude/known-pitfalls.md` as write targets.

**Target behavior (doc-writer.md):**
References `CLAUDE.md` (root) and `.ruckus/known-pitfalls.md` as write targets.

**ADR handling decision:** ADR-005 references `docs/claude/.workflow-upgrades` (2 occurrences in context/consequences). ADR-006 references `docs/claude/known-pitfalls.md` and `docs/claude/CLAUDE.md` (2 occurrences in context/reasoning). These are historical context describing what was true when the ADRs were written — the decisions themselves remain valid with updated paths. **Recommended approach:** Add a one-line footnote at the bottom of each ADR: `> **Note (v0.1.2):** \`docs/claude/\` was renamed to \`.ruckus/\`. Path references above reflect the original structure.` This is a minimal annotation, not a decision change, so it does not require a new ADR.

**ADR constraints:**
- ADR-006: Skills must read project context at runtime, not baked in. The rename changes WHERE files live but not HOW they're consumed — skills still read CLAUDE.md and known-pitfalls.md at runtime. No conflict.
- ADR-005: Maturity check decisions are still stored in the workflow-upgrades file. The path changes but the format and behavior don't. No conflict.

**Cross-reference impacts:**
- Every agent that inlines the preamble text must be updated with the new path. The agent-preamble.md header (lines 6-10) lists all consumers — use this as a checklist.
- The CLAUDE.md structure table must update the row for `docs/claude/` to `.ruckus/`.
- The README project structure tree must replace `docs/claude/` with `.ruckus/`.

**Acceptance Criteria:**
- [x] Zero `docs/claude/` references remain in: `agents/`, `skills/`, `CLAUDE.md`, `README.md`, `skills/setup/templates/`
- [x] Verification: `grep -r "docs/claude/" agents/ skills/ README.md CLAUDE.md skills/setup/templates/` returns zero matches
- [x] `.ruckus/known-pitfalls.md` is the path in all agents and skills (not `docs/claude/known-pitfalls.md`)
- [x] `.ruckus/workflow-upgrades` is the path in build, fix, setup, upgrade (not `docs/claude/.workflow-upgrades`)
- [x] Root `CLAUDE.md` is the sole copy — no `docs/claude/CLAUDE.md` reference in setup or doc-writer
- [x] Setup creates `.ruckus/` directory (not `docs/claude/`)
- [x] Setup writes root `CLAUDE.md` directly (not `docs/claude/CLAUDE.md` + root copy)
- [x] Upgrade has migration step that detects `docs/claude/` and offers to move files
- [x] Upgrade mapping table points to `CLAUDE.md` (root) and `.ruckus/known-pitfalls.md`
- [x] ADR-005 and ADR-006 have footnotes noting the rename
- [x] README project structure tree shows `.ruckus/` instead of `docs/claude/`
- [x] CLAUDE.md structure table shows `.ruckus/` instead of `docs/claude/`

---

### S2: Pipeline loop caps ✅

**Status:** Merged (2026-04-25)
**Priority:** P1

**Files:**
- `skills/build/SKILL.md` — lines 100, 168, 194, 196
- `skills/fix/SKILL.md` — lines 109, 177, 199, 201

**Context:**

Four pipeline loops have no bound or incorrect bounds and can run indefinitely. All four changes are identical in both build and fix skills.

**Change 1 — Stage 4 review-plan retry (build:100, fix:109):**

Current behavior:
```
Repeat until PASS or until 2 consecutive NEEDS REVISION verdicts
```
The word "consecutive" allows bypass by alternating between PASS-adjacent and NEEDS REVISION results. A non-consecutive failure resets the counter.

Target behavior:
```
Repeat until PASS or until 2 total NEEDS REVISION verdicts
```

**Change 2 — Stage 5c question re-dispatch (build:168, fix:177):**

Current behavior:
```
- If the subagent returned questions: answer them, re-dispatch.
```
No cap — if the subagent keeps returning questions, the orchestrator keeps re-dispatching indefinitely.

Target behavior (use terse wording to avoid adding a line — this is a line-budget-critical file):
```
- If the subagent returned questions: answer them, re-dispatch (max 2; then escalate to human).
```

**Change 3 — Stage 6 review-fix loop (build:194, fix:199):**

Current behavior:
```
Fix any critical findings. Re-run review until clean.
```
No iteration cap — could loop indefinitely on persistent findings.

Target behavior:
```
Fix any critical findings. Re-run review (max 2 review-fix cycles; if still failing, present findings to human).
```

**Change 4 — Stage 6 gate disambiguation (build:196, fix:201):**

Current behavior:
```
**Gate:** "Review complete. Proceed to verification? (yes / address warnings / abort)"
```
"Address warnings" is ambiguous — the LLM could interpret this as permission to self-loop without human involvement.

Target behavior:
```
**Gate:** "Review complete. Proceed to verification? (yes / list warnings to address [then re-review once] / abort)"
```

**ADR constraints:**
- ADR-007: Two-stage review must run after every task. These changes cap the retry loop, not the review itself. No conflict.
- ADR-001: Review-plan is dispatched as blocking subagent. The cap applies to re-dispatches, not the dispatch mechanism. No conflict.

**Line budget:** S1 is net-zero lines in build/fix (inline path replacements only). Changes 1 and 4 are inline rewording (0 net lines). Change 2 must use terse wording (0 net lines). Change 3 adds 1 line. Net: **+1 line per file.** Post-S1+S2: build 289→290, fix 294→295.

**Acceptance Criteria:**
- [x] Stage 4 says "2 total" not "2 consecutive" in both build and fix
- [x] Stage 5c has explicit 2-attempt cap with human escalation in both build and fix
- [x] Stage 6 review-fix loop has 2-cycle cap with human escalation in both build and fix
- [x] Stage 6 gate option is unambiguous — specifies what "address warnings" does and limits it

---

### S3: Compaction preserve lists and re-validation

**Priority:** P1

**Files:**
- `skills/build/SKILL.md` — lines 112-114, 184, between lines 210 and 212
- `skills/fix/SKILL.md` — lines 121-123, 191, between lines 214 and 216

**Context:**

Context compaction boundaries risk losing critical data that downstream stages need. Three issues remain (the fourth — plan file path missing from Stage 4 preserve list — was verified as already addressed: build line 108 and fix line 117 already include "plan file path").

**Change 1 — Stage 5 plan file re-validation (build: after line 114, fix: after line 123):**

Current behavior: Stage 5 starts with "Read the verified plan" but does not confirm the plan file path survived compaction from Stage 4.

Target behavior: Add after the Stage 5 prerequisite line:
```
Re-read the plan file. If the path is no longer in context after Stage 4 compaction, check `docs/plans/` for the most recent plan file matching the feature name.
```

**Change 2 — Stage 5d preserve list (build:184, fix:191):**

Current behavior:
```
Compact context before review. Preserve: feature summary, list of all files changed, task completion count, any verification warnings or deviations.
```
Missing the task ID list — the orchestrator would need to re-read the plan to know which tasks were completed.

Target behavior:
```
Compact context before review. Preserve: feature summary, task ID list, list of all files changed, task completion count, any verification warnings or deviations.
```

**Change 3 — Post-Stage 7 compaction (build: between lines 210 and 212, fix: between lines 214 and 216):**

Current behavior: No compaction between Stage 7 verification and Stage 8 maturity checks. Maturity checks run on context bloated with all implementation, review, and verification history.

Target behavior: Merge compaction into the existing Stage 7 gate line to save a line (line-budget-critical):
```
**Gate:** "Verification passed. Ready to commit? (yes / additional checks / abort)" — then compact context, preserving: feature summary, files changed, verification verdict.
```

**ADR constraints:**
- ADR-002: Subagent-per-task architecture means orchestrator context grows across tasks. Compaction boundaries are the mechanism to manage this. Adding boundaries supports, not conflicts with, the ADR. No conflict.

**Line budget:** +2 lines (change 1) + 0 lines (change 2, inline edit) + 1 line (change 3, merged into gate) = **+3 lines per file.** Post-S1+S2+S3: build 290→293, fix 295→298.

**Acceptance Criteria:**
- [ ] Stage 5 re-validates plan file path after Stage 4 compaction in both build and fix
- [ ] Stage 5d preserve list includes "task ID list" in both build and fix
- [ ] Compaction instruction exists between Stage 7 and Stage 8 in both build and fix
- [ ] Stage 5d preserve list includes "task ID list"; post-Stage 7 compaction preserves feature summary, files changed, and verification verdict

---

### S4: Error handling disambiguation

**Priority:** P1

**Files:**
- `skills/build/SKILL.md` — line ~174 (post-S3; original line 172, shifted by S3 Stage 5 insertion)
- `skills/fix/SKILL.md` — line ~183 (post-S3; original line 181, shifted by S3 Stage 5 insertion)
- `skills/review-plan/SKILL.md` — lines 17-19

**Note:** Line numbers for build/fix are approximate after S3. Locate target text by content pattern: `If it fails: fix the issue OR re-dispatch`.

**Context:**

Two error handling paths are ambiguous, causing agents to guess at correct behavior. A third issue (spec-reviewer file reference) was verified as already clean — no active skill references the file as runtime instructions.

**Change 1 — Stage 5c quality check retry (build:172, fix:181):**

Current behavior:
```
- If it fails: fix the issue OR re-dispatch the subagent with the error
```
Doesn't distinguish between auto-fixable errors (type error in a file this task modified) and unfixable errors (missing dependency, architecture problem, file outside task scope). Agents guess which path to take.

Target behavior:
```
- If it fails on files this task owns: attempt auto-fix (max 2 attempts). If it fails on files outside this task's scope or on environmental issues (missing dependency, config error): escalate to human immediately.
```

**Change 2 — Review-plan missing CLAUDE.md (review-plan/SKILL.md lines 17-19):**

Current behavior:
```
You receive:
- A path to the plan file
- The project's CLAUDE.md and known-pitfalls.md

Read all three before starting verification.
```
If CLAUDE.md or known-pitfalls.md doesn't exist (setup wasn't run), the agent fails cryptically with no actionable guidance.

Target behavior:
```
You receive:
- A path to the plan file
- The project's CLAUDE.md and .ruckus/known-pitfalls.md

Read all three before starting verification. If CLAUDE.md is missing, return NEEDS REVISION: "CLAUDE.md not found — run /ruckus:setup first." If .ruckus/known-pitfalls.md is missing, note the gap but proceed — it's informational, not blocking.
```

Note: The `.ruckus/` path above assumes S1 is complete. This story MUST execute after S1.

**ADR constraints:**
- ADR-007: Two-stage review runs after every task. This change clarifies retry behavior within the quality check stage, not the review structure. No conflict.

**Line budget:** Change 1 is an inline expansion (+1 line). Change 2 adds ~2 lines to review-plan (90→92). Post-S1+S2+S3+S4: build 293→294, fix 298→299. **Within 300-line limit with 1 line of headroom on fix.**

**Acceptance Criteria:**
- [ ] Quality check retry distinguishes auto-fixable (task-owned files) from unfixable (external) in both build and fix
- [ ] Auto-fix is capped at 2 attempts before escalation
- [ ] Review-plan returns clear NEEDS REVISION when CLAUDE.md is missing
- [ ] Review-plan notes missing known-pitfalls.md as informational gap, not a blocker
- [ ] Spec-reviewer reference verified clean (no dangling file references in active skills)
- [ ] fix/SKILL.md stays at or under 300 lines after all S1-S4 changes applied

---

### S5: Agent preamble drift documentation and detection

**Priority:** P2

**Files:**
- `agents/agent-preamble.md` — lines 9-10 (expand comment)
- `skills/build/implementer-prompt.md` — add sync comment
- `skills/upgrade/SKILL.md` — STEP 1 (add drift check)

**Context:**

The agent-preamble.md header documents which agents use the preamble and which don't (lines 6-10), but doesn't explain WHY static-analysis and doc-writer differ. The implementer-prompt.md has an abbreviated preamble that could drift from the canonical version. There's no mechanism to detect preamble drift during upgrade.

**Change 1 — agent-preamble.md (expand lines 9-10):**

Current behavior:
```
     Not used by: static-analysis (reads CLAUDE.md for commands only, not conventions),
     doc-writer (writes to these files — reads them for deduplication, not execution context). -->
```

Target behavior (expand to clarify why):
```
     Not used by: static-analysis (reads CLAUDE.md for commands only — it runs type check,
     lint, and build commands but does not need project conventions or pitfall patterns since
     it reports raw tool output, not convention-aware analysis),
     doc-writer (writes to CLAUDE.md and known-pitfalls.md — reads them for deduplication
     context to avoid adding duplicate entries, not as execution guidance). -->
```

**Change 2 — implementer-prompt.md (add sync comment):**

Current behavior (line 12, after S1 rename):
```
Read CLAUDE.md and .ruckus/known-pitfalls.md before implementing.
```

Target behavior:
```
<!-- Abbreviated agent-preamble. Source of truth: agents/agent-preamble.md -->
Read CLAUDE.md and .ruckus/known-pitfalls.md before implementing.
```

**Change 3 — upgrade/SKILL.md STEP 1 (add drift check):**

Current behavior: STEP 1 inventories template files and their installed counterparts but does not check agent preamble consistency.

Target behavior: Add after the agent file check (line 34):
```
**Preamble drift check:** Compare the context-loading instruction in each agent file against `agents/agent-preamble.md`. Flag any agent where the instruction text differs from the canonical version (excluding agents listed as exceptions in the preamble header: static-analysis, doc-writer).
```

**ADR constraints:** No ADRs are affected. This is a documentation and detection enhancement.

**Line budget:** agent-preamble.md: 14→18 lines. implementer-prompt.md: 36→37 lines. upgrade/SKILL.md: 117→123 lines. All well within limits.

**Acceptance Criteria:**
- [ ] agent-preamble.md explains WHY static-analysis and doc-writer have different preambles
- [ ] implementer-prompt.md has a comment noting its relationship to agent-preamble.md
- [ ] Upgrade STEP 1 checks for preamble drift across agent files
- [ ] The drift check excludes agents listed as exceptions in the preamble header

---

### S6: Audit-epic token budget batching

**Priority:** P2

**Files:**
- `skills/audit-epic/SKILL.md` — STEP 3 (per-story review dispatch)

**Context:**

For epics with 10+ stories, all per-story review reports accumulate in the orchestrator's context before synthesis. At 3-5K tokens per report, a 12-story epic loads 36-60K tokens before the cross-cutting analysis begins, risking context pressure and quality degradation.

See [audit-epic/SKILL.md](../../skills/audit-epic/SKILL.md) STEP 3 for current dispatch logic.

**Current behavior:** All per-story review subagents dispatch in parallel regardless of story count.

**Target behavior:** Add a conditional before dispatch:
```
**If 10+ stories:** Batch per-story reviews in groups of 5. After each batch completes:
1. Summarize the batch findings (key themes, critical issues, affected stories)
2. Compact context, preserving only the batch summary and remaining story list
3. Dispatch the next batch

**If <10 stories:** Dispatch all per-story reviews in parallel (current behavior).
```

**ADR constraints:**
- ADR-008: Audit-epic dispatches subagents at Sonnet, not Opus. Batching doesn't change the model. No conflict.
- ADR-002: Subagent-per-task pattern. Batching is an orchestration optimization, not a change to the per-task model. No conflict.

**Line budget:** audit-epic/SKILL.md: 129→~141 lines. Well within 300-line limit.

**Acceptance Criteria:**
- [ ] Epics with 10+ stories batch per-story reviews in groups of 5
- [ ] Intermediate batch summaries are created with context compaction between batches
- [ ] Epics with <10 stories dispatch all reviews in parallel (no behavioral change)
- [ ] Cross-cutting analysis receives batch summaries, not raw per-story reports (for 10+ story epics)

---

### S7: Setup and upgrade hardening

**Priority:** P2

**Files:**
- `skills/setup/SKILL.md` — Steps 2, 3, 5a
- `skills/upgrade/SKILL.md` — Step 4

**Context:**

Four behavioral gaps in setup and upgrade that could produce incorrect output. Each is a small, targeted fix.

**Change 1 — Required-field enforcement gate (setup/SKILL.md between Steps 3 and 4):**

Current behavior (line 48): "These fields are required. Setup does not proceed without them." This is a behavioral instruction with no explicit gate. The LLM can interpret "provided" loosely and proceed with partial answers.

Target behavior: Add after Step 3, before Step 4:
```
**Gate:** Confirm all 6 required fields have non-empty, non-placeholder values. If any field is missing or contains only "TBD", "TODO", "skip", or similar placeholders, loop back to that specific question. Do not proceed to Step 4 until all 6 fields have substantive answers.
```

**Change 2 — Enrich mode gap definition (setup/SKILL.md line 42):**

Current behavior:
```
If enriching, read existing files and identify gaps to fill.
```
"Gaps" is undefined — the agent must guess what constitutes a gap vs. existing content.

Target behavior:
```
If enriching, read existing files and identify gaps: any of the 6 required fields (Step 3) that are missing, empty, or contain placeholder text ("TBD", "TODO", "None", template markers like `{{...}}`). Only prompt for gap fields — preserve all existing non-gap content.
```

**Change 3 — Formatter removal instruction (setup/SKILL.md line 89):**

Current behavior: Line 89 says `{{FORMATTER_COMMAND}}` — from Step 4 (if provided, otherwise remove the Format row)` — but this is buried in the placeholder replacement list. The removal instruction isn't prominent enough; if the agent processes the list sequentially and replaces `{{FORMATTER_COMMAND}}` with an empty string, the Format row remains with no value.

Target behavior: Add an explicit instruction after the placeholder list:
```
**If no formatter was provided:** Remove the entire `| Format | ... |` row from the Commands table. Do not leave a row with an empty command.
```

**Change 4 — Upgrade hook preservation (upgrade/SKILL.md Step 4, line 74-82):**

Current behavior: Step 4 says "Merge structural changes with preserved customizations" but doesn't explicitly mention hooks. The upgrade could overwrite user-added hooks when merging settings.json.

Target behavior: Add to the Step 4 instructions:
```
**For settings.json:** Preserve all existing hook entries. Only add or update hooks defined in the plugin template. Never remove or overwrite user-added hooks — they may be from other plugins or custom workflows.
```

**ADR constraints:** No ADRs are affected. These are behavioral hardening fixes within existing skills.

**Line budget:** setup/SKILL.md: 165→~172 lines. upgrade/SKILL.md (after S5): 123→~127 lines. Both well within limits.

**Acceptance Criteria:**
- [ ] Setup has explicit gate preventing Step 4 until all 6 required fields have substantive answers
- [ ] Enrich mode defines "gap" as missing/empty/placeholder required fields
- [ ] Setup explicitly removes Format row when no formatter is provided
- [ ] Upgrade preserves user-added hooks when merging settings.json
- [ ] No existing behavior changes for users who provide all required fields

---

### S8: Documentation accuracy

**Priority:** P2 (documentation only — no validation required)

**Files:**
- `README.md` — lines 226-240 (token usage), lines 106-118 (skills reference), lines 242-273 (troubleshooting), lines 14-54 (Quick Start), lines 199-207 (maturity)
- `skills/fix/SKILL.md` — line 3 (frontmatter description)

**Context:**

Six documentation inaccuracies identified in the issues document. All are factual corrections, not behavioral changes.

**Change 1 — Token usage table (README.md ~line 226):**

Current behavior: Token usage table doesn't reflect Phase 4 compaction savings.

Target behavior: Add a note to the build and fix rows in the token usage table: "Includes 3 compaction points that reduce peak context."

**Change 2 — Review vs review-plan relationship (README.md, Skills Reference section ~line 106):**

Current behavior: The relationship between `/ruckus:review` (post-implementation code review) and `/ruckus:review-plan` (pre-implementation plan verification) is not explained. Users may confuse them.

Target behavior: Add after the Skills Reference table:
```
> **review vs review-plan:** `review-plan` verifies the implementation plan against the codebase *before* implementation starts (dispatched as a blocking subagent by build/fix Stage 4). `review` evaluates the implemented code *after* implementation completes (Stage 6).
```

**Change 3 — Context management guidance (README.md, Troubleshooting section ~line 242):**

Current behavior: No guidance for managing context on large builds.

Target behavior: Add a troubleshooting entry:
```
**Issue:** Build pipeline loses context or quality degrades on later tasks
**Cause:** Plans with 10+ tasks accumulate context faster than compaction can clear it
**Fix:** Split the plan into 2-3 smaller builds of 5-7 tasks each. Each build gets a fresh context.
```

**Change 4 — fix/SKILL.md description (line 3):**

Current behavior:
```
description: "Bug/issue fix pipeline: investigate → plan → review plan → implement (subagent-per-task with two-stage review) → review → verify build. Self-upgrades investigator agent when project reaches 50+ files."
```

Target behavior:
```
description: "Bug/issue fix pipeline: investigate → plan → review plan → implement (subagent-per-task with two-stage review) → review → verify build. Offers to create investigator agent when project reaches 50+ files."
```

**Change 5 — Quick Start file list (README.md ~line 14):**

This is verified by S1 — the Quick Start file list paths change from `docs/claude/` to `.ruckus/` as part of the rename. No separate work needed, but this AC confirms the change was applied.

**Change 6 — "maturity" inline definition (README.md, Quick Start section):**

Current behavior: "maturity" is used in Quick Start without definition.

Target behavior: On first use, add parenthetical: "maturity level (greenfield, scaffolded, or established — based on source file count)"

**Acceptance Criteria:**
- [ ] Token usage table notes compaction savings for build and fix
- [ ] Review vs review-plan relationship is explained near the Skills Reference
- [ ] Troubleshooting section has context management guidance for large builds
- [ ] fix/SKILL.md description says "Offers to create" not "Self-upgrades"
- [ ] Quick Start file list uses `.ruckus/` paths (verified by S1)
- [ ] "maturity" has inline definition on first use in Quick Start

---

## Exit Criteria

- [ ] All 8 stories complete
- [ ] `CLAUDE.md` updated to reflect `.ruckus/` structure and any new conventions
- [ ] `README.md` updated with `.ruckus/` paths, documentation corrections, and new troubleshooting entries
- [ ] `CHANGELOG.md` updated with v0.1.2 release entry
- [ ] All cross-references valid (skills reference existing agents, agents reference existing files)
- [ ] `plugin.json` version bumped to 0.1.2
- [ ] fix/SKILL.md stays at or under 300 lines after all changes
- [ ] build/SKILL.md stays at or under 300 lines after all changes
- [ ] Zero `docs/claude/` references in active plugin files
- [ ] Tag `v0.1.2` pushed

---

## Parallelization Notes

**Execution phases:**

| Phase | Stories | Rationale |
|-------|---------|-----------|
| 1 | S1 | All other stories depend on renamed paths |
| 2 | S2 + S5 + S6 | Disjoint files: S2=build/fix, S5=agents+upgrade, S6=audit-epic |
| 3 | S3 + S7 | Disjoint files: S3=build/fix, S7=setup/upgrade |
| 4 | S4 + S8 | S4=build/fix+review-plan, S8=README+fix frontmatter |

**Merge conflict risks:**
- S2, S3, S4 all modify build/SKILL.md and fix/SKILL.md but in different sections (Stage 4, Stage 5, Stage 6). Sequential execution within phases eliminates conflict.
- S5 and S7 both modify upgrade/SKILL.md but in different steps (STEP 1 vs STEP 4). Safe to parallel.
- **Critical constraint:** fix/SKILL.md line budget is 300 lines. S1 is net-zero (inline replacements). Cumulative: S2 (+1, with terse wording) + S3 (+3, with gate-merged compaction) + S4 (+1) = +5 lines. Final: 294 + 5 = **299 lines** (1 line headroom). Each story touching this file MUST report post-edit line count and use the compressed wording specified in the story context.

---

## Issues Resolved During Planning

1. **Compaction issue item 1 (plan file path missing from preserve list):** Verified as already addressed. Build line 108 and fix line 117 both include "plan file path" in the Stage 4 compaction preserve list. Removed from S3 scope.

2. **Spec-reviewer reference issue:** Verified as already clean. No active skill files reference `spec-reviewer-prompt.md` as runtime instructions. Remaining references are in CLAUDE.md (structure table) and ADR-003 (design decision documentation) — both appropriate. Removed from S4 scope; added as verification-only AC.

3. **ADR modification approach:** Recommended one-line footnote rather than ADR-009. The directory rename doesn't change any architectural decision — only the paths referenced in context sections. A footnote preserves historical accuracy while noting the change.

4. **Line budget correction (found during validation):** Original estimates assumed S1 would save 2-3 lines in build/fix by shortening paths. Validation confirmed S1 is net-zero lines (inline string replacement doesn't change line count). Corrected all downstream estimates. Added compression guidance to S2 (terse re-dispatch cap wording) and S3 (merge compaction into gate text) to keep fix/SKILL.md at 299 lines (1 line headroom).

5. **S1 reference count corrections (found during validation):** build/SKILL.md has 6 `docs/claude/` references (not 5), fix/SKILL.md has 7 (not 5), review/SKILL.md has 3. All line numbers verified via grep.

6. **S4 line-shift note (found during validation):** S4's target lines in build/fix shift by +2 after S3's Stage 5 insertion. Added note to locate by content pattern rather than line number.

7. **S6 Sonnet model confirmed:** audit-epic/SKILL.md line 56 explicitly specifies `model: sonnet` for per-story review subagents. S6's ADR-008 compliance note is accurate.

8. **ADR compliance — all stories clean:** Validation confirmed zero ADR conflicts across S1-S7. Each story's ADR constraints section was verified as correct.

---

## References

- [CLAUDE.md](../../CLAUDE.md) — project conventions
- [ADR-001 through ADR-008](../../adrs/) — design decisions
- [v0.1.2 Issues List](../prompts/ruckus-v0.1.2-issues.md) — issues driving this release
- [Post-Phase 5 Review](../review-ruckus-plugin-v2.md) — review findings
