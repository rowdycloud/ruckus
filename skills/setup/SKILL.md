---
name: setup
description: "Bootstrap Ruckus for a new project. Detects maturity level, collects required project context, creates CLAUDE.md and supporting docs. Does not complete until minimum viable context is provided."
---

# Ruckus Setup

Bootstrap Ruckus for this project. Detects project maturity, collects essential context through targeted questions, and creates the documentation structure that powers all other Ruckus skills.

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
- Existing .claude/, .ruckus/, or docs/claude/ directory

Display: "Project maturity: [level] ([N] source files). Detected: [test framework], [formatter], [CI]."

---

## STEP 2: CHECK EXISTING STATE

If `docs/claude/` exists:
> "Legacy Ruckus installation detected at `docs/claude/`. Run `/ruckus:upgrade` to migrate to `.ruckus/` first, then re-run `/ruckus:setup` if needed. (proceed anyway / abort)"

Else if `.ruckus/` or `.claude/` already exists:
> "Existing Ruckus/Claude configuration detected. Options: (enrich) add missing fields / (replace) fresh setup / (abort)"

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
   *e.g., "Cannabis compliance platform for tracking inventory from seed to sale" or "Real-time multiplayer game server"*

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

Create `.ruckus/` directory if it doesn't exist.

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

`CLAUDE.md` is the canonical project context file, read by all Ruckus agents.

### 5b. known-pitfalls.md
Read `skills/setup/templates/known-pitfalls.md.template`. Replace `{{PROJECT_NAME}}` with the project name and `{{DOMAIN_DESCRIPTION}}` with the domain description from Step 3. Write to `.ruckus/known-pitfalls.md`.

### 5c. .claudeignore
Read `skills/setup/templates/claudeignore.template`. Write to `.claudeignore` (project root).

### 5d. settings.json
Create `.claude/` directory if it doesn't exist.

If a formatter was provided: read `skills/setup/templates/settings.json.template`, replace `{{FORMATTER_COMMAND}}` with the formatter command, and write to `.claude/settings.json`.

If no formatter was provided and `.claude/settings.json` does **not** already exist: write a minimal `.claude/settings.json`:
```json
{
  "hooks": {}
}
```

If `.claude/settings.json` already exists, leave it unchanged — it may contain hooks from another plugin or a prior setup run.

### 5e. workflow-upgrades
Read the current plugin version from `.claude-plugin/plugin.json` (the `version` field).

If `.ruckus/workflow-upgrades` does **not** exist: create it with the version line:
```
ruckus-version [version from plugin.json] [today's date YYYY-MM-DD]
```

If the file **already exists** (re-run / enrich mode): update or insert the `ruckus-version` line at the top, preserving all other entries (maturity check decisions from prior build/fix runs).

This file tracks plugin version (for upgrade detection) and maturity check decisions (recorded by build/fix pipelines at wrap-up).

---

## STEP 6: MATURITY-BASED OFFERS

Based on detected maturity:

**Greenfield:**
> "Project is greenfield. Ruckus will self-upgrade as it grows — investigator agent at 50+ files, Stop hook when verification matures."

**Scaffolded:**
> "Project is scaffolded. Standard configuration applied."

**Established:**
> "Project is established ([N] files). Enable the investigator agent for `/ruckus:fix`? It traces code paths to diagnose bugs. (yes / not yet)"
If yes: record `investigator-v1-added YYYY-MM-DD` in `.ruckus/workflow-upgrades`. The agent definition ships with the plugin — no file copy needed.

---

## STEP 7: SUMMARY

Display what was created:
```
# Ruckus Setup Complete

**Maturity:** [level] ([N] files)
**Created:**
- CLAUDE.md — project context for all skills
- .ruckus/known-pitfalls.md — grows as you work
- .ruckus/workflow-upgrades — tracks plugin version and maturity decisions
- .claudeignore — keeps context lean
- .claude/settings.json — [formatter hook configured / empty hooks structure]

**Next steps:**
- Run `/ruckus:build` for your first feature
- Run `/ruckus:fix` when you hit a bug
- Ruckus will self-upgrade as your project matures
```
