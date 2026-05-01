# E03 Epic Review — Trust hardening + ergonomics + CI

**Reviewed:** 2026-05-01
**Reviewer:** Roughly epic-reviewer (opus)
**Epic file:** [E03-trust-and-ergonomics.md](./E03-trust-and-ergonomics.md)

**Verdict:** Needs Revision

---

## Summary

E03 is an unusually well-structured epic — risk register, sequencing rationale, open questions, v0.1.6 candidates, and a release thesis are all present and sharp. The decomposition is sensible, the framing of trust-as-enforcement is on-thesis, and several of the more dangerous failure modes (Stop-hook conflict handling, CI source-tree pollution, plan-mode mechanism uncertainty) are explicitly named.

That said, three concerns block a "Ready" verdict:

1. The line-cap ceiling on `skills/build/SKILL.md` (296/300) and `skills/fix/SKILL.md` (299/300) makes simultaneous landing of S1 + S2 + S3 + S6 + S7 + S9 + S10 mathematically difficult without a refactoring story that does not exist in the epic.
2. Open Question #4 (`roughly.dev` source location) is a true blocker on S12a/S12b — the epic correctly calls this out but does not gate the docs stories on it, which means the cluster could land at the very end and discover the question is unresolved during a release crunch.
3. Several dependency claims in the sequencing table are weaker than asserted, and S0's spike is mis-bounded for the value at stake.

Plus a handful of cross-story factual errors that need correcting before implementation begins (most notably a misalignment between what S2 ships in `verify-all-stop-hook.sh.template` and what the dogfood `verify-all.sh` currently does).

---

## Findings by Dimension

### Technical Accuracy

- **S1/S0 — plan-mode detection mechanism is genuinely uncertain, and the spike timebox is too tight.** The epic correctly identifies that no programmatic API exists for detecting plan mode from inside a skill. But ½ day to definitively answer "does ExitPlanMode invoked from a skill body reliably exit plan mode" + "which hooks fire under plan mode" + "what triggers auto-engagement" is aggressive given that each of these requires a distinct dogfood scenario. Recommend either (a) expand timebox to 1 day with explicit checkpoint at half-day, or (b) narrow the spike to the single highest-value question (does `ExitPlanMode` work from a skill body) and treat the rest as known-unknown.

- **S1 AC ambiguity on the recovery path.** AC: "On detection, the orchestrator either invokes `ExitPlanMode` and continues into Stage 1, or aborts with a one-line redirect message (the choice depends on S0 findings)." The epic punts the choice to S0 but does not surface it as an open question. If S0 is inconclusive, S1 has no fallback semantics defined. Recommend: add to S1's "Out of scope" or open questions: "If S0 is inconclusive, S1 defaults to abort-with-redirect, not ExitPlanMode invocation, because invoking a tool whose semantics are unverified inside a skill body has worse failure modes than aborting."

- **S2 — Stop hook template and dogfood `verify-all.sh` diverge in non-trivial ways the epic understates.** The dogfood `.claude/hooks/verify-all.sh` doesn't run "verify-all commands from CLAUDE.md" (S2 AC #1) — it runs structural checks (line caps, agent preamble integrity, legacy path detection). The S2 AC says the template should "run verify-all commands from CLAUDE.md (or `.roughly/commands.md` if present), and report drift via `systemMessage` JSON when checks fail." That's a different design than the dogfood: the dogfood is structural drift detection, the template would be type-check/test/build re-execution. Re-running build/test on every Claude turn would be far too heavy — typical projects have multi-second builds. Recommend the AC be rewritten: the template runs only fast verification (type-check ideally, or an explicit "lightweight" subset of CLAUDE.md commands), with a comment explaining why test/build are excluded.

- **S2 conflict handling mechanism.** AC #5 says: "If `.claude/settings.json` already has a `Stop` hook, the orchestrator prompts: keep existing / replace / merge (chained execution) / decline — no silent overwrite." The "merge (chained execution)" branch is non-trivial — chaining bash hooks requires either wrapping both in a parent script or modifying `settings.json` to support a hook array (Claude Code does support hook arrays at the matcher level, so this is feasible). Recommend the AC specify: "merge writes both hooks as separate entries in the `Stop` hooks array" so the implementer doesn't invent a wrapper script.

- **S6 — `Plan-format-version: 1` line placement.** The current plan template (`skills/build/SKILL.md` and `skills/fix/SKILL.md`) is a markdown header `# Implementation Plan: [feature name]` followed immediately by a `## File Table` section. AC #1 says "after the title, before the body." The unstated question: is the version line (a) markdown body text on its own line, (b) HTML comment, (c) frontmatter? Each has different parsing properties for v0.2.0's migration step. Recommend the AC pin a format — e.g., a body line `Plan-format-version: 1` between title and File Table, mirroring the version-line conventions used in `.roughly/workflow-upgrades` (`roughly-version 0.1.4 2026-04-30`).

- **S11a/S11b — `claude` CLI in CI is not a solved problem.** The CI scaffolding AC #5 says "claude CLI authentication is handled via a documented secret (e.g., `ANTHROPIC_API_KEY`); CONTRIBUTING.md explains how to set it." This understates the problem: running `claude --plugin-dir` non-interactively against a fixture, with the orchestrator engaging human gates ("Plan drafted...Ready to implement? (yes / revise plan / abort)"), requires either non-interactive mode or canned-answer streaming. Open Question #1 captures this. Until it's resolved, S11a's AC is technically incomplete — "claude CLI authentication is handled" is necessary but not sufficient. Recommend: S11a explicitly defers the CLI-driving mechanism to S11b, and S11a's scope is reduced to (a) workflow yaml exists, (b) script exists with worktree isolation, (c) script is a no-op at the `claude` invocation point until S11b lands.

- **S4 — wording-drift detection AC is good but the Stop hook script doesn't do this today.** AC #3 says: "Wording is identical across all 8 skills [...] drift detected by `.claude/hooks/verify-all.sh` if added as a check." The current `.claude/hooks/verify-all.sh` checks line caps, agent-preamble HTML integrity, and legacy `.ruckus/known-pitfalls` references — it does not check pre-flight wording uniformity across skills. The AC's "if added as a check" is a soft phrasing that leaves the work undefined. Recommend: either commit to adding the check (and price it into S4) or strike the clause.

### Best Practices

- **No new ADR proposed for the plan-mode detection contract (S1).** The detection mechanism — whether preamble-only, hook-based, or both — is a design decision that future contributors will want to understand. CLAUDE.md says "All significant design changes need ADRs." Plan-mode detection is a more significant decision than S6's version field. Recommend: S1 spawns a new ADR documenting the detection contract, especially if S0 concludes "preamble + hook." This is also why the agent-preamble manual sync model exists (ADR-003) — adding a new sync target deserves a record.

- **S3 retirement contradicts ADR-005 — partial.** ADR-005 says "When a plugin update improves a check, the version increments [...] A previous `test-verify-v1-declined` entry does not suppress the v2 check." Retirement is not the same as a version bump — it removes the check entirely. The epic addresses this by saying "formal retirement, not a version bump" and adding an ADR-005 footnote (S3 AC #4). Acceptable, but recommend the footnote explicitly state: "Retirement is a third disposition alongside add/decline/version-bump, used when the check's value has migrated elsewhere. Existing `*-declined` entries in user `.roughly/workflow-upgrades` files become inert but are not removed." Otherwise the next time someone retires a check, they'll re-derive this rationale.

- **S8 `/roughly:help` `disable-model-invocation: false`.** Correctly identified as the exception. CLAUDE.md says coordinator and pipeline skills must have `disable-model-invocation: true`. Help is neither, so the epic's choice is right. Worth adding a note that this matches the existing setup/upgrade pattern.

- **S7 ergonomics offer at Stage 1 may break the Stage 8 record-keeping contract.** ADR-005 records maturity decisions at Stage 8 wrap-up, when the project state is known to have been touched. Stage-1 application means the upgrade is recorded *before* the build/fix run completes — if the run aborts at Stage 4 review-plan, the upgrade record persists for a feature that didn't ship. Not a correctness bug, but it does change the semantics. Recommend: AC #3 wording change to "...recorded in `.roughly/workflow-upgrades` immediately upon acceptance, regardless of whether the pipeline run subsequently aborts."

- **S8 violates the established 9-skills-in-CLAUDE.md count.** AC #6 covers updating CLAUDE.md (count goes from 9 to 10). Good. But S2 also adds a setup template and S11a adds a workflow file and a script — those don't appear in CLAUDE.md's structure table at all. Worth a single AC line in the epic: "CLAUDE.md structure table audited for completeness post-release."

### Risks

The risk register is solid. Five additional risks the epic does not list:

- **Skill line-cap ceiling.** `skills/build/SKILL.md` is at 296 lines, `skills/fix/SKILL.md` at 299. The 300-line cap is enforced by the dogfood Stop hook. S1, S2, S6, S7, S9, and S10 all add lines to these two files. Even if S3 retires two maturity-check blocks for net negative, the remaining additions plausibly exceed the headroom. The epic flags the cap in 4 separate AC lists ("No skill body exceeds 300 lines") but doesn't price the cumulative budget. **Recommendation: add a sequencing-level AC: "After each story merges, re-run `wc -l` and ensure neither exceeds 300." Or insert an explicit refactor story before S1 that consolidates the duplicated build/fix prose into a shared reference (similar to agent-preamble.md), reducing both files by 20-40 lines.**

- **S2 Stop-hook script vs. existing PostToolUse formatter conflict.** The setup template `settings.json.template` currently has a `PostToolUse` `Write|Edit` matcher running `{{FORMATTER_COMMAND}} $FILE_PATH`. Adding a `Stop` hook is additive (different event), so no direct conflict. But S2 AC #4 says "the `Stop` entry added to the user's `.claude/settings.json`." Risk is the implementer writes a fresh `Stop` block that clobbers a user's existing PostToolUse block. Recommend: AC #4 explicitly say "Stop hook entry added without modifying any existing `hooks.PostToolUse` entries."

- **S11b CI scenario fragility on plan format changes.** The CI happy-path scenario depends on the plan format being stable. S6 adds a version line, S10 may add comment lines for caps, future v0.2.0 work changes the format substantially. If S11b's fixture comparison is too strict (line-by-line plan output match), every plan format change breaks CI. Recommend: AC for S11b — "Scenario assertions check structural properties (plan file exists, contains `## Tasks`, has at least one task, review-plan returned PASS) rather than full content match."

- **S9 prose sweep risk of regression in current-good ABORT HANDLING block.** The existing build/fix ABORT HANDLING blocks are well-engineered. S9's "every abort branch...produces a message that includes (a)(b)(c)(d)" reads as a wholesale rewrite. If executed without care, the existing nuanced handling could regress. Recommend: a `git diff` AC: "ABORT HANDLING block lines are unchanged; only per-gate abort messages are updated."

- **CI cost.** Running a full `/roughly:build` cycle in CI invokes Sonnet for orchestration + investigator + plan-reviewer + 3 parallel review agents + spec-reviewer per task + code-reviewer at Stage 6. A single happy-path run could be 100K+ tokens of Sonnet per CI invocation. At 100 PR pushes per release cycle, this is a real money question that the epic doesn't surface. Recommend: a budget-cap AC in S11b — "scenario completes within $X token budget" or at minimum "scenario uses minimal-task fixture (1-task plan only)."

### Overengineering

- **S7 (in-session maturity offers at Stage 1) is potentially overengineered for v0.1.5.** The epic justifies Stage 1 offers as: "By [Stage 8] the user has finished the work and may not be in a mood to take on new setup." That's a UX heuristic, not a measured pain point. The mechanism doubles each maturity check evaluation site (Stage 1 *and* Stage 8) and introduces "not yet" / "never" semantics that have to be coordinated across two stages without double-prompting. The complexity-vs-value ratio is questionable for v0.1.5. Recommend: punt S7 to v0.1.6 unless there's user feedback specifically asking for up-front offers. If retained, add an AC capping the scope: "Only `investigator-v1` and `stop-hook-v1` are offered at Stage 1 in v0.1.5 — adding more checks is a v0.1.6 decision based on observed Stage 1 acceptance rates."

- **S11a + S11b combined scope is large for v0.1.5's remaining headroom.** The dependency chain (S11a → S11b → S10) means CI lands very late and any failure in S11b cascades. Recommend: split S11b into S11b-1 (script invokes `claude --plugin-dir <fixture>` and gets a "hello world" response — proves the auth + CLI plumbing) and S11b-2 (script drives the full build cycle). S11b-1 lands earlier, providing regression-coverage scaffolding for S9/S10 even if the full scenario isn't ready.

- **S9 abort-prose sweep is plausibly the right size.** Reading the actual abort points: there are about 5 abort-able gates per pipeline + the existing ABORT HANDLING block, plus review-plan NEEDS REVISION abort, plus audit-epic AC failure. That's ~12 sites total across the codebase. Each gets a few extra lines — probably 30-50 lines net across all five files. Recommend keeping S9 as-scoped, but tighten the AC: "Abort message structure (a/b/c/d) MAY be encoded as a single template referenced by all gates rather than duplicated per gate" to give the implementer license to keep the line count down.

- **S12a + S12b — engineer-to-engineer-tone AC is unverifiable.** "No marketing voice ('industry-leading', 'revolutionary', etc.)" is testable; "engineer-to-engineer tone matching the roadmap" is not. Recommend: replace with "Reviewer reads cold and produces three takeaways consistent with the SKILL.md content; if takeaways diverge, prose is rewritten."

### Acceptance Criteria Quality

- **S0 ACs are excellent.** Each is testable. The "no belt-and-suspenders unless justified" AC is exactly right.

- **S1 AC #6 is the only weak one in S1.** "Known-pitfalls.md L14 entry is updated..." — the line number reference is brittle. Recommend: refer to the entry by content ("the plan-mode hijack entry in `.roughly/known-pitfalls.md` Domain-Specific section") not line number.

- **S2 AC #1 is technically wrong** (see Technical Accuracy section). Rewrite needed.

- **S3 ACs are tight and testable.** AC #5 — "Existing entries in `.roughly/workflow-upgrades` for these check IDs are not auto-cleaned" — is specifically valuable.

- **S5 ACs lack a "no Edit/sed regression" line.** The AC checklist verifies the section's structure but doesn't verify the section actually prevents the issue. Recommend: "After landing, re-run the verification commands from the section against `.claude/hooks/verify-all.sh` to confirm the document's own example holds."

- **S6 AC #3 is a great negative AC** ("review-plan/SKILL.md is unchanged — it does not validate, parse, or branch on the version field in v0.1.5"). More stories should have these.

- **S7 ACs miss the Stage 4 abort case** noted above.

- **S8 ACs are complete except for one gap.** AC #3 specifies output structure but doesn't say what happens when there are conflicts (e.g., two plan files in `docs/plans/` for different in-progress features). Recommend: "If multiple in-progress plan files are detected, list each with its modified date and ask the user which is current."

- **S9 AC #2 (`rg -n 'aborted\.?$' skills/`) is testable but brittle.** The pattern misses "Aborted!" or "aborted at Stage 5." Recommend: a positive AC with specific examples — "Each abort message contains the literal substring 'Stage [N]' and 'recovery'" or similar.

- **S10 ACs are weak by design (waiting on per-cap decisions in OQ #3).** This means ~25% of S10 is undefined at epic-ready time.

- **S11a AC #4 is excellent** ("verify by checking `git status --porcelain` is unchanged before and after a CI run") — exactly the kind of mechanically-checkable AC the epic should have more of.

- **S11b — missing AC on cleanup of fixture state.** If the fixture repo is in `tests/fixtures/<name>/`, dogfood mutations to `.roughly/` inside the fixture also need teardown. Recommend: "Fixture state is reset between runs (either via clean-checkout or explicit teardown of `tests/fixtures/<name>/.roughly/` and `tests/fixtures/<name>/docs/plans/`)."

- **S12a/S12b — line-budget ACs are testable, but the "no prose contradicts SKILL.md" AC is a manual review burden** with no specific verification command. Recommend: "After landing, the docs CI check (or manual review checklist) compares the canonical claims (number of stages, command list, maturity check IDs) extracted from prose vs. extracted from SKILL.md."

### Dependencies

The sequencing table is mostly defensible, with three corrections needed:

- **S2 → S3 dependency claim is right.** S2's "after S3 to avoid double-touching maturity check section" is correct because S3 removes maturity-check blocks before S2 rewrites the `stop-hook-v1` block. Keep.

- **S7 → S2 + S3 dependency claim is right.** S7 evaluates `stop-hook-v1` at Stage 1; without S2's templating, accepting at Stage 1 is still a no-op. Without S3, the Stage 8 fallback path includes the to-be-retired checks. Keep.

- **S11b → S1, S6, S9 dependency claim is partially correct.**
  - S11b → S1 is **correct**: without plan-mode auto-detect, CI dogfood may auto-engage plan mode and skip Stage 4 — exactly the regression the test is supposed to catch.
  - S11b → S6 is **weak**: S6 adds a version line that doesn't break the scenario. The epic admits this. This is not a dependency, it's a sanity check. Remove from the dependency list.
  - S11b → S9 is **incorrect**: S9 makes failure messages clearer; this is nice-to-have for diagnosis but is not a blocker for the scenario passing. The epic admits this too. Treat as a soft preference, not a dependency.

- **S0 → S1 dependency is correct.** Keep.

- **S11a → S1 dependency is debatable.** S11a establishes the worktree + script infrastructure. The script doesn't *need* to invoke `/roughly:build` — it could initially just run a `--version` check or a stub scenario. Recommend: S11a can land before S1 if the script is a stub; full invocation moves to S11b. This decouples the CI scaffolding from the spike's outcome.

- **Dependency missing: S2 → setup template handling at Step 5d in setup/SKILL.md.** S2 modifies `settings.json.template` and adds a new template. The setup skill has settings.json handling logic that needs updating. This isn't called out in S2's "Files touched" list. Recommend: S2 Files touched adds `skills/setup/SKILL.md` Step 5d (or a new Step 5e for the Stop hook handling), and AC explicitly confirms setup writes the Stop hook entry conditionally.

- **Sequencing position of S12a is questionable.** Position 10 ("ladders mid-release rather than batch-landing"). But Open Question #4 (roughly.dev source location) is unresolved. Landing S12a at position 10 with the question still open means a release-week scramble. Recommend: gate S12a/S12b on Open Question #4's resolution before any code in the docs cluster begins, OR move both stories to position 14-15 (after everything else) with explicit acknowledgment that they're at risk.

### Open Questions Assessment

The four open questions vary widely in their genuineness:

- **OQ #1 (CI scripted format).** Real open question. Trade-offs are documented, decision is technical. The epic explicitly says "decision needed before S11b implementation," which means S11b can't start without resolution. **Not a blocker, given the late position of S11b.**

- **OQ #2 (maturity check coverage loss).** Real open question. The "manual edit" coverage gap is acceptable for v0.1.5 because the failure mode is "user manually edited their pitfalls file and didn't get an organize prompt," not a regression. **Not a blocker.**

- **OQ #3 (per-cap decisions for S10).** Punts a decision the epic should have made. The four caps are fixed, observable, and have well-known characteristics. The epic could have proposed defaults: "Stage 5c questions: keep at 2; Stage 5c type-check fix: raise to 4; Stage 5c lint fix: raise to 4; Stage 6 review-fix cycles: keep at 2." A real open question would be "we don't know which auto-fix categories to call cheap." The current OQ pretends these are unknowable. **Soft blocker — recommend the epic propose default decisions and let S10 implementation challenge them.**

- **OQ #4 (roughly.dev source location).** **Hard blocker.** This is not an open question; it's a deferred decision that S12a cannot start without. The three options have completely different file-touch lists, dependencies, and CI implications. **Recommend: either resolve OQ #4 before the epic moves to "Ready," or insert an "S12.0: Resolve roughly.dev source location" pre-story as the first thing in the docs cluster.**

---

## Recommendations

### Blockers (resolve before implementation begins)

1. **Resolve OQ #4 (roughly.dev source location).** Either pick one of the three options and update S12a/S12b accordingly, or add S12.0 as a pre-story.

2. **Add a line-cap budget audit story or refactor preceding S1.** Build is at 296/300, fix at 299/300. Either: (a) explicit refactor story extracting shared build/fix prose into a reference (parallel to `agent-preamble.md`), OR (b) per-story AC requiring `wc -l skills/build/SKILL.md skills/fix/SKILL.md` checked against running budget after each merge.

3. **Fix S2 AC #1's mismatch with the dogfood `verify-all.sh`.** Rewrite to scope what the templated hook actually runs (lightweight checks only), and explicitly distinguish from the dogfood's structural-drift role.

4. **Tighten OQ #3 with proposed default cap decisions for S10**, making this a "challenge these defaults" OQ rather than a "decide later" OQ.

### Major (resolve during early implementation)

5. **Reconsider S7 scope or punt to v0.1.6.** Highest-cost-for-questionable-value story. If retained, add the abort-mid-pipeline record-keeping AC.

6. **Add a new ADR for plan-mode detection contract (S1).** Significant design decision; CLAUDE.md says ADRs required for these.

7. **Split S11b** into a "smoke test" sub-story (auth + CLI plumbing) and a "scenario" sub-story (full build cycle).

8. **Correct sequencing dependencies:** S11b → S6 is not a dependency, S11b → S9 is not a dependency, S11a → S1 is weak. Update the table.

9. **Add S2 dependency on `skills/setup/SKILL.md` Step 5d** (settings.json handling for the new Stop hook entry), and add it to the Files touched list.

### Minor (nice-to-have)

10. **S1 AC #6: rewrite by content reference, not line number.** "L14" will go stale.

11. **S5 add a self-verification AC** running the doc's own example commands against the actual file the incident occurred in.

12. **S6 pin a specific format** for the version line (markdown body line vs frontmatter vs HTML comment).

13. **S9 AC #2: make the abort-message AC positive and content-specific** rather than the brittle `aborted\.?$` regex.

14. **S11a AC #5/S11b: add a token-cost cap** to prevent the CI run from being a hidden release-cost driver.

15. **Cross-cutting: replace unverifiable AC phrases.** "engineer-to-engineer tone" (S12), "if added as a check" (S4) — replace with concrete verification commands wherever possible.
