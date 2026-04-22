---
name: build
description: "Full feature pipeline: discover → plan → verify plan → implement (subagent-per-task with two-stage review) → review → verify build. Detects UI work and loads frontend-design skill automatically. Use for new features, stories, or epics."
disable-model-invocation: true
---

# Feature Build Pipeline

You are the build orchestrator. Drive this pipeline sequentially with human gates at each stage. You coordinate — subagents implement.

## Context
- Changed files: !`git diff --name-only HEAD 2>/dev/null || echo "clean"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "no branch"`

Feature to build: $ARGUMENTS

---

## STAGE 1: INTAKE

Parse `$ARGUMENTS`. If it references a file (epic, story, spec), read it. Display a summary of what's being built.

Ask: **"Is this the correct scope? (yes / adjust / abort)"**

---

## STAGE 2: DISCOVER

Dispatch the `discovery` agent with the feature description and any referenced architecture docs or ADRs.

When it returns, display the discovery report.

**Gate:** "Discovery complete. Proceed to planning? (yes / investigate further / abort)"

---

## STAGE 3: PLAN

Using the discovery report, write an implementation plan. The plan MUST be structured as discrete tasks:

### Plan Format

```markdown
# Implementation Plan: [feature name]

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| src/components/Widget.tsx | Create | T1, T2 |
| src/hooks/useWidget.ts | Create | T3 |

## Tasks

### T1: [short title] (~3 min)
**Files:** src/components/Widget.tsx
**Action:** Create the base Widget component with props interface
**Details:** [exact what to implement — specific enough that a subagent with zero project context can execute it]
**Verify:** [command to run after this task, e.g., type check passes]
**UI:** yes/no [whether this task involves visual/component/layout work]

### T2: [short title] (~5 min)
**Files:** src/components/Widget.tsx
**Depends on:** T1
**Action:** Add interaction handlers and state management
**Details:** [specific implementation details]
**Verify:** [verification command]
**UI:** yes/no

## Blast Radius
- Do NOT modify: [files outside scope]
- Watch for: [side effects, dependencies]

## Conventions
- [Reference ADRs, existing patterns to follow]
```

Each task should be 2-5 minutes of work. If a task feels larger, break it down. Tasks must include exact file paths and be specific enough that a fresh subagent with no project history can execute them.

Write the plan to a file: `docs/plans/<feature-name>-plan.md` (e.g., `user-dashboard-plan.md`)

Present the plan summary to the human.

**Gate:** "Plan drafted with [N] tasks. Proceed to plan verification? (yes / revise plan / abort)"

---

## STAGE 4: VERIFY PLAN

**MANDATORY — this stage cannot be skipped.**

Dispatch a subagent to verify the plan. Use model `sonnet`. The subagent receives:

**Subagent prompt:**

```
You are a plan verification agent. Read the implementation plan and verify it against the actual codebase. You do NOT modify any files.

Read: CLAUDE.md, docs/claude/known-pitfalls.md
Read: [plan file path]

## Verification Checks

### Completeness
- Does every requirement from the original spec have a corresponding task?
- Are there gaps between tasks where work would fall through?
- Does each task have a verification step?

### Assumptions
- Do the file paths referenced in tasks actually exist (for modifications) or are the parent directories valid (for new files)?
- Are function signatures, component names, and imports referenced in task details accurate?
- Are there dependencies between tasks that aren't marked?

### Overengineering
- Could any task be simpler while still meeting requirements?
- Does any task introduce abstractions that aren't needed at current scale?
- Are there existing utilities, patterns, or components in the codebase that tasks should reuse instead of creating new ones?

For each check, investigate the codebase for evidence. Do not speculate.

## Output Format

## Plan Verification

**Status:** PASS / NEEDS REVISION

### Findings
- ✅ [what checks out — cite evidence]
- ⚠️ [concerns — cite evidence, suggest specific revision]
- ❌ [blockers — cite evidence, this must be fixed]

### Suggested Plan Edits
[If NEEDS REVISION: specific changes to make, referencing task IDs]
```

When the subagent returns, display its findings.

**If PASS:** proceed to gate.
**If NEEDS REVISION:** apply the suggested edits to the plan file, show the human what changed.

**Gate:** "Plan verification complete. [summary]. Ready to implement? (yes / revise further / abort)"

---

## STAGE 5: IMPLEMENT (subagent-per-task)

**Prerequisite:** Stage 4 must have completed and been approved.

### 5a. Create task tracking

Read the verified plan. Create a TodoWrite entry for each task. Note task dependencies — do not dispatch a task until its dependencies are marked complete.

### 5b. Execute tasks

For each task in order, dispatch a fresh implementation subagent. Use model `sonnet`.

**Implementation subagent prompt (constructed per-task):**

```
You are implementing a single task for [PROJECT_NAME].

## Your Task
[Full task text from plan: title, files, action, details, verify]

## Project Context
Read these files before implementing:
- CLAUDE.md — project conventions
- docs/claude/known-pitfalls.md — known issues to avoid

[IF TASK IS MARKED UI: yes]
Use the Skill tool to run `frontend-design` to load design guidelines.
Read any project design system files referenced in CLAUDE.md.
Apply frontend-design principles within project design system constraints.
[END IF]

## Rules
- Implement ONLY what this task describes
- Do NOT modify files outside the task's file list
- Run the verification command after changes: [verify command from task]
- If verification fails, fix the issue before returning
- If the task is unclear or you need information not available to you, return a question instead of guessing

## Return
- Files created or modified
- Verification result (pass/fail)
- Any deviations from the task spec and why
- Any questions that blocked you (if applicable)
```

### 5c. Two-stage review after each task

After each subagent returns:

**Stage 1 — Spec compliance (orchestrator performs inline):**
- Did the subagent modify only the files listed in the task?
- Did the verification command pass?
- Does the implementation match the task description?
- If the subagent returned questions: answer them, re-dispatch.

**Stage 2 — Quick quality check (orchestrator performs inline):**
- Run the project's type check / lint command
- If it fails: fix the issue OR re-dispatch the subagent with the error

**If both stages pass:** mark task complete in TodoWrite, proceed to next task.
**If spec compliance fails:** re-dispatch with clarified instructions OR escalate to human.
**If quality check fails repeatedly (>2 attempts):** escalate to human.

### 5d. Completion

After all tasks are complete:

**Gate:** "Implementation complete. [N] tasks executed, all passing. Summary: [task list with status]. Proceed to review? (yes / adjust / abort)"

---

## STAGE 6: REVIEW

Invoke `/ruckus:review` (or the project's review command) with a description of what was built. This dispatches code-reviewer, static-analysis, and silent-failure-hunter in parallel.

Fix any critical findings. Re-run review until clean.

**Gate:** "Review complete. Proceed to verification? (yes / address warnings / abort)"

---

## STAGE 7: VERIFY

Invoke `/ruckus:verify-all` (or the project's verify-all command). Fix failures and re-run until clean.

**Gate:** "Verification passed. Ready to commit? (yes / additional checks / abort)"

---

## STAGE 8: WRAP-UP

1. `git add` changed files
2. Draft commit message:
   ```
   feat: [short description]

   [What was built and why]
   Tasks: [N] completed
   Changes: [file list with one-line descriptions]
   Tested: [verification summary]
   ```
3. Show commit for approval. Commit but do NOT push.
4. Run maturity checks (see below).
5. Ask: "Did this work reveal any new pitfalls or conventions for `docs/claude/known-pitfalls.md`?" If yes, dispatch `doc-writer` agent.

---

## MATURITY CHECKS (run at wrap-up)

Read `docs/claude/.workflow-upgrades` (create if missing).

Check IDs are versioned (e.g., `investigator-v1`). When the plugin updates a check, the version bumps and previously-declined checks are re-offered with an explanation of what changed.

Format per entry: `[check-id]-[added|declined] YYYY-MM-DD`

Three responses per upgrade:
- **yes** — apply, record `[id]-added YYYY-MM-DD`
- **not yet** — don't record (ask again next run)
- **never** — record `[id]-declined` (never ask again for this version)

**Check: CLAUDE.md quality (every run, not gated by upgrades file):**
Read CLAUDE.md. If it's missing build command, type check command, or stack summary, warn:
> "CLAUDE.md is missing [fields]. This reduces the quality of every Ruckus skill. Run `/ruckus:setup` to fix, or provide the missing info now."
Continue with whatever the human provides — not a hard block, but a visible gap.

**Check: investigator-v1:**
If `.claude/agents/investigator.md` does NOT exist AND source file count > 50 AND not declined:
> "This project has [N] source files but no investigator agent. It improves bug diagnosis. Create one?"

**Check: pitfalls-organized-v1:**
If `docs/claude/known-pitfalls.md` > 80 lines AND no `pitfalls-organized-v1` within last 30 days:
> "known-pitfalls.md has grown to [N] lines. Deduplicate and organize?"

**Check: test-verify-v1:**
If test config exists AND verify-all test step is placeholder AND not declined:
> "A test suite is configured. Add test execution to verify-all?"

**Check: stop-hook-v1:**
If `.claude/settings.json` has no `Stop` hook AND verify-all has at least 2 meaningful checks AND not declined:
> "Verification is robust enough to enforce. Add a Stop hook?"
