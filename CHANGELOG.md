# Changelog

## [Unreleased]

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
