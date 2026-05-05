# Implementation Plan: E03.S2 — Stop-hook-v1 maturity check completion

**Plan format version:** 1
**Branch:** `feat/S03.2-stop-hook-v1-maturity-check`
**Epic reference:** [docs/planning/epics/E03-trust-and-ergonomics.md](../planning/epics/E03-trust-and-ergonomics.md) lines 184-225

## Goal

Close the `stop-hook-v1` no-op gap. Today, accepting the build/fix Stage 8 offer records a workflow-upgrades entry but installs nothing. This story ships the missing template, the setup-skill plumbing, conflict handling, and updates the build/fix Stage 8 offer text.

## Design decisions (locked from Stage 2 discovery)

1. **Type-check value:** injected at template-copy time via `{{TYPE_CHECK_COMMAND}}` substitution (matches existing `{{FORMATTER_COMMAND}}` pattern in [settings.json.template](../../skills/setup/templates/settings.json.template)).
2. **Hook filename in user project:** `.claude/hooks/verify-all.sh` (matches dogfood convention; conflict detection checks file existence at this exact path).
3. **Setup Step 6 offer gate:** fire only when `Established` maturity AND CLAUDE.md type-check command is not `none`. Skip "2+ checks" gate (verify-all is being created by setup itself).
4. **`settings.json` Stop entry:** added at acceptance time via `jq`, NOT baked into [settings.json.template](../../skills/setup/templates/settings.json.template). Avoids conditional-template complexity.
5. **Conflict handling:** keep / replace / merge / decline four-way prompt when a Stop hook already exists. Merge appends a new entry to the outer `.hooks.Stop` array (Claude Code's native multi-entry support, no wrapper script).
6. **Build/fix Stage 8 line budget:** new block must keep build SKILL.md ≤ 300 lines and fix SKILL.md ≤ 300 lines. Current: build 288, fix 291. Budget for new content: ~10 lines per file.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| skills/setup/templates/verify-all-stop-hook.sh.template | Create | T1 |
| skills/setup/SKILL.md | Modify (Step 5d new sub-step, Step 6 offer, Step 7 summary line) | T2 |
| skills/build/SKILL.md | Modify (Stage 8 `stop-hook-v1` block, lines 260-262) | T3 |
| skills/fix/SKILL.md | Modify (Stage 8 `stop-hook-v1` block, lines 263-265) | T4 |

**NOT modified** (per design decision #4): `skills/setup/templates/settings.json.template` stays as-is.

## Tasks

### T1: Create the verify-all-stop-hook template (~5 min)

**Files:** `skills/setup/templates/verify-all-stop-hook.sh.template`

**Action:** Create a new bash hook template. Project-agnostic, fast verification only, drift via `systemMessage` JSON.

**Details:** Write the file with this exact structure (no other content):

```bash
#!/usr/bin/env bash
# Stop hook: fast verification for {{PROJECT_NAME}}.
# Fires after every Claude turn. Non-blocking — informational only.
# Outputs JSON with systemMessage when drift is detected; silent otherwise.
#
# SCOPE: this hook runs ONLY fast checks (default: type-check). Slow checks
# (full test suites, production builds) are deliberately excluded — they
# would be unacceptably heavy on every Claude turn. Add slow checks to:
#   - /roughly:verify-all (manual, on demand)
#   - CI (GitHub Actions, GitLab CI, etc.)
#   - pre-commit hook (runs once per commit, blocks bad commits)
#
# To enable additional fast checks (lint, format), uncomment the relevant
# blocks below.

set -e
shopt -s nullglob

# `|| true` prevents `set -e` from exiting non-zero when this hook runs
# outside a git repo, which would violate the always-exit-0 contract.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$ROOT" ] && exit 0
cd "$ROOT"

issues=""

# Type check (default-on)
if ! TYPE_CHECK_OUTPUT=$({{TYPE_CHECK_COMMAND}} 2>&1); then
  issues="${issues}- type check failed:\n${TYPE_CHECK_OUTPUT}\n"
fi

# Lint check (opt-in — replace <your-lint-command> and uncomment)
# if ! LINT_OUTPUT=$(<your-lint-command> 2>&1); then
#   issues="${issues}- lint failed:\n${LINT_OUTPUT}\n"
# fi

# Format check (opt-in — replace <your-format-check-command> and uncomment)
# if ! FORMAT_OUTPUT=$(<your-format-check-command> 2>&1); then
#   issues="${issues}- formatting drift:\n${FORMAT_OUTPUT}\n"
# fi

emit_drift_json() {
  local m="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -nc --arg m "$m" '{systemMessage: $m}'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; print(json.dumps({"systemMessage": sys.argv[1]}))' "$m"
  fi
  # If neither is available, drop the structured output rather than emit
  # malformed JSON. The hook still exits 0 below.
}

if [ -n "$issues" ]; then
  msg=$(printf 'verify-all drift detected:\n%b' "$issues")
  emit_drift_json "$msg" || true
fi
exit 0
```

**Verify:** `bash -n skills/setup/templates/verify-all-stop-hook.sh.template` (parse-only check; the unsubstituted `{{TYPE_CHECK_COMMAND}}` token is fine — `bash -n` tokenizes literally without executing). Confirm exit 0.

**UI:** no

---

### T2: Update setup SKILL.md — install path + initial-setup offer (~5 min)

**Files:** `skills/setup/SKILL.md`

**Depends on:** T1 (the file path it references must exist)

**Action:** Three edits to setup SKILL.md.

**Details:**

**Edit A** — replace the placeholder comment at line 159 (`<!-- Future S2 additions: ... -->`) with a new sub-step:

```markdown
**Branch 4 — stop-hook-v1 was accepted in Step 6 below:**
(This branch runs only if the Step 6 offer was accepted. If declined or not offered, skip.)

Read `skills/setup/templates/verify-all-stop-hook.sh.template`, replace `{{PROJECT_NAME}}` with the project name and `{{TYPE_CHECK_COMMAND}}` with the Step 3 question 3 type-check command. Write to `.claude/hooks/verify-all.sh` and `chmod +x`.

Then add a `Stop` hook entry to `.claude/settings.json`:

- If `.claude/settings.json` does not exist OR `.hooks.Stop` is null/absent: add the entry. Use `jq`:
  ```bash
  jq '.hooks.Stop = [{"hooks":[{"type":"command","command":".claude/hooks/verify-all.sh","timeout":10}]}]' .claude/settings.json > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json
  ```
  (`.claude/settings.json` is guaranteed to exist at this point — Branches 1, 2, or 3 above always create or validate it before Branch 4 runs. No "create file" step needed.)

- If `.hooks.Stop` already has an entry: prompt the human:
  > "A Stop hook is already configured in .claude/settings.json. Options: (keep) leave existing untouched / (replace) overwrite with verify-all hook / (merge) add verify-all alongside existing (both fire on every turn) / (decline) don't add"
  - **keep:** no-op. Do NOT record acceptance — the offer was effectively withdrawn. Skip the workflow-upgrades write below.
  - **replace:** overwrite via the same jq command above.
  - **merge:** append using `jq '.hooks.Stop += [{"hooks":[{"type":"command","command":".claude/hooks/verify-all.sh","timeout":10}]}]' ...` (note the `+=` operator — appends to the existing array).
  - **decline:** record `stop-hook-v1-declined` instead of `stop-hook-v1-added`. Skip the hook copy above (delete `.claude/hooks/verify-all.sh` if already written, since user declined the merge step).

If `jq` is unavailable: surface a Step 7 blocking-warning matching the Branch 3 pattern: `WARNING: jq not installed — could not register Stop hook in .claude/settings.json. Install jq and re-run /roughly:setup, or manually add a Stop entry pointing at .claude/hooks/verify-all.sh.`
```

**Edit B** — modify the **Established** block in Step 6 (lines 185-187 currently). Replace:
```markdown
**Established:**
> "Project is established ([N] files). Enable the investigator agent for `/roughly:fix`? It traces code paths to diagnose bugs. (yes / not yet)"
If yes: record `investigator-v1-added YYYY-MM-DD` in `.roughly/workflow-upgrades`. The agent definition ships with the plugin — no file copy needed.
```

with:
```markdown
**Established:**
> "Project is established ([N] files). Enable the investigator agent for `/roughly:fix`? It traces code paths to diagnose bugs. (yes / not yet)"
If yes: record `investigator-v1-added YYYY-MM-DD` in `.roughly/workflow-upgrades`. The agent definition ships with the plugin — no file copy needed.

**Established + type-check configured (additional offer):**
If the Step 3 question 3 type-check command is set (not `none`):
> "Add a Stop hook? It runs your type-check after every Claude turn — silent on success, surfaces drift via systemMessage. (yes / not yet / never)"
- **yes:** Branch 4 in Step 5d performs the install. Record `stop-hook-v1-added YYYY-MM-DD` in `.roughly/workflow-upgrades` (UNLESS the conflict prompt resolved to `keep` — in which case no record is written).
- **not yet:** no record (re-offered next build/fix run that hits the gate).
- **never:** record `stop-hook-v1-declined` in `.roughly/workflow-upgrades`.
```

(Note: Step 5d Branch 4 logically depends on a Step 6 decision. The orchestrator must run Step 6 BEFORE the Step 5d Stop-hook sub-step. This is fine because Step 5 currently runs Branches 1-3 unconditionally; Branch 4 is gated on the Step 6 outcome and runs after. Treat the order as: 5a → 5b → 5c → 5d Branches 1-3 → 6 → 5d Branch 4 → 5e → 7. Document this in the Step 5d Branch 4 preamble.)

**Edit C** — modify the Step 7 summary template (lines 198-204). Add one line under `**Created:**` (after the `.claude/settings.json` line):

```markdown
- .claude/hooks/verify-all.sh — Stop hook running type-check after every Claude turn (only if stop-hook-v1 accepted)
```

**Verify:** `wc -l skills/setup/SKILL.md` returns ≤ 300. Confirm Edit A added a Branch 4 block. Confirm Edit B added the additional Established offer. Confirm Edit C added one bullet to the Step 7 summary.

**UI:** no

---

### T3: Update build SKILL.md — Stage 8 stop-hook-v1 block (~3 min)

**Files:** `skills/build/SKILL.md`

**Action:** Replace the existing `stop-hook-v1` check block (lines 260-262) with the templating-aware version.

**Details:** Find the exact existing text:

```markdown
**Check: stop-hook-v1:**
If `.claude/settings.json` has no `Stop` hook AND verify-all has at least 2 meaningful checks AND not declined:
> "Verification is robust enough to enforce. Add a Stop hook?"
```

Replace with:

```markdown
**Check: stop-hook-v1:**
If `.claude/settings.json` has no `Stop` entry AND verify-all has 2+ meaningful checks AND CLAUDE.md type-check is set (not `none`) AND not declined:
> "Verification is robust enough to enforce. Add a Stop hook? It runs type-check after every Claude turn — silent on success, surfaces drift. (yes / not yet / never)"

If yes: read `skills/setup/templates/verify-all-stop-hook.sh.template`, substitute `{{PROJECT_NAME}}` and `{{TYPE_CHECK_COMMAND}}` (from CLAUDE.md), write to `.claude/hooks/verify-all.sh`, `chmod +x`. Then add a `Stop` entry to `.claude/settings.json` via `jq` (create file with `{"hooks":{}}` first if absent). Record `stop-hook-v1-added YYYY-MM-DD`.

(If `.claude/settings.json` already has a `Stop` entry when this gate fires, skip silently — the gate condition above will have already excluded this run. The conflict prompt lives in setup's Step 5d Branch 4 for the initial-install path, where it is reachable.)

If never: record `stop-hook-v1-declined`. If `jq` is unavailable: warn the human and skip the install (no record either way — re-offer next run when jq is available).
```

**Verify:** `wc -l skills/build/SKILL.md` returns ≤ 300. Run `grep -n "stop-hook-v1" skills/build/SKILL.md` and confirm only the updated block appears (no stale references).

**UI:** no

---

### T4: Update fix SKILL.md — Stage 8 stop-hook-v1 block (~3 min)

**Files:** `skills/fix/SKILL.md`

**Action:** Identical text replacement to T3, but in `skills/fix/SKILL.md`. The existing block is at lines 263-265 with slightly different prose ("at least 2 meaningful checks" → "2+ meaningful checks") — the new text is identical to T3's replacement.

**Details:** Find the exact existing text:

```markdown
**Check: stop-hook-v1:**
If `.claude/settings.json` has no `Stop` hook AND verify-all has 2+ meaningful checks AND not declined:
> "Verification is robust enough to enforce. Add a Stop hook?"
```

Replace with the same multi-paragraph block from T3 (verbatim — both files must end up with identical stop-hook-v1 blocks).

**Verify:** `wc -l skills/fix/SKILL.md` returns ≤ 300. Run `diff <(awk '/^\*\*Check: stop-hook-v1:\*\*$/,/^---$/' skills/build/SKILL.md) <(awk '/^\*\*Check: stop-hook-v1:\*\*$/,/^---$/' skills/fix/SKILL.md)` and confirm zero output (blocks are identical).

**UI:** no

---

## Blast Radius

**Do NOT modify:**
- `.claude/hooks/verify-all.sh` (dogfood, project-specific, explicitly out of scope per AC)
- `.claude/settings.json` (this repo's dogfood settings)
- `skills/setup/templates/settings.json.template` (per design decision #4 — Stop entry added via jq, not baked in)
- `agents/agent-preamble.md` (no agent change needed)
- `docs/adrs/` (no new ADR — implementation of an existing maturity check, not a design change)
- Any other skills, agents, or docs

**Watch for:**
- Setup SKILL.md ordering: Step 5d Branch 4 logically depends on Step 6's outcome, so the orchestrator-execution order is 5a→5b→5c→5d(1-3)→6→5d(4)→5e→7. This must be explicit in the Branch 4 preamble or implementers/users will follow the file's top-to-bottom structure literally and skip the dependency.
- Line caps: build and fix SKILL.md hold ≤ 300 lines (currently 288/291). Verify after each task.
- Conflict matrix: `keep` must NOT write to workflow-upgrades (offer was withdrawn, not declined). `decline` records `stop-hook-v1-declined`.
- The Stop hook outer-array shape: `[ { "hooks": [ { "type": "command", "command": "..." } ] } ]` — note the nested `hooks` array. Merge uses `+=` on `.hooks.Stop`, NOT on `.hooks.Stop[0].hooks`.
- The dogfood `.claude/settings.json` already has a Stop hook (this repo's verify-all). The new Stop-hook offer would trigger conflict handling if a user ran the templated logic against this repo. That's expected — out of scope for this story; we don't dogfood the template at install time.

## Conventions

- **ADR-005 (versioned maturity checks):** `stop-hook-v1` keeps its v1 ID. No version bump (no semantic change to the offer; only the install path changes from no-op to real). Decline format: `stop-hook-v1-declined` (no date), accept format: `stop-hook-v1-added YYYY-MM-DD`.
- **Template placeholder syntax:** `{{UPPER_SNAKE}}` markers, no template engine. The setup orchestrator performs literal string substitution at copy time.
- **`disable-model-invocation: true`** is preserved on coordinator skills — none touched in this plan.
- **Skill body line cap:** ≤ 300 lines per CLAUDE.md conventions. T2 must not push setup SKILL.md past 300; T3/T4 must not push build/fix past 300.
- **Quote integrity:** the new build/fix block uses backtick `Stop` and backtick `none` — preserve them verbatim across both files.
- **systemMessage JSON contract:** matches dogfood [.claude/hooks/verify-all.sh](../../.claude/hooks/verify-all.sh) — `{systemMessage: $m}`, jq → python3 → drop fallback.
