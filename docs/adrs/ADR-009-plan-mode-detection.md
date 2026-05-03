# ADR-009: Plan-Mode Auto-Detection at Skill Invocation

**Date:** 2026-05
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

Claude Code's built-in plan mode runs a Phase 1–5 workflow (analyze → plan → confirm → implement → summarize) via its own `Plan` subagent and `ExitPlanMode` tool. When plan mode is active during a `/roughly:build` or `/roughly:fix` invocation, it substitutes its own workflow for the pipeline's Stages 1–4. This is not a graceful override — it is a silent replacement. The pipeline's Stage 4 gate (the blocking `/roughly:review-plan` subagent dispatch, established in ADR-001) is never reached. Instead, plan-mode's `Plan` subagent performs a generic implementation design pass that returns no PASS/NEEDS REVISION verdict and does not check the codebase against spec. The human has no visible signal that the correct pipeline did not run.

The existing CRITICAL warning at `skills/build/SKILL.md:11` and `skills/fix/SKILL.md:11` reads: "Do NOT use Claude Code's built-in plan mode." Despite this warning, the hijack can occur via plan mode's auto-engagement at SessionStart, which fires before the skill body is read. The preamble is bypassed structurally — not read and ignored. No preamble improvement can close a gap that exists before the preamble is reached. This structural bypass is documented in `.roughly/known-pitfalls.md` line 14.

The E03.S0 spike (`docs/planning/spikes/plan-mode-detection-findings.md`) surveyed available runtime signals and concluded that `permission_mode` in hook stdin JSON (Signal C in the findings) is the strongest programmatic detection point: a stable, structured, harness-owned field available at the invocation boundary, before any pipeline stage exists. The spike recommended a combined mechanism — updated preamble + a hook reading `permission_mode` — with S1 empirical verification as the critical gate before shipping the hook.

The mechanism is significant enough to warrant a new ADR per CLAUDE.md's "all significant design changes need ADRs" convention, particularly because it adds a new manual-sync target alongside the ADR-003 pattern and must formally distinguish itself from ADR-001's hook-rejection precedent.

## Decision

The detection mechanism is: updated preamble at `skills/build/SKILL.md:11` and `skills/fix/SKILL.md:11` (serving the manual-recovery path) plus a `UserPromptSubmit` hook that reads `permission_mode` from stdin JSON and blocks invocation when the value is `"plan"`. The hook ships as `.claude/hooks/plan-mode-gate.sh` and is templated into user projects via `skills/setup/templates/plan-mode-gate.sh.template` and `settings.json.template`. Per-skill scoping (restricting enforcement to `/roughly:build` and `/roughly:fix`) happens inside the hook script by matching the `prompt` field against `/roughly:(build|fix)`, not via the `matcher` field (which supports tool-name matching only, not slash-command matching).

## Empirical Verification (Step 1)

**Test method:** `claude --print --permission-mode plan "say hi briefly"` run in a temp directory (`/private/tmp/s1-verify`) with a logging hook registered under `UserPromptSubmit`. The hook wrote the full stdin JSON to a log file on each invocation.

**Date:** 2026-05-02

**Verdict: PASS.** `UserPromptSubmit` fires under plan mode and stdin includes `permission_mode: "plan"`.

**Captured stdin JSON (verbatim):**

```json
{"session_id":"59838d60-40aa-4784-a8f7-197836e839f2","transcript_path":"/Users/nickkirkes/.claude/projects/-private-tmp-s1-verify/59838d60-40aa-4784-a8f7-197836e839f2.jsonl","cwd":"/private/tmp/s1-verify","permission_mode":"plan","hook_event_name":"UserPromptSubmit","prompt":"say hi briefly"}
```

The `permission_mode` field carries the value `"plan"` as a stable, structured JSON field — not prose. This confirms the load-bearing assumption from S0: a hook registered on `UserPromptSubmit` can reliably detect plan mode at the invocation boundary.

## Spike-Doc Correction

The spike findings document at `docs/planning/spikes/plan-mode-detection-findings.md` repeatedly refers to the hook event as `UserPromptExpansion` — including in the Section 4 summary table, the Section 5 mechanism recommendation, and the S1 next steps. The actual Claude Code hook event name is `UserPromptSubmit`. This correction is recorded here as authoritative; the spike doc is retained as historical reference per the E03.S1 AC10 spike-retention decision, but readers should treat all references to `UserPromptExpansion` in that document as a known error corrected in ADR-009. The `permission_mode` field and blocking semantics described in the spike doc are otherwise accurate.

## ADR-001 Distinction

ADR-001 rejected hook-based enforcement for the review-plan gate with the following reasoning: "This would work mechanistically but adds brittle coupling between the hook system and the pipeline's internal stage tracking."

ADR-001's objection does not apply to this use case. The distinction operates on two dimensions:

**1. Invocation gate vs. mid-pipeline stage gate.** ADR-001's rejected hook needed to know that Stage 4 had been reached — internal pipeline state that the hook would need to track or infer. The `UserPromptSubmit` hook reads only `permission_mode` from the harness-provided stdin JSON at the prompt-submit event, before Stage 1 exists. The pipeline has no stages yet; there is no pipeline-internal state to couple to.

**2. Harness-owned data vs. pipeline-internal data.** `permission_mode` is provided by the Claude Code harness as a stable, documented contract — a field the harness sets, not one the pipeline must write. ADR-001's rejected hook would have needed to observe that `/roughly:review-plan` had run, a pipeline-internal event with no harness representation. The `UserPromptSubmit` hook's only dependency is the harness's own stdin schema.

ADR-001's stance on pipeline-internal coupling is fully preserved. The hook here couples to the harness API, not to the pipeline.

## Hook Registration Scope

Claude Code's `matcher` field for hook registrations supports tool-name matching (e.g., `Bash`, `Edit|Write`). It does NOT support slash-command matching. Therefore, registering the hook with a `matcher` of `roughly:build` or `roughly:fix` is not available.

Per-skill scoping is achieved inside the hook script by inspecting the `prompt` field in the stdin JSON and matching it against `/roughly:(build|fix)`. The hook is registered globally (no `matcher` restriction) but short-circuits cheaply for non-roughly prompts — reading stdin JSON and checking a single string field adds negligible overhead per invocation.

The alternative — a top-level `matcher` field scoped to the Roughly commands — would be cleaner and is noted as a preferred future state if Claude Code adds slash-command matching support. For now, in-script prompt inspection is the correct and only available approach.

## Manual Sync Targets

The preamble update covers two files: `skills/build/SKILL.md:11` and `skills/fix/SKILL.md:11`. Manual sync only; verbatim text in both files. This sync target is separate from the `agents/agent-preamble.md` sync list (ADR-003) — the plan-mode detection prose is skill-preamble scope, not agent-preamble scope.

## Alternatives Considered

**Preamble-only (no hook).** Rejected because plan mode's auto-engagement at SessionStart fires before the skill body is read. The CRITICAL warning at `skills/build/SKILL.md:11` and `skills/fix/SKILL.md:11` is bypassed structurally — not read and ignored. No prose improvement closes a gap that exists before the prose is reached. The spike findings document Section 5 establishes this as the core structural deficiency; the pitfall entry at `.roughly/known-pitfalls.md:14` documents the same bypass mode from prior observation.

**ExitPlanMode invocation from skill body.** Rejected/deferred. The spike findings Section 3 identifies three unresolved scenarios: ExitPlanMode exits cleanly and returns control (desirable), presents an interactive UI prompt the skill cannot advance past (blocks the pipeline), or is ignored because plan mode controls the execution path (silent failure). S1 empirical verification did not exercise ExitPlanMode under active plan mode — this remains an open empirical gap. The `UserPromptSubmit` hook abort-with-redirect path is strictly safer: it requires no tool whose interactive semantics are unverified, and it fires before the skill body is reached, making skill-body recovery unnecessary.

**Inconclusive / defer.** Rejected. The empirical verification (Step 1) yielded a clean PASS — `UserPromptSubmit` fires under plan mode and `permission_mode: "plan"` is present in stdin. The mechanism is empirically grounded and shippable. Deferring would cause S1 to fall back to preamble-only, which the spike evidence shows is structurally insufficient.

## Consequences

### Positive

- The invocation-gate hook closes the structural bypass that prose alone cannot close — plan mode is blocked before Stage 1 is entered, not warned about after the pipeline has already been hijacked.
- The hook script is a single small bash file reading one JSON field from stdin; it introduces no pipeline-internal state and no coupling between the hook system and pipeline stages.
- Per-skill scoping inside the script is robust to future Claude Code changes to the `matcher` field — the script's prompt-matching logic is independent of hook registration API changes.
- ADR-001's stance on pipeline-internal coupling is fully preserved; the hook couples only to the harness stdin contract.

### Negative

- The hook ships as a sibling file to `settings.json.template` — one additional file for `/roughly:setup` to copy into user projects, and one additional entry in `settings.json.template` to register it.
- The mechanism relies on `UserPromptSubmit` firing under plan mode with `permission_mode: "plan"` in stdin. This was verified PASS on 2026-05-02, but a future Claude Code change to hook event names, stdin schema, or plan-mode firing behavior could silently regress the gate. This is recorded as an integration assumption; the verification test should be re-run against new Claude Code versions.
- ExitPlanMode interactive semantics remain untested. If a future story requires in-skill recovery (rather than abort-with-redirect), this gap must be closed with a dedicated empirical test before ExitPlanMode is used inside a skill body.

### Neutral

- Known edge cases: `defaultMode: "plan"` in a user's `settings.json` is the most likely silent auto-engagement path (a global setting that silently activates plan mode every session). The hook covers this path — `permission_mode` is set by the harness regardless of how plan mode was engaged. Mid-session Shift+Tab toggle into plan mode after a session has started is out of scope for this ADR.
- The spike findings document (`docs/planning/spikes/plan-mode-detection-findings.md`) is retained as historical reference. ADR-009 is the authoritative record of the mechanism; the spike doc's `UserPromptExpansion` references are a known error corrected here.

## Open Items

- **ExitPlanMode interactive semantics** empirical test deferred. If a future story requires self-recovery from inside a skill body (rather than abort-with-redirect at the invocation gate), this must be tested in an isolated plan-mode session before ExitPlanMode is relied upon in any skill.
- **Hook-event suppression audit under plan mode for non-UserPromptSubmit events** (PreToolUse, Stop, SubagentStart, etc.) — informational, not load-bearing for S1. The S0 spike Section 4 noted all non-SessionStart events as "presumed" to fire under plan mode; a full audit would confirm or correct those entries.
