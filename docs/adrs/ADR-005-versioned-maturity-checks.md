# ADR-005: Self-Upgrading Maturity Checks with Versioned IDs

**Date:** 2026-04
**Status:** Accepted
**Decider:** Nick Kirkes

---

## Context

Ruckus adapts its behavior based on project maturity. A greenfield project doesn't need an investigator agent, a Stop hook, or test verification — installing them would add overhead with no benefit. But as the project grows (more source files, test suite added, CI configured), these capabilities become valuable.

The question is how to offer these upgrades without nagging users who've decided they don't want them, while still re-offering when the plugin improves a previously-declined check.

## Decision

Maturity checks run at the wrap-up stage of every `/ruckus:build` and `/ruckus:fix` invocation. Each check has a versioned ID (e.g., `investigator-v1`, `test-verify-v1`). User responses are recorded in `.ruckus/workflow-upgrades` with the format `[check-id]-[added|declined] YYYY-MM-DD`.

Three response options per check: **yes** (apply the upgrade), **not yet** (ask again next run), **never** (stop asking for this version).

When a plugin update improves a check, the version increments (e.g., `test-verify-v1` → `test-verify-v2`). A previous `test-verify-v1-declined` entry does not suppress the v2 check, so the user is re-offered the improved version with an explanation of what changed.

## Reasoning

Without versioning, a "never" decision is permanent across all future plugin versions. A user who declined test integration because the check only detected Jest would never be re-offered when the check adds Vitest support. Versioning solves this without nagging — the user only sees re-offers when the check itself has genuinely improved.

The three-response UX (yes / not yet / never) respects user autonomy. "Not yet" is the low-commitment option — it doesn't record anything, so the check fires again on the next pipeline run. This is important for users who want the upgrade but aren't ready to deal with it right now (mid-feature, end of day, etc.).

## Alternatives Considered

**No versioning — "never" means never.** Simpler, but permanently locks out users from improvements they'd want.

**Auto-upgrade without asking.** Install capabilities silently when conditions are met. Rejected because it violates the human-gate principle — the user should always know what's being changed and approve it.

**Separate upgrade command only.** Don't check at wrap-up; require users to explicitly run `/ruckus:upgrade` to get new capabilities. Rejected because most users won't remember to run it, and the natural trigger (wrap-up of a pipeline that just revealed the project has grown) is a better moment.

## Consequences

### Positive
- Projects get progressively more rigorous as they grow, without manual configuration
- Users who decline aren't nagged — but they do get re-offered when the check improves
- The upgrades file is human-readable and git-committed, so the team's maturity decisions are visible

### Negative
- Every pipeline run reads and evaluates the upgrades file at wrap-up, adding ~200-300 tokens
- Contributors must remember to bump version IDs when improving checks, or users won't see the improvement
- The upgrades file format is loose (not validated), so a malformed entry could silently suppress a check

### Neutral
- The upgrades file doubles as a lightweight project history — you can see when the investigator was added, when tests were integrated, etc.

> **Note (v0.1.2):** `docs/claude/` was renamed to `.ruckus/`. Path references above reflect the updated structure.
