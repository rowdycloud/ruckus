# Implementation Plan: E03.S2 — Stop-hook-v1 maturity check completion

**Plan format version:** 1
**Branch:** `feat/S03.2-stop-hook-v1-maturity-check`
**Epic reference:** [docs/planning/epics/E03-trust-and-ergonomics.md](../planning/epics/E03-trust-and-ergonomics.md) lines 184-225

> **POST-MERGE REFINEMENT NOTICE:** This plan describes the *initially-planned* T1-T4 implementation that was approved at Stage 4. After the original commit (`fd1a2ae`), 13+ post-merge fixes refined the design substantially — most notably restructuring Branch 4 into a 4-phase deferred-write commit model (`e9da9be`), adding type-array guards to the merge path (`d1907c0`), runtime fallback in `emit_drift_json` (`50d5ae0`), Stop-hook timeout adjustments, and various rollback/cleanup semantics. **The bash code block in T1 is kept byte-identical with the live template** (last sync: `5652603`), so it always reflects current canonical hook content. **The setup-skill text snippets in T2** (e.g., the Branch 4 "If yes" instructions) **describe the original Edit A and may diverge from current `skills/setup/SKILL.md`** — cross-reference the live file for canonical current behavior. Don't recreate from this plan verbatim without checking commit history.

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

# NOTE: `set -e` is intentionally NOT used here. This Stop hook MUST exit
# 0 (informational/non-blocking contract); `set -e` would let any
# unguarded command failure (a missing path on `cd`, etc.) abort the
# script with a non-zero status and break the contract. Each potentially-
# failing command below is explicitly guarded.
#
# `shopt -s nullglob` is intentionally NOT set: this template uses no
# globs, and enabling it globally could silently drop unmatched glob
# arguments in commands users add later (lint/format opt-in blocks),
# masking failures.

# `|| true` swallows non-zero exits inside the command substitution so
# the script reaches the empty-root guard below when run outside a git
# repo (violating exit 0 otherwise).
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$ROOT" ] && exit 0
cd "$ROOT" 2>/dev/null || exit 0

issues=""

# Type check (default-on). Real newlines via $'\n' instead of literal `\n`
# strings so we can use printf '%s' below — `printf %b` would re-interpret
# backslash sequences in command output, mangling Windows paths and
# similar content.
if ! TYPE_CHECK_OUTPUT=$({{TYPE_CHECK_COMMAND}} 2>&1); then
  issues+="- type check failed:"$'\n'"${TYPE_CHECK_OUTPUT}"$'\n'
fi

# Lint check (opt-in — replace <your-lint-command> and uncomment)
# if ! LINT_OUTPUT=$(<your-lint-command> 2>&1); then
#   issues+="- lint failed:"$'\n'"${LINT_OUTPUT}"$'\n'
# fi

# Format check (opt-in — replace <your-format-check-command> and uncomment)
# if ! FORMAT_OUTPUT=$(<your-format-check-command> 2>&1); then
#   issues+="- formatting drift:"$'\n'"${FORMAT_OUTPUT}"$'\n'
# fi

emit_drift_json() {
  local m="$1" out=""
  # Each encoder attempt captures stdout into $out via $(...) and only
  # commits the output on exit-0. A runtime failure (jq OOM, python3
  # broken install, etc.) falls through to the next encoder rather than
  # silently emitting nothing — the prior structure ('if command -v jq;
  # then jq ...; elif python3 ...') would produce no output when jq
  # existed but failed at runtime, defeating the hook's enforcement
  # purpose.

  if command -v jq >/dev/null 2>&1; then
    if out=$(jq -nc --arg m "$m" '{systemMessage: $m}' 2>/dev/null); then
      printf '%s\n' "$out"
      return 0
    fi
  fi

  if command -v python3 >/dev/null 2>&1; then
    if out=$(python3 -c 'import json,sys; print(json.dumps({"systemMessage": sys.argv[1]}))' "$m" 2>/dev/null); then
      printf '%s\n' "$out"
      return 0
    fi
  fi

  # Final fallback: hand-build minimal JSON via bash parameter expansion
  # (bash 3+ syntax). Pre-strip all U+0000–U+001F control characters
  # except tab/newline/CR (which we escape explicitly below) so strict
  # JSON parsers accept the output even when input contains ANSI color
  # codes (ESC = 0x1b), form feed, vertical tab, backspace, etc.
  # Cosmetic residue from stripped ANSI sequences (e.g., '[31m'
  # fragments) may remain in the message — the result is a well-formed
  # `systemMessage` the model can always read; install jq or python3
  # for full fidelity.
  local cleaned
  cleaned=$(printf '%s' "$m" | LC_ALL=C tr -d '\000-\010\013-\014\016-\037')
  local escaped="${cleaned//\\/\\\\}"
  escaped="${escaped//\"/\\\"}"
  escaped="${escaped//$'\n'/\\n}"
  escaped="${escaped//$'\t'/\\t}"
  escaped="${escaped//$'\r'/\\r}"
  printf '{"systemMessage":"%s"}\n' "$escaped"
}

if [ -n "$issues" ]; then
  msg="verify-all drift detected:"$'\n'"${issues}"
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
  jq '.hooks.Stop = [{"hooks":[{"type":"command","command":".claude/hooks/verify-all.sh","timeout":30}]}]' .claude/settings.json > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json
  ```
  (`.claude/settings.json` is guaranteed to exist at this point — Branches 1, 2, or 3 above always create or validate it before Branch 4 runs. No "create file" step needed.)

- If `.hooks.Stop` already has an entry: prompt the human:
  > "A Stop hook is already configured in .claude/settings.json. Options: (keep) leave existing untouched / (replace) overwrite with verify-all hook / (merge) add verify-all alongside existing (both fire on every turn) / (decline) don't add"
  - **keep:** no-op. Do NOT record acceptance — the offer was effectively withdrawn. Skip the workflow-upgrades write below.
  - **replace:** overwrite via the same jq command above.
  - **merge:** first verify `.hooks.Stop` is an array (`jq -e '.hooks.Stop | type == "array"'`) — `+=` errors on non-arrays. If the type guard passes, append using `jq '.hooks.Stop += [{"hooks":[{"type":"command","command":".claude/hooks/verify-all.sh","timeout":30}]}]' ...` (note the `+=` operator — appends to the existing array).
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
- **systemMessage JSON contract:** `{systemMessage: $m}` on stdout. Encoder chain (introduced in commits `8784300` and `50d5ae0` after initial implementation): jq → python3 → bash hand-built JSON via parameter expansion, with **runtime fallback** at each level (each encoder captures stdout and only commits on exit-0; a runtime failure falls through to the next). The dogfood [.claude/hooks/verify-all.sh](../../.claude/hooks/verify-all.sh) still uses the original 2-level chain (jq → python3 → drop) — explicitly out of scope for S03.2 per AC.
