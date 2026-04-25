# Ruckus

Ruckus is a Claude Code plugin that implements gated development pipelines with subagent-per-task execution.

## Stack

Pure markdown plugin — no runtime, no build step. Runs inside Claude Code sessions.

## Commands

| Action | Command |
|--------|---------|
| Build | `none — pure markdown` |
| Type check | `none` |
| Test | `none yet` |

## Conventions

- None documented yet

## Architecture

Subagent-per-task implementation (ADR-002), coordinator-orchestrates/subagents-implement, shared agent-preamble as manual sync reference (ADR-003), two-stage review after every task (ADR-007), Opus reserved for epic-reviewer only (ADR-008)

## Cross-Boundary Concerns

Plugin skills run in the user's project context, not the plugin source directory — all file paths in skills must resolve relative to the user's repo, not the plugin repo

## Documentation

- ADRs: docs/adrs/
- Known pitfalls: docs/claude/known-pitfalls.md
