# Changelog

## [Unreleased]

### Changed

- **Breaking:** Rename `docs/claude/` to `.ruckus/` for unambiguous plugin ownership (E01.S1)
  - `docs/claude/known-pitfalls.md` → `.ruckus/known-pitfalls.md`
  - `docs/claude/.workflow-upgrades` → `.ruckus/workflow-upgrades` (dropped leading dot)
- Eliminate secondary `docs/claude/CLAUDE.md` — root `CLAUDE.md` is now the sole copy (E01.S1)
- Setup writes `CLAUDE.md` directly to project root instead of `docs/claude/CLAUDE.md` + root copy (E01.S1)
- Doc-writer agent writes to root `CLAUDE.md` and `.ruckus/known-pitfalls.md` (E01.S1)
- Update all agent preambles and skill references to use `.ruckus/` paths (E01.S1)
- ADR-005 and ADR-006 updated with footnotes noting the directory rename (E01.S1)

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

### Added

- Upgrade migration step: detects `docs/claude/` in existing projects and offers to move files to `.ruckus/` (E01.S1)
- `.ruckus/` row added to CLAUDE.md structure table (E01.S1)

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
