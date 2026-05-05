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

First check that `jq` is available. If unavailable, surface a Step 7 blocking-warning matching the Branch 3 pattern: `WARNING: jq not installed — could not register Stop hook in .claude/settings.json. Install jq and re-run /roughly:setup, or manually add a Stop entry pointing at .claude/hooks/verify-all.sh.` Abort Branch 4: write nothing to disk and write no `.roughly/workflow-upgrades` record (the offer is re-issued next run when jq is available).

Then validate that the existing `.claude/settings.json` parses cleanly: `jq empty .claude/settings.json`. If parse fails (e.g., Branch 3 above already detected malformed JSON and surfaced a warning but did not repair the file), surface a Step 7 warning: `WARNING: existing .claude/settings.json is invalid JSON — Stop hook not registered. Fix the file and re-run /roughly:setup.` Abort Branch 4 with no hook file write and no `.roughly/workflow-upgrades` record. This validation must happen before any disk writes — otherwise a failed jq merge below leaves the hook file orphaned without a registered Stop entry.

Otherwise: ensure `.claude/hooks/` exists (`mkdir -p .claude/hooks/`); if `mkdir` fails, surface a Step 7 warning and abort the install (no record). Then read `skills/setup/templates/verify-all-stop-hook.sh.template`, replace `{{PROJECT_NAME}}` with the project name and `{{TYPE_CHECK_COMMAND}}` with the Step 3 question 3 type-check command. Write to `.claude/hooks/verify-all.sh` and `chmod +x`.

Then add a `Stop` hook entry to `.claude/settings.json`:

- If `.hooks.Stop` is null or absent: add the entry. Use `jq`:
  ```bash
  jq '.hooks.Stop = [{"hooks":[{"type":"command","command":".claude/hooks/verify-all.sh","timeout":10}]}]' .claude/settings.json > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json
  ```
  Record `stop-hook-v1-added YYYY-MM-DD` in `.roughly/workflow-upgrades`. (`.claude/settings.json` is guaranteed to exist at this point — Branches 1, 2, or 3 above always create or validate it before Branch 4 runs.)

- If `.hooks.Stop` already has an entry: prompt the human:
  > "A Stop hook is already configured in .claude/settings.json. Options: (keep) leave existing untouched / (replace) overwrite with verify-all hook / (merge) add verify-all alongside existing (both fire on every turn) / (decline) don't add"
  - **keep:** delete `.claude/hooks/verify-all.sh` (it was already written above; the user is keeping their existing Stop hook, not ours). Record `stop-hook-v1-declined` in `.roughly/workflow-upgrades` so the offer is not re-issued. If `rm` fails, surface a Step 7 warning: `WARNING: could not remove .claude/hooks/verify-all.sh — delete manually.`
  - **replace:** overwrite via the same jq command above. Record `stop-hook-v1-added YYYY-MM-DD` in `.roughly/workflow-upgrades`.
  - **merge:** first verify `.hooks.Stop` is an array (`jq -e '.hooks.Stop | type == "array"' .claude/settings.json`); if not (e.g., a hand-edited single object), surface a Step 7 warning: `WARNING: .claude/settings.json .hooks.Stop is not an array — cannot merge. Convert to array form manually and re-run.` Delete the just-written `.claude/hooks/verify-all.sh` (rm-failure → Step 7 warning), abort the merge with no `.roughly/workflow-upgrades` record. If the array check passes: append using `jq '.hooks.Stop += [{"hooks":[{"type":"command","command":".claude/hooks/verify-all.sh","timeout":10}]}]' .claude/settings.json > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json` (note the `+=` operator — appends to the existing array). Record `stop-hook-v1-added YYYY-MM-DD` in `.roughly/workflow-upgrades`.
  - **decline:** delete `.claude/hooks/verify-all.sh` (it was already written above). If `rm` fails, surface a Step 7 warning: `WARNING: could not remove .claude/hooks/verify-all.sh — delete manually.` Record `stop-hook-v1-declined` in `.roughly/workflow-upgrades`.

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
If the Step 3 question 3 type-check command is set (not `none`):
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
