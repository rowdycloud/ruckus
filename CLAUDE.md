# Ruckus

Ruckus is a Claude Code plugin that implements gated development pipelines with subagent-per-task execution. MIT licensed, by Nick Kirkes.

This is a plugin, not a standalone app. It runs inside Claude Code sessions in the user's project.

## Structure

| Path | Contents |
|------|----------|
| `skills/<name>/SKILL.md` | Skill definitions (9 skills) |
| `agents/<name>.md` | Agent definitions (7 agents) |
| `agents/agent-preamble.md` | Canonical sync reference for project context loading (see note below) |
| `skills/setup/templates/` | Templates populated by `/ruckus:setup` |
| `skills/build/implementer-prompt.md` | Reference copy of implementation subagent prompt (runtime copy is inlined in build/fix SKILL.md) |
| `skills/build/spec-reviewer-prompt.md` | Reference copy of spec compliance checklist (runtime copy is inlined in build/fix SKILL.md) |
| `docs/adrs/` | Architecture Decision Records (ADR-001 through ADR-008) |
| `.ruckus/` | Runtime files installed per-project: `known-pitfalls.md` and `workflow-upgrades` |
| `.claude-plugin/plugin.json` | Plugin manifest |

**agent-preamble.md** is a sync reference, not an auto-include. Claude Code plugins have no include mechanism. Each agent inlines the preamble text in its Process step 1. When updating, manually sync to all agents listed in the file header. See ADR-003 for the shared-reference pattern.

**implementer-prompt.md and spec-reviewer-prompt.md** are canonical reference copies. The runtime versions are inlined in `build/SKILL.md` and `fix/SKILL.md` Stage 5b/5c. Edit the inline copies for runtime changes; update the reference files to keep them in sync.

## Build / Test

There is no build step — this is pure markdown.

**Test locally:** `claude --plugin-dir /path/to/your/ruckus-clone` from a test project.

**Verify structure:** Check frontmatter fields, cross-references between skills and agents, file counts, line/word limits.

## Conventions

- Skills must have YAML frontmatter with `name` and `description`
- Agents must have YAML frontmatter with `name`, `description`, `tools`, `model`
- Pipeline skills (build, fix) must have `disable-model-invocation: true`
- Coordinator skills (review, review-plan, verify-all, audit-epic, review-epic) must have `disable-model-invocation: true`
- Agent prompts must stay under 500 words
- Skill bodies must stay under 300 lines
- Project-specific values use `{{PLACEHOLDER}}` markers — never hardcode project names, commands, or paths
- Maturity check IDs must be versioned (e.g., `investigator-v1`)
- All significant design changes need ADRs (see `docs/adrs/`)

## Key Design Decisions

See `docs/adrs/` for full reasoning. Summary:

| ADR | Decision |
|-----|----------|
| ADR-001 | Review-plan dispatched as blocking subagent, not skill invocation |
| ADR-002 | Fresh subagent per implementation task, orchestrator coordinates only |
| ADR-003 | Spec-reviewer checklist shared between build and fix pipelines |
| ADR-004 | UI work detected per-task via flag, not a separate command |
| ADR-005 | Maturity check IDs are versioned; declined checks re-offered on version bump |
| ADR-006 | CLAUDE.md read at runtime by agents, not baked into skill text |
| ADR-007 | Two-stage review (spec compliance + quality) runs after every task |
| ADR-008 | Opus reserved for epic-reviewer only; all other agents use Sonnet |

## Known Pitfalls for Contributors

- **User context, not plugin context.** Skill content runs in the user's project — file paths must resolve relative to the user's repo, not the plugin source directory.
- **`disable-model-invocation: true` is critical.** Without it on coordinator skills, Claude may answer conversationally instead of dispatching agents.
- **Avoid ambiguous override language in gates.** LLMs interpret "you can skip this" as permission to skip. Stage 4 uses an explicit override protocol requiring the human to say "override" (see build/SKILL.md).
- **Template conditionals need explicit instructions.** `{{#IF_UI_TASK}}` blocks have no template engine — the orchestrator must be told to include or omit them based on the task's UI flag.
- **Agent preamble sync is manual.** There is no auto-include. If you change `agent-preamble.md`, you must manually update every agent that inlines it.
