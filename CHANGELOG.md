# Changelog

## [Unreleased] — v0.1.5

> Trust hardening + ergonomics + CI. Scope per [docs/planning/epics/E03-trust-and-ergonomics.md](docs/planning/epics/E03-trust-and-ergonomics.md).

### Added

- **E03.S3 — Retire `test-verify-v1` and `pitfalls-organized-v1` maturity checks.** Stage 8 maturity-check loop reduced from 5 → 3 active checks (CLAUDE.md quality, `investigator-v1`, `stop-hook-v1`). The retired checks' work now lives in [agents/doc-writer.md](agents/doc-writer.md) Process step 5, which fires post-write conditionally on `wc -l > 80` for organize-suggestions and on test-config detection (`package.json`/`pytest`/`vitest`/`jest`/`pyproject.toml`) for test-integration suggestions. Coverage gap is two-part-gate: suggestions fire only when (a) the user confirms new pitfalls/conventions at wrap-up AND (b) doc-writer actually writes to `.roughly/known-pitfalls.md`. Manual edits are explicitly out of the new trigger surface; documented in agents/doc-writer.md and [README.md:221](README.md#L221). Existing `*-declined` entries in users' `.roughly/workflow-upgrades` are not auto-cleaned (verified inert). Build/fix line counts: 297 → 288 and 300 → 291 (12 and 9 lines headroom for downstream stories). Merged 2026-05-04 on `feat/S03.3-retire-test-verify-v1` (8 commits — `33bf966` core, plus 7 follow-ups including `9078a5f` fix/SKILL.md Stage 8 wrap-up harmonization to ask about conventions, matching build).
- **ADR-005 fourth disposition: retirement.** [docs/adrs/ADR-005-versioned-maturity-checks.md](docs/adrs/ADR-005-versioned-maturity-checks.md) gains a v0.1.5 retirement footnote and a Consequences/Negative bullet acknowledging retirement as a formal disposition alongside add/decline/version-bump. Future stories that retire checks should follow the same pattern (footnote + Consequences/Negative bullet).
- **Two pitfalls captured in [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) during E03.S3 wrap-up (commit `9440ecb`):**
  - LLM agent conditionals need explicit failure-handling clauses — discovered when first-pass review of doc-writer step 5 produced 3 P1 silent-failure findings on what looked like a simple two-bullet conditional addition.
  - Pre-existing markdown lint warnings on `PostToolUse:Edit` hooks are unrelated to changed lines — discovered during T5 ROADMAP edit (~30 warnings on untouched lines).

- **E03.S1 — Plan-mode auto-detect/exit at Stage 1 of build/fix (highest-value v0.1.5 item).** When `/roughly:build` or `/roughly:fix` is invoked while Claude Code's plan mode is active, the new `UserPromptSubmit` hook at [.claude/hooks/plan-mode-gate.sh](.claude/hooks/plan-mode-gate.sh) reads `permission_mode` from stdin and emits `decision: "block"` JSON, preventing the prompt from reaching the model. Per-skill scoping (restricting enforcement to `/roughly:build` and `/roughly:fix`) happens inside the hook script via `prompt`-field regex, since Claude Code's hook `matcher` field is tool-name only. Hook posture is fail-closed (no `set -e`, parser-tool guards, explicit fail-closed branches at every parsing failure point). Templated into user projects via [skills/setup/templates/plan-mode-gate.sh.template](skills/setup/templates/plan-mode-gate.sh.template) and a new `UserPromptSubmit` registration in [skills/setup/templates/settings.json.template](skills/setup/templates/settings.json.template), deployed by `/roughly:setup` Step 5d (three-branch registration with `jq`/JSON preflights and warning escalation). Build/fix preambles updated at L11 (substitution-only; line counts preserved at 296/299). Closes ADR-001's enforcement gap for plan-mode hijack. Authoritative artifact: [docs/adrs/ADR-009-plan-mode-detection.md](docs/adrs/ADR-009-plan-mode-detection.md). Merged 2026-05-02 via PR #25 (`c598ef6`); follow-up fixes `5b09864`, `a299ada`, `6d268e9`, `2c1436b` through 2026-05-03.
- **ADR-009 — Plan-Mode Detection.** New ADR documenting: detection mechanism, Step 1 empirical verification result (PASS, 2026-05-02), spike-doc API-name correction (`UserPromptExpansion` → `UserPromptSubmit`), distinction from ADR-001 (invocation gate vs mid-pipeline stage gate; harness-owned data vs pipeline-internal data), hook registration scope (in-script `prompt`-field matching since `matcher` is tool-name only), hook posture (fail-closed), open items. ADR-001 through ADR-009 now cited in [CLAUDE.md](CLAUDE.md); [docs/adrs/README.md](docs/adrs/README.md) gains a "Current ADRs" list. The plan-format-v2 ADR previously slotted as ADR-009 in v0.2.0 is bumped to ADR-010 (ADRs are numbered by landing order).
- **`UserPromptSubmit` hook templating in `/roughly:setup`.** Step 5d gains a three-branch registration flow (no settings.json → write fresh; existing settings.json with no `UserPromptSubmit` → merge; existing with `UserPromptSubmit` → preserve and warn) plus `jq`-availability and JSON-validity preflights surfacing blocking warnings in Step 7.
- **E03.S0 — Plan-mode detection spike (½-day).** [docs/planning/spikes/plan-mode-detection-findings.md](docs/planning/spikes/plan-mode-detection-findings.md) maps the design space for plan-mode auto-detection at Stage 1 of build/fix. **Conclusion:** preamble + lightweight hook — `UserPromptSubmit` (corrected from spike's `UserPromptExpansion` during S1; see [ADR-009 §Spike-Doc Correction](docs/adrs/ADR-009-plan-mode-detection.md)) reading `permission_mode` from hook stdin (documented value `"plan"` when plan mode is active). Implementation gated to E03.S1's empirical-verification step. Spike findings doc preserved per AC10 retention decision. Merged 2026-05-01 via PR #24 (`e5d630f`).
- **Five pitfalls captured in [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) during E03.S0/S1 wrap-up:**
  - *Planning & Scoping* — `permission_mode` in hook stdin is a programmatic plan-mode signal that planners routinely miss (S0, commit `a4a4726`).
  - *Planning & Scoping* — "Confirmed empirically" ACs in spike stories can be unachievable from inside an active pipeline session (S0, commit `a4a4726`).
  - *Planning & Scoping* — Spike-doc external API identifiers must be re-verified against the live API at implementation start (S1, commit `2c1436b`; surfaced when the spike's `UserPromptExpansion` propagated unchecked through plan + plan-review PASS).
  - *Build & Deploy* — Markdown-list-nested heredocs in copy-paste-ready docs are indentation-fragile and silently break (S1, commit `2c1436b`; recommends `printf '%s\n' ...` over `cat <<EOF` inside numbered lists).
  - *Build & Deploy* — `set -euo pipefail` combined with unguarded parser tools silently opens safety-gate hooks (S1, commit `2c1436b`; drop `set -e`, keep `set -uo pipefail`, audit every parser-tool call for fail-closed alternatives).

### Changed

- **Plan-mode hijack pitfall recategorized.** [.roughly/known-pitfalls.md](.roughly/known-pitfalls.md) Domain-Specific entry rewritten from "open silent failure" to "blocked by S1 enforcement (ADR-009)" with recovery instructions and a caveat for users whose `.claude/settings.json` already has a `UserPromptSubmit` entry (setup will not overwrite — verify manually that plan-mode protection is in place).

### Fixed

- **`PostToolUse` template schema.** [skills/setup/templates/settings.json.template](skills/setup/templates/settings.json.template) `PostToolUse` entry corrected to nested `{matcher, hooks: [{type, command}]}` shape (the prior flat shape was broken in Claude Code 2.x). Caught while adding the `UserPromptSubmit` registration in S1; without this fix, S1 would have shipped a working plan-mode hook alongside a broken formatter hook on user installs.

## [0.1.4] — 2026-04-30

> Hard-cut rename from `ruckus` to `roughly`. Behavior is identical to v0.1.3 — only names, paths, namespace identifiers, and the workflow-upgrades version-line identifier change.

### Changed

- Renamed plugin from `ruckus` to `roughly`. Hard cut with no aliases or backwards compatibility (E02.S2.1)
- Plugin name field updated in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` from `ruckus` to `roughly` (E02.S2.1)
- Slash command namespace migrated from `/ruckus:*` to `/roughly:*` across all 9 skills — `/roughly:build`, `/roughly:fix`, `/roughly:review`, `/roughly:review-plan`, `/roughly:review-epic`, `/roughly:audit-epic`, `/roughly:verify-all`, `/roughly:setup`, `/roughly:upgrade` (E02.S2.1)
- Plugin-installed dotdir migrated from `.ruckus/` to `.roughly/` in skill bodies and v0.1.4 upgrade-migration logic (E02.S2.2)
- Workflow-upgrades version-line identifier renamed from `ruckus-version` to `roughly-version` across setup and upgrade skills (E02.S2.2)
- v0.1.2 upgrade migration step (`docs/claude/` → `.ruckus/`) modified to migrate directly to `.roughly/`, skipping the `.ruckus/` intermediate for users upgrading from v0.1.0/v0.1.1 directly to v0.1.4 (E02.S2.2)
- Agent preamble path reference updated from `.ruckus/known-pitfalls.md` to `.roughly/known-pitfalls.md` in `agents/agent-preamble.md` (canonical) and the 6 consumer agents (code-reviewer, discovery, epic-reviewer, investigator, silent-failure-hunter, doc-writer); `static-analysis.md` remains the documented exception (E02.S2.3)
- This repo's own dogfood `.ruckus/` directory renamed to `.roughly/` via `git mv`, with content updates in `known-pitfalls.md` (project name, domain description, command references, subagent_type example) and `workflow-upgrades` (version-line identifier). `git log --follow` continuity preserved across both v0.1.2 and v0.1.4 transitions (E02.S2.6)
- Setup templates updated for new project installs: `skills/setup/templates/CLAUDE.md.template` L33 (`.ruckus/known-pitfalls.md` → `.roughly/known-pitfalls.md`) and `skills/setup/templates/known-pitfalls.md.template` L6 (`/ruckus:build` and `/ruckus:fix` → `/roughly:build` and `/roughly:fix`). Existing `{{PLACEHOLDER}}` markers and the unchanged `claudeignore.template` / `settings.json.template` are preserved verbatim. Folded into PR #19 as a P1 follow-up rather than a separate PR because deferring would have shipped a broken first-install experience for new `/roughly:setup` runs (E02.S2.4)
- Active documentation renamed `Ruckus` → `Roughly`: `README.md` (title, opening, install commands `/plugin marketplace add nickkirkes/roughly` + `/plugin install roughly@nickkirkes`, clone path `~/.claude/plugins/roughly/`, all 22 `/roughly:*` references in code blocks and prose), `CLAUDE.md` (title, opening, structure table prose, `/roughly:setup` reference, `roughly-clone` test path), `CONTRIBUTING.md` (title `# Contributing to Roughly`, clone paths use `roughly-clone` at L8 and L54, 4 `/roughly:*` CLI examples). Zero unintentional `ruckus` residue — the only remaining `ruckus` mentions in active docs are inside the new "Migrating from ruckus (v0.1.3) to roughly (v0.1.4)" subsection (E02.S2.5)
- Two pitfalls captured during S2.5 wrap-up in `.roughly/known-pitfalls.md` via the documented Stage 8 flow per ADR-006 (E02.S2.5 commit `4ff8e5a`)
- Repo-relative paths used in plan verify commands (small docs cleanup discovered during the rename pass) (E02.S2.5 commit `7b6ad8f`)

### Added

- **NEW v0.1.4 upgrade-migration step in `skills/upgrade/SKILL.md`** — detects existing `.ruckus/` directories in user projects and migrates to `.roughly/`. 10-point spec covers: git-vs-plain-`mv` detection, `.ruckus/.migration-in-progress` marker file for partial-failure idempotency, conflict-or-resume branching with explicit abort behavior, idempotent moves, version-line identifier rewrite, anchored boilerplate regex with warn-on-skip, literal-substring CLAUDE.md update with displayed match counts, interactive prompt for user-extra files, marker cleanup, idempotency contract on re-runs (E02.S2.2)
- **Pre-flight migration check in 6 skills** (`build`, `fix`, `review`, `review-plan`, `review-epic`, `setup`) — detects legacy `.ruckus/.migration-in-progress`, `.ruckus/known-pitfalls.md`, or `.ruckus/workflow-upgrades` state and aborts with a redirect to `/roughly:upgrade`. Protects v0.1.3 users who install the new plugin without first running the migration. Beneficial scope expansion beyond the original S2.2 spec (E02.S2.2)
- **Doc-writer path-string sync note in `agents/agent-preamble.md` HTML comment** — exceptions paragraph now explicitly notes that `doc-writer.md` L22 (write-target reference) requires path-string sync whenever the known-pitfalls.md path changes, even though doc-writer's pattern is genuinely different from the preamble-inlining consumers. The L5–L8 manual-sync target list remains unchanged (E02.S2.3)
- **Two new pitfalls captured in `.roughly/known-pitfalls.md`** during S2.3 implementation, recorded via the documented Stage-8 wrap-up flow (E02.S2.3 follow-up commit)
- **Structural Stop-hook (`.claude/hooks/verify-all.sh`)** — fires after every Claude turn in the dogfood repo, reports drift on: stale `.ruckus/known-pitfalls` references in `agents/`, skill bodies > 300 lines, agent bodies > 500 words, and HTML comment integrity in `agents/agent-preamble.md`. Non-blocking and informational; no-op outside the plugin repo. Aligns with ADR-005 maturity-check `stop-hook-v1` (E02.S2.3 scope expansion)

### Fixed

- `skills/fix/SKILL.md` post-S2.2-merge line count (301) reduced to 299 by collapsing the standalone "Format per entry" sentence in the MATURITY CHECKS section into the preceding "Check IDs are versioned" paragraph. Restores compliance with CLAUDE.md's 300-line skill body cap. No behavior change (commit `b2fa658`)
- Stop-hook script gracefully falls back to a heredoc-based JSON emission when `jq` is unavailable on the user's system (commit `1a01f55`)

### Notes

- Behavior is identical to v0.1.3 across all 9 skills and 7 agents. The plugin's pipeline gates, subagent dispatch patterns, two-stage review (ADR-007), Opus-for-epic-reviewer-only model selection (ADR-008), and runtime-context-loading from CLAUDE.md / known-pitfalls.md (ADR-006) are all preserved unchanged.
- Prior CHANGELOG entries (v0.1.0 through v0.1.3) retain `ruckus` naming as historical fact.
- ADR body text in ADR-004/005/006/008 retains its original `/ruckus:*` and capital-R `Ruckus` references as historical decision text. v0.1.4 footnotes were appended to those four ADRs in E02.S2.5.
- `docs/plans/**` historical implementation plans retain their original naming as historical fact.

### Migration

If you were using the previous `ruckus` plugin, follow these steps once per machine and once per project (mirrored in the README's "Migrating from ruckus" section):
1. Install the new plugin under the `roughly` name: `/plugin marketplace add nickkirkes/roughly` followed by `/plugin install roughly@nickkirkes`.
2. Run `/roughly:upgrade` from each project that previously used `/ruckus:*`. The upgrade detects the legacy `.ruckus/` directory and migrates `known-pitfalls.md`, `workflow-upgrades`, and any path references in your root `CLAUDE.md` to `.roughly/`. The migration is resumable on partial failure via the `.ruckus/.migration-in-progress` marker.
3. Optionally uninstall the old plugin: `/plugin uninstall ruckus`. The new and old plugins can coexist temporarily, but only `/roughly:upgrade` runs the migration; the old `/ruckus:*` commands continue to operate on the legacy paths until uninstalled.

The `### Migration` section is a deliberate departure from Keep-a-Changelog convention (Added/Changed/Deprecated/Removed/Fixed/Security only). The rename is the one and only release where existing users must take explicit action — the section's prominence outweighs strict convention conformance.

## [0.1.3] — 2026-04-28

### Fixed

- Upgrade skill no longer offers to install plugin-shipped agents into user projects — agents ship with the plugin and are loaded via `subagent_type`, never copied (E01 audit follow-up)

### Changed

- Setup domain example: replace cannabis-specific example with general-audience e-commerce example

### Added

- New pitfall in `.ruckus/known-pitfalls.md`: plugin-shipped agents must not be inventoried for user installation
- E01 epic audit report: 45 ACs evaluated, 42 MET, 3 PARTIAL (cosmetic), 0 NOT MET

## [0.1.2] — 2026-04-27

### Changed

- **Breaking:** Rename `docs/claude/` to `.ruckus/` for unambiguous plugin ownership (E01.S1)
  - `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
  - `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades` (dropped leading dot)
- Eliminate secondary `docs/claude/CLAUDE.md` — root `CLAUDE.md` is now the sole copy (E01.S1)
- Setup writes `CLAUDE.md` directly to project root instead of `docs/claude/CLAUDE.md` + root copy (E01.S1)
- Doc-writer agent writes to root `CLAUDE.md` and `.ruckus/known-pitfalls.md` (E01.S1)
- Update all agent preambles and skill references to use `.ruckus/` paths (E01.S1)
- ADR-005 and ADR-006 updated with footnotes noting the directory rename (E01.S1)
- fix/SKILL.md description: "Self-upgrades" → "Offers to create" investigator agent (E01.S8)

### Fixed

- Cap four unbounded pipeline loops in build and fix skills (E01.S2):
  - Stage 4 review-plan retry: "2 consecutive" → "2 total" to prevent bypass via alternating results
  - Stage 5c question re-dispatch: add max-2 cap with human escalation
  - Stage 6 review-fix loop: add max-2-cycle cap with human escalation
  - Stage 6 gate: disambiguate "address warnings" with explicit action and one-re-review limit
- Add compaction-resilience to build and fix pipelines (E01.S3):
  - Stage 5 re-validates plan file path after context compaction
  - Stage 5d preserve list includes task ID list
  - Post-Stage 7 compaction boundary preserves feature summary, files changed, and verification verdict
- Disambiguate error handling in pipeline quality checks and review-plan (E01.S4):
  - Stage 5c quality check: split "fix OR re-dispatch" into task-owned auto-fix (max 2) vs external escalation
  - Summary line updated from ">2 attempts" to "after 2 auto-fix attempts" for consistency
  - review-plan: add `.ruckus/` prefix to known-pitfalls.md path reference
  - review-plan: return NEEDS REVISION when CLAUDE.md missing, note gap when known-pitfalls.md missing
- Setup hardening: explicit gate enforcing all 6 required fields before file creation, define "gap" for enrich mode, explicit formatter row removal when no formatter provided (E01.S7)
- Upgrade hardening: preserve user-added hooks when merging settings.json (E01.S7)

### Added

- Upgrade migration step: detects `docs/claude/` in existing projects and offers to move files to `.ruckus/` (E01.S1)
- `.ruckus/` row added to CLAUDE.md structure table (E01.S1)
- Agent preamble drift documentation: explain why static-analysis and doc-writer differ from canonical preamble (E01.S5)
- Implementer-prompt sync comment noting relationship to agent-preamble.md (E01.S5)
- Upgrade preamble drift check: flags agents with stale context-loading instructions (E01.S5)
- Audit-epic token budget batching: batch per-story reviews in groups of 5 for epics with 10+ stories (E01.S6)
- README: review vs review-plan relationship explanation (E01.S8)
- README: context management troubleshooting entry for large builds (E01.S8)
- README: token usage table notes compaction savings (E01.S8)
- README: inline "maturity" definition on first use in Quick Start (E01.S8)

## [0.1.1] — 2026-04-24

### Fixed

- Prevent plan mode hijack in build/fix pipelines — Claude Code's built-in plan mode was intercepting Stage 3→4 flow and skipping review-plan entirely (#8)
- Move marketplace.json to `.claude-plugin/` where Claude Code expects it — root placement caused "Marketplace file not found" errors
- Use `./` source path in marketplace.json for schema validation

### Changed

- Tighten README opener and Quick Start bridging text
- Rename "Self-Upgrading" section to "Upgrade Checks"
- Trim redundant build pipeline bullets (covered in How It Works)
- Modify install instructions in README

### Added

- "Built with Ruckus" invitation section in README
- Issue-first step to CONTRIBUTING PR process
- CODE_OF_CONDUCT.md (Contributor Covenant v2.1)

## [0.1.0] — 2026-04-22

First public release.

### Skills (9)

- `/ruckus:build` — Feature implementation pipeline (8 gated stages)
- `/ruckus:fix` — Bug fix pipeline with investigation stage
- `/ruckus:review` — Parallel 3-agent code review
- `/ruckus:review-epic` — Pre-implementation epic review (Opus)
- `/ruckus:audit-epic` — Post-implementation epic audit with AC verification
- `/ruckus:verify-all` — Type check + test + build verification loop
- `/ruckus:review-plan` — Plan verification (dispatched as subagent)
- `/ruckus:setup` — Project bootstrap with maturity detection
- `/ruckus:upgrade` — Update installed files from plugin templates

### Agents (7)

- `discovery` — Feature research and scoping
- `investigator` — Bug diagnosis via code tracing
- `epic-reviewer` — Cross-story epic review (Opus)
- `code-reviewer` — Code quality and security review
- `static-analysis` — Toolchain verification
- `silent-failure-hunter` — Error handling audit
- `doc-writer` — Documentation updates

### Pipeline Features

- Subagent-per-task implementation with two-stage review after every task
- Mandatory plan review via blocking subagent dispatch
- Explicit override protocol for plan review gate (requires human to say "override")
- UI task detection per-task via `UI: yes/no` flag (loads frontend-design automatically)
- Context compaction boundaries after Stages 4, 5, 6 in build and fix pipelines
- Abort handling with staged cleanup based on pipeline progress
- Plan file validation pre-check before Stage 4 dispatch
- MANDATORY markers on Stages 6 and 7
- Self-upgrading maturity checks with versioned IDs
- CLAUDE.md quality enforcement at implementation start

### Templates

- Stack-aware section comments in claudeignore.template (delete-if-not-using guidance)
- Example pitfall entries in known-pitfalls.md.template
- Plan naming convention: `docs/plans/<feature-name>-plan.md` and `docs/plans/fix-<issue>-plan.md`

### Agents & Prompts

- Shared agent-preamble.md as canonical sync reference for project context loading
- Implementer prompt and spec-reviewer checklist inlined into build/fix SKILL.md (eliminates plugin-relative file path dependencies)
- Compressed implementer prompt from ~170 to ~80 words

### Documentation

- CLAUDE.md — contributor guide with conventions, structure, pitfalls
- CONTRIBUTING.md — fork/test/PR workflow and code standards
- 8 Architecture Decision Records (ADR-001 through ADR-008)
- README with installation, quick start, first-feature walkthrough, pipeline docs, troubleshooting, token usage
- `disable-model-invocation: true` on all pipeline and coordinator skills
