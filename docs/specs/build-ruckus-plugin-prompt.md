# Task: Build the Ruckus Plugin for Claude Code

## What Is Ruckus

Ruckus is a Claude Code plugin by Rowdy Cloud that implements a gated development pipeline with subagent-per-task execution. It's opinionated about process: every stage proves itself before the next begins.

The core philosophy: agents don't quietly hope code works — they make noise at every gate until they've proven it.

## Plugin Identity

- **Name:** `ruckus`
- **Org:** Rowdy Cloud
- **Repo:** (will be public GitHub)
- **License:** MIT
- **Install command:** `/plugin install ruckus@rowdy-cloud` (once marketplace is set up)
- **Skill prefix:** `/ruckus:build`, `/ruckus:fix`, `/ruckus:review`, etc.

## Architecture Summary

### Two pipeline commands (skills):

**`/ruckus:build`** — Feature implementation pipeline
```
Intake → Discover → Plan (task-level) → Verify Plan (subagent) → Implement (subagent-per-task + two-stage review) → Review (parallel 3-agent) → Verify Build → Wrap-up
```

**`/ruckus:fix`** — Bug/issue fix pipeline
```
Intake → Investigate (subagent, self-upgrading) → Plan (task-level) → Verify Plan (subagent) → Implement (subagent-per-task + two-stage review) → Review (parallel 3-agent) → Verify Build → Wrap-up
```

### Supporting skills:
- **`/ruckus:review`** — Parallel dispatch of 3 review agents (code-reviewer, static-analysis, silent-failure-hunter)
- **`/ruckus:review-epic`** — Pre-implementation epic file review
- **`/ruckus:audit-epic`** — Post-implementation epic audit with AC verification
- **`/ruckus:verify-all`** — Type check + test + build verification loop
- **`/ruckus:verify-plan`** — Plan verification (dispatched as subagent by build/fix, also invokable standalone)
- **`/ruckus:upgrade`** — Update installed Ruckus files from latest templates
- **`/ruckus:setup`** — Bootstrap Ruckus for a new project (maturity detection, project-specific adaptation)

### 7 agents:
- **`discovery`** — Research and scope features/tasks before planning
- **`investigator`** — Diagnose bugs by tracing code (created automatically when project reaches 50+ source files)
- **`epic-reviewer`** — Pre-implementation epic review (uses Opus for cross-story reasoning)
- **`code-reviewer`** — Bugs, logic errors, security, anti-patterns, consistency
- **`static-analysis`** — Type check, dead code, convention violations, build verification
- **`silent-failure-hunter`** — Swallowed errors, missing handling, data integrity risks
- **`doc-writer`** — Updates CLAUDE.md, known-pitfalls.md, ADRs

### Hooks:
- **PostToolUse** — Auto-format on Write/Edit (formatter detected during setup)
- **Stop** — Block completion without verification (installed via maturity self-upgrade, not on greenfield)

### Doc templates:
- **CLAUDE.md** — Lean index template (<150 lines)
- **known-pitfalls.md** — Starter with domain section headers
- **.claudeignore** — Comprehensive ignore patterns

## Key Design Decisions

### 1. Subagent-per-task implementation (inspired by Superpowers)
Each task in the plan gets a fresh subagent. The orchestrator stays lean (coordination only). After each subagent returns, two-stage review: spec compliance (did it do what the plan said?) then code quality (does it pass type check/build?). This prevents context overflow and catches issues before they compound.

### 2. UI work detected, not forked
No separate build-ui command. The `/ruckus:build` skill reads each task's `UI: yes/no` flag from the plan. For UI tasks, the implementation subagent loads the `frontend-design` skill automatically. Non-UI tasks skip it. One command handles everything.

### 3. Verify-plan dispatched as subagent, not invoked as skill
The orchestrator dispatches verify-plan as a subagent and waits for it to return. The orchestrator cannot skip it because it's blocking on the subagent's response. This solves the "agents skip verify-plan" problem.

### 4. Self-upgrading maturity checks
Both build and fix run maturity checks at wrap-up. They offer to create the investigator agent (when 50+ source files exist), add test execution to verify-all (when test config appears), add the Stop hook (when verification has 2+ meaningful checks), etc. Three responses: yes/not yet/never.

**Maturity check IDs are versioned.** Each check has an ID like `test-verify-v1`. When a plugin update improves a check (e.g., adds Vitest detection to the test suite check), the ID bumps to `test-verify-v2`. The old `test-verify-v1-declined` entry in `.workflow-upgrades` doesn't suppress the new v2 check, so users who previously declined get re-offered the improved version with an explanation: "This check has been updated since you last declined. [what changed]. Add it now?"

The `.workflow-upgrades` file format is: `[check-id]-[v{N}]-[added|declined] YYYY-MM-DD`. Example:
```
investigator-v1-added 2026-04-15
test-verify-v1-declined 2026-04-15
test-verify-v2-added 2026-04-20
stop-hook-v1-added 2026-04-22
```

### 5. CLAUDE.md quality enforcement (setup refuses to finish without essentials)
The plugin's quality depends on CLAUDE.md having real project context. A weak CLAUDE.md degrades every skill — subagents don't know build commands, reviewers don't know conventions, the silent-failure-hunter doesn't know domain-specific risks.

**Setup enforces minimum viable context.** `/ruckus:setup` collects required fields through targeted questions and does not complete until they are provided:
- Stack summary (language, framework, key libraries) — **required**
- Build command — **required**
- Type check command (or "none") — **required**
- Test command (or "none yet") — **required**
- At least one project-specific convention or pattern — **required**
- Domain description (what the project does) — **required**

Optional but prompted:
- Formatter command (for PostToolUse hook)
- Architecture patterns (repository pattern, service layer, etc.)
- Cross-boundary concerns (native bridge, client/server, multi-device)
- Links to architecture docs or ADRs

**Skills fail loudly on missing context.** If a skill reads CLAUDE.md and can't find a build command, it warns: "CLAUDE.md is missing build commands. Run `/ruckus:setup` to configure, or tell me your build command now." It continues with whatever the human provides inline — not a hard block, but a visible gap.

**Known-pitfalls.md self-heals weak CLAUDE.md over time.** Every `/ruckus:fix` and `/ruckus:build` wrap-up asks "Did this reveal new pitfalls?" After 5-10 pipeline runs, known-pitfalls.md contains more actionable project context than most CLAUDE.md files. Skills read both.

### 6. Skill templates use `{{PLACEHOLDER}}` markers
All skills and agents use placeholder markers that `/ruckus:setup` replaces with project-specific values during bootstrap. This is how one plugin adapts to any stack.

### 7. Project maturity levels
Setup detects greenfield (<10 source files), scaffolded (10-50), or established (50+). Adjusts what gets installed: greenfield skips investigator, simplifies verify-all, omits Stop hook. These self-upgrade as the project grows.

## Directory Structure

```
ruckus/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── build/
│   │   ├── SKILL.md                    ← Unified build pipeline
│   │   ├── implementer-prompt.md       ← Template for implementation subagent
│   │   └── spec-reviewer-prompt.md     ← Template for spec compliance check
│   ├── fix/
│   │   └── SKILL.md                    ← Fix pipeline
│   ├── review/
│   │   └── SKILL.md                    ← Parallel 3-agent review
│   ├── review-epic/
│   │   └── SKILL.md                    ← Pre-implementation epic review
│   ├── audit-epic/
│   │   └── SKILL.md                    ← Post-implementation epic audit
│   ├── verify-all/
│   │   └── SKILL.md                    ← Build + type + test verification
│   ├── verify-plan/
│   │   └── SKILL.md                    ← Plan verification
│   ├── upgrade/
│   │   └── SKILL.md                    ← Upgrade installed Ruckus files
│   └── setup/
│       ├── SKILL.md                    ← Bootstrap Ruckus for a new project
│       └── templates/
│           ├── CLAUDE.md.template
│           ├── known-pitfalls.md.template
│           ├── claudeignore.template
│           └── settings.json.template
├── agents/
│   ├── discovery.md
│   ├── investigator.md
│   ├── epic-reviewer.md
│   ├── code-reviewer.md
│   ├── static-analysis.md
│   ├── silent-failure-hunter.md
│   └── doc-writer.md
├── README.md                           ← Full documentation with workflow guide
├── CHANGELOG.md
└── LICENSE                             ← MIT
```

## What to Build — Step by Step

### Step 1: Create the repo structure

Create all directories. Create `plugin.json`:
```json
{
  "name": "ruckus",
  "description": "Gated development pipelines with subagent-per-task execution. Discover → Plan → Verify → Implement → Review → Ship. By Rowdy Cloud.",
  "version": "0.1.0"
}
```

### Step 2: Build the unified /ruckus:build skill

Use the spec in `ruckus-build-skill.md` (attached/provided). This is the centerpiece — get it right. Key things to preserve:
- 8-stage pipeline with human gates
- Plan format with task-level granularity and UI flag per task
- Verify-plan dispatched as subagent (can't be skipped)
- Subagent-per-task implementation with two-stage review
- Conditional frontend-design loading for UI tasks
- Maturity checks at wrap-up
- All project-specific values use `{{PLACEHOLDER}}` markers

### Step 3: Build /ruckus:verify-plan

Use the spec in `ruckus-verify-plan-skill.md` (attached/provided). Key things:
- Up to 3 automated iterations
- Evidence-based findings (cite files, not speculation)
- Structured PASS / NEEDS REVISION verdict
- Suggested plan edits reference specific task IDs

### Step 4: Build /ruckus:fix

Same 8-stage structure as build, but:
- Stage 2 is Investigate (not Discover) — dispatches investigator subagent
- Self-upgrading investigator creation (when project reaches 50+ files)
- Compact before investigation to preserve context
- Commit message format uses `fix:` prefix and references issue ID

### Step 5: Build /ruckus:review

Parallel dispatch of code-reviewer, static-analysis, silent-failure-hunter. Synthesized report with severity-grouped findings and "Known Pitfalls Update?" section.

### Step 6: Build /ruckus:review-epic

Pre-implementation epic review. Dispatches epic-reviewer agent (Opus). Checks technical accuracy, best practices, risks, overengineering. Saves review alongside epic file.

### Step 7: Build /ruckus:audit-epic

Post-implementation epic audit. Parses stories, maps to files via git history, dispatches per-story review subagents in parallel, cross-cutting review, AC verification. Read-only — does not modify code.

### Step 8: Build /ruckus:verify-all

Template with placeholders for type check, test, and build commands. Iterate-until-clean loop.

### Step 9: Build /ruckus:setup

The bootstrap skill. The most critical skill to get right — a weak setup produces weak results from every other skill.

**Maturity detection:** Scan repo for source files, tests, CI, docs. Classify as greenfield/scaffolded/established.

**Required context collection (setup does NOT complete without these):**
1. Stack summary — language(s), framework(s), key libraries. Ask: "What's your tech stack?"
2. Build command — how to build the project. Ask: "What command builds the project?"
3. Type check command — or explicit "none." Ask: "What command type-checks? (e.g., `npx tsc --noEmit`, `mypy .`, or 'none')"
4. Test command — or explicit "none yet." Ask: "What command runs tests? (or 'none yet')"
5. At least one convention — ask: "What's the one pattern or convention agents must always follow in this project?"
6. Domain — ask: "In one sentence, what does this project do?"

**Optional context (prompted but not blocking):**
- Formatter (for PostToolUse hook)
- Architecture patterns
- Cross-boundary concerns
- ADR/doc locations

**File creation:** Creates docs/claude/ directory, CLAUDE.md (from template, populated with required fields), known-pitfalls.md (starter with section headers), .claudeignore, settings.json (with formatter hook if detected).

**Must handle:**
- First-time setup (full bootstrap)
- Existing projects with .claude/ files (merge, don't overwrite)
- Re-running setup to strengthen a weak CLAUDE.md (detect existing, offer to enrich rather than replace)

### Step 10: Build /ruckus:upgrade

Diffs installed files against plugin templates. Classifies as new/changed/unchanged/local-only. Applies structural updates while preserving project customizations. Never overwrites without asking.

### Step 11: Build all 7 agents

Each agent has YAML frontmatter (name, description, tools, model) and a system prompt under 500 words. All agents use `{{PLACEHOLDER}}` markers for project-specific values that setup replaces.

### Step 12: Build the README

The README must include:
- What Ruckus is (one paragraph)
- Installation (`/plugin install ruckus@rowdy-cloud`)
- Quick start (run `/ruckus:setup` in a new project)
- Full workflow documentation showing when to use each skill:
  ```
  New feature:  /ruckus:build docs/epics/E02-story-3.md
  Bug fix:      /ruckus:fix docs/issues/uat-issues.md ISSUE-001
  Code review:  /ruckus:review "Added auth flow"
  Epic review:  /ruckus:review-epic docs/epics/E02.md  (before implementation)
  Epic audit:   /ruckus:audit-epic docs/epics/E02.md   (after implementation)
  Upgrade:      /ruckus:upgrade
  ```
- Agent descriptions (what each does, when it's used)
- Maturity levels (greenfield → scaffolded → established)
- Self-upgrading behavior table
- Philosophy section ("loud, gated, opinionated")
- Contributing guide

### Step 13: Create marketplace.json

```json
{
  "name": "rowdy-cloud",
  "owner": {
    "name": "Rowdy Cloud"
  },
  "plugins": [
    {
      "name": "ruckus",
      "source": ".",
      "description": "Gated development pipelines with subagent-per-task execution."
    }
  ]
}
```

## Constraints

- Every skill body must be under 300 lines (context budget)
- Every agent system prompt must be under 500 words
- CLAUDE.md template must be under 150 lines
- All project-specific values use `{{PLACEHOLDER}}` markers — no hardcoded project names, commands, or paths
- `disable-model-invocation: true` on pipeline skills (build, fix) so they're only user-invoked
- Agent model defaults: Opus for epic-reviewer only, Sonnet for all others
- Skills reference agents by name, not by inlining prompts (keeps skills lean)
- The implementer-prompt.md and spec-reviewer-prompt.md in build/ are subagent prompt templates the orchestrator fills in per-task — they are NOT skills themselves
- **Maturity check IDs must be versioned** (e.g., `investigator-v1`, `test-verify-v1`). The `.workflow-upgrades` file records `[check-id]-[added|declined] YYYY-MM-DD`. When a future plugin version improves a check, the ID version bumps and previously-declined checks are re-offered.
- **Every pipeline skill (build, fix) must check CLAUDE.md quality** at the start of implementation (Stage 5). If essential fields are missing (build command, type check, stack), warn the human and offer to continue with inline-provided values. Not a hard block — the pipeline should still work — but the gap must be visible.
- **Setup must enforce minimum viable context.** It does not complete until required fields are provided: stack, build command, type check command, test command (or "none yet"), one convention, domain description.

## Reference Material

The two core skill specs (ruckus-build-skill.md and ruckus-verify-plan-skill.md) contain the finalized architecture. Use them as the source of truth for those two skills. All other skills and agents should be built to be consistent with the patterns established in those two.
