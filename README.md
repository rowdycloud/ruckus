# Ruckus

Gated development pipelines with subagent-per-task execution. Ruckus is a Claude Code plugin by Rowdy Cloud that makes agents prove their work at every stage — no quiet failures, no skipped steps, no hoping things work. Discover, plan, verify, implement, review, ship.

## Installation

```sh
/plugin install ruckus@rowdy-cloud
```

The install format is `plugin-name@publisher` — `rowdy-cloud` is the marketplace publisher. If install fails: check that Claude Code is v1.0+ (`claude --version`), verify internet access, and try `/plugin list` to confirm marketplace connectivity. As a fallback, clone the repo manually into `~/.claude/plugins/ruckus/`.

## Quick Start

```sh
/ruckus:setup
```

Setup detects your project's maturity level, collects essential context (stack, build commands, conventions), and creates the documentation structure that powers all Ruckus skills.

## How It Works

Ruckus pipelines are built on four architectural ideas:

**Subagent-per-task.** Each implementation task gets a fresh agent with clean context. The orchestrator (build/fix skill) coordinates but doesn't implement. This prevents context overflow — the #1 failure mode for long AI sessions.

**Two-stage review.** After every task, the orchestrator checks: (1) spec compliance — did the subagent do what the plan said? (2) quality — does the code pass type check and build? Both must pass before the next task starts.

**Mandatory plan review.** Before implementation begins, the plan is sent to a review-plan subagent as a blocking call — the orchestrator waits for it to return. It can't be skipped because it's not a skill invocation; it's a subagent dispatch.

**Shared context files.** All agents read `docs/claude/CLAUDE.md` (project stack, commands, conventions) and `docs/claude/known-pitfalls.md` (gotchas discovered during development). These are the shared context that makes agents project-aware without bloating individual prompts.

## Understanding Gates

A gate is a human confirmation point between pipeline stages. Every gate shows what just happened, then asks you to decide before continuing.

Example gate (after Stage 2 discovery):

```text
Discovery complete. Found 3 existing patterns to reuse,
2 files in blast radius.

Proceed to planning? (yes / investigate further / abort)
```

**Gate options:**

- **yes** — advance to the next stage
- **middle option** — varies by stage (revise plan, investigate further, adjust scope, etc.)
- **abort** — stop the pipeline and preserve all work done so far

You can abort at any gate, but you can't skip one. Gates are the mechanism that makes Ruckus "loud" — no silent transitions between stages.

## Choose Your Workflow

| Situation | Command | Why this one |
| --------- | ------- | ----------- |
| Building a new feature or story | `/ruckus:build` | Full 8-stage pipeline with discovery |
| Fixing a bug or issue | `/ruckus:fix` | Investigation instead of discovery, `fix:` commits |
| Want a code review of recent changes | `/ruckus:review` | Parallel 3-agent review, no implementation |
| Reviewing an epic before implementation | `/ruckus:review-epic` | Catches spec issues before you invest implementation time |
| Auditing an epic after implementation | `/ruckus:audit-epic` | Verifies acceptance criteria were met across all stories |
| Checking if the build is clean | `/ruckus:verify-all` | Type check + test + build loop |
| Setting up Ruckus for the first time | `/ruckus:setup` | Run once per project |
| Updating Ruckus after a plugin update | `/ruckus:upgrade` | Diffs and applies template changes |

## Skills Reference

| Skill | Purpose | When to use |
| ----- | ------- | ----------- |
| `build` | 8-stage feature pipeline with subagent-per-task | New features, stories, epics — any additive work |
| `fix` | 8-stage bug fix pipeline with investigation | Bugs, regressions, issues — any corrective work |
| `review` | Parallel 3-agent code review | After implementation, before committing, or as standalone review |
| `review-epic` | Pre-implementation epic review (Opus) | Before starting an epic — catches spec problems early |
| `audit-epic` | Post-implementation epic audit with AC verification | After completing an epic — verifies acceptance criteria |
| `verify-all` | Type check + test + build verification loop | Standalone build verification; also called by build/fix pipelines |
| `review-plan` | Plan verification subagent (3-iteration max) | Auto-dispatched by build/fix; also usable standalone |
| `setup` | Project bootstrap with maturity detection | First time using Ruckus in a project |
| `upgrade` | Update installed files from latest templates | After plugin updates, or to refresh CLAUDE.md |

## Pipeline: `/ruckus:build`

The build pipeline drives feature implementation through 8 gated stages:

```text
Intake → Discover → Plan → Review Plan → Implement → Review → Verify → Wrap-up
```

**Key behaviors:**

- Each task in the plan gets a fresh subagent (prevents context overflow)
- Two-stage review after every task (spec compliance + quality check)
- Plan review is mandatory and dispatched as a blocking subagent
- UI work detected per-task via `UI: yes/no` flag (loads frontend-design automatically)
- Human gates at every stage transition
- Context compacted after Stages 4, 5, 6 to prevent overflow on longer builds

## Pipeline: `/ruckus:fix`

Same 8-stage structure with investigation instead of discovery:

```text
Intake → Investigate → Plan → Review Plan → Implement → Review → Verify → Wrap-up
```

**Key differences from build:**

- Stage 2 dispatches the investigator agent (or performs inline if agent doesn't exist)
- Compacts context before investigation and after Stages 4, 5, 6
- Commit messages use `fix:` prefix with issue ID reference
- Self-upgrades: offers to create investigator agent when project reaches 50+ files

## Agents

| Agent | Model | Purpose | When dispatched |
| ----- | ----- | ------- | -------------- |
| `discovery` | Sonnet | Research and scope features | `build` Stage 2 |
| `investigator` | Sonnet | Diagnose bugs by tracing code | `fix` Stage 2 (created at 50+ files) |
| `epic-reviewer` | Opus | Cross-story epic review | `review-epic` |
| `code-reviewer` | Sonnet | Bugs, security, conventions | `review` (parallel), `build`/`fix` Stage 6 |
| `static-analysis` | Sonnet | Type check, lint, build, dead code | `review` (parallel) |
| `silent-failure-hunter` | Sonnet | Swallowed errors, missing handling | `review` (parallel) |
| `doc-writer` | Sonnet | Updates CLAUDE.md, known-pitfalls, ADRs | `build`/`fix` wrap-up (if new pitfalls found) |

## Input Formats

### Epic files

Used by `/ruckus:build`, `/ruckus:review-epic`, and `/ruckus:audit-epic`. Place in `docs/epics/` by convention.

No rigid schema — Ruckus parses what it finds. More structure produces better agent output. Recommended format:

```markdown
# E02: User Authentication

## Story 1: Login Flow
**AC:**
- User can log in with email/password
- Failed login shows error message
- Session persists across page reloads

## Story 2: Password Reset
**AC:**
- User receives reset email within 60 seconds
- Reset link expires after 24 hours
```

### Issue files

Used by `/ruckus:fix`. Can be a file reference or inline description:

```sh
/ruckus:fix docs/issues/uat-issues.md ISSUE-001
/ruckus:fix "Login button returns 403 on first click"
```

If referencing a file, include symptoms, reproduction steps, and any known context.

### Plan files

Generated by build/fix pipelines — not user-authored. Written to `docs/plans/` automatically. Each plan contains a file table, discrete tasks (T1, T2...), blast radius notes, and a verify command per task.

## Maturity Levels

Ruckus adapts to your project's size, detected by source file count during setup:

| Level | Source Files | What changes |
| ----- | ----------- | ----------- |
| Greenfield | <10 | `verify-all` runs build only (skips test/typecheck if not configured). No investigator agent created. No Stop hook offered. |
| Scaffolded | 10-50 | Standard configuration. All verification checks active if commands were provided during setup. Doc-writer agent runs at wrap-up. |
| Established | 50+ | Setup offers to create investigator agent immediately. Stop hook offered when verify-all has 2+ meaningful checks. `pitfalls-organized` check activates when known-pitfalls.md exceeds 80 lines. |

## Self-Upgrading

Ruckus checks for upgrade opportunities at the end of every build/fix run:

| Check ID | Trigger | Offers |
| -------- | ------- | ------ |
| `investigator-v1` | 50+ source files, no investigator agent | Create investigator agent |
| `test-verify-v1` | Test config exists, verify-all test step is placeholder | Add test execution |
| `stop-hook-v1` | verify-all has 2+ meaningful checks, no Stop hook | Add Stop hook |
| `pitfalls-organized-v1` | known-pitfalls.md > 80 lines | Deduplicate and organize |

Check IDs are versioned. When a plugin update improves a check, the version bumps and previously-declined checks are re-offered with an explanation of what changed.

**Responses:** `yes` (apply) / `not yet` (ask again next run) / `never` (don't ask again for this version)

## Token Usage

Approximate token consumption per skill invocation. Actual usage varies with project size, plan complexity, and task count.

| Skill | Approximate Tokens | Notes |
| ----- | ------------------ | ----- |
| `setup` | 5K-10K | One-time; mostly human Q&A |
| `build` | 40K-80K | Scales with task count (~8-12K per task) |
| `fix` | 30K-60K | Usually fewer tasks than build |
| `review` | 15K-25K | 3 parallel agents reading changed files |
| `review-epic` | 10K-20K | Single Opus dispatch; scales with epic size |
| `audit-epic` | 20K-50K | Per-story subagents + synthesis |
| `verify-all` | 3K-8K | Depends on fix iterations |
| `review-plan` | 5K-10K | Up to 3 verification iterations |
| `upgrade` | 3K-5K | Template diffing only |

## Troubleshooting

### Context overflow mid-build

**Symptom:** Agent loses track of earlier tasks or gives confused output late in a build.
**Cause:** Too many tasks in the plan for a single context window.
**Fix:** Break large features into smaller builds (5-7 tasks max per run). If mid-run, abort and split remaining tasks into a second `/ruckus:build`.
Ruckus automatically compacts context after Stages 4, 5, and 6 to reduce overflow risk, but very large plans (10+ tasks) may still hit limits.

### Subagent returns empty or fails

**Symptom:** Implementation subagent returns without making changes or errors out.
**Cause:** Insufficient task detail in the plan, or the task references files that don't exist yet (dependency ordering).
**Fix:** Check task dependencies. Ensure `Depends on:` is set correctly. If a task needs files from a previous task, they must run sequentially.

### Verification loop won't converge

**Symptom:** `verify-all` keeps failing after 3 fix attempts per check.
**Cause:** The issue may be environmental (missing dependency, wrong Node version) rather than code.
**Fix:** Run the failing command manually to see full output. Check that CLAUDE.md commands are correct. The escalation message tells you which check failed — fix it outside Ruckus if needed.

### "CLAUDE.md is missing build commands" warning

**Symptom:** Pipeline warns about missing context at the start of implementation (Stage 5).
**Cause:** `/ruckus:setup` wasn't run, or was run with incomplete answers.
**Fix:** Run `/ruckus:setup`. If setup was already run, check `docs/claude/CLAUDE.md` for placeholder values that weren't replaced.

### Plan review seems stuck or loops

**Symptom:** `review-plan` keeps returning NEEDS REVISION after multiple iterations.
**Cause:** Plan has fundamental issues the review keeps flagging, or review criteria conflict with the plan's scope.
**Fix:** After 2 auto-revisions, the orchestrator asks you to decide. Read the review feedback — if concerns are valid, revise the plan manually. If concerns are pedantic for this scope, override and proceed.

## Philosophy

**Loud.** Every gate produces visible output. No silent passes. If something fails, it makes noise until it's fixed.

**Gated.** No stage starts until the previous one proves itself. Plan review can't be skipped because it's a blocking subagent. Implementation can't start without verified plan approval.

**Opinionated.** Ruckus has opinions about how code should be built: discover first, plan in discrete tasks, verify the plan, implement one task at a time, review everything, verify the build. You can abort at any gate, but you can't skip one.

## Project Structure

```text
ruckus/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── build/          (feature pipeline + subagent templates)
│   ├── fix/            (bug fix pipeline)
│   ├── review/         (parallel 3-agent review)
│   ├── review-epic/    (pre-implementation epic review)
│   ├── audit-epic/     (post-implementation epic audit)
│   ├── verify-all/     (type check + test + build loop)
│   ├── review-plan/    (plan verification)
│   ├── upgrade/        (update installed files)
│   └── setup/          (bootstrap + templates)
├── agents/             (7 agent definitions)
├── README.md
├── CHANGELOG.md
├── LICENSE
└── marketplace.json
```

## Contributing

1. Fork the repo
2. Create a feature branch
3. Make your changes (follow the gated pipeline — use `/ruckus:build` on itself)
4. Ensure all skills are under 300 lines and all agents under 500 words
5. Submit a PR

## License

MIT - Rowdy Cloud
