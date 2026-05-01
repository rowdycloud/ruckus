# E03 — Trust hardening + ergonomics + CI

**Status:** Drafted (PM handoff for v0.1.5)
**Target version:** v0.1.5
**Target effort:** 6-7 wk
**Dependencies:** E01 (pipeline foundation, audit follow-up shipped v0.1.3); E02 (rename to `roughly` shipped v0.1.4 — namespace, dotdir, version-line identifier all assumed in place)

---

## Release thesis

Roughly's value is enforcement. Enforcement with known holes is theater. v0.1.5 closes the silent-failure modes still present in the pipeline — plan-mode hijack, untested maturity gaps, ambiguous abort UX — and lays the regression-coverage groundwork (plugin self-test CI) that every subsequent release will depend on.

Three clusters: **trust hardening** (S0–S6), **ergonomics** (S8–S10, S7 punted to v0.1.6), **CI** (S11). Plus **docs** (S12), which lands incrementally rather than as a final-week dump.

Scope is frozen. Items surfaced during epic writing that are clearly related but out of scope are listed under [v0.1.6 candidates](#v016-candidates).

---

## Risk register

1. **Plan-mode detection mechanism uncertainty (S1).** Plan mode is signalled to the orchestrator via a `<system-reminder>` block and `ExitPlanMode` tool availability — neither is a programmatic API a skill can introspect. The mechanism choice (preamble guard, hook, or both) is gated on the S0 spike. If the spike finds no reliable signal, S1 falls back to preamble-only and accepts a documented edge case where mid-pipeline auto-engagement bypasses the guard. Risk: enforcement still has a known hole post-v0.1.5; mitigated by the fallback being explicit, not silent.

2. **CI bootstrapping (S11).** The plugin tests itself against the repo containing the plugin. A naive run mutates `.roughly/`, writes plan files in `docs/plans/`, and may dirty the working tree. Self-test must run in an ephemeral worktree/checkout with strict teardown, or CI poisons source-repo state visible to subsequent commits. Risk: a CI run that "passes" but corrupts the dogfood `.roughly/` state masks bugs; mitigated by isolation contract in S11a.

3. **Docs scope creep (S12).** "roughly.dev v0.1.5 floor" is four pages, but the underlying surface area is 9 (10 with `/roughly:help`) skills + 7 agents + 8 ADRs. Without explicit per-page outlines and word budgets in the story, docs balloons and slips the release. Risk: docs becomes a final-week landmine; mitigated by docs stories laddering throughout the release rather than batch-landing.

4. **Retry-loop tuning regressions (S10).** Raising caps on cheap checks can hide flakiness; replacing hard escalation with prompts shifts cost to humans mid-pipeline. Each adjustment needs a before/after dogfood pass on a known case. Risk: silent trust degradation; mitigated by per-cap rationale recorded inline and dogfood verification gated by S11 CI.

5. **Stop-hook-v1 templating completion (S2).** This repo's [.claude/hooks/verify-all.sh](.claude/hooks/verify-all.sh) is a dogfood instance with project-specific drift checks (line caps for `agents/`, `.ruckus/` legacy detection, etc.) — it is not a plugin-shipped template. The maturity check must template a generic Stop hook into the user's `.claude/`, handling the case where the user already has a Stop hook configured (merge vs prompt vs decline). Risk: under-spec'd templating ships a hook that conflicts with an existing user hook; mitigated by explicit conflict-handling AC in S2.

6. **Skill line-cap ceiling.** [skills/build/SKILL.md](../../skills/build/SKILL.md) is at 296/300 lines, [skills/fix/SKILL.md](../../skills/fix/SKILL.md) at 299/300. The cap is enforced by [.claude/hooks/verify-all.sh:25](../../.claude/hooks/verify-all.sh#L25). S1, S2, S6, S9, and S10 all add lines to these two files; S3 retires two maturity-check blocks for net negative, but the residual headroom is thin. Risk: a story lands and pushes the file past 300, breaking the dogfood Stop hook; mitigated by the line-cap budget contract below.

7. **CI cost.** A full `/roughly:build` cycle in CI invokes Sonnet for orchestration, investigator, plan-reviewer, three parallel review agents, spec-reviewer per task, and code-reviewer at Stage 6. A single happy-path run is plausibly 100K+ Sonnet tokens; at ~100 PR pushes per release cycle, this is non-trivial spend. Risk: CI becomes a hidden release-cost driver; mitigated by S11b-2's minimal-task fixture and explicit token-budget AC.

---

## Line-cap budget contract

The dogfood Stop hook enforces a 300-line cap on every `skills/*/SKILL.md`. Build (296) and fix (299) are within ~1-4 lines of the cap as v0.1.5 begins. Cumulative additions from this epic plausibly exceed that headroom even with S3's retirements absorbing some, so the epic adopts a budget-tracking contract:

- **After each story merges**, the implementer runs `wc -l skills/build/SKILL.md skills/fix/SKILL.md` and records the deltas in the story's PR description.
- **If either file would land above 285** as a result of a story, that story must include a sub-task to extract repeated prose (preamble, ABORT HANDLING, maturity-check scaffolding) into a referenced block — using the same shared-reference pattern as [agents/agent-preamble.md](../../agents/agent-preamble.md) and ADR-003 — before adding new content.
- **Hard cap is 300**, enforced by [.claude/hooks/verify-all.sh:25](../../.claude/hooks/verify-all.sh#L25). A story whose merge would exceed 300 cannot ship.
- **The implementer may at any time decide to land a refactor-only story** (no behavior change, prose extraction only) ahead of the next pipeline-touching story if they project the budget will not hold. Such a refactor story is in scope for v0.1.5 even though it is not in the original story list.

This contract supersedes the per-story "No skill body exceeds 300 lines" ACs by making the constraint explicit and giving the implementer a clear sub-300 target plus an off-ramp.

---

## Stories

Stories are grouped by cluster. Sequencing — which is by dependency, not roadmap order — appears in [the final section](#sequencing).

### Trust hardening cluster

#### E03.S0: Plan-mode detection spike

**Maps to roadmap item:** #1 (gates S1)
**Type:** Investigation/spike (½-day timebox)

**Files touched:**
- `docs/planning/spikes/plan-mode-detection-findings.md` (new — scratch output, not committed if conclusions land in S1)

**Context:**

S1 needs a detection mechanism, but it's unclear what programmatic signals are available to a skill at runtime. This spike is bounded research: probe what the harness exposes, decide preamble-only vs preamble+hook, and document the answer before S1 starts. Half-day cap.

**Acceptance criteria:**
- [ ] Findings doc enumerates plan-mode signals observable to a skill at runtime (system reminder text, ExitPlanMode tool availability, any others)
- [ ] Findings doc identifies what triggers Claude Code's plan-mode auto-engagement (SessionStart hooks, settings, user toggles) — confirmed empirically, not from documentation alone
- [ ] Findings doc reports whether `ExitPlanMode` invoked from a skill body reliably exits plan mode, with at least one dogfood test result attached
- [ ] Findings doc lists which Claude Code hook events (SessionStart, PreToolUse, Stop, others) fire under plan mode and which do not
- [ ] Findings doc concludes with one of: **preamble-only** (default), **preamble + lightweight hook** (only if auto-engagement bypasses preamble), or **inconclusive — implementation must accept documented edge case** — with rationale
- [ ] No "both as belt-and-suspenders" outcome unless explicitly justified by a failure case observed during the spike

**Verification:**
- Spike output reviewed before S1 starts; conclusion drives S1's mechanism choice
- If timebox exceeded without conclusion, spike returns "inconclusive" and S1 proceeds preamble-only with a known-pitfalls.md entry documenting the gap

**Dependencies:** None — ships first.

**Out of scope:**
- Implementing the detection mechanism (that's S1)
- Writing tests for detection beyond what's needed to validate the spike's conclusion

---

#### E03.S1: Plan-mode auto-detect/exit at Stage 1 of build/fix

**Maps to roadmap item:** #1 (highest-value item in v0.1.5)

**Files touched:**
- [skills/build/SKILL.md](../../skills/build/SKILL.md) — preamble + Stage 1
- [skills/fix/SKILL.md](../../skills/fix/SKILL.md) — preamble + Stage 1
- [.roughly/known-pitfalls.md](../../.roughly/known-pitfalls.md) — extend the existing plan-mode hijack entry in the Domain-Specific section
- `docs/adrs/ADR-009-plan-mode-detection.md` (new) — documents the detection contract chosen in S0
- Possibly `.claude/hooks/<name>.sh` (new) — only if S0 concludes a hook is required

**Context:**

The plan-mode hijack is documented in the Domain-Specific section of [.roughly/known-pitfalls.md](../../.roughly/known-pitfalls.md): when plan mode is active during a `/roughly:build` or `/roughly:fix` invocation, plan-mode's workflow substitutes for Stages 1–4 and Stage 4's `/roughly:review-plan` dispatch is silently skipped. Without S1, ADR-001 (plan verification as blocking subagent) is unenforced — the build skill's review-plan call never fires.

S1 commits to **observable behavior only**, not a specific mechanism. Mechanism is chosen in S0. The mechanism is significant enough to warrant a new ADR (per CLAUDE.md's "all significant design changes need ADRs"), particularly because it adds a new manual-sync target to the agent-preamble pattern from ADR-003.

**Note on ADR numbering:** The plan-format-v2 ADR previously slotted as ADR-009 in the v0.2.0 roadmap is bumped to ADR-010. ADRs are numbered by landing order; v0.1.5's plan-mode-detection ADR ships first.

**Acceptance criteria:**
- [ ] When `/roughly:build` is invoked while Claude Code's plan mode is active, Stage 1 does not begin until plan mode is exited
- [ ] When `/roughly:fix` is invoked while Claude Code's plan mode is active, Stage 1 does not begin until plan mode is exited
- [ ] On detection, the orchestrator either invokes `ExitPlanMode` and continues into Stage 1, or aborts with a one-line redirect message (the choice depends on S0 findings). **Fallback:** if S0 is inconclusive, S1 defaults to abort-with-redirect, not ExitPlanMode invocation, because invoking a tool whose semantics are unverified inside a skill body has worse failure modes than aborting
- [ ] The detection contract is documented in [skills/build/SKILL.md](../../skills/build/SKILL.md) preamble and synced verbatim to [skills/fix/SKILL.md](../../skills/fix/SKILL.md) preamble — manual sync as with [agents/agent-preamble.md](../../agents/agent-preamble.md), no automation
- [ ] If a hook ships per S0 findings, the hook is added to [skills/setup/templates/settings.json.template](../../skills/setup/templates/settings.json.template) and templated into user projects on `/roughly:setup`
- [ ] **New ADR-009 (`docs/adrs/ADR-009-plan-mode-detection.md`)** documents: the detection mechanism chosen in S0 (preamble-only / preamble+hook / inconclusive), the rationale, the manual-sync targets if preamble-based, and any known edge cases. Status: Accepted
- [ ] [docs/adrs/README.md](../../docs/adrs/README.md) updated with ADR-009 entry; CLAUDE.md "8 ADRs" count updated to 9
- [ ] The plan-mode hijack entry in [.roughly/known-pitfalls.md](../../.roughly/known-pitfalls.md) Domain-Specific section is updated to reflect the new enforcement path; the silent-failure mode is recategorized as "blocked by S1 enforcement" not "open hole"

**Verification:**
- Manual dogfood: invoke `/roughly:build` from a session where plan mode is active before the command runs; confirm Stage 1 does not enter without an exit step
- Manual dogfood: same test for `/roughly:fix`
- CI dogfood (post-S11): scripted scenario asserts the abort/exit behavior under plan mode
- Re-read `.roughly/known-pitfalls.md` entry to confirm the rewrite is accurate

**Dependencies:** S0 (mechanism conclusion).

**Out of scope:**
- Detection of the generic `Plan` agent dispatch in non-plan-mode sessions (different concern; not a hijack)
- Hardening against hostile users who manually re-enter plan mode mid-pipeline (out of v0.1.5's threat model)

---

#### E03.S2: Stop-hook-v1 maturity check completion

**Maps to roadmap item:** #2

**Files touched:**
- [skills/build/SKILL.md](../../skills/build/SKILL.md) — Stage 8 maturity check section (`stop-hook-v1` block at L268)
- [skills/fix/SKILL.md](../../skills/fix/SKILL.md) — Stage 8 maturity check section (`stop-hook-v1` block at L271)
- [skills/setup/SKILL.md](../../skills/setup/SKILL.md) — Step 5d/5e settings.json handling AND initial setup offer (currently absent)
- `skills/setup/templates/verify-all-stop-hook.sh.template` (new — generic Stop hook template, **not** the dogfood [.claude/hooks/verify-all.sh](../../.claude/hooks/verify-all.sh) which has roughly-repo-specific checks)
- [skills/setup/templates/settings.json.template](../../skills/setup/templates/settings.json.template) — Stop hook entry, additive to existing PostToolUse formatter entry

**Context:**

`stop-hook-v1` exists as a maturity check stub in build/fix Stage 8 today: "If `.claude/settings.json` has no `Stop` hook AND verify-all has 2+ meaningful checks AND not declined, offer." But there is no template for the hook itself — accepting "yes" today does nothing because the orchestrator has no script to template.

S2 closes the gap: ship a generic Stop hook template, plumb it through setup and the maturity check, and handle conflict with existing user hooks. The dogfood [.claude/hooks/verify-all.sh](../../.claude/hooks/verify-all.sh) stays as-is (project-specific drift checks for the plugin's own development); this story produces a separate, project-agnostic template.

The Stop hook fires after **every** Claude turn — re-running test/build/full-verify on every turn would be unacceptably heavy. The template is therefore scoped to **fast** verification only.

**Acceptance criteria:**
- [ ] New template `skills/setup/templates/verify-all-stop-hook.sh.template` exists. The template runs only **fast** verification (default: type-check, if a type-check command is configured in CLAUDE.md / commands.md). Lint/format checks are opt-in. Test and build commands are explicitly excluded as too heavy for a hook firing on every Claude turn; a comment block at the top of the template states this rationale and tells users where to add slower checks (manual `/roughly:verify-all` invocation, CI, or pre-commit hook)
- [ ] The template is project-agnostic — no hard-coded paths, line caps, or `.ruckus/` legacy strings; placeholders used where setup must inject project specifics
- [ ] The template reports drift via `systemMessage` JSON when checks fail (matching the dogfood hook's output contract); silent on success
- [ ] [skills/setup/SKILL.md](../../skills/setup/SKILL.md) Step 5d (settings.json handling) is updated: when stop-hook-v1 is offered and accepted at initial setup, the Stop hook entry is added to `.claude/settings.json` **without modifying any existing `hooks.PostToolUse` entries** (formatter, etc.)
- [ ] [skills/setup/SKILL.md](../../skills/setup/SKILL.md) gains a `stop-hook-v1` offer in the initial setup flow (currently only in build/fix wrap-up), gated on the same condition as build/fix
- [ ] When the user accepts `stop-hook-v1`, the template is copied to `.claude/hooks/<name>.sh` and the `Stop` entry added to the user's `.claude/settings.json`
- [ ] If `.claude/settings.json` already has a `Stop` hook, the orchestrator prompts: keep existing / replace / merge / decline — no silent overwrite. **Merge** writes both hooks as separate entries in the `Stop` hooks array (using Claude Code's native hook-array support at the matcher level — no wrapper scripts)
- [ ] Acceptance is recorded as `stop-hook-v1-added YYYY-MM-DD` in `.roughly/workflow-upgrades`; decline is recorded as `stop-hook-v1-declined`
- [ ] The build/fix Stage 8 `stop-hook-v1` offer text is updated to reflect the new templating path (no longer a no-op)

**Verification:**
- Dogfood `/roughly:setup` in a fresh project that has no `.claude/settings.json`; accept the offer; confirm hook file written, settings entry added, and `.roughly/workflow-upgrades` updated
- Dogfood `/roughly:setup` in a project that already has a `Stop` hook; confirm the conflict prompt appears and each branch behaves correctly
- Manually trigger the templated hook (`bash .claude/hooks/<name>.sh`) and confirm it reports drift correctly when verify-all fails

**Dependencies:** S3 (retire test-verify-v1 / pitfalls-organized-v1) lands first to avoid double-touching the maturity check section.

**Out of scope:**
- Replacing the dogfood [.claude/hooks/verify-all.sh](../../.claude/hooks/verify-all.sh) with the templated version
- Bumping `stop-hook-v1` to v2 (no change of behavior justifies a version bump per ADR-005)
- Cross-platform Stop hook support beyond bash (Windows users out of v0.1.5 threat model)

---

#### E03.S3: Retire test-verify-v1 and pitfalls-organized-v1

**Maps to roadmap item:** #3

**Files touched:**
- [skills/build/SKILL.md:260-269](../../skills/build/SKILL.md#L260-L269) — remove `pitfalls-organized-v1` and `test-verify-v1` blocks
- [skills/fix/SKILL.md:263-271](../../skills/fix/SKILL.md#L263-L271) — same
- [agents/doc-writer.md](../../agents/doc-writer.md) — fold trigger logic into known-pitfalls write path
- [docs/adrs/ADR-005-versioned-maturity-checks.md](../../docs/adrs/ADR-005-versioned-maturity-checks.md) — footnote noting retirement (not a new ADR)

**Context:**

These two checks fire at Stage 8 wrap-up of every build/fix run. `pitfalls-organized-v1` triggers when known-pitfalls.md exceeds 80 lines; `test-verify-v1` triggers when test config exists but verify-all's test step is a placeholder. Both are work that the doc-writer agent — which already runs after every successful build/fix — could perform contextually as part of its known-pitfalls write path.

Retiring them from the maturity-check loop simplifies wrap-up, removes nag patterns, and centralizes pitfall hygiene. The risk is coverage loss: doc-writer fires only on pipeline-driven writes, not on manual edits to `.roughly/known-pitfalls.md`. See [open questions](#open-questions).

**Acceptance criteria:**
- [ ] `pitfalls-organized-v1` and `test-verify-v1` blocks removed from [skills/build/SKILL.md](../../skills/build/SKILL.md) and [skills/fix/SKILL.md](../../skills/fix/SKILL.md) maturity check sections
- [ ] [agents/doc-writer.md](../../agents/doc-writer.md) gains an organize-suggestion step: when about to write to known-pitfalls.md, if the post-write file would exceed 80 lines, append a one-line note suggesting reorganization
- [ ] [agents/doc-writer.md](../../agents/doc-writer.md) gains a verify-all test integration suggestion: when test config is detected (presence of `package.json` test script, `pytest.ini`, etc.) and the verify-all test command is a placeholder per CLAUDE.md, append a one-line note suggesting adding the test step
- [ ] [docs/adrs/ADR-005-versioned-maturity-checks.md](../../docs/adrs/ADR-005-versioned-maturity-checks.md) gains a footnote noting `pitfalls-organized-v1` and `test-verify-v1` were retired in v0.1.5 (formal retirement, not a version bump per the ADR's reasoning)
- [ ] Existing entries in `.roughly/workflow-upgrades` for these check IDs are not auto-cleaned (they remain as historical record)
- [ ] No skill body grows past 300 lines as a result of changes (verify per CLAUDE.md cap)

**Verification:**
- Dogfood `/roughly:build` on a project where known-pitfalls.md is 85 lines; confirm doc-writer's note appears in the wrap-up summary, NOT a Stage 8 maturity-check prompt
- Dogfood `/roughly:fix` on a project with `package.json` test script and placeholder verify-all test step; confirm doc-writer's suggestion appears
- `wc -l skills/build/SKILL.md skills/fix/SKILL.md` ≤ 300 each

**Dependencies:** None blocking; sequenced before S2 to avoid double-touching maturity check sections.

**Out of scope:**
- Bumping `investigator-v1` or `stop-hook-v1` versions
- Adding new maturity checks to replace these
- Cleaning up historical `pitfalls-organized-v1-declined` entries from existing user `.roughly/workflow-upgrades` files

---

#### E03.S4: Pre-flight migration check in remaining 2 skills

**Maps to roadmap item:** #4

**Files touched:**
- [skills/audit-epic/SKILL.md](../../skills/audit-epic/SKILL.md) — preamble (mirror existing pattern from build/fix L19)
- [skills/verify-all/SKILL.md](../../skills/verify-all/SKILL.md) — preamble (same)

**Context:**

6 of 9 skills currently abort with a redirect to `/roughly:upgrade` if legacy `.ruckus/` state is detected (build, fix, review, review-plan, review-epic, setup). The roadmap line "remaining 3" is imprecise — `/roughly:upgrade` is the migration target, not a redirect candidate, so the actual scope is 2 skills: audit-epic and verify-all. Marker-aware resume improvements within `/roughly:upgrade` are surfaced as a [v0.1.6 candidate](#v016-candidates).

ROADMAP.md item 4 wording is updated separately as part of this story.

**Acceptance criteria:**
- [ ] [skills/audit-epic/SKILL.md](../../skills/audit-epic/SKILL.md) preamble contains the standard pre-flight migration check: "If `.ruckus/.migration-in-progress`, `.ruckus/known-pitfalls.md`, or `.ruckus/workflow-upgrades` exists, abort with: 'Legacy `.ruckus/` state detected... Run `/roughly:upgrade` to migrate or resume, then re-run.' A `.ruckus/` directory containing only user-extras (post-`leave` state from a completed upgrade) is fine — proceed."
- [ ] [skills/verify-all/SKILL.md](../../skills/verify-all/SKILL.md) preamble contains the same check
- [ ] Wording is identical across all 8 skills that now have the check (audit-epic, build, fix, review, review-plan, review-epic, setup, verify-all). Verified at landing time by `rg -c "Legacy \`.ruckus/\` state detected" skills/*/SKILL.md` returning 8 matches, all with identical surrounding context. Drift-check automation (e.g., extending `.claude/hooks/verify-all.sh`) is **out of scope** for this story — flagged as a v0.1.6 candidate
- [ ] [docs/ROADMAP.md](../../docs/ROADMAP.md) item 4 wording corrected to "Pre-flight migration check in remaining 2 skills (currently 6/9, upgrade excluded by design)"
- [ ] No skill body grows past 300 lines

**Verification:**
- `rg -n "Legacy \`.ruckus/\` state detected" skills/` returns matches in 8 skills (build, fix, review, review-plan, review-epic, setup, audit-epic, verify-all)
- Manual dogfood: create a fake `.ruckus/.migration-in-progress` file; invoke `/roughly:audit-epic` and `/roughly:verify-all`; confirm both abort with the redirect message

**Dependencies:** None; independent of pipeline changes.

**Out of scope:**
- Marker-aware resume improvements in [skills/upgrade/SKILL.md](../../skills/upgrade/SKILL.md)
- Adding pre-flight to `/roughly:help` (S8 will define this on its own)

---

#### E03.S5: Document Edit `replace_all` dual-semantic-token failure

**Maps to roadmap item:** #5

**Files touched:**
- [CONTRIBUTING.md](../../CONTRIBUTING.md) — new "Tooling pitfalls" section (or equivalent)

**Context:**

The S02.7 wrap-up incident (recorded at [.roughly/known-pitfalls.md:38](../../.roughly/known-pitfalls.md#L38)) showed that `Edit`'s `replace_all: true` is dangerous when the same token serves dual semantic roles in a file — legacy detection code and user-facing prose both contained "ruckus" in [.claude/hooks/verify-all.sh](../../.claude/hooks/verify-all.sh), and a bulk replacement silently inverted the legacy detector. This is a contributor pitfall, not a runtime issue — prose-only documentation is sufficient.

Code-level defense is explicitly deferred per the roadmap's "Deferred" section ("Edit replace_all code-level defense: prose-only in v0.1.5; code defense waits for a second occurrence").

**Acceptance criteria:**
- [ ] [CONTRIBUTING.md](../../CONTRIBUTING.md) gains a "Tooling pitfalls" section (or extends an existing pitfalls/conventions section)
- [ ] The section names the specific failure mode, names the at-risk tools (Edit, IDE find/replace, sed), and includes a worked example drawn from the dual-semantic-token incident recorded in [.roughly/known-pitfalls.md](../../.roughly/known-pitfalls.md) (the `ruckus` token serving as both legacy detector and prose token in `verify-all.sh`)
- [ ] The section names the verification commands: `rg -nw 'old-token' <file>` and `rg -nw 'new-token' <file>` after a bulk replacement, with the expected match outputs to compare against
- [ ] **Self-verification:** running the documented verification commands against the actual incident file ([.claude/hooks/verify-all.sh](../../.claude/hooks/verify-all.sh)) produces the expected match counts described in the worked example (validates that the doc's example holds against the real-world artifact)
- [ ] Section length is 15-30 lines — long enough to be load-bearing, short enough to read in 60 seconds
- [ ] No skill, agent, or hook changes — prose-only

**Verification:**
- Reviewer reads the section cold (without prior incident context) and can describe the failure mode in their own words
- `wc -l` of the new section is in 15-30 line range
- Run the doc's example commands against [.claude/hooks/verify-all.sh](../../.claude/hooks/verify-all.sh); confirm the match counts match the doc's claim

**Dependencies:** None. Slot wherever fits.

**Out of scope:**
- Code-level defense (Edit tool wrapper, lint rule, etc.) — deferred per roadmap
- Generalizing to other dual-semantic-token risks beyond this incident

---

#### E03.S6: Plan-format version field

**Maps to roadmap item:** #6

**Files touched:**
- [skills/build/SKILL.md](../../skills/build/SKILL.md) — Stage 3 plan template
- [skills/fix/SKILL.md](../../skills/fix/SKILL.md) — Stage 3 plan template
- (Possibly) [skills/build/spec-reviewer-prompt.md](../../skills/build/spec-reviewer-prompt.md) reference copy — for sync only, not behavior

**Context:**

v0.2.0 will introduce plan format v2 (complexity flag, ADR-009). v0.1.5 adds a forward-compat version line so v0.2.0's migration step can detect existing plans by version. **review-plan does NOT consume the field in v0.1.5** — that's v0.2.0's job. The field exists; nothing reads it yet.

**Acceptance criteria:**
- [ ] Plan template in [skills/build/SKILL.md](../../skills/build/SKILL.md) Stage 3 includes a `Plan-format-version: 1` line as a markdown body line, placed between the `# Implementation Plan: [feature name]` title and the `## File Table` section. Format mirrors `.roughly/workflow-upgrades` style (single-line key-value, no frontmatter delimiters, no HTML comment) so a future migration step can grep for it with `rg '^Plan-format-version:'`
- [ ] Plan template in [skills/fix/SKILL.md](../../skills/fix/SKILL.md) Stage 3 includes the same line in the same position
- [ ] [skills/review-plan/SKILL.md](../../skills/review-plan/SKILL.md) is unchanged — it does not validate, parse, or branch on the version field in v0.1.5
- [ ] The template change is reflected in spec-reviewer prompt reference copies (no runtime impact)
- [ ] No new ADR for the version field itself — the plan-format-v2 ADR (now **ADR-010**, bumped from ADR-009 to make room for S1's plan-mode detection ADR) lands in v0.2.0 per roadmap and folds the version-field rationale in
- [ ] Documentation (CHANGELOG entry under "Added") notes the field is forward-compat only

**Verification:**
- Dogfood `/roughly:build`; confirm generated plan file at `docs/plans/<name>-plan.md` has `Plan-format-version: 1` near the top
- Dogfood `/roughly:fix`; same
- `rg -n 'Plan-format-version' skills/review-plan/SKILL.md` returns no matches (review-plan doesn't consume the field)

**Dependencies:** None. Lands early so v0.2.0 work can begin parallel.

**Out of scope:**
- Any logic that reads or validates the version field
- Migration of existing plans in `docs/plans/` to add the field (those are historical artifacts)
- ADR for the field itself (folded into ADR-009 in v0.2.0)

---

### Ergonomics cluster

> **Note:** S7 (in-session maturity offers at Stage 1) was scoped out of v0.1.5 during epic review. Rationale: complexity-vs-value ratio is questionable when the headline win is closing the plan-mode hijack, the line-cap budget is tight, and the underlying UX heuristic ("users aren't in the mood at Stage 8") is unmeasured. Moved to [v0.1.6 candidates](#v016-candidates) where it can be revisited with feedback from v0.1.5 dogfood.

#### E03.S8: `/roughly:help` command

**Maps to roadmap item:** #8

**Files touched:**
- `skills/help/SKILL.md` (new — 10th skill)
- [README.md](../../README.md) — mention in commands table
- [CLAUDE.md](../../CLAUDE.md) structure table — add help skill

**Context:**

There's no in-CLI overview. Users discover commands by reading SKILL.md files or the README. `/roughly:help` adds a structured at-a-glance view: list of commands grouped by purpose, current pipeline state if applicable, and current maturity check status.

Unlike pipeline/coordinator skills, this one is interactive and informational — not a gate. **`disable-model-invocation: false`**.

**Acceptance criteria:**
- [ ] New skill at `skills/help/SKILL.md` with frontmatter `name: help`, `description: <one line>`, `disable-model-invocation: false`
- [ ] Skill body under 300 lines
- [ ] Output structure: (a) commands grouped by cluster (pipeline / coordinator / utility), (b) current `.roughly/workflow-upgrades` state (which maturity checks added, which declined), (c) current pipeline state if a `docs/plans/<name>-plan.md` exists for an in-progress feature
- [ ] If multiple in-progress plan files are detected in `docs/plans/`, list each with its modified date and ask the user which is current — do not silently assume the most-recent one
- [ ] Skill respects pre-flight migration check (S4 conventions don't apply here — help is the recovery path itself, like upgrade)
- [ ] [README.md](../../README.md) commands table updated to include `/roughly:help`
- [ ] [CLAUDE.md](../../CLAUDE.md) structure table updated to include the new skill (count goes from 9 to 10)
- [ ] Plugin loads: `claude --plugin-dir <repo>` from a fresh project shows `/roughly:help` in autocomplete

**Verification:**
- Dogfood `/roughly:help` in a fresh project; confirm output covers all three sections cleanly
- Dogfood `/roughly:help` in this repo (mid-pipeline state); confirm pipeline-state section reports correctly
- Plugin manifest test: confirm 10 skills load

**Dependencies:** Late-cluster — depends on S2 maturity-check refactor and S3 retirements being settled, since the help output reflects those states.

**Out of scope:**
- Interactive command launch (e.g., picking a command from the help output and invoking it)
- Localization
- Help-as-a-subagent (this is a skill, not an agent)

---

#### E03.S9: Situation-specific abort prose at every pipeline failure point

**Maps to roadmap item:** #9

**Files touched:**
- [skills/build/SKILL.md](../../skills/build/SKILL.md) — every gate's abort branch
- [skills/fix/SKILL.md](../../skills/fix/SKILL.md) — same
- [skills/review-plan/SKILL.md](../../skills/review-plan/SKILL.md) — abort branches in NEEDS REVISION path
- [skills/review-epic/SKILL.md](../../skills/review-epic/SKILL.md) — abort on Risk verdict
- [skills/audit-epic/SKILL.md](../../skills/audit-epic/SKILL.md) — abort on AC failure threshold

**Context:**

Today's [skills/build/SKILL.md](../../skills/build/SKILL.md) ABORT HANDLING section (around L210) is good — it differentiates by stage (no files, plan written, implementation started). But many individual gates (review-plan NEEDS REVISION abort, Stage 6 review-fix max-cycles abort, Stage 5c question-loop max abort) emit generic "abort" messages that don't tell the user what state files are in. S9 is a sweep: every abort point produces a message naming the stage, the reason, and the state of files.

**Acceptance criteria:**
- [ ] Every abort branch in build/fix/review-plan/review-epic/audit-epic produces a message that includes: (a) what stage aborted (literal substring `Stage [N]` or `Stage [name]`), (b) why (one-line reason), (c) what files exist and in what state (plan exists/doesn't, implementation files staged/unstaged, etc.), (d) the recovery action (re-run / manually edit / escalate), with the literal word `recovery` or `next step` so the message is greppable
- [ ] **Positive verification:** for each pipeline skill, every abort branch matches the regex pattern `Stage .* (aborted|stopped|cannot proceed)` AND includes one of `recovery|next step|re-run|escalate` in the same message block. Verified by reviewer walking each abort site, not by a single `rg` invocation
- [ ] **Negative verification:** `rg -n 'aborted\b' skills/ | rg -v 'Stage'` returns no matches — every "aborted" mention is paired with a stage marker
- [ ] Existing ABORT HANDLING block in build/fix retained verbatim as the canonical state-of-files reference. **Diff verification:** `git diff` of build/fix at the ABORT HANDLING block (currently around L274-296 in build, L277-299 in fix) shows zero line changes; only per-gate abort messages elsewhere in the files are updated
- [ ] Abort message structure (a/b/c/d) MAY be encoded as a single template block referenced by gates rather than duplicated per gate, to keep the line-cap budget healthy
- [ ] Line-cap budget contract (see [Line-cap budget contract](#line-cap-budget-contract)) — neither file exceeds 300 lines

**Verification:**
- `rg -n 'abort' skills/` and review every match; confirm each abort message names stage, reason, file state, recovery
- Dogfood: trigger review-plan NEEDS REVISION + abort; confirm message tells user the plan file path, that it's been written but not consumed, and how to revise
- Dogfood: trigger Stage 6 review-fix max-cycles; confirm message names which findings remain and which files are dirty

**Dependencies:** Late-cluster — sweeps across all pipeline skills, lands after pipeline-touching stories stabilize to avoid merge churn.

**Out of scope:**
- Abort handling in `/roughly:setup` and `/roughly:upgrade` (those are setup flows, not pipelines)
- Abort handling in `/roughly:help` (added in S8)
- Localization

---

#### E03.S10: Retry-loop tuning

**Maps to roadmap item:** #10

**Files touched:**
- [skills/build/SKILL.md:172](../../skills/build/SKILL.md#L172) — Stage 5c questions cap
- [skills/build/SKILL.md:176-181](../../skills/build/SKILL.md#L176-L181) — Stage 5c quality auto-fix cap
- [skills/build/SKILL.md:199](../../skills/build/SKILL.md#L199) — Stage 6 review-fix cycles cap
- [skills/fix/SKILL.md:181](../../skills/fix/SKILL.md#L181) — same questions cap
- [skills/fix/SKILL.md:185-190](../../skills/fix/SKILL.md#L185-L190) — same auto-fix cap
- [skills/fix/SKILL.md:204](../../skills/fix/SKILL.md#L204) — same review-fix cycles cap

**Context:**

v0.1.2 capped four previously-unbounded loops (per [CHANGELOG.md:82](../../CHANGELOG.md#L82)). Caps are conservative — set to "max 2" across the board with hard escalation to human on hit. v0.1.5 audits each cap individually: cheap checks may raise the cap (e.g., type-check fixes are nearly free), expensive ones may convert hard escalation to a prompt ("Continue with another auto-fix attempt? (yes / escalate)").

Each cap decision needs a before/after dogfood pass on a known case to verify behavior change is what was intended.

**Acceptance criteria:**
- [ ] All four cap sites audited; for each, the story records: (a) keep at 2, (b) raise to N, or (c) convert hard escalation to prompt — with rationale recorded inline as a one-line comment in the SKILL.md or in a new short ADR (decision pending — see [open questions](#open-questions))
- [ ] Stage 5c questions cap: decision recorded; if raised, cheap check (e.g., questions about clarification only — never about scope); if converted to prompt, prompt is one line and resolved in <100 tokens
- [ ] Stage 5c quality auto-fix cap: decision recorded; cheap auto-fix candidates (type-check, lint formatter) may raise; expensive ones (test fixes, refactors) stay at 2 or convert to prompt
- [ ] Stage 6 review-fix cycles cap: decision recorded; this is the most expensive loop — defaults to staying at 2 unless evidence supports raising
- [ ] Each adjusted cap has a before/after dogfood pass on a known case: a build/fix run that previously hit the cap, re-run after the change, with documented behavior delta
- [ ] CHANGELOG entry under "Changed" lists each cap and its v0.1.5 disposition
- [ ] No skill body exceeds 300 lines

**Verification:**
- Dogfood replay of each cap-hit case (test fixtures from S11b-2 CI may help here)
- `rg -n 'max 2|max-2' skills/build/SKILL.md skills/fix/SKILL.md` returns expected matches given the per-cap decisions
- ADR review (if a new ADR is added)

**Dependencies:** S11 (CI) — benefits from regression coverage so cap adjustments are validated, not just edited.

**Out of scope:**
- Adding new caps to currently-uncapped loops (none exist in v0.1.5)
- Cap adjustments outside build/fix (review-epic, audit-epic, etc. — different concern)

---

### CI cluster

#### E03.S11a: Plugin self-test CI scaffolding

**Maps to roadmap item:** #11 (part 1)

**Files touched:**
- `.github/workflows/dogfood.yml` (new)
- `scripts/ci-dogfood.sh` (new)
- [CONTRIBUTING.md](../../CONTRIBUTING.md) — CI section (where to find logs, how to reproduce locally)

**Context:**

The plugin tests itself against the repo containing the plugin. Bootstrapping concerns:
- The dogfood run mutates `.roughly/`, writes plan files in `docs/plans/`, and may dirty the working tree
- A failed run leaves partial state (incomplete plan files, marker files, etc.) that can confuse subsequent CI runs and human review
- `claude` CLI usage in CI requires authentication, which is non-trivial to manage in GitHub Actions

S11a establishes the isolation contract: an ephemeral worktree, scoped teardown, and a no-pollution AC. The actual CLI invocation lands in S11b-1 (smoke test) and the full build-cycle scenario in S11b-2.

**Acceptance criteria:**
- [ ] `.github/workflows/dogfood.yml` created; runs on push to main and on PR; jobs named clearly (`dogfood-build-cycle` etc.)
- [ ] `scripts/ci-dogfood.sh` created; sets up an ephemeral git worktree at `/tmp/roughly-dogfood-${SHA}` containing the plugin checkout
- [ ] Worktree teardown runs on success AND failure (`trap cleanup EXIT`); failed runs do not leave state behind
- [ ] No dogfood run mutates the source-repo working tree visible to subsequent commits — verify by checking `git status --porcelain` is unchanged before and after a CI run
- [ ] `claude` CLI authentication is handled via a documented secret (e.g., `ANTHROPIC_API_KEY`); CONTRIBUTING.md explains how to set it
- [ ] At the `claude` invocation point, the script is a **no-op stub** in S11a (returns 0 without invoking the CLI). Real invocation lands in S11b-1 (smoke test) and S11b-2 (full scenario). This decouples scaffolding from S0/S1's mechanism findings
- [ ] `scripts/ci-dogfood.sh` is runnable locally with the same env vars, producing the same behavior
- [ ] CONTRIBUTING.md gains a CI section: where workflow logs live, how to reproduce a failure locally, what's in scope vs out of scope for CI, and the **token-cost expectations** for CI runs (S11b-1: ~5K tokens; S11b-2: ≤150K Sonnet tokens per run; CI budget caveats around PR push frequency)

**Verification:**
- Push a no-op branch to a fork; confirm dogfood.yml fires, completes (with a stub scenario), and tears down cleanly
- Locally invoke `bash scripts/ci-dogfood.sh`; confirm same behavior and no source-tree pollution. To verify no pollution: `git diff --quiet` exits 0 (no tracked diff) AND `[ -z "$(git status --porcelain)" ]` is true (no untracked or modified files in working tree)
- Inspect the worktree path during a run; confirm it's isolated from the source checkout

**Dependencies:** None for the scaffolding itself. The script is a no-op stub at the `claude` invocation point until S11b-1 lands; this decouples scaffolding from S0/S1's plan-mode mechanism findings, allowing S11a to land in parallel with the spike.

**Out of scope:**
- The CLI plumbing smoke test (S11b-1)
- The actual build-cycle scenario (S11b-2)
- Coverage of `/roughly:fix`, `/roughly:setup`, `/roughly:upgrade` (S11b-2 expands; for v0.1.5 happy-path-only)
- Caching node_modules / Claude state between runs (correctness first, perf later)

---

#### E03.S11b-1: CLI plumbing smoke test

**Maps to roadmap item:** #11 (part 2a — split during epic review)

**Files touched:**
- `scripts/ci-dogfood.sh` (extend with smoke step)
- `.github/workflows/dogfood.yml` (extend smoke job)

**Context:**

Before driving a full build cycle, prove the CLI plumbing works in CI: `claude --plugin-dir <repo>` against a minimal target, with auth and a deterministic exit. This proves S11a's isolation contract holds end-to-end and that auth secrets are correctly wired before anyone tackles the harder Stage-4-without-a-human problem.

S11b-1 lands ahead of S11b-2 so subsequent stories (S9, S10) ship with at least minimal regression scaffolding even if the full scenario isn't ready.

**Acceptance criteria:**
- [ ] `scripts/ci-dogfood.sh` smoke step invokes `claude` non-interactively in a way that **provably exercises both plugin loading and authenticated API access**. A minimal `--print`/`-p` invocation against a trivial prompt is the expected shape (e.g., `claude --plugin-dir $WORKTREE -p "respond with the literal string ok"` and assert the response contains `ok`). A bare `--version` is **not sufficient** — it can succeed without loading the plugin or making any API call, which would let the smoke test pass while the real integration path is still broken
- [ ] Plugin loading is asserted: the smoke step verifies that at least one plugin-defined slash command (e.g., `/roughly:setup`) appears in the CLI's command list / autocomplete output, not just that the CLI starts
- [ ] Auth via the documented `ANTHROPIC_API_KEY` secret is exercised — a missing/invalid secret produces a clear error in CI logs, not a hang. Tested by running the same step with the secret deliberately removed and confirming a recognizable auth-error string in the output
- [ ] The smoke step completes in under 60 seconds wall-clock
- [ ] Token cost cap: smoke step uses ≤5K tokens (the trivial-prompt invocation is sized to be a few hundred tokens; the cap leaves headroom for retries)

**Verification:**
- Push a change with an unset `ANTHROPIC_API_KEY` secret; confirm CI fails with the expected error message, not a timeout
- Push a clean change; confirm smoke step passes in <60s

**Dependencies:** S11a (scaffolding).

**Out of scope:**
- The full build-cycle scenario (S11b-2)
- Driving any pipeline command (`/roughly:build`, `/roughly:fix`, etc.)

---

#### E03.S11b-2: Scripted dogfood happy-path build cycle

**Maps to roadmap item:** #11 (part 2b — split during epic review)

**Files touched:**
- `scripts/ci-dogfood.sh` (extend with full scenario)
- `tests/fixtures/<name>/` (new — fixture repo for the scenario)

**Context:**

S11a establishes isolation; S11b-1 proves CLI plumbing; S11b-2 drives the actual scenario. The hard problem: a build cycle includes Stage 4 plan review, which today requires human input on PASS / NEEDS REVISION + override. CI must drive this without a human.

Options for the format are documented in [open questions](#open-questions); the story commits to a happy-path scenario only.

**Acceptance criteria:**
- [ ] `tests/fixtures/<name>/` contains a minimal repo (CLAUDE.md, one source file, a trivial test) that exercises the build pipeline end-to-end
- [ ] Fixture is a single-task plan ("add a constant" or similar) — explicitly chosen to minimize token cost
- [ ] `scripts/ci-dogfood.sh` invokes `/roughly:build` against the fixture for a small, deterministic feature
- [ ] The scenario succeeds: plan written, review-plan returns PASS, implementation runs, verify-all passes, wrap-up records workflow upgrades, no abort
- [ ] Scenario assertions check **structural properties** (plan file exists, contains `## Tasks`, has at least one task, review-plan returned PASS, `git status --porcelain` of the fixture repo shows expected diff) rather than full content match — this insulates the test from plan-format changes (e.g., S6's version line, future v0.2.0 format v2)
- [ ] CI fails loudly if any stage produces unexpected output (silent failure mode protection)
- [ ] CI fails loudly if Stage 4 review-plan is not invoked (plan-mode hijack regression protection — relies on S1)
- [ ] The scenario completes in under 5 minutes wall-clock on GitHub Actions standard runners
- [ ] **Token cost cap:** scenario uses ≤150K Sonnet tokens per run (sized for the minimal fixture); CI fails or warns if a run exceeds this, signaling fixture growth or pipeline regression
- [ ] Failure logs include enough context (stage reached, last 50 lines of output) to diagnose without re-running locally
- [ ] Fixture state is reset between runs — either via clean re-checkout of `tests/fixtures/<name>/` or explicit teardown of `tests/fixtures/<name>/.roughly/` and `tests/fixtures/<name>/docs/plans/`

**Verification:**
- Push a change that breaks Stage 4 dispatch; confirm CI fails with a clear message
- Push a change that breaks plan-mode detection (S1 regression); confirm CI fails with a clear message
- Push a clean change; confirm CI passes in <5 min and ≤150K tokens

**Dependencies:** S11a (scaffolding), S11b-1 (plumbing proven), S1 (plan-mode detection). S6 and S9 are NOT dependencies — S6's version line should not break the scenario (verified post-merge), and S9's abort prose improves diagnosis but is not required for the happy path.

**Out of scope:**
- `/roughly:fix` scenario (next release)
- `/roughly:setup` scenario (next release)
- Negative-path scenarios (review-plan NEEDS REVISION, Stage 6 max cycles, etc.)
- Performance benchmarking
- Cross-platform CI (Linux only)

---

### Docs cluster

> **Note:** Per [docs/planning/README.md:84](../../docs/planning/README.md#L84), the `roughly.dev` site is "out of repo scope; tracked separately." The PM prompt asserts docs are part of v0.1.5 DoD. **S12.0 must land before S12a/S12b** to resolve this contradiction; the docs cluster is gated on its outcome.

#### E03.S12.0: Resolve roughly.dev source location

**Maps to roadmap item:** #12 (gates S12a, S12b)
**Type:** Decision/scoping (½-day timebox)

**Files touched:**
- [docs/planning/README.md](../../docs/planning/README.md) — L84 deferred-items entry
- [docs/ROADMAP.md](../../docs/ROADMAP.md) — v0.1.5 item #12 wording
- [docs/planning/epics/E03-trust-and-ergonomics.md](./E03-trust-and-ergonomics.md) — S12a/S12b "Files touched" lists, after the decision

**Context:**

The DoD-vs-deferred-items contradiction was identified during epic writing. S12a and S12b cannot start until one of three options is chosen:
- **(a) In-repo source:** `docs/site/*.md` ships with the plugin; manual publish to roughly.dev is a separate, untracked step.
- **(b) Separate repo:** S12a/S12b are restructured to work against a `roughly-dev` repo with cross-repo coordination.
- **(c) Defer docs cluster from v0.1.5 DoD entirely:** roadmap item #12 moves to v0.1.6; docs/planning/README.md L84 stays as-is.

**Acceptance criteria:**
- [ ] One of (a), (b), or (c) is chosen and rationale recorded inline (1-2 paragraphs in the epic body where the cluster note currently sits)
- [ ] [docs/planning/README.md](../../docs/planning/README.md) L84 entry is updated or struck per the decision
- [ ] [docs/ROADMAP.md](../../docs/ROADMAP.md) v0.1.5 item #12 wording reflects the decision (possibly removed from v0.1.5 if (c))
- [ ] If (a): S12a/S12b "Files touched" lists confirmed accurate as `docs/site/*.md`
- [ ] If (b): S12a/S12b "Files touched" lists rewritten with cross-repo paths and the cross-repo coordination cost added to the risk register
- [ ] If (c): S12a/S12b are removed from the epic and listed in [v0.1.6 candidates](#v016-candidates); remaining stories renumbered if needed

**Verification:**
- Decision is recorded; no story in this epic still references "open question 4" as unresolved
- A reviewer can read the docs cluster intro and know exactly what files are produced and where they live

**Dependencies:** None — must land before S12a starts.

**Out of scope:**
- Implementation of any docs page (S12a/S12b)
- Site framework / build tooling for roughly.dev (always separate repo regardless of decision)

---

#### E03.S12a: roughly.dev landing + setup walkthrough

**Maps to roadmap item:** #12 (part 1)

**Files touched:**
- `docs/site/index.md` (new — landing page source)
- `docs/site/setup.md` (new — setup walkthrough source)

**Context:**

The roadmap floor for v0.1.5 docs is four pages: landing, pipeline overview, commands reference, setup walkthrough. S12a covers landing + setup walkthrough; S12b covers the other two. Splitting reduces final-week landmine risk.

**Acceptance criteria:**
- [ ] `docs/site/index.md` (landing): one-paragraph thesis (paraphrased from ROADMAP), three-bullet "what Roughly does" summary, install command, link to setup walkthrough; budget: 80-150 lines including markdown
- [ ] `docs/site/setup.md` (setup walkthrough): `/roughly:setup` step-by-step for a single-project install, including the maturity check decision tree (which checks fire when, what they offer); budget: 120-200 lines including code blocks
- [ ] Both pages cross-link to commands reference (S12b) with placeholder anchors that resolve once S12b lands
- [ ] No prose contradicts the in-repo SKILL.md files. Verified by extracting canonical claims (number of stages, command list, maturity check IDs) from the docs and comparing to the same claims grepped from SKILL.md sources; mismatches block landing
- [ ] No marketing voice ("industry-leading", "revolutionary", "powerful", "seamlessly", "robust", etc.) — banned-word list checked by `rg -i '<word>' docs/site/*.md`. **Tone verification:** a reviewer reads both pages cold and produces three takeaways; if those takeaways diverge from what SKILL.md / ROADMAP.md actually say, prose is rewritten

**Verification:**
- Reviewer reads both pages cold; can describe what Roughly does and run `/roughly:setup` correctly without reading SKILL.md
- `wc -l` on each file is within budget

**Dependencies:** None blocking; ladders early in the release.

**Out of scope:**
- Pipeline overview (S12b)
- Commands reference (S12b)
- Site framework / build tooling for roughly.dev (separate repo)
- Visual design beyond plain markdown

---

#### E03.S12b: roughly.dev pipeline overview + commands reference

**Maps to roadmap item:** #12 (part 2)

**Files touched:**
- `docs/site/pipeline.md` (new — pipeline overview)
- `docs/site/commands.md` (new — commands reference)

**Context:**

Pipeline overview = the 8 build stages + abort handling + maturity checks, written for a stranger who has not read SKILL.md. Commands reference = the 10 commands (post-S8) with one-line summary, when to use, what they produce.

**Acceptance criteria:**
- [ ] `docs/site/pipeline.md`: covers all 8 build stages with one paragraph each, plus abort handling and maturity checks; budget: 200-350 lines
- [ ] `docs/site/commands.md`: lists all 10 commands (`/roughly:build`, `/roughly:fix`, `/roughly:review`, `/roughly:review-plan`, `/roughly:review-epic`, `/roughly:audit-epic`, `/roughly:verify-all`, `/roughly:setup`, `/roughly:upgrade`, `/roughly:help`); each entry has: one-line summary, when to use, what it produces, link to relevant SKILL.md anchor; budget: 150-250 lines
- [ ] Cross-links from S12a's landing/setup pages resolve correctly
- [ ] No prose contradicts the in-repo SKILL.md files. Verified by extracting canonical claims from the docs (stage count, command list, maturity check IDs, ADR count) and grepping the same in SKILL.md sources; mismatches block landing
- [ ] No marketing voice; same banned-word check as S12a (`rg -i` against the list); reviewer-cold-read takeaways match SKILL.md content

**Verification:**
- Reviewer reads both pages cold; can describe the build pipeline accurately and pick the right command for a given situation
- `wc -l` on each file is within budget
- All cross-references resolve (no broken anchor links)

**Dependencies:** S8 (must include `/roughly:help` in commands reference — sequence S12b after S8 lands).

**Out of scope:**
- ADR summaries (deferred — link to ADRs is sufficient)
- Tutorial content beyond setup
- Migration guides from other workflows

---

## Open questions

These are surfaced in story bodies but consolidated here for the implementer's convenience.

1. **CI scripted build cycle format (S11b-2).** Options:
   - **(a) Heredoc-fed answers** — pipe canned PASS/override responses via stdin
   - **(b) Override-token env var** — set `ROUGHLY_CI_AUTO_PASS=true` in the build skill's review-plan dispatch
   - **(c) Mock-mode flag in build skill** — `/roughly:build --ci` shortcuts review-plan with a synthetic PASS verdict
   - Each has trade-offs: (a) most realistic but brittle to skill prompt changes; (b) clean but requires skill modification; (c) cleanest but skill modification is more invasive. Decision needed before S11b-2 implementation; S11b-1 (CLI smoke test) does not depend on this resolution.

2. **Maturity check replacement coverage (S3).** Doc-writer fires on pipeline-driven writes only. Manual edits to `.roughly/known-pitfalls.md` (user opening it in their editor) won't trigger the organize-suggestion. Acceptable coverage loss for v0.1.5, or push triggers into `.claude/hooks/verify-all.sh` (Stop hook from S2) so manual edits are caught at next session boundary?

3. **Retry-loop per-cap decisions (S10).** Each of the four caps may stay, raise, or convert to prompt. **Proposed defaults (challenge these before S10 lands):**
   - **Stage 5c questions cap:** keep at 2. Questions interrupt a fresh subagent — raising the cap risks runaway clarification loops on under-specified plans. Better to surface plan ambiguity at S0/Stage 4 review.
   - **Stage 5c quality auto-fix cap (type-check):** raise to 4. Type errors are nearly free to detect and re-fix; a 2-cap is conservative.
   - **Stage 5c quality auto-fix cap (lint/format):** raise to 4. Same reasoning — formatter changes are mechanical and safe.
   - **Stage 5c quality auto-fix cap (test fixes):** keep at 2. Test fixes are open-ended; runaway test-rewriting is a known failure mode.
   - **Stage 6 review-fix cycles cap:** keep at 2. Most expensive loop in the pipeline; raising it amplifies cost on already-expensive work. Consider converting hard escalation to a prompt only if dogfood evidence shows cycles 2-3 land legitimate fixes.
   The implementer should prepare a per-cap rationale comment in the SKILL.md edits documenting which default was kept vs. challenged and why, with a before/after dogfood case backing each change.

4. ~~**roughly.dev source location (S12).**~~ **Resolved by S12.0** — the docs cluster is gated on a ½-day decision story that picks one of (a) in-repo `docs/site/`, (b) separate repo, or (c) defer docs from v0.1.5 DoD. See [E03.S12.0](#e03s120-resolve-roughlydev-source-location).

---

## v0.1.6 candidates

Items surfaced during epic writing that are clearly related to v0.1.5 work but explicitly out of frozen scope:

- **In-session maturity offers at Stage 1 (former S7).** Originally scoped for v0.1.5 to evaluate `investigator-v1` and `stop-hook-v1` triggers up-front, before the user has invested effort in the build/fix run. Moved to v0.1.6 because: (a) line-cap budget on build/fix is tight, (b) the "users are tired by Stage 8" premise is unmeasured, (c) Stage-1 acceptance changes the semantics of `.roughly/workflow-upgrades` (records can persist for runs that subsequently abort). Revisit with v0.1.5 dogfood data on Stage 8 acceptance/decline rates.
- **Marker-aware resume improvements in [skills/upgrade/SKILL.md](../../skills/upgrade/SKILL.md)** — surfaced while scoping S4. Today's `/roughly:upgrade` migration logic handles `.ruckus/.migration-in-progress` markers, but there's room to make resume reporting cleaner (which steps already ran, which still need to). Not blocking v0.1.5 since the marker mechanism is correct as-is.
- **Expanded plan-mode signals if S0 spike reveals additional gaps** — if S0 finds the preamble-only mechanism leaves a known hole, additional defense (Stop-hook check, etc.) is a v0.1.6 candidate rather than v0.1.5 scope expansion.
- **Per-field maturity-check organization beyond v1 IDs** — S3's retirement raises the question of whether the existing v1 IDs are themselves the right grain. Deferred.
- **Manual-edit detection for `.roughly/known-pitfalls.md`** (relates to open question 2) — pushing organize-suggestion logic into the Stop hook so manual edits are caught.
- **CI coverage for `/roughly:fix`, `/roughly:setup`, `/roughly:upgrade`** (S11b-2 is happy-path build only). Per-command CI scenarios.
- **Negative-path CI scenarios** (review-plan NEEDS REVISION, Stage 6 max cycles, abort recovery).
- **Pre-flight wording drift detection in `.claude/hooks/verify-all.sh`** — surfaced in S4. Today's hook checks line caps and HTML comment integrity but not skill-prose uniformity. A drift check for the pre-flight migration block (8 skills must have identical wording) would catch silent regressions.
- **Refactor build/fix preamble + Stage 1 + Stage 8 prose into a shared reference** — surfaced by the line-cap budget contract. If the contract's "extract before adding" off-ramp gets used during v0.1.5, this becomes a real refactor; if it doesn't, it's still a debt to retire when the next big additive story lands.

---

## Sequencing

Order is by dependency, not roadmap item number.

| # | Story | Why this position |
|---|---|---|
| 1 | **E03.S0** (plan-mode spike) | ½-day investigation; gates S1 |
| 2 | **E03.S11a** (CI scaffolding) | Lands ahead of S1 — scaffolding script is a stub at the `claude` invocation point until S11b-1, so doesn't depend on plan-mode detection |
| 3 | **E03.S1** (plan-mode auto-detect/exit) | Highest-value item; unblocks safe CI dogfood runs |
| 4 | **E03.S11b-1** (CLI plumbing smoke test) | Proves auth + CLI plumbing in CI before subsequent prose-touching stories land |
| 5 | **E03.S12.0** (resolve roughly.dev source location) | Gates S12a/S12b; ½-day decision |
| 6 | **E03.S6** (plan-format version field) | Additive, low-risk; lands next so v0.2.0 work can begin parallel |
| 7 | **E03.S5** (CONTRIBUTING prose) | Independent, prose-only; slot anywhere |
| 8 | **E03.S4** (pre-flight in audit-epic + verify-all) | Independent of pipeline changes |
| 9 | **E03.S3** (retire test-verify-v1 / pitfalls-organized-v1) | Folds triggers into doc-writer; doesn't break anything |
| 10 | **E03.S2** (stop-hook-v1 templating) | After S3 to avoid double-touching maturity check section |
| 11 | **E03.S12a** (docs landing + setup) | Ladders mid-release rather than batch-landing; gated on S12.0 |
| 12 | **E03.S9** (situation-specific abort prose) | Sweep across pipeline skills; lands late to avoid merge churn |
| 13 | **E03.S10** (retry-loop tuning) | Late; benefits from CI regression coverage from S11 |
| 14 | **E03.S11b-2** (full dogfood scenario) | After pipeline-touching stories stabilize. NOT dependent on S6 or S9 — S6 is a compatibility check post-merge; S9 improves diagnosis but isn't required for the happy path |
| 15 | **E03.S8** (`/roughly:help` command) | Late; documents the final shape of the release |
| 16 | **E03.S12b** (docs pipeline + commands) | After S8 so commands reference includes `/roughly:help`; gated on S12.0 |

**Removed from v0.1.5:** S7 (in-session maturity offers at Stage 1) — moved to [v0.1.6 candidates](#v016-candidates).

---

## Definition of done

- All 16 stories merged (S0, S1, S2, S3, S4, S5, S6, S8, S9, S10, S11a, S11b-1, S11b-2, S12.0, S12a, S12b — note S7 punted to v0.1.6, S11b split into -1/-2, S12.0 added)
- v0.1.5 tag pushed
- CHANGELOG entry covers Added / Changed / Fixed / Notes for each story
- ROADMAP.md updated to reflect v0.1.5 shipped + v0.1.6 candidates surfaced (including former S7)
- CI dogfood run passing on main (S11b-2 happy path)
- roughly.dev pages live OR S12.0 chose option (c) and the docs cluster is explicitly deferred — both outcomes satisfy DoD
- ADR-009 (plan-mode detection) merged; CLAUDE.md ADR count updated to 9
- After every merge, `wc -l skills/build/SKILL.md skills/fix/SKILL.md` is recorded in PR description; final values both ≤300
