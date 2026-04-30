# ADR-004: UI Work Detected Conditionally, Not a Separate Command

**Date:** 2026-04
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

The plugin needs to handle both UI/frontend work (components, screens, layouts) and non-UI work (APIs, data layers, business logic). UI work benefits from loading a frontend-design skill that provides design guidelines, component patterns, and styling constraints. The question is whether this should be a separate command (`/ruckus:build-ui`) or a conditional within the unified `/ruckus:build`.

Early versions of the workflow kit maintained two separate commands: `/build` and `/build-ui`. In practice, many features required both — a story might include a data model, an API endpoint, and a component. Users had to choose which command to use, and either missed the design skill on UI tasks or loaded it unnecessarily on data tasks.

## Decision

A single `/ruckus:build` command handles all work. Each task in the plan includes a `UI: yes/no` flag. When the implementation subagent is dispatched for a task flagged as UI work, it loads the `frontend-design` skill. Non-UI tasks skip it. The orchestrator makes no decision — the flag is set during planning and consumed during implementation.

## Reasoning

The subagent-per-task architecture (ADR-002) makes this natural. Since each task gets a fresh subagent, loading the frontend-design skill for UI tasks and skipping it for non-UI tasks is a per-dispatch decision with no leakage between tasks. A data model task doesn't carry the design skill's context, and a component task gets it fresh.

Maintaining two commands (`build` and `build-ui`) meant duplicating the entire 8-stage pipeline with one difference in Stage 5. When improvements were made to one (e.g., adding abort handling, compaction boundaries), the other had to be updated separately. The commands drifted in practice.

## Alternatives Considered

**Two separate commands (`/ruckus:build` and `/ruckus:build-ui`).** Clearer intent at invocation time. Rejected because it doubles maintenance, causes drift, and forces users to choose when many features span both UI and non-UI work.

**Always load the frontend-design skill.** Simpler — no conditional logic. Rejected because the skill adds to the subagent's context budget, reducing room for actual project files on non-UI tasks.

## Consequences

### Positive
- One command to maintain, not two
- Features that mix UI and non-UI tasks get the right skill loaded per task
- No user decision required — the plan's UI flags drive the behavior

### Negative
- Planning must include UI flags per task — adds a small burden to the planning stage
- If an agent misjudges a task's UI flag, the wrong skill configuration is used for that task
- The frontend-design skill must be installed separately (it's a public Anthropic skill, not bundled with Ruckus)

### Neutral
- Projects with no UI work at all will never trigger the frontend-design loading — the flag defaults to `no`

> **Note (v0.1.4):** The plugin was renamed from `ruckus` to `roughly`. Slash commands now use the `/roughly:*` namespace; the plugin-installed dotdir is `.roughly/`. Original identifiers above reflect the original naming.
