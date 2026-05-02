# E03.S0 — Plan-mode detection spike: findings

**Spike type:** Investigation / scoping (½-day timebox)
**Date:** 2026-05-01
**Gates:** E03.S1 (plan-mode auto-detect/exit at Stage 1)
**Status:** Complete — conclusion: preamble + lightweight hook (pending S1 empirical verification of presumed claims)

## Context

Claude Code's built-in plan mode runs a Phase 1–5 workflow (analyze → plan → confirm → implement → summarize) via its own `Plan` subagent and `ExitPlanMode` tool. When this mode is active during a Roughly pipeline invocation, it substitutes its own workflow for the pipeline's Stages 1–4. This is not a graceful override — it is a silent replacement. The Roughly pipeline's Stage 4 gate (the blocking `/roughly:review-plan` subagent dispatch, established in [ADR-001](../../../docs/adrs/ADR-001-verify-plan-as-subagent.md)) is never reached; instead, the plan-mode `Plan` subagent performs a generic implementation design pass that returns no PASS/NEEDS REVISION verdict and does not check the codebase against spec. The human has no visible signal that the correct pipeline did not run.

The existing warning at [skills/build/SKILL.md:11](../../../skills/build/SKILL.md#L11) and [skills/fix/SKILL.md:11](../../../skills/fix/SKILL.md#L11) reads: "**CRITICAL:** Do NOT use Claude Code's built-in plan mode (EnterPlanMode/ExitPlanMode). Present all gates as inline text prompts in the conversation. The pipeline has its own gate protocol — Claude Code's plan mode will hijack the flow and skip stages." Despite this warning, the hijack can occur via plan mode's auto-engagement at SessionStart, which engages before the skill body is read. Prose alone has been insufficient.

The [.roughly/known-pitfalls.md:14](../../../.roughly/known-pitfalls.md#L14) Domain-Specific entry documents the failure mode in full. The exact text is:

> **Plan mode (Claude Code's built-in) hijacks the build/fix pipeline.** When `/roughly:build` or `/roughly:fix` runs with plan mode active, plan-mode's workflow (Phase 1–5 → ExitPlanMode) substitutes for the build skill's Stages 1–4. The build skill's preamble warns about this, but it can still happen via auto-engagement at SessionStart. Most common silent failure: Stage 4 (`/roughly:review-plan` dispatch) gets skipped because plan-mode's generic `Plan` subagent looks like it fulfills the design-review step — it does NOT. The `Plan` agent designs implementations; `/roughly:review-plan` returns a structured PASS/NEEDS REVISION verdict against the codebase. If plan mode is active when invoking a Roughly pipeline, exit plan mode and re-invoke; or explicitly dispatch `/roughly:review-plan` to recover.

This spike was opened because S1 requires a detection mechanism and it is unclear which programmatic signals are available to a skill at runtime. [ADR-003](../../../docs/adrs/ADR-003-shared-spec-reviewer.md)'s manual-sync model (reference copy + inline runtime copy) applies to any future warning text that is shared across build and fix pipelines.

---

## Section 1: Signals observable to a skill at runtime

Each signal is assessed across three dimensions: (a) who can observe it, (b) whether it is programmatic or prose, and (c) citation.

### Signal A: System-reminder text injected when plan mode is active

- **Source/citation:** [.roughly/known-pitfalls.md:14](../../../.roughly/known-pitfalls.md#L14) references that plan-mode can auto-engage "via auto-engagement at SessionStart" and substitutes its own workflow. Claude Code injects context (including mode state) into the model's system prompt at session start and on mode change.
- **Who can observe it:** The skill body — Claude reads it as part of its context. Hook scripts do not receive the system-reminder text.
- **Programmatic or prose:** Not programmatic — prose. The skill body (and the orchestrator model) reads it as natural language in the context window. No structured field is returned; detection would require pattern-matching on the text.
- **Empirical gap:** The verbatim text of the plan-mode system-reminder injection is NOT captured in this repo. What the injected text says, whether it includes a stable machine-readable marker, and whether it is distinct enough to pattern-match reliably is unverified. Flagged as **empirical gap**.

### Signal B: ExitPlanMode tool availability in the orchestrator's tool list

- **Source/citation:** [Claude Code permission modes docs](https://docs.anthropic.com/en/docs/claude-code/permission-modes) document plan mode as a Claude Code feature; the [hooks docs](https://docs.anthropic.com/en/docs/claude-code/hooks) reference `ExitPlanMode` as a hookable tool that appears under PreToolUse matchers, confirming the tool exists. The hooks docs reference is incidental to ExitPlanMode's role as a plan-mode signal — its primary purpose is exiting plan mode from inside Claude's tool-calling flow.
- **Who can observe it:** The skill body — the orchestrator can attempt to call ExitPlanMode. Hook scripts do not directly observe the tool list.
- **Programmatic or prose:** Programmatic — it is a tool call, not a text pattern. If the tool is present and callable, the orchestrator can invoke it.
- **Empirical gap:** Whether ExitPlanMode is actually callable from inside a skill body when plan mode is active (vs. presenting an interactive UI prompt that the skill cannot advance past) is unverified from this session. See Section 3.

### Signal C: `permission_mode` field in hook stdin JSON

- **Source/citation:** [Claude Code hooks docs](https://docs.anthropic.com/en/docs/claude-code/hooks) document that hook scripts receive a JSON blob on stdin; the `permission_mode` field carries the current mode value, including `"plan"` when plan mode is active.
- **Who can observe it:** Hook scripts only. The skill body cannot read hook stdin; this field is not visible to the orchestrator model's context.
- **Programmatic or prose:** Programmatic — a structured JSON field with a stable enumerated value (`"plan"`).

### Signal D: SubagentStart event with `agent_type: "Plan"`

- **Source/citation:** [Claude Code hooks docs](https://docs.anthropic.com/en/docs/claude-code/hooks) document a `SubagentStart` hook event that fires when any subagent is spawned, with an `agent_type` field. When plan mode spawns its own `Plan` subagent, `agent_type` would be `"Plan"`.
- **Who can observe it:** Hook scripts only, via a `SubagentStart` hook registration.
- **Programmatic or prose:** Programmatic — a structured JSON field. However, per the hooks docs' "can-block" table, `SubagentStart` **cannot block**. A hook registered on this event cannot prevent the plan-mode subagent from running; it can only observe that it started.

### Signal E: `setMode` output available to SessionStart and PermissionRequest hooks

- **Source/citation:** [Claude Code hooks docs](https://docs.anthropic.com/en/docs/claude-code/hooks) document that `SessionStart` and `PermissionRequest` hook scripts can return a `setMode` field in their JSON output, which causes Claude Code to switch modes. This is an output signal (hook controlling mode), not an input signal (hook observing mode) — though a `SessionStart` hook that reads the session environment could infer state.
- **Who can observe it:** Hook scripts only, and only via the output protocol (not input observation).
- **Programmatic or prose:** Programmatic — structured JSON output.

### Summary table

| Signal | Available to skill body? | Available to hook script? | Programmatic? |
|--------|--------------------------|---------------------------|---------------|
| system-reminder text | yes (read by Claude) | no | no — prose |
| ExitPlanMode tool | yes (callable) | no | yes — tool call |
| permission_mode hook field | no | yes | yes — JSON field |
| SubagentStart agent_type=Plan | no | yes (cannot block) | yes — JSON field |
| setMode hook output | no | yes (SessionStart, PermissionRequest only) | yes — JSON output |

---

## Section 2: Auto-engagement triggers

Each trigger is listed with its citation and empirical-confirmation status.

### Trigger 1: User toggle (Shift+Tab cycling)

- **Mechanism:** The user presses Shift+Tab to cycle Claude Code's permission mode: default → acceptEdits → plan.
- **Citation:** [Claude Code permission modes docs](https://docs.anthropic.com/en/docs/claude-code/permission-modes)
- **Empirical status:** Documented. Not confirmed empirically in this session (no interactive UI available). The cycle is reversible — pressing Shift+Tab again moves past plan mode back to default.

### Trigger 2: CLI flag at startup

- **Mechanism:** Starting Claude Code with `claude --permission-mode plan` engages plan mode from the first prompt.
- **Citation:** [Claude Code permission modes docs](https://docs.anthropic.com/en/docs/claude-code/permission-modes)
- **Empirical status:** Documented. Not confirmed empirically in this session.

### Trigger 3: `defaultMode` in settings.json

- **Mechanism:** A project or user `settings.json` containing `{"permissions": {"defaultMode": "plan"}}` causes every Claude Code session to start in plan mode automatically.
- **Citation:** [Claude Code permission modes docs](https://docs.anthropic.com/en/docs/claude-code/permission-modes)
- **Empirical status:** Documented. This is the most likely **silent auto-engagement** path — a user who has set this in their global settings will always enter plan mode and may not notice when invoking Roughly pipelines.

### Trigger 4: IDE / Desktop / claude.ai mode selectors

- **Mechanism:** Claude Code IDE integrations and the Desktop app may expose mode selectors that persist across sessions, engaging plan mode without a CLI flag.
- **Citation:** [Claude Code permission modes docs](https://docs.anthropic.com/en/docs/claude-code/permission-modes)
- **Empirical status:** Documented. Not confirmed in this session. Specific UI behavior varies by integration.

### Trigger 5: SessionStart hook returning `setMode: "plan"`

- **Mechanism:** A `SessionStart` hook script can return `{"setMode": "plan"}` in its JSON output, causing Claude Code to switch into plan mode before the first prompt is processed. This is the auto-engagement path most relevant to E03 — a user who has installed a hook that sets plan mode will experience Roughly pipeline hijack silently and repeatedly.
- **Citation:** [Claude Code hooks docs](https://docs.anthropic.com/en/docs/claude-code/hooks)
- **Empirical status:** Documented. Not confirmed empirically; no SessionStart hook with `setMode: "plan"` is installed in this repo's `.claude/settings.json`.

### Empirical observation from this session

The current Claude Code session's SessionStart output does NOT include `setMode: "plan"`, and plan mode is not active in this session. This is observable because the orchestrator's tool list includes deferred tools (see Section 3) but `ExitPlanMode` is not surfaced as an actively callable tool in the current tool schemas — consistent with plan mode being inactive. This constitutes one observable data point — but it is a baseline observation about a non-plan-mode session, not validation of any detection mechanism. The active-plan-mode trigger behavior is unobserved.

Toggling plan mode and observing the resulting system-reminder text and tool-list change is left as a **known empirical gap**. The spike does not have a clean mechanism to perform this test from inside an active pipeline session without either terminating the session or engaging plan mode and potentially disrupting the pipeline under investigation. This gap must be resolved in S1 verification. **AC2 acknowledgment:** the epic's AC2 (line 71) requires triggers to be "confirmed empirically, not from documentation alone." This spike does not satisfy that AC fully — every trigger above is documented but none was empirically exercised during S0 due to the session constraint. AC2 should be marked as a known gap pending S1 verification rather than as fully satisfied; this should be flagged to the human at the build pipeline's wrap-up gate.

---

## Section 3: ExitPlanMode invocation from a skill body

### What the docs say

Per the [Claude Code hooks docs](https://docs.anthropic.com/en/docs/claude-code/hooks), `ExitPlanMode` is listed as a tool that appears in PreToolUse matchers. The docs note that Claude Code's plan mode "requires user interaction and normally blocks in non-interactive mode with the `-p` flag." This phrasing implies that ExitPlanMode may present an interactive confirmation step rather than silently returning control to the calling context.

The key unresolved question is whether `ExitPlanMode` invoked from inside an active-plan-mode skill body:
1. Silently exits plan mode and returns control to the skill body (desirable for S1)
2. Presents a UI prompt that the skill body cannot advance past (blocks the pipeline)
3. Is ignored because the plan-mode workflow controls the execution path and the skill body is not running

### Dogfood observation — current session

In the current session (plan mode inactive), `ExitPlanMode` appears in the deferred-tool registry — it is listed in the `<system-reminder>` block alongside other deferred tools (`CronCreate`, `Monitor`, `WebFetch`, etc.). However, it is not surfaced as a directly callable tool in the active tool schemas. The deferred-tool registry loads tool names without schemas; the schema is fetched only when explicitly requested via `ToolSearch`.

**Dogfood test result:** In a non-plan-mode session, `ExitPlanMode` is present in the deferred tool registry but is not surfaced as a directly callable tool until plan mode engages. The tool's presence in the deferred registry does confirm it exists in the harness. Whether invoking ExitPlanMode from inside an active-plan-mode skill body reliably exits plan mode and returns control to the skill (vs. presenting a UI prompt the skill cannot advance past, or being silently ignored because the plan-mode execution path does not yield to the skill body) is **NOT confirmed by this dogfood observation** and remains an **empirical gap**.

### Remaining uncertainty

Three open questions for S1 empirical verification:
1. Does ExitPlanMode become a directly callable (non-deferred) tool when plan mode is active?
2. When called from a skill body under active plan mode, does it exit cleanly or block on user interaction?
3. If plan mode's Phase 1–5 has already begun executing, does ExitPlanMode halt mid-flow or wait for plan-mode completion?

---

## Section 4: Hook event behavior under plan mode

Each hook event is assessed against: (a) does it fire under plan mode per the docs, (b) can it block under plan mode, (c) does it receive `permission_mode`.

### SessionStart

- **Fires under plan mode:** Yes — fires once at the start of any session, including plan-mode sessions.
- **Can block:** Not applicable (session-start, not a tool or prompt gate). Can return `setMode` to change the mode before the first prompt.
- **Receives permission_mode:** Yes, per the [Claude Code hooks docs](https://docs.anthropic.com/en/docs/claude-code/hooks). A SessionStart hook can read the incoming mode and potentially return `setMode: "default"` to suppress plan mode before any pipeline skill runs.
- **Empirical status:** Documented. The `setMode` output mechanism is the strongest programmatic pre-engagement gate.

### UserPromptExpansion

- **Fires under plan mode:** Presumed yes — fires when a typed command (e.g., `/roughly:build`) expands into a prompt, BEFORE Claude reads the skill body. This would fire before plan mode processes the skill.
- **Can block:** Yes — supports `decision: "block"` to prevent the prompt from being processed.
- **Receives permission_mode:** Yes — the hook stdin JSON includes `permission_mode`. If `permission_mode == "plan"`, the hook could block the skill invocation and return an error message to the user.
- **Empirical status:** **Presumed** — that UserPromptExpansion fires before the plan-mode workflow begins (rather than being suppressed or delayed by plan mode) is an **empirical gap**. This is the most critical assumption underlying any hook-based detection strategy — if UserPromptExpansion does NOT fire before plan mode intercepts, the hook cannot gate the invocation.

### PreToolUse

- **Fires under plan mode:** Presumed yes — fires before each tool invocation. Plan mode's own tool calls (ExitPlanMode, etc.) would trigger this.
- **Can block:** Yes — supports `decision: "block"`.
- **Receives permission_mode:** Yes.
- **Empirical status:** **Presumed**. Not empirically tested in a plan-mode session.

### PostToolUse

- **Fires under plan mode:** Presumed yes — fires after tool completion.
- **Can block:** No — cannot prevent the tool result from reaching Claude.
- **Receives permission_mode:** Yes.
- **Empirical status:** **Presumed**.

### Stop

- **Fires under plan mode:** Presumed yes — fires after each Claude response.
- **Can block:** No — can append context but cannot block execution.
- **Receives permission_mode:** Yes.
- **Empirical status:** **Presumed**.

### SubagentStart

- **Fires under plan mode:** Presumed yes — fires when any subagent is spawned, including the plan-mode `Plan` subagent.
- **Can block:** No — explicitly documented in the hooks docs' "can-block" table as non-blocking.
- **Receives permission_mode:** Yes, with `agent_type` also available. A `SubagentStart` hook can observe that `agent_type: "Plan"` indicates plan-mode engagement, but cannot prevent the subagent from running.
- **Empirical status:** **Presumed**.

### PermissionRequest

- **Fires under plan mode:** Yes — fires when Claude requests a permission.
- **Can block:** Yes.
- **Receives permission_mode:** Yes. Can also return `setMode` to change the active mode.
- **Empirical status:** Documented.

### Note on documented suppression

Per the [Claude Code hooks docs](https://docs.anthropic.com/en/docs/claude-code/hooks), no events are listed as explicitly suppressed when plan mode is active. However, the docs do not exhaustively enumerate plan-mode-specific behavior for each event — this is a stated documentation gap. Whether plan mode's execution flow causes any events to be skipped, reordered, or suppressed is left as an **empirical gap** for S1 verification before relying on any hook-based mechanism.

### Summary table

| Event | Fires under plan mode? | Can block? | Receives permission_mode? |
|-------|------------------------|------------|---------------------------|
| SessionStart | yes | n/a | yes |
| UserPromptExpansion | yes (presumed) | yes | yes |
| PreToolUse | yes (presumed) | yes | yes |
| PostToolUse | yes (presumed) | no | yes |
| Stop | yes (presumed) | no | yes |
| SubagentStart | yes (presumed) | no | yes |
| PermissionRequest | yes | yes | yes |

Cells marked "presumed" represent **empirical gaps**: the spike's conclusion in Section 5 must account for the dependency any hook-based mechanism places on these unverified firing behaviors. A UserPromptExpansion hook is the strongest candidate hook-based gate IF it fires before plan mode processes the skill invocation — and this dependency must be verified by the S1 implementation before the mechanism is relied upon in production.

---

## Section 5: Conclusion

**Mechanism choice:** preamble + lightweight hook

The evidence assembled in Sections 1–4 supports a combined mechanism: update the shared preamble prose (ADR-003 sync model) AND register a UserPromptExpansion hook that reads `permission_mode` from hook stdin and blocks skill invocation when `permission_mode == "plan"`. The two elements are not belt-and-suspenders redundancy — they are distinct enforcement layers that address distinct failure modes, as justified below.

### Why the combined mechanism is the strongest choice

The core finding of this spike is that `permission_mode` is a programmatic, stable, structured JSON field available to hook scripts at the invocation boundary (Section 1, Signal C). This field was unknown when E03 was written. Its discovery changes the cost-benefit calculus: a UserPromptExpansion hook can detect plan mode before the skill body is read, before plan mode's Phase 1–5 workflow begins, and before any pipeline stage is entered. This is a different enforcement point from anything available in the preamble-only model. The hook fires at the invocation gate; the preamble is read (if at all) only after the hook passes the prompt through.

The preamble-only alternative is structurally insufficient against the documented failure path. Per [.roughly/known-pitfalls.md:14](../../../.roughly/known-pitfalls.md#L14), the hijack occurs "via auto-engagement at SessionStart, which engages before the skill body is read." The existing CRITICAL warning at [skills/build/SKILL.md:11](../../../skills/build/SKILL.md#L11) and [skills/fix/SKILL.md:11](../../../skills/fix/SKILL.md#L11) is a prose-only defense — and it is bypassed before being read, not read and ignored. This is a structural bypass: plan mode engages at SessionStart, the skill is invoked, plan mode's Phase 1–5 workflow runs, and the CRITICAL warning in the skill body is never reached. Adding more or better prose to the preamble cannot close this gap, because no amount of prose improvement can be read before the bypass occurs. Prose alone cannot gate an invocation that is intercepted before the skill body is loaded.

### Why the rejected alternatives are weaker

**Preamble-only** addresses the wrong failure point. The hijack is an invocation-time event; the preamble is a skill-body event. These are separated by at least one execution boundary (plan mode's auto-engagement at SessionStart, before the skill body is loaded). The existing warning at `skills/build/SKILL.md:11` is evidence: it is bypassed structurally rather than ignored, and the pitfall entry in known-pitfalls.md documents this exact bypass mode. Strengthening the prose cannot close this gap because the prose is never reached on the failure path.

**Inconclusive** is not warranted. The spike has surfaced a concrete, documentable programmatic signal (`permission_mode`) with a documented hook event (UserPromptExpansion) that is presumed to fire before skill-body execution (the event type is confirmed in the hooks docs; whether it fires before plan mode's Phase 1–5 workflow under active plan mode is an empirical gap S1 must verify — see Section 4). The open empirical questions (Section 4) are about operational detail — whether UserPromptExpansion fires under plan mode — not about whether the signal exists. The evidence is sufficient to conclude and hand off a concrete S1 specification. Declaring inconclusive would cause S1 to default to preamble-only per the fallback AC, which the spike evidence shows is already insufficient.

### Belt-and-suspenders justification

[AC6](../../../docs/planning/epics/E03-trust-and-ergonomics.md) explicitly forbids "both as belt-and-suspenders" unless an observed failure case during the spike justifies it. The justification here is structural and pre-existing: the pitfall entry at [.roughly/known-pitfalls.md:14](../../../.roughly/known-pitfalls.md#L14) documents that plan mode engages at SessionStart, which fires before the skill body containing the CRITICAL warning at `skills/build/SKILL.md:11` and `skills/fix/SKILL.md:11` is loaded. The preamble warning is bypassed structurally, not read and ignored. The spike's contribution is not first-time observation — it is confirmation, via reading the pre-existing pitfall record and the hooks documentation, that any prose-only defense has the same structural bypass and that no preamble improvement can close it. (This interpretation reads "observed during the spike" inclusively to cover observations made by analyzing prior-session records — if a strict reading requires empirical reproduction during S0, the AC6 justification falls back to the structural argument: the bypass is documented in the harness's auto-engagement timing, independent of any specific prior incident.) The preamble update is included in the combined mechanism for a separate purpose: it serves the manual-recovery path. A user who manually exits plan mode and re-invokes (per the known-pitfalls.md recovery instruction) should see updated prose reflecting the new auto-detection behavior. The two elements serve different failure paths; neither is redundant.

### Line-cap budget impact

The 300-line cap applies to both `skills/build/SKILL.md` and `skills/fix/SKILL.md`. Current counts: `skills/build/SKILL.md` is at **296/300 lines** and `skills/fix/SKILL.md` is at **299/300 lines**. Any preamble change that adds text inline to both files must stay within these budgets. `fix/SKILL.md` has only 1 line of headroom. The correct approach, per [ADR-003](../../../docs/adrs/ADR-003-shared-spec-reviewer.md)'s reference-copy pattern, is to extract the shared plan-mode detection prose into a reference copy (analogous to `spec-reviewer-prompt.md`) and reference it in the agent-preamble sync list — not to add inline text to both files independently. S1 must treat budget extraction as a first-class constraint, not an afterthought, when scoping the preamble-update task.

### ADR-001 hook-rejection precedent

[ADR-001](../../../docs/adrs/ADR-001-verify-plan-as-subagent.md) rejected hook-based enforcement for the review-plan gate on the grounds that it "adds brittle coupling between the hook system and the pipeline's internal stage tracking." The hook mechanism proposed here is distinguishable on two dimensions:

1. **Invocation gate vs. mid-pipeline stage gate.** ADR-001's objection targets a hook that would need to know that Stage 4 has or has not been reached — an internal pipeline state. A UserPromptExpansion hook that checks `permission_mode == "plan"` at invocation entry needs no knowledge of pipeline-internal state. It fires before Stage 1; the pipeline has no stages yet. The coupling is between the hook and the Claude Code harness (a stable external contract), not between the hook and the pipeline's own stage-tracking logic.

2. **Blocking at entry vs. blocking mid-flow.** ADR-001's alternative "would work mechanistically but adds brittle coupling" because the hook would need to observe that verify-plan ran (an internal pipeline event) and block based on that. A UserPromptExpansion hook instead reads `permission_mode` from the harness-provided stdin JSON (a harness-owned field, not a pipeline internal) and blocks the invocation before any pipeline logic runs. No pipeline state is tracked or observed.

ADR-001's objection does not apply to this use case. This distinction will be formalized in ADR-009 (S1 deliverable).

### S1 next steps

1. **Empirically verify UserPromptExpansion under plan mode.** Enable plan mode in a test session, invoke a Roughly skill, and confirm the UserPromptExpansion hook fires and receives `permission_mode: "plan"` in stdin. This is the load-bearing assumption for the hook-based mechanism; S1 must not ship without this confirmation.

2. **Implement the UserPromptExpansion hook (CONDITIONAL on Step 1).** **IF Step 1 confirms** UserPromptExpansion fires before plan mode's workflow with `permission_mode: "plan"` in stdin, write a hook script that reads `permission_mode` from stdin JSON; if the value is `"plan"`, return `{"decision": "block", "reason": "Roughly pipelines cannot run in Claude Code plan mode. Exit plan mode (Shift+Tab) and re-invoke."}`. Wire it to `/roughly:build` and `/roughly:fix` skill invocations in `settings.json.template` and update `skills/setup/SKILL.md` Step 5d to include hook registration. **IF Step 1 falsifies** the assumption (UserPromptExpansion does not fire, fires after plan-mode interception, or does not receive `permission_mode`), STOP — the hook mechanism is not viable; return to S1's preamble-only fallback per the epic's S1 fallback AC (epic line 111) and document the empirical finding in known-pitfalls.md as a gap S1 cannot close.

3. **Update shared preamble prose.** Revise the CRITICAL warning at `skills/build/SKILL.md:11` and `skills/fix/SKILL.md:11` to reflect auto-detection behavior — the message should describe what happens when plan mode is detected and how to recover, not just warn that plan mode is problematic. Respect the line-cap budget (build at 296/300, fix at 299/300); extract shared prose to a reference copy rather than adding inline lines to both files.

4. **Verify ExitPlanMode interactive semantics.** Test whether ExitPlanMode, when invoked from inside an active-plan-mode skill body, exits cleanly or presents a blocking UI prompt the skill cannot advance past. This determines whether abort-with-redirect (hook blocks and instructs user) is the only feasible path, or whether the skill can self-recover by calling ExitPlanMode directly.

5. **Write ADR-009.** Document the mechanism choice, the ADR-001 distinction, and the empirical verification results from S1. Reference this findings doc as the spike evidence base.

6. **Update known-pitfalls.md.** Revise the Domain-Specific entry at line 14 to reflect the auto-detection mechanism: the hijack is now caught at invocation rather than requiring manual user vigilance.

### Empirical gaps for S1 verification

- **UserPromptExpansion firing under plan mode (critical).** The hook-based mechanism's viability depends entirely on UserPromptExpansion firing before plan mode's Phase 1–5 workflow begins. This was marked "presumed" in Section 4 — the docs do not exhaustively enumerate plan-mode suppression behavior. S1 must confirm this empirically before the hook is shipped.

- **ExitPlanMode interactive semantics.** Section 3 leaves open whether ExitPlanMode, called from a skill body under active plan mode, (a) exits cleanly and returns control to the skill, (b) presents an interactive UI prompt that blocks the skill, or (c) is ignored because plan mode controls the execution path. This determines whether in-skill self-recovery is feasible or whether the hook must be the sole gate.

- **System-reminder text verbatim content.** Signal A (Section 1) notes that the verbatim text of the plan-mode system-reminder injection is not captured in this repo. S1 should record it: if the text includes a stable marker, Signal A may serve as a fallback detection path for environments where hooks are not installed.

- **Hook event suppression audit.** Section 4 notes that the docs do not exhaustively enumerate which hook events are suppressed or reordered under plan mode. S1's empirical verification should run a full hook-event audit under active plan mode (SessionStart, UserPromptExpansion, PreToolUse, PostToolUse, Stop, SubagentStart) and record which events fire, in what order, and with what stdin payloads.

- **`defaultMode: "plan"` session behavior.** Trigger 3 (Section 2) identifies `defaultMode: "plan"` in settings.json as the most likely silent auto-engagement path. S1 should verify that the hook-based gate fires correctly under this trigger — i.e., that a UserPromptExpansion hook registered in `settings.json.template` fires even when plan mode was set by the same `settings.json` at session start.
