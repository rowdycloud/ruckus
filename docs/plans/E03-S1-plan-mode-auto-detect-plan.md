# Implementation Plan: E03.S1 — Plan-mode auto-detect/exit at Stage 1 of build/fix

**Story spec:** [docs/planning/epics/E03-trust-and-ergonomics.md:101-154](../planning/epics/E03-trust-and-ergonomics.md)
**Spike findings (input):** [docs/planning/spikes/plan-mode-detection-findings.md](../planning/spikes/plan-mode-detection-findings.md)
**Branch:** `feat/S03.1-plan-mode-auto-detect`

> **Post-execution note (2026-05-03):** all references to `UserPromptExpansion` below are inherited from the spike findings doc and were corrected to `UserPromptSubmit` during S1's empirical verification on 2026-05-02. Treat any `UserPromptExpansion` mention here as historical context — see [docs/adrs/ADR-009-plan-mode-detection.md](../adrs/ADR-009-plan-mode-detection.md) "Spike-Doc Correction" section for the authoritative event name and rationale. The plan is preserved as-written for the historical record per AC10's spike-output retention decision.

## Locked-in defaults (confirmed by user before plan was written)

1. **Step 1 verification execution:** human-performed in a parallel Claude Code session; result reported back to the orchestrator at the mid-Stage-5 gate (between T1 and T2).
2. **Preamble shape:** **same-length single-line substitution** of the existing CRITICAL warning at line 11 in both `skills/build/SKILL.md` and `skills/fix/SKILL.md`. **No prose extraction**, no net-new lines. (`fix/SKILL.md` is at 299/300 — any net-new line trips the cap and the `verify-all.sh` Stop hook blocks the commit.)
3. **Hook registration scope:** prefer per-skill (command-scoped UserPromptExpansion matcher matching `/roughly:build` and `/roughly:fix`) IF Claude Code's hook API supports it; otherwise default to global registration. Decision researched in T2 and recorded in ADR-009.

## Branching contract — Step 1 outcome

The Step 1 verification result determines whether the hook chain (T3, T4, T5) executes.

- **PASS** — UserPromptExpansion fires under plan mode AND receives `permission_mode: "plan"` in stdin: dispatch T3, T4, T5.
- **FAIL** — UserPromptExpansion does NOT fire OR fires too late OR `permission_mode` is missing/wrong: skip T3, T4, T5. T2 (ADR-009), T6 (preamble), T7 (known-pitfalls), T8 (CLAUDE.md) still execute, but their **content branches** to the preamble-only fallback path.
- **INCONCLUSIVE** — verification could not be performed cleanly: per epic line 134's fallback AC, treat as FAIL (preamble-only). ADR-009 documents the inconclusive result.

## File Table

| File | Action | Task(s) | Conditional? |
|------|--------|---------|--------------|
| `docs/planning/spikes/s1-verification-harness.md` | Create | T1 | No |
| `docs/adrs/ADR-009-plan-mode-detection.md` | Create | T2 | No (content branches) |
| `.claude/hooks/plan-mode-gate.sh` | Create | T3 | YES — only on PASS |
| `skills/setup/templates/settings.json.template` | Modify | T4 | YES — only on PASS |
| `skills/setup/templates/plan-mode-gate.sh.template` | Create | T4 | YES — only on PASS |
| `skills/setup/SKILL.md` | Modify (Step 5d) | T5 | YES — only on PASS |
| `skills/build/SKILL.md` | Modify (line 11) | T6 | No (text branches) |
| `skills/fix/SKILL.md` | Modify (line 11) | T6 | No (text branches) |
| `.roughly/known-pitfalls.md` | Modify (Domain-Specific entry) | T7 | No (text branches) |
| `CLAUDE.md` | Modify (line 17 + ADR table) | T8 | No |

## Tasks

### T1: Author Step 1 verification harness doc (~5 min)

**Files:** `docs/planning/spikes/s1-verification-harness.md`

**Action:** Create a self-contained harness doc the human will follow in a parallel Claude Code session to verify that UserPromptExpansion fires under plan mode and receives `permission_mode: "plan"`.

**Details:** Doc must include:
1. **Hook script body** (a 3-5 line bash script that writes `cat /dev/stdin` to `/tmp/uphook-test.log` and exits 0 — does NOT block the prompt; non-blocking is critical so the test does not interfere with the parallel session).
2. **Settings.json snippet** to register the hook under `UserPromptExpansion`. Include both forms: a global registration (no matcher) and a per-skill registration (matcher that targets `/roughly:build` or any roughly slash-command). The human will test the global form first; per-skill is a follow-up if global confirms.
3. **Step-by-step protocol:**
   - Create temp dir `/tmp/s1-verify`
   - `cd /tmp/s1-verify && mkdir -p .claude/hooks`
   - Paste hook script as `.claude/hooks/log-stdin.sh`, chmod +x
   - Paste settings.json under `.claude/settings.json`
   - `truncate -s 0 /tmp/uphook-test.log`
   - Start `claude --permission-mode plan` from `/tmp/s1-verify`
   - In the new session, type any user prompt (e.g., "hi")
   - In a separate terminal, `cat /tmp/uphook-test.log`
   - Inspect the log: did the hook fire? What stdin JSON was received? Is `permission_mode: "plan"` present?
4. **PASS criteria:** log contains a JSON line with `"permission_mode": "plan"`.
5. **FAIL criteria:** log is empty (hook didn't fire) OR log entry lacks `permission_mode` OR field value is not `"plan"`.
6. **INCONCLUSIVE criteria:** any other anomaly (hook fires partially, log shows error, plan mode doesn't engage).
7. **Bonus test (S1 next-step #4 from spike):** brief instructions for testing whether `ExitPlanMode`, called from a skill body, exits cleanly or blocks. This is informational for ADR-009; not a gate.
8. **What to paste back:** the contents of `/tmp/uphook-test.log` and a one-word verdict (PASS / FAIL / INCONCLUSIVE).

The doc should be written so a human can complete it in 5–10 minutes without prior context.

**Verify:** `wc -l docs/planning/spikes/s1-verification-harness.md` returns at least 30 lines; the doc is self-contained (a reader can perform the test without consulting any other file in the repo).

**UI:** no

---

### MID-STAGE-5 HUMAN GATE (after T1, before T2)

After T1 completes, the orchestrator must pause and ask the human:

> "Verification harness is at `docs/planning/spikes/s1-verification-harness.md`. Please run it in a parallel Claude Code session and paste back the verdict (PASS / FAIL / INCONCLUSIVE) plus the captured log contents. I will use the result to write ADR-009 (T2) and decide whether to dispatch the conditional hook tasks (T3, T4, T5)."

The orchestrator does NOT proceed past this gate until the human reports the result.

---

### T2: Draft ADR-009 (~10 min, depends on human gate result)

**Files:** `docs/adrs/ADR-009-plan-mode-detection.md`

**Action:** Author ADR-009 documenting the chosen detection mechanism, the empirical verification result from Step 1, the ADR-001 distinction, the hook registration scope decision, the manual-sync targets, and known edge cases.

**Details:** Required sections:
- **Status:** Accepted
- **Context:** plan-mode hijack of build/fix Stages 1–4; existing CRITICAL warning is bypassed structurally (auto-engagement at SessionStart fires before the skill body is read); reference [docs/planning/spikes/plan-mode-detection-findings.md](../planning/spikes/plan-mode-detection-findings.md) for the full evidence base.
- **Decision (PASS branch):** preamble (substitution at line 11) + UserPromptExpansion hook reading `permission_mode` from stdin and blocking when value is `"plan"`. Hook ships at `.claude/hooks/plan-mode-gate.sh` and is templated into user projects via `skills/setup/templates/plan-mode-gate.sh.template` and `skills/setup/templates/settings.json.template`.
- **Decision (FAIL/INCONCLUSIVE branch):** preamble-only (substitution at line 11). Hook is NOT shipped. The structural-bypass gap documented in the spike is left explicit in known-pitfalls.md as an enforcement gap S1 cannot close.
- **Empirical verification results:** verbatim summary of human's Step 1 verdict (PASS / FAIL / INCONCLUSIVE) plus the captured log excerpt. If FAIL, include a one-paragraph note on what was observed and why the hook mechanism is not viable.
- **ADR-001 distinction:** quote ADR-001's hook-rejection sentence verbatim. Argue (a) invocation gate vs. mid-pipeline state — UserPromptExpansion fires before any pipeline stage exists; (b) harness-owned data (`permission_mode` in stdin JSON) vs. pipeline-internal data (Stage 4 completion). Mirror the structure from spike findings lines 239–244.
- **Hook registration scope decision:** record per-skill-vs-global. As part of authoring this ADR, the subagent must research the current Claude Code hooks docs (https://docs.anthropic.com/en/docs/claude-code/hooks) to determine whether UserPromptExpansion supports a command-scoped matcher. If yes, recommend per-skill (matcher targeting `/roughly:build` and `/roughly:fix`). If no, recommend global with a documented tradeoff (the hook will fire on every user prompt; the script must short-circuit cheaply when the prompt is not a roughly invocation).
- **Manual sync targets:** `skills/build/SKILL.md:11` and `skills/fix/SKILL.md:11` (2-file scope, build/fix only — not tied to `agents/agent-preamble.md`'s sync list).
- **Known edge cases:** `defaultMode: "plan"` in user's settings.json is the most likely silent-engagement path; `Shift+Tab` toggle mid-session is out of scope; ExitPlanMode interactive semantics (note bonus-test result from T1 if collected, otherwise note "untested in S1").
- **Spike output retention decision:** keep `docs/planning/spikes/plan-mode-detection-findings.md` as historical reference; ADR-009 references it.

The ADR text must explicitly reflect the verification result (PASS or FAIL/INCONCLUSIVE branch) — the subagent will be told which branch to write.

**Verify:** `ls docs/adrs/ADR-009-plan-mode-detection.md`; file exists and has Status, Context, Decision, ADR-001 distinction, Empirical verification, Hook registration scope, Sync targets, Edge cases sections. `wc -l` ≥ 50.

**UI:** no

---

### T3: Write the UserPromptExpansion hook script (CONDITIONAL on PASS, ~3 min)

**Files:** `.claude/hooks/plan-mode-gate.sh`

**Depends on:** T2 (registration scope decision determines matcher behavior, but the hook script itself is the same either way)

**Action:** Write a bash hook script that reads JSON from stdin, extracts `permission_mode`, and blocks with a `decision: "block"` JSON response if the value is `"plan"`.

**Note on file purpose:** `plan-mode-gate.sh` is placed in `.claude/hooks/` as the canonical source for T4's template copy — it is **NOT** registered in this repo's `.claude/settings.json`. This repo's active hooks remain limited to the Stop hook (`verify-all.sh`). The hook is for user projects only. Developers who want to dogfood it locally must manually add a UserPromptExpansion entry to `.claude/settings.json` for the test duration, then revert.

**Details:**
- Script reads stdin into a variable, uses `jq` (acceptable dependency — `.claude/hooks/verify-all.sh` already uses jq at lines 44-45; if absent on a target system, fall back to a regex match on `"permission_mode"\s*:\s*"plan"`).
- If `permission_mode == "plan"`: emit JSON to stdout: `{"decision": "block", "reason": "Roughly pipelines cannot run while Claude Code's plan mode is active. Exit plan mode (Shift+Tab) and re-invoke."}` and exit 0.
- Otherwise: exit 0 silently (no output — the prompt continues normally).
- Script must short-circuit cheaply on non-plan prompts (the global-registration case — fires on every prompt — must not add noticeable latency).
- Add `#!/usr/bin/env bash` shebang and `set -euo pipefail`.
- Make file executable (the implementer subagent must `chmod +x` after writing).

**Verify:** `bash -n .claude/hooks/plan-mode-gate.sh` (syntax check passes); `[ -x .claude/hooks/plan-mode-gate.sh ]` (executable bit set); a quick smoke test: `echo '{"permission_mode": "plan"}' | bash .claude/hooks/plan-mode-gate.sh` outputs the expected block-JSON; `echo '{"permission_mode": "default"}' | bash .claude/hooks/plan-mode-gate.sh` outputs nothing and exits 0.

**UI:** no

---

### T4: Update settings.json.template + add hook script template (CONDITIONAL on PASS, ~5 min)

**Files:**
- `skills/setup/templates/settings.json.template` (modify)
- `skills/setup/templates/plan-mode-gate.sh.template` (create — exact copy of `.claude/hooks/plan-mode-gate.sh` from T3, so user installs get the same script via `/roughly:setup`)

**Depends on:** T2 (scope decision), T3 (hook script body)

**Action:** Add the UserPromptExpansion hook registration to `settings.json.template`. Create a sibling `plan-mode-gate.sh.template` so `/roughly:setup` can copy the hook script into the user's `.claude/hooks/` directory.

**Details:**
- For settings.json.template: add a `UserPromptExpansion` entry under the existing `hooks` object. Use the per-skill matcher form if T2's research confirmed support; otherwise use the global form. Include a comment marker if the file format supports it (JSON does not — but the matcher value itself can document the scope).
- The template file `plan-mode-gate.sh.template` is a verbatim copy of `.claude/hooks/plan-mode-gate.sh` written by T3.
- The existing PostToolUse formatter entry must be preserved; this is purely additive.
- Must NOT collide with E03.S2's planned Stop-hook-v1 maturity check: the new `UserPromptExpansion` key sits at the same level as `PostToolUse` and a future `Stop` key.

**Verify:** `cat skills/setup/templates/settings.json.template | jq .` (parses as valid JSON); the existing PostToolUse block is unchanged; the new UserPromptExpansion block matches the scope decision in ADR-009; `[ -f skills/setup/templates/plan-mode-gate.sh.template ]` and `diff .claude/hooks/plan-mode-gate.sh skills/setup/templates/plan-mode-gate.sh.template` produces no output.

**UI:** no

---

### T5: Update setup/SKILL.md Step 5d to copy the hook (CONDITIONAL on PASS, ~5 min)

**Files:** `skills/setup/SKILL.md` (modify Step 5d only — currently lines 113–125)

**Depends on:** T4

**Action:** Extend Step 5d so that during `/roughly:setup`, (a) the plan-mode-gate hook script is copied into the user's `.claude/hooks/` directory unconditionally, and (b) UserPromptExpansion is registered in the user's `.claude/settings.json` across **all three** Step 5d branches (formatter-provided, no-formatter-no-settings, settings-already-exists).

**Details:**
- **Hook script copy (unconditional):** copy `skills/setup/templates/plan-mode-gate.sh.template` to `<user-project>/.claude/hooks/plan-mode-gate.sh`, set executable bit. This runs in all three Step 5d branches.
- **Branch 1 (formatter provided):** the existing template-substitution path now naturally includes UserPromptExpansion because T4 added it to `settings.json.template`. Verify the substitution preserves the new entry.
- **Branch 2 (no formatter, settings.json absent):** change the minimal write from `{"hooks": {}}` to a JSON containing the UserPromptExpansion entry (and an empty PostToolUse if needed for forward-compat). The exact JSON should mirror the UserPromptExpansion block from `settings.json.template` (T4) so the two branches produce equivalent enforcement state.
- **Branch 3 (settings.json already exists):** add a merge sub-step. Read existing settings.json with `jq`, check `.hooks.UserPromptExpansion`. If absent, add the entry preserving all other content; if present, leave unchanged (the user may have customized it). Do NOT overwrite an existing UserPromptExpansion entry — log a one-line note that registration was skipped and instruct the user to manually verify.
- **Structure for S2 forward-compat:** keep the additions clearly delineated (section break or sub-step heading) so E03.S2 can append a Stop-hook block to the same Step 5d without merge churn.
- Do NOT renumber sub-steps if doing so would invalidate cross-references elsewhere in the SKILL.md (search for "Step 5d" elsewhere first).

**Verify:** `grep -n "plan-mode-gate" skills/setup/SKILL.md` finds the new sub-step in all three branches; manual smoke test for at least branches 1 and 2: in a temp project run `/roughly:setup` (or simulate by invoking the relevant logic) and confirm `cat .claude/settings.json | jq '.hooks.UserPromptExpansion'` returns the hook entry; the formatter logic at the original location is functionally preserved (diff to confirm only the additive change).

**UI:** no

---

### T6: Update preamble line 11 in build/SKILL.md and fix/SKILL.md (~5 min)

**Files:**
- `skills/build/SKILL.md` (modify line 11)
- `skills/fix/SKILL.md` (modify line 11)

**Depends on:** T2 (verification result determines wording)

**Action:** Replace line 11 in both files with a single line of new wording that reflects the chosen mechanism. Preserve total file line count exactly (substitution-only — no net new lines).

**Details:**
- **PASS branch wording (single line):** `**CRITICAL:** This skill detects Claude Code's plan mode at invocation and blocks. If active, exit plan mode (Shift+Tab) and re-invoke. Pipeline gates are inline conversation prompts — never use EnterPlanMode/ExitPlanMode mid-pipeline.`
- **FAIL/INCONCLUSIVE branch wording (single line):** `**CRITICAL:** Do NOT invoke this skill while Claude Code's plan mode is active — plan mode hijacks Stages 1–4 silently. Exit plan mode (Shift+Tab) before invoking, and never use EnterPlanMode/ExitPlanMode mid-pipeline.`
- Must be byte-identical between `build/SKILL.md` and `fix/SKILL.md`. The two-file scope is captured in ADR-009.
- File line count must NOT change. Verify with `wc -l` before and after — both files must show identical totals to before the edit (296 for build, 299 for fix).

**Verify:** `wc -l skills/build/SKILL.md` returns `296`; `wc -l skills/fix/SKILL.md` returns `299`; `diff <(sed -n '11p' skills/build/SKILL.md) <(sed -n '11p' skills/fix/SKILL.md)` produces no output (lines match exactly); the new line 11 contains "CRITICAL" and "plan mode".

**UI:** no

---

### T7: Update .roughly/known-pitfalls.md plan-mode entry (~5 min)

**Files:** `.roughly/known-pitfalls.md` (modify the Domain-Specific plan-mode hijack entry — currently around line 14)

**Depends on:** T2

**Action:** Rewrite the existing plan-mode hijack entry to reflect the new enforcement state.

**Details:**
- **PASS branch:** rewrite the entry as "blocked by S1 enforcement." Describe the hook gate, the block message, and the recovery flow ("if you see the block, exit plan mode and re-invoke"). Reference ADR-009.
- **FAIL/INCONCLUSIVE branch:** keep the entry as a documented enforcement gap. Update the recovery instruction (now somewhat tightened by the preamble update from T6) but explicitly note that S1 could not close the structural bypass and that future work would need a different mechanism. Reference ADR-009 and the spike findings doc.
- The subagent must locate the entry (it begins with `**Plan mode (Claude Code's built-in) hijacks the build/fix pipeline.**`) and replace it in place; do not add a duplicate entry.
- Length budget: ≤ existing length + 30%. Don't bloat known-pitfalls.md.

**Verify:** `grep -c "Plan mode (Claude Code's built-in) hijacks" .roughly/known-pitfalls.md` returns `1` (no duplication); the new entry text contains "ADR-009"; the entry's category remains Domain-Specific (no section change).

**UI:** no

---

### T8: Update CLAUDE.md (~3 min)

**Files:** `CLAUDE.md` (two surgical edits)

**Depends on:** T2

**Action:** Update the ADR count in the structure table at line 17 and add an ADR-009 row to the Key Design Decisions table at lines 49–58.

**Details:**
- **Edit 1, line 17:** Change `Architecture Decision Records (ADR-001 through ADR-008)` → `Architecture Decision Records (ADR-001 through ADR-009)`.
- **Edit 2, after line 58:** Append a new table row: `| ADR-009 | Plan-mode auto-detect: <one-line summary matching ADR-009's Decision> |`. The summary text must be ≤ 80 characters and convey the chosen mechanism (e.g., "Detect plan mode at invocation via UserPromptExpansion hook + preamble" for PASS, or "Plan-mode detection deferred — preamble-only substitution; structural gap documented" for FAIL).
- If T3, T4, T5 ran (PASS branch), also update CLAUDE.md's Structure section if the new hook script warrants a row. Practically: the `.claude/hooks/` row already exists implicitly via the project's standard structure; do NOT add a new row unless the existing structure clearly omits hooks.

**Verify:** `grep -c "ADR-001 through ADR-009" CLAUDE.md` returns `1`; `grep -c "ADR-001 through ADR-008" CLAUDE.md` returns `0`; `grep "ADR-009" CLAUDE.md` returns the new row in the Key Design Decisions table.

**UI:** no

---

## Blast Radius

**Do NOT modify:**
- Any existing ADRs (`docs/adrs/ADR-001` through `ADR-008`).
- The PostToolUse formatter block in `skills/setup/templates/settings.json.template` (T4 is additive only).
- The agent-preamble.md sync list at `agents/agent-preamble.md` — S1's preamble sync is build/fix only, not via the agent-preamble pattern.
- Any other line in `skills/build/SKILL.md` or `skills/fix/SKILL.md` besides line 11 (T6 is line-11-only).
- Any other entry in `.roughly/known-pitfalls.md` besides the plan-mode hijack entry (T7 is single-entry).
- `skills/setup/SKILL.md` outside Step 5d (T5 is Step-5d-only).

**Watch for:**
- The `verify-all.sh` Stop hook: it enforces line caps (296→300, 299→300). T6 must preserve line counts exactly. If T6's substitution accidentally adds a line, the commit will be blocked and Stage 7 will fail.
- E03.S2 will also touch Step 5d. T5 must structure additions to be clearly delineated so S2 can append cleanly.
- The dogfood `.claude/hooks/verify-all.sh` is a Stop hook for THIS repo; T3's new `plan-mode-gate.sh` is a UserPromptExpansion hook for user projects. Different events, different purposes — do not confuse them.
- The user's `.claude/settings.json` may already exist with custom content. The setup skill's Step 5d must merge, not overwrite. Confirm existing logic before adding the UserPromptExpansion entry (T5 task verification).

## Conventions

- **ADR-003** reference-copy pattern: NOT used here (substitution-only preamble update; no extraction needed).
- **ADR-001** hook-rejection precedent: T2 (ADR-009) explicitly distinguishes from this; no compromise of ADR-001's stance.
- **CLAUDE.md** "all significant design changes need ADRs" — satisfied by T2 (ADR-009).
- **Maturity check IDs are versioned** (CLAUDE.md convention) — not relevant here (this is not a maturity check addition).
- **Pipeline skills `disable-model-invocation: true`** — preserved (T6 only touches line 11, not frontmatter).

## Branching matrix (concise)

| Verification verdict | T2 (ADR-009) | T3 hook | T4 template | T5 setup | T6 preamble | T7 known-pitfalls | T8 CLAUDE.md |
|----------------------|--------------|---------|-------------|----------|-------------|--------------------|--------------|
| PASS | PASS-branch text | yes | yes | yes | PASS wording | "blocked by S1" wording | yes |
| FAIL or INCONCLUSIVE | FAIL-branch text | skip | skip | skip | FAIL wording | "enforcement gap" wording | yes |
