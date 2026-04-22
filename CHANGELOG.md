# Changelog

## [Unreleased]

### Changed

- Compressed implementer-prompt.md from ~170 words to ~80 words (saves ~1K tokens per build run)
- Removed duplicate known-pitfalls rules from code-reviewer, silent-failure-hunter, investigator agents

### Added

- Context compaction boundaries after Stages 4, 5, 6 in build and fix pipelines (saves 8K-12K tokens per run)
- Shared agent-preamble.md as canonical reference for project context loading instructions

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
