# Known Pitfalls

Project: Ruckus
Domain: Ruckus is a Claude Code plugin that implements gated development pipelines with subagent-per-task execution.

Pitfalls discovered through development. Updated by `/ruckus:build` and `/ruckus:fix` wrap-up stages.

---

## Domain-Specific

- **Agent files are plugin-shipped, not project-installed.** All 7 agents are loaded via `subagent_type` (e.g., `ruckus:code-reviewer`) from the plugin cache. The upgrade skill must never classify agent files as "New" or offer to copy them to `.claude/agents/`. The only valid agent-related check during upgrade is preamble drift on pre-existing `.claude/agents/` files.

## Data & State

<!-- Pitfalls related to data handling, state management, persistence -->

## Integration

<!-- Pitfalls related to APIs, third-party services, cross-system communication -->

## Build & Deploy

<!-- Pitfalls related to build process, CI/CD, deployment -->

## Testing

<!-- Pitfalls related to test reliability, test data, flaky tests -->
