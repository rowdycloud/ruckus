---
name: setup
description: "Bootstrap Roughly for a new project. Detects maturity level, collects required project context, creates CLAUDE.md and supporting docs. Does not complete until minimum viable context is provided."
---

# Roughly Setup

Bootstrap Roughly for this project. Detects project maturity, collects essential context through targeted questions, and creates the documentation structure that powers all other Roughly skills.

**Setup does NOT complete until required fields are provided.**

---

## STEP 1: DETECT MATURITY

Count source files (exclude node_modules, vendor, build, dist, .git):

```bash
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.swift" -o -name "*.kt" \) -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/.git/*" -not -path "*/build/*" -not -path "*/dist/*" | wc -l
```

Classify:
- **Greenfield** (<10 source files): Skip investigator, simplify verify-all, omit Stop hook
- **Scaffolded** (10-50): Standard setup
- **Established** (50+): Full setup including investigator agent offer

Also detect:
- Test framework (jest, vitest, pytest, go test, etc.)
- Formatter (prettier, black, gofmt, etc.)
- CI configuration (.github/workflows, .gitlab-ci, etc.)
- Existing .claude/, .ruckus/, .roughly/, or docs/claude/ directory

Display: "Project maturity: [level] ([N] source files). Detected: [test framework], [formatter], [CI]."

---

## STEP 2: CHECK EXISTING STATE

If `.ruckus/.migration-in-progress`, `.ruckus/known-pitfalls.md`, or `.ruckus/workflow-upgrades` exists:
> "Legacy `.ruckus/` state detected (v0.1.3 install or incomplete v0.1.4 migration). Run `/roughly:upgrade` first to migrate to `.roughly/` or resume, then re-run `/roughly:setup` if needed. (proceed anyway / abort)"

Else if `docs/claude/` exists:
> "Legacy Roughly installation detected at `docs/claude/`. Run `/roughly:upgrade` to migrate to `.roughly/` first, then re-run `/roughly:setup` if needed. (proceed anyway / abort)"

Else if `.roughly/` or `.claude/` already exists:
> "Existing Roughly/Claude configuration detected. Options: (enrich) add missing fields / (replace) fresh setup / (abort)"

If enriching, read existing files and identify gaps: any of the 6 required fields (Step 3) that are missing, empty, or contain placeholder text ("TBD", "TODO", template markers like `{{...}}`). Exception: for the type-check and test-command fields only, answers like "none", "none yet", or other deliberate opt-outs are valid — do not treat them as gaps. Only prompt for gap fields — preserve all existing non-gap content.

---

## STEP 3: COLLECT REQUIRED CONTEXT

These fields are **required**. Setup does not proceed without them.

Ask each question. If the human provides "skip" or refuses, explain why it matters and ask again. Only proceed when all 6 are provided.

1. **Stack:** "What's your tech stack? (language, framework, key libraries)"
   *e.g., "TypeScript, Next.js 14, Prisma, PostgreSQL" or "Python 3.12, FastAPI, SQLAlchemy"*
2. **Build command:** "What command builds the project? (e.g., `npm run build`, `go build ./...`)"
   *e.g., `npm run build`, `go build ./...`, `cargo build`*
3. **Type check:** "What command type-checks? (e.g., `npx tsc --noEmit`, `mypy .`, or 'none')"
   *e.g., `npx tsc --noEmit`, `mypy .`, `none`*
4. **Test command:** "What command runs tests? (e.g., `npm test`, `pytest`, or 'none yet')"
   *e.g., `npm test`, `pytest -x`, `none yet`*
5. **Convention:** "What's the one pattern or convention agents must always follow in this project?"
   This is the single most impactful field. Think: what rule would you put in a code review checklist?
   *e.g., "All API routes must validate input with Zod schemas before processing" or "Repository pattern — data access only through repository classes, never direct DB queries in handlers"*
6. **Domain:** "In one sentence, what does this project do?"
   *e.g., "E-commerce platform tracking orders from cart to delivery" or "Real-time multiplayer game server"*

**Gate:** Confirm all 6 required fields have non-empty, non-placeholder values. If any field is missing or contains only "TBD", "TODO", "skip", or similar placeholders, loop back to that specific question. Exception: for type-check and test-command, answers like "none" or "none yet" are valid opt-outs — accept them. Do not proceed to Step 4 until all 6 fields have substantive answers.

---

## STEP 4: COLLECT OPTIONAL CONTEXT

Prompt but don't block on:

- **Formatter:** "What formatter do you use? (for auto-format hook — e.g., `npx prettier --write`, `black`, or 'none')"
- **Architecture:** "Any architecture patterns to know? (e.g., repository pattern, service layer, hexagonal)"
- **Cross-boundary:** "Any cross-boundary concerns? (e.g., native bridge, client/server split, multi-device)"
- **Docs:** "Where are architecture docs or ADRs? (path or 'none')"

---

## STEP 5: CREATE FILES

Create `.roughly/` directory if it doesn't exist.

### 5a. CLAUDE.md
Read `skills/setup/templates/CLAUDE.md.template`. Derive `{{PROJECT_NAME}}` from the repo directory name (or package.json `name` field if available). Replace all `{{PLACEHOLDER}}` markers with collected values:
- `{{PROJECT_NAME}}` — derived from repo/package name
- `{{DOMAIN_DESCRIPTION}}` — from Step 3 question 6
- `{{STACK_SUMMARY}}` — from Step 3 question 1 (full answer)
- `{{BUILD_COMMAND}}`, `{{TYPE_CHECK_COMMAND}}`, `{{TEST_COMMAND}}` — from Step 3
- `{{FORMATTER_COMMAND}}` — from Step 4 (if provided, otherwise remove the Format row)
- `{{CONVENTIONS}}` — from Step 3 question 5
- `{{ARCHITECTURE_NOTES}}`, `{{CROSS_BOUNDARY_NOTES}}`, `{{ADR_LOCATION}}` — from Step 4 (if not provided, write "None documented yet")

**If no formatter was provided:** Remove the entire `| Format | ... |` row from the Commands table. Do not leave a row with an empty command.

Write to root `CLAUDE.md`.

`CLAUDE.md` is the canonical project context file, read by all Roughly agents.

### 5b. known-pitfalls.md
Read `skills/setup/templates/known-pitfalls.md.template`. Replace `{{PROJECT_NAME}}` with the project name and `{{DOMAIN_DESCRIPTION}}` with the domain description from Step 3. Write to `.roughly/known-pitfalls.md`.

### 5c. .claudeignore
Read `skills/setup/templates/claudeignore.template`. Write to `.claudeignore` (project root).

### 5d. settings.json

**Hook script (unconditional — do this first, before any settings.json branch):**
Create `.claude/hooks/` if it doesn't exist. Copy `skills/setup/templates/plan-mode-gate.sh.template` to `.claude/hooks/plan-mode-gate.sh`. Set the executable bit (`chmod +x .claude/hooks/plan-mode-gate.sh`).

---

**Branch 1 — formatter was provided:**
Read `skills/setup/templates/settings.json.template`, replace `{{FORMATTER_COMMAND}}` with the formatter command, and write to `.claude/settings.json`. The template already contains both `PostToolUse` (formatter) and `UserPromptSubmit` (plan-mode-gate) entries — no additional merging required.

**Branch 2 — no formatter provided AND `.claude/settings.json` does not exist:**
Write a minimal `.claude/settings.json` that registers the plan-mode-gate hook:
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/plan-mode-gate.sh"
          }
        ]
      }
    ]
  }
}
```

**Branch 3 — no formatter provided AND `.claude/settings.json` already exists:**
(When formatter IS provided, Branch 1 wins regardless of whether settings.json exists — Branch 1 overwrites with the template. This is the pre-S1 behavior, preserved for backwards compatibility. Users with both a formatter and customizations in settings.json should run setup once without a formatter, then add their formatter manually.)

First check whether `jq` is available (`command -v jq`). If `jq` is unavailable, halt this branch and surface a blocking-warning in Step 7 summary: `WARNING: jq not installed — could not register plan-mode-gate hook in existing .claude/settings.json. Install jq and re-run /roughly:setup, or manually add a UserPromptSubmit entry pointing at .claude/hooks/plan-mode-gate.sh.` (Skip the merge below.)

If `jq` is available, validate the existing file parses cleanly first: `jq empty .claude/settings.json`. If parse fails, halt this branch and surface: `WARNING: existing .claude/settings.json is invalid JSON — plan-mode-gate not registered. Fix the file and re-run /roughly:setup.` (Skip the merge.)

Only when both checks pass, inspect `.hooks.UserPromptSubmit`:

- If `.hooks.UserPromptSubmit` is null or absent: add a UserPromptSubmit entry pointing at `.claude/hooks/plan-mode-gate.sh` while preserving every other field. Use `jq` to merge:
  ```bash
  jq '.hooks.UserPromptSubmit = [{"hooks":[{"type":"command","command":".claude/hooks/plan-mode-gate.sh"}]}]' .claude/settings.json > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json
  ```
- If `.hooks.UserPromptSubmit` already has any entry: do NOT overwrite it. Surface a blocking-warning in Step 7 summary: `WARNING: existing UserPromptSubmit hook detected at .claude/settings.json — plan-mode-gate.sh not registered. Verify manually that plan-mode protection is in place.` This warning MUST appear in the Step 7 summary output (not just inline log noise) so the human sees it.

---

**Branch 4 — stop-hook-v1 was accepted in Step 6 below:**
(This branch runs only if the Step 6 offer was accepted. Execution order is 5a→5b→5c→5d Branches 1–3→6→5d Branch 4→5e→7. If declined or not offered, skip.)

**Branch 4 invariant — collect ALL decisions BEFORE any disk mutations.** This branch can prompt the user twice (settings-conflict and file-conflict). Every prompt outcome must be resolved into a final install plan BEFORE we write or delete any file. Otherwise the second prompt's abort path can destroy state the first prompt's choice authorized only conditionally.

**Step A — read-only checks (no disk writes).**

First check that `jq` is available. If unavailable, surface a Step 7 blocking-warning matching the Branch 3 pattern: `WARNING: jq not installed — could not install Stop hook. Install jq and re-run /roughly:setup.` Abort Branch 4: write nothing to disk and write no `.roughly/workflow-upgrades` record. Do NOT direct the user toward a manual install path — Branch 4 writes nothing on this branch.

If `.claude/settings.json` exists, validate it parses cleanly: `jq empty .claude/settings.json`. If parse fails (file exists but JSON is malformed), surface a Step 7 warning: `WARNING: existing .claude/settings.json is invalid JSON — Stop hook not registered. Fix the file and re-run /roughly:setup.` Abort with no record. If `.claude/settings.json` does NOT exist, do NOT abort — proceed to Step D, where item 3's defensive-creation path will produce a minimal valid file before jq runs. (The file-missing case is unexpected per the Branch 1/2/3 invariant, but defensive handling lives in Step D so this read-only step doesn't need to write.)

**Step B — settings-conflict resolution (prompt may fire; no disk writes yet).**

The binary question this step resolves is: **does the user already have a Stop hook configured?** Two outcomes only — "no Stop hook" (the no-conflict path) or "Stop hook present" (prompt for conflict resolution). Use the file inspection below to decide; do NOT inspect via `jq` if `.claude/settings.json` does not exist (jq errors on missing files) — instead treat missing-file as "no Stop hook" (logically the same as `.hooks.Stop` being absent).

Inspect `.hooks.Stop`:

- **No Stop hook configured** — `.claude/settings.json` is missing, OR `.hooks.Stop` is null, absent (`.hooks.Stop` field doesn't exist in the JSON), or an empty array (`[]`): plan is **add-new** (jq command will be `'.hooks.Stop = [...]'`). Skip the conflict prompt entirely.
- **Stop hook configured** — `.hooks.Stop` is a non-empty array (i.e., it contains one or more existing entries): prompt the human:
  > "A Stop hook is already configured in .claude/settings.json. Options: (keep) leave existing untouched / (replace) overwrite with verify-all hook / (merge) add verify-all alongside existing (both fire on every turn) / (decline) don't add"
  - **keep:** plan is **abort-passive**. Do NOT write the hook file, do NOT modify `.claude/settings.json`, do NOT delete any pre-existing `.claude/hooks/verify-all.sh`, and **do NOT record** `stop-hook-v1-declined` (this was passive preservation of an existing Stop hook, not active rejection — recording `-declined` would suppress build/fix Stage 8's offer per its `not declined` gate, which would be too permanent for "I have my own hook right now"). Return from Branch 4. (Note: build/fix Stage 8's gate also self-suppresses when `.hooks.Stop` is non-empty, so re-prompts won't loop the user.)
  - **decline:** plan is **abort-declined** (active rejection). Record `stop-hook-v1-declined` in `.roughly/workflow-upgrades` (matches Step 6's `never` semantics — suppresses future build/fix Stage 8 offers). Do NOT write the hook file, do NOT modify `.claude/settings.json`, do NOT delete any pre-existing `.claude/hooks/verify-all.sh`. Return from Branch 4.
  - **replace:** plan is **replace** (jq command `'.hooks.Stop = [...]'`).
  - **merge:** verify `.hooks.Stop` is an array (`jq -e '.hooks.Stop | type == "array"' .claude/settings.json`); if not (e.g., a hand-edited single object), surface a Step 7 warning: `WARNING: .claude/settings.json .hooks.Stop is not an array — cannot merge. Convert to array form manually and re-run.` Abort with no record. If the array check passes: plan is **merge** (jq command `'.hooks.Stop += [...]'`).
- `.hooks.Stop` exists but is not an array: surface a Step 7 warning: `WARNING: .claude/settings.json .hooks.Stop is not an array (Claude Code hooks contract requires array form) — Stop hook not registered. Fix manually and re-run.` Abort with no record.

**Step C — file-conflict prompt (only fires when plan will write the hook file).**

Plans **add-new**, **replace**, and **merge** all need a hook file at `.claude/hooks/verify-all.sh`. Check whether the file already exists. If it does, prompt:
> "A `.claude/hooks/verify-all.sh` already exists. Options: (overwrite) replace with the verify-all template — your existing file content will be lost / (abort) preserve the existing file and skip Stop-hook installation (no record — re-offered next setup or build/fix run)"
- **overwrite:** proceed.
- **abort:** preserve user file untouched. **Do NOT record** `stop-hook-v1-declined` (passive preservation, parallel to Step B's `keep` — recording would too-permanently suppress build/fix Stage 8 future offers). Return from Branch 4.

**Step D — commit phase (transactional: all-or-nothing).**

The previous staging-then-promote pattern matters here: if Step C's `overwrite` was chosen, a pre-existing user file is at `.claude/hooks/verify-all.sh` and would be lost the moment we write our template content directly. Step D writes to a staging path, takes a settings.json snapshot before mutating it, applies jq, promotes the staging file, and only commits the install if every step succeeds. If anything fails, the user is rolled back to a clean state: pre-existing user files at `.claude/hooks/verify-all.sh` remain byte-identical, and `.claude/settings.json` is restored to its pre-Step-D content (with one carve-out: if the snapshot step below — Step D's item 3, NOT the setup skill's top-level Step 3 — had to defensively create settings.json because the user originally had no file, rollback leaves a minimal `{"hooks":{}}` instead of restoring "no file"; the originally-empty hook configuration is recoverable but the bare-no-file precondition is not).

1. Ensure `.claude/hooks/` exists (`mkdir -p .claude/hooks/`); if `mkdir` fails, surface a Step 7 warning and abort with no record. No other state has been touched yet.
2. Read `skills/setup/templates/verify-all-stop-hook.sh.template`, replace `{{PROJECT_NAME}}` with the project name and `{{TYPE_CHECK_COMMAND}}` with the Step 3 question 3 type-check command. Write the substituted content to **`.claude/hooks/verify-all.sh.new`** (NOT to the final path), and `chmod +x` the staging file. Do NOT touch `.claude/hooks/verify-all.sh` yet.
3. Snapshot the current settings.json so we have a rollback target.
   - If `.claude/settings.json` does not exist (unexpected per the Branch 1/2/3 invariant — those branches always create or validate it before Branch 4 runs — but defensive for enrich-mode races and external deletions): first create a minimal valid settings.json for jq to modify: `printf '%s' '{"hooks":{}}' > .claude/settings.json`. Note that this defensive creation makes the rollback "byte-identical" guarantee no longer hold for users who originally had no settings.json — see step 6's rollback paragraph for the actual end state in that case.
   - Then snapshot: `cp .claude/settings.json .claude/settings.json.pre-stop-hook` (distinct from `.claude/settings.json.tmp` which jq uses internally). This snapshot is the rollback target if any later step fails.
   - If `cp` fails, abort: rm the staging `.new` file, surface a Step 7 warning with the cp error, no record.
4. Apply the pre-determined settings-install plan via jq, **referencing the final path** (`.claude/hooks/verify-all.sh`) in the registered command — that path is where the file will live once we promote the staging file at the end:

   - **add-new** or **replace:**
     ```bash
     jq '.hooks.Stop = [{"hooks":[{"type":"command","command":".claude/hooks/verify-all.sh","timeout":30}]}]' .claude/settings.json > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json
     ```
   - **merge:**
     ```bash
     jq '.hooks.Stop += [{"hooks":[{"type":"command","command":".claude/hooks/verify-all.sh","timeout":30}]}]' .claude/settings.json > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json
     ```

   (The `timeout` value is in seconds. 30 is a generous default for fast type-checks; users with slower type-checks can hand-edit `.claude/settings.json` to bump it. The earlier dogfood-only value of 10 was too aggressive for arbitrary type-checks and could silently time out without surfacing drift.)

5. If the jq command fails (disk full, write-locked, race condition): rm the staging `.new` file, rm `.claude/settings.json.tmp` (jq may have created/truncated it), rm the snapshot `.claude/settings.json.pre-stop-hook` (settings.json was never modified, so the snapshot is unused). Surface a Step 7 warning. No record.
6. On jq success: promote the staging file with `mv .claude/hooks/verify-all.sh.new .claude/hooks/verify-all.sh` (atomic within the same filesystem — `rename(2)` semantics). This is the only point where a pre-existing user file is replaced.

   If `mv` fails (typical causes: insufficient permissions on `.claude/hooks/`, read-only filesystem, file locked by another process, full disk / ENOSPC, or quota exceeded — surface the underlying error message in the warning so the user can address the specific cause):
   - **Restore settings.json from the snapshot:** `mv .claude/settings.json.pre-stop-hook .claude/settings.json`. This undoes step 4's jq write so settings.json no longer references the (now-broken) `.claude/hooks/verify-all.sh` path.
   - rm the leftover `.claude/hooks/verify-all.sh.new` (no longer referenced anywhere).
   - Surface a Step 7 warning that includes the `mv` error and suggests addressing the underlying cause and re-running.
   - No `.roughly/workflow-upgrades` record (the install is fully rolled back).

   This rollback restores the user's pre-Step-D state: settings.json has its original contents, the staging file is gone, the user's pre-existing `.claude/hooks/verify-all.sh` (if any) is untouched.

7. On full success (mv succeeded): rm `.claude/settings.json.pre-stop-hook` (no longer needed). Record `stop-hook-v1-added YYYY-MM-DD` in `.roughly/workflow-upgrades`.

### 5e. workflow-upgrades
Read the current plugin version from `.claude-plugin/plugin.json` (the `version` field).

If `.roughly/workflow-upgrades` does **not** exist: create it with the version line:
```
roughly-version [version from plugin.json] [today's date YYYY-MM-DD]
```

If the file **already exists** (re-run / enrich mode): update or insert the `roughly-version` line at the top, preserving all other entries (maturity check decisions from prior build/fix runs).

This file tracks plugin version (for upgrade detection) and maturity check decisions (recorded by build/fix pipelines at wrap-up).

---

## STEP 6: MATURITY-BASED OFFERS

Based on detected maturity:

**Greenfield:**
> "Project is greenfield. Roughly will self-upgrade as it grows — investigator agent at 50+ files, Stop hook when verification matures."

**Scaffolded:**
> "Project is scaffolded. Standard configuration applied."

**Established:**
> "Project is established ([N] files). Enable the investigator agent for `/roughly:fix`? It traces code paths to diagnose bugs. (yes / not yet)"
If yes: record `investigator-v1-added YYYY-MM-DD` in `.roughly/workflow-upgrades`. The agent definition ships with the plugin — no file copy needed.

**Established + type-check configured (additional offer):**
If the Step 3 question 3 type-check command is a real, runnable command — exclude both deliberate opt-outs (`none`, `none yet`) and any placeholder values that may have slipped past Step 3's gate (`skip`, `n/a`, `TBD`, `TODO`, blank). Step 3 explicitly accepts only `none` and `none yet` as opt-outs (placeholders loop back), but defensive exclusion here matters: if a user manually edited CLAUDE.md to a non-command value post-setup, the hook would otherwise be installed with that string substituted as `{{TYPE_CHECK_COMMAND}}` and would error every turn:
> "Add a Stop hook? It runs your type-check after every Claude turn — silent on success, surfaces drift via systemMessage. (yes / not yet / never)"
- **yes:** Branch 4 in Step 5d performs the install AND writes the appropriate `.roughly/workflow-upgrades` record itself. Each Branch 4 outcome (no-conflict install, replace, merge, keep, decline) records `-added` or `-declined` explicitly per its branch — do not write a record here in Step 6 for the yes path.
- **not yet:** no record (re-offered next build/fix run that hits the gate).
- **never:** record `stop-hook-v1-declined` in `.roughly/workflow-upgrades`.

---

## STEP 7: SUMMARY

Display what was created:
```
# Roughly Setup Complete

**Maturity:** [level] ([N] files)
**Created:**
- CLAUDE.md — project context for all skills
- .roughly/known-pitfalls.md — grows as you work
- .roughly/workflow-upgrades — tracks plugin version and maturity decisions
- .claudeignore — keeps context lean
- .claude/hooks/plan-mode-gate.sh — blocks /roughly:build and /roughly:fix when plan mode is active (ADR-009)
- .claude/settings.json — [formatter hook configured / minimal with plan-mode-gate / merged with existing]
- .claude/hooks/verify-all.sh — Stop hook running type-check after every Claude turn [INCLUDE this line ONLY if `stop-hook-v1-added` was recorded; OMIT entirely otherwise]

[Surface any Step 5d blocking-warnings (Branches 3 and 4) here, prefixed with WARNING:]

**Next steps:**
- Run `/roughly:build` for your first feature
- Run `/roughly:fix` when you hit a bug
- Roughly will self-upgrade as your project matures
```
