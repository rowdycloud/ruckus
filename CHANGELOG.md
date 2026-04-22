# Changelog

## [Unreleased]

### Changed

- Compressed implementer-prompt.md from ~170 words to ~80 words (saves ~1K tokens per build run)
- Removed duplicate known-pitfalls rules from code-reviewer, silent-failure-hunter, investigator agents

### Added

- Context compaction boundaries after Stages 4, 5, 6 in build and fix pipelines (saves 8K-12K tokens per run)
- Shared agent-preamble.md as canonical sync reference for project context loading instructions (agents inline preamble text; file is the single source of truth for manual sync)
- Abort handling sections in build and fix pipelines (staged cleanup based on pipeline progress)
- Plan file validation pre-check before Stage 4 dispatch
- MANDATORY markers on Stages 6 and 7
- Stack-aware section comments in claudeignore.template (delete-if-not-using guidance per stack)
- Example pitfall entries in known-pitfalls.md.template (Domain-Specific, Data & State, Integration)
- Plan naming convention: `docs/plans/<feature-name>-plan.md` and `docs/plans/fix-<issue>-plan.md`
- Inlined implementer-prompt.md and spec-reviewer-prompt.md into build and fix pipeline SKILL.md files (eliminates plugin-relative file path dependencies)
- Explicit override protocol for Stage 4 plan review gate (requires human to say "override" — ambiguous responses rejected)
- `disable-model-invocation: true` added to review/SKILL.md
- Context compaction boundary after audit-epic Step 3 (prevents 3K-5K token accumulation during synthesis)
- Subagent/orchestrator terminology defined in README How It Works section
- Setup file list added to README Quick Start section
- `.workflow-upgrades` file location documented in README Self-Upgrading section
- Slash-command dispatch (`/ruckus:review-plan`) replaces file-read dispatch in Stage 4

## 0.1.0 — 2026-04-20

Initial release.

### Skills
- `/ruckus:build` — Feature implementation pipeline (8 gated stages)
- `/ruckus:fix` — Bug fix pipeline with investigation stage
- `/ruckus:review` — Parallel 3-agent code review
- `/ruckus:review-epic` — Pre-implementation epic review (Opus)
- `/ruckus:audit-epic` — Post-implementation epic audit with AC verification
- `/ruckus:verify-all` — Type check + test + build verification loop
- `/ruckus:review-plan` — Plan verification (dispatched as subagent)
- `/ruckus:setup` — Project bootstrap with maturity detection
- `/ruckus:upgrade` — Update installed files from plugin templates

### Agents
- `discovery` — Feature research and scoping
- `investigator` — Bug diagnosis via code tracing
- `epic-reviewer` — Cross-story epic review (Opus)
- `code-reviewer` — Code quality and security review
- `static-analysis` — Toolchain verification
- `silent-failure-hunter` — Error handling audit
- `doc-writer` — Documentation updates

### Features
- Subagent-per-task implementation with two-stage review
- Self-upgrading maturity checks with versioned IDs
- Mandatory plan review via blocking subagent dispatch
- UI task detection with automatic frontend-design skill loading
- CLAUDE.md quality enforcement
