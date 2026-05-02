# Implementation Plan: E03.S0 — Plan-mode detection spike

Plan-format-version: 1

## Feature summary

Bounded research spike (½-day timebox) producing a findings doc that enumerates plan-mode signals observable to a Roughly skill at runtime, identifies plan-mode auto-engagement triggers, reports `ExitPlanMode` behavior from skill bodies, lists hook event behavior under plan mode, and concludes with one of: **preamble-only**, **preamble + lightweight hook**, or **inconclusive**. The conclusion gates S1's mechanism choice.

This is a research/spike, not a code feature. The "implementation" is writing one markdown findings doc. There is no source code change, no test code, and no SKILL.md modification in S0 — those land in S1.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| docs/planning/spikes/ | Create directory | T1 |
| docs/planning/spikes/plan-mode-detection-findings.md | Create | T1, T2 |

## Tasks

### T1: Draft findings doc sections 1–4 (~8 min)

**Files:** docs/planning/spikes/plan-mode-detection-findings.md
**Action:** Create the spike findings doc with frontmatter/header metadata and Sections 1–4 written. Section 5 (conclusion) is deliberately deferred to T2 so the evidence is fully captured before synthesis.

**Details:**

Create the directory `docs/planning/spikes/` (mkdir -p) if it does not exist, then create the file `docs/planning/spikes/plan-mode-detection-findings.md` with the following structure. Do NOT write Section 5 — that is T2's responsibility.

Required structure:

```markdown
# E03.S0 — Plan-mode detection spike: findings

**Spike type:** Investigation / scoping (½-day timebox)
**Date:** 2026-05-01
**Gates:** E03.S1 (plan-mode auto-detect/exit at Stage 1)
**Status:** Draft — pending Stage 5 conclusion

## Context

[1-2 paragraph summary of what plan mode is and why the hijack matters. Reference ADR-001 (review-plan as blocking subagent), and quote the existing Domain-Specific entry from `.roughly/known-pitfalls.md:14` verbatim. Cite the existing CRITICAL warning at skills/build/SKILL.md:11 and skills/fix/SKILL.md:11 — note that prose alone has been insufficient since the bug exists despite the warning.]

## Section 1: Signals observable to a skill at runtime

[For EACH signal below, document: (a) the signal name, (b) the source/citation URL, (c) WHO can observe it (skill body prose vs hook script vs subagent), (d) whether it is a programmatic API or prose. Be explicit about the prose-vs-programmatic distinction — this is the hinge of the spike's conclusion.]

Signals to enumerate:
- system-reminder text injected when plan mode is active (citation: known-pitfalls.md L14 references it; verbatim text is NOT captured in the repo — flag as empirical gap)
- `ExitPlanMode` tool availability in the orchestrator's tool list (citation: hooks docs list it under PreToolUse matchers)
- `permission_mode` field in hook stdin JSON, with documented value `"plan"` (citation: docs.anthropic.com/en/docs/claude-code/hooks)
- `SubagentStart` event with `agent_type: "Plan"` (citation: same hooks docs; note this CANNOT block per the docs' "can-block" table)
- `setMode` output available to SessionStart and PermissionRequest hooks (citation: same docs)

End the section with a summary table:

| Signal | Available to skill body? | Available to hook script? | Programmatic? |
|--------|--------------------------|---------------------------|---------------|
| system-reminder text | yes (read by Claude) | no | no — prose |
| ExitPlanMode tool | yes (callable) | no | yes — tool call |
| permission_mode hook field | no | yes | yes — JSON field |
| SubagentStart agent_type=Plan | no | yes (cannot block) | yes — JSON field |
| setMode hook output | no | yes (SessionStart, PermissionRequest only) | yes — JSON output |

## Section 2: Auto-engagement triggers

[Enumerate the documented mechanisms by which plan mode auto-engages, with citation URLs. For each, note empirical-confirmation status: confirmed in repo / documented but not yet confirmed.]

Triggers to enumerate:
- User toggle (Shift+Tab cycling: default → acceptEdits → plan)
- CLI flag at startup: `claude --permission-mode plan`
- `defaultMode` in settings.json: `{"permissions": {"defaultMode": "plan"}}`
- IDE / Desktop / claude.ai mode selectors
- SessionStart hook returning `setMode: "plan"` — this is the auto-engagement path the E03 epic describes

Empirical observation captured in this session: the current Claude Code session's SessionStart hook output (visible in the orchestrator's initial context) does NOT include `setMode: "plan"`, and the current session is not in plan mode. Document this as one observable data point. Note that toggling plan mode and observing the resulting system-reminder text is left as a known empirical gap for the human or for S1 verification — the spike does not have a clean way to perform this test from inside the current pipeline session.

## Section 3: ExitPlanMode invocation from a skill body

[Document what is known about ExitPlanMode from official docs: it is a tool listed in PreToolUse matchers, "requires user interaction and normally blocks in non-interactive mode with the -p flag." Cite https://docs.anthropic.com/en/docs/claude-code/hooks.]

[Provide at least one dogfood observation — what is observable in the current session: the ExitPlanMode tool was deferred (visible in the deferred-tools list at session start) but not currently in the active tool schemas. Document whether it appears in the available tool list when plan mode is inactive. State this as the dogfood test result: "In a non-plan-mode session, ExitPlanMode is present in the deferred tool registry but is not surfaced as a directly callable tool until plan mode engages." Note remaining uncertainty: whether invoking `ExitPlanMode` from inside an active-plan-mode skill body reliably exits plan mode and returns control to the skill (vs. presenting a UI prompt the skill cannot advance past) is NOT confirmed by this dogfood test.]

## Section 4: Hook event behavior under plan mode

[For each hook event documented in https://docs.anthropic.com/en/docs/claude-code/hooks, list (a) event name, (b) does it fire under plan mode (per docs / per empirical test), (c) can it block under plan mode.]

Events to enumerate:
- SessionStart — fires once at session start; can return `setMode` to set plan mode
- UserPromptExpansion — fires when a typed command expands into a prompt, BEFORE Claude reads the skill body; supports `decision: "block"`; receives `permission_mode` in stdin JSON
- PreToolUse — fires before each tool invocation; supports blocking via decision; receives `permission_mode`
- PostToolUse — fires after tool completion; receives `permission_mode`; cannot prevent the tool result from reaching Claude
- Stop — fires after each Claude response; receives `permission_mode`; can append context but cannot block
- SubagentStart — fires when a subagent is spawned; receives `agent_type` (including `"Plan"`); CANNOT block
- PermissionRequest — fires when Claude requests a permission; can return `setMode`

For each event, note any documented suppression under plan mode. Per the hooks docs, no events are listed as suppressed when plan mode is active — but this is a stated empirical gap (the docs do not exhaustively cover plan-mode behavior, and an empirical test is left as a S1-verification followup).

End the section with a summary table:

| Event | Fires under plan mode? | Can block? | Receives permission_mode? |
|-------|------------------------|------------|---------------------------|
| SessionStart | yes | n/a | yes |
| UserPromptExpansion | yes (presumed) | yes | yes |
| PreToolUse | yes (presumed) | yes | yes |
| PostToolUse | yes (presumed) | no | yes |
| Stop | yes (presumed) | no | yes |
| SubagentStart | yes (presumed) | no | yes |
| PermissionRequest | yes | yes | yes |

(Mark "presumed" cells as empirical gaps; the spike's conclusion notes that a UserPromptExpansion hook is the strongest candidate IF it does in fact fire when plan mode is active — and this is a dependency the S1 implementation must verify before relying on it.)
```

Style guidance:
- Use markdown tables and bullet lists for skim-ability
- Cite source URLs inline as `[label](url)` — minimum citations: docs.anthropic.com/en/docs/claude-code/hooks (for hook events, permission_mode, ExitPlanMode), docs.anthropic.com/en/docs/claude-code/permission-modes (for triggers)
- Reference internal files using markdown links: [.roughly/known-pitfalls.md:14](../../../.roughly/known-pitfalls.md#L14), [skills/build/SKILL.md:11](../../../skills/build/SKILL.md#L11), etc.
- Be ruthless about flagging empirical gaps — anything not directly observable from the current session or directly cited from docs is "documented but not empirically confirmed"
- The "at least one dogfood test result" AC is satisfied by the Section 3 observation (ExitPlanMode is deferred, plan mode not active in current session, etc.)
- Quote the verbatim plan-mode entry from `.roughly/known-pitfalls.md:14` exactly as it appears

Do NOT:
- Write Section 5 (conclusion) — that's T2
- Recommend a mechanism choice anywhere in Sections 1–4 — Sections 1–4 are evidence only
- Modify any file outside `docs/planning/spikes/plan-mode-detection-findings.md`

**Verify:** `wc -l docs/planning/spikes/plan-mode-detection-findings.md` returns a count > 50; `rg -c "## Section [1234]" docs/planning/spikes/plan-mode-detection-findings.md` returns 4; the file does NOT yet contain `## Section 5` or `## Conclusion`.

**UI:** no

---

### T2: Add Section 5 (conclusion) and self-verification (~5 min)

**Files:** docs/planning/spikes/plan-mode-detection-findings.md
**Depends on:** T1
**Action:** Append Section 5 (conclusion) to the findings doc with the spike's mechanism recommendation and rationale, then run AC verification spot-checks against the completed doc.

**Details:**

Append to the findings doc — do not modify Sections 1–4.

Required structure for Section 5:

```markdown
## Section 5: Conclusion

**Mechanism choice:** [ONE of: preamble-only / preamble + lightweight hook / inconclusive]

[3-6 paragraphs of rationale citing specific evidence from Sections 1-4. Address each of the following:]

1. Why the chosen mechanism best balances enforcement strength with implementation cost
2. Why the rejected alternatives are weaker (cite specific evidence from earlier sections)
3. The line-cap budget impact on whichever mechanism includes a preamble change (skills/build/SKILL.md is at 296/300 and skills/fix/SKILL.md at 299/300 — quote these counts)
4. The ADR-001 hook-rejection precedent: ADR-001 rejected hooks for review-plan enforcement on the grounds that hooks introduce brittle coupling between hook system and pipeline stage tracking. If the conclusion includes a hook, distinguish the use case (skill-invocation gate before Stage 1 vs. mid-pipeline stage gate inside Stage 4) and why the same objection does not apply
5. Any belt-and-suspenders justification — the AC explicitly forbids "both as belt-and-suspenders" unless an observed failure case during the spike justifies it. If the conclusion is preamble + hook, the justification must be: prose alone has been demonstrated insufficient because the existing CRITICAL warning at skills/build/SKILL.md:11 and skills/fix/SKILL.md:11 has not prevented the documented hijack — this is the observed failure case
6. Empirical gaps the S1 implementation must verify before relying on the chosen mechanism (UserPromptExpansion firing under plan mode, ExitPlanMode interactive semantics, etc.)

[End the section with a clear "S1 next steps" subheading listing 3-6 concrete tasks the S1 implementer must perform, derived from the conclusion. These tasks become the inputs to the S1 plan.]

### Empirical gaps for S1 verification

[Bulleted list of the empirical questions enumerated in earlier sections that S1's verification must resolve before merge. Quote the open question text from the discovery report's Section "Open Questions for Empirical Tests in Stage 5".]
```

Mechanism choice guidance:

The spike implementer should weigh:
- Preamble-only: cheapest, fits ADR-003 sync model, but unenforced (same failure mode as the existing CRITICAL warning that already exists at skills/build/SKILL.md:11)
- Preamble + UserPromptExpansion hook: programmatic enforcement at invocation gate via `permission_mode` field; bypasses prose-read failure; requires settings.json.template update and skills/setup/SKILL.md Step 5d update; UserPromptExpansion firing under plan mode is presumed but not empirically confirmed
- Inconclusive: declares the mechanism cannot be chosen with confidence within the timebox; S1 defaults to preamble-only with abort-with-redirect on detection (per S1 fallback AC)

Recommended mechanism (the implementer may challenge): **preamble + lightweight hook**. The discovery surfaced `permission_mode` as a programmatic signal that was unknown when E03 was written. UserPromptExpansion fires before the skill body is read, eliminating the prose-read failure mode that has already produced the documented bug. ADR-001's hook objection is about mid-pipeline stage coupling, not about gating skill invocation entry — distinguish in ADR-009. The line-cap budget pressure (fix/SKILL.md at 299/300) is best handled by extracting shared preamble prose per the budget contract rather than by avoiding the change.

If the implementer concludes preamble-only or inconclusive instead, document the rationale rigorously — this conclusion ships with the v0.1.5 release and will be referenced as ADR-009 design context.

After writing Section 5, perform self-verification by running these checks:

```
# Check 1: doc has all 5 sections
rg -c "^## Section [12345]" docs/planning/spikes/plan-mode-detection-findings.md
# Expected: 5

# Check 2: conclusion is one of the three allowed values
rg "^\*\*Mechanism choice:\*\*" docs/planning/spikes/plan-mode-detection-findings.md
# Expected: one of "preamble-only" / "preamble + lightweight hook" / "inconclusive"

# Check 3: at least one dogfood test result is documented
rg "dogfood" docs/planning/spikes/plan-mode-detection-findings.md
# Expected: at least 1 match in Section 3 referencing observable session state

# Check 4: every AC bullet is addressed
# AC1 (signals enumerated) — Section 1 with table
# AC2 (auto-engagement triggers, empirically confirmed) — Section 2 with empirical observation
# AC3 (ExitPlanMode dogfood result) — Section 3 with at least one observation
# AC4 (hook event firing under plan mode) — Section 4 with table
# AC5 (conclusion is one of three values) — Section 5 with explicit mechanism choice
# AC6 (no "both as belt-and-suspenders" without observed failure) — Section 5 explicitly addresses this if conclusion is preamble+hook

# Check 5: file size sanity
wc -l docs/planning/spikes/plan-mode-detection-findings.md
# Expected: 100-300 lines (spike output, not a comprehensive ADR)

# Check 6: no broken internal links
rg "skills/build/SKILL.md|skills/fix/SKILL.md|.roughly/known-pitfalls.md" docs/planning/spikes/plan-mode-detection-findings.md | head -5
# Expected: at least 3 file references; the relative paths in the doc must resolve from docs/planning/spikes/
```

If any check fails, fix the doc inline and re-run. Return a summary of what was written and the check results.

**Verify:** All 6 checks above return expected output. The doc reads coherently from top to bottom; the conclusion follows from the evidence in Sections 1–4.

**UI:** no

## Blast Radius

**Do NOT modify:**
- skills/build/SKILL.md (S1's job)
- skills/fix/SKILL.md (S1's job)
- .roughly/known-pitfalls.md (S1's job — this story does NOT update the pitfall entry; it only quotes it)
- Any agent file in agents/ (no agent change in S0)
- docs/adrs/ (ADR-009 is S1's deliverable, not S0's)
- docs/ROADMAP.md, CLAUDE.md, CHANGELOG.md (no count updates in S0)
- Any file in .claude/ — no hook changes in S0; the spike output recommends but does not implement

**Watch for:**
- Accidentally writing the doc in `docs/plans/` instead of `docs/planning/spikes/` (the file paths look similar)
- Accidentally implementing S1 (this is a research spike — output is prose, not code or skill changes)
- Conclusion drift: Sections 1–4 are evidence; only Section 5 may make a recommendation. Do not let Sections 1–4 sneak in mechanism advocacy.
- Line-cap budget references: this doc is in `docs/planning/spikes/`, so the 300-line `skills/*/SKILL.md` cap does NOT apply to the doc itself. The cap is referenced as a CONSTRAINT the conclusion must consider — not a constraint on the doc.

## Conventions

- Spike output is a working scratch doc per E03 epic L62: "scratch output, not committed if conclusions land in S1." Treat it as a draft that will be referenced by ADR-009 (S1) and possibly retired.
- Cite ADRs by full path: `docs/adrs/ADR-001-verify-plan-as-subagent.md`, `docs/adrs/ADR-003-shared-spec-reviewer.md`.
- Follow the wording established in `.roughly/known-pitfalls.md:14` when quoting the existing pitfall — do not paraphrase.
- The spike implementer should NOT make claims not supported by either documented citation or directly observable session state. Empirical gaps must be flagged explicitly with "presumed", "unverified", or "empirical gap" — not stated as fact.
