---
name: build
description: "Full feature pipeline: discover → plan → review plan → implement (subagent-per-task with two-stage review) → review → verify build. Detects UI work and loads frontend-design skill automatically. Use for new features, stories, or epics."
disable-model-invocation: true
---

# Feature Build Pipeline

You are the build orchestrator. Drive this pipeline sequentially with human gates at each stage. You coordinate — subagents implement.

**CRITICAL:** Do NOT use Claude Code's built-in plan mode (EnterPlanMode/ExitPlanMode). Present all gates as inline text prompts in the conversation. The pipeline has its own gate protocol — Claude Code's plan mode will hijack the flow and skip stages.

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

Do NOT present the plan to the human yet — proceed directly to Stage 4.

---

## STAGE 4: REVIEW PLAN

**MANDATORY — this stage cannot be skipped. Do NOT present the plan to the human before this stage completes.**

**Pre-check:** Before dispatching, verify the plan file from Stage 3:
1. Confirm the file exists at the expected path
2. Confirm it contains a `## Tasks` section with at least one task (T1)
3. If either check fails: warn the human and loop back to Stage 3

Dispatch `/ruckus:review-plan` as a blocking subagent call. Use model `sonnet`. Pass the plan file path from Stage 3 as the input.

The subagent verifies completeness, assumptions, and overengineering against the actual codebase. It returns a structured PASS / NEEDS REVISION verdict.

**If NEEDS REVISION:** apply the suggested edits to the plan file, then re-dispatch the review-plan subagent against the updated plan. Repeat until PASS or until 2 total NEEDS REVISION verdicts — at that point, present findings to the human and let them decide.

**After review completes:** NOW present the plan and review results to the human. Display the plan summary, task count, and the review verdict (PASS or outstanding concerns).

**Gate (only after PASS or explicit override):** "Plan drafted with [N] tasks and verified against the codebase. [Review summary]. Ready to implement? (yes / revise plan / abort)"

**Override protocol:** If the human wants to proceed without PASS, they must explicitly say "override." Ambiguous responses ("skip it," "good enough," "it's fine") are NOT overrides — ask for clarification. When override is confirmed, display: "Proceeding without plan review PASS. The plan has not been verified against the codebase."

Compact context before implementation. Preserve: feature summary, plan file path, PASS verdict. The plan file on disk contains all implementation details — re-read it in Stage 5.

---

## STAGE 5: IMPLEMENT (subagent-per-task)

**Prerequisite:** Stage 4 must have completed and been approved.

Re-read the plan file. If the path is no longer in context after Stage 4 compaction, check `docs/plans/` for the most recent plan file matching the feature name.

### 5a. Create task tracking

Read the verified plan. Create a TodoWrite entry for each task. Note task dependencies — do not dispatch a task until its dependencies are marked complete.

### 5b. Execute tasks

For each task in order, dispatch a fresh implementation subagent. Use model `sonnet`.

**Implementation subagent prompt (constructed per-task):**

Fill in the `{{VARIABLES}}` below for this specific task. For UI tasks (`UI: yes` in the plan), include the "UI Task" section. For non-UI tasks (`UI: no`), omit the "UI Task" section entirely.

```
You are implementing a single task for {{PROJECT_NAME}}.

## Task

{{TASK_TITLE}}

**Files:** {{TASK_FILES}}
**Action:** {{TASK_ACTION}}
**Details:** {{TASK_DETAILS}}
**Verify:** {{TASK_VERIFY_COMMAND}}

## Context

Read CLAUDE.md and .ruckus/known-pitfalls.md before implementing.

## UI Task (include ONLY when plan task has UI: yes — omit entirely for UI: no)

Invoke `frontend-design` skill if available. If unavailable, apply design system conventions from CLAUDE.md directly.

## Rules

- Implement ONLY this task — do NOT modify files outside the task's file list
- Run verification after changes: {{TASK_VERIFY_COMMAND}} — fix failures before returning
- If unclear or blocked, return a question instead of guessing

## Return

Files changed, verification result (pass/fail), any deviations or blocking questions.
```

### 5c. Two-stage review after each task

After each subagent returns:

**Stage 1 — Spec compliance (orchestrator performs inline):**
Run the spec compliance checklist:
- Did the subagent modify only the files listed in the task?
- Did the verification command pass?
- Does the implementation match the task description?
- If the subagent returned questions: answer them, re-dispatch (max 2; then escalate to human).

**Stage 2 — Quick quality check (orchestrator performs inline):**
- Run the project's type check / lint command
- If it fails on files this task owns: attempt auto-fix (max 2 attempts); if still failing, escalate to human.
- If it fails on files outside this task's scope or on environmental issues (missing dependency, config error): escalate to human immediately.

**If both stages pass:** mark task complete in TodoWrite, proceed to next task.
**If spec compliance fails:** re-dispatch with clarified instructions OR escalate to human.
**If quality check auto-fix fails after 2 attempts:** escalate to human.

### 5d. Completion

After all tasks are complete:

**Gate:** "Implementation complete. [N] tasks executed, all passing. Summary: [task list with status]. Proceed to review? (yes / adjust / abort)"

Compact context before review. Preserve: feature summary, task ID list, list of all files changed, task completion count, any verification warnings or deviations.

---

## STAGE 6: REVIEW

**MANDATORY — this stage cannot be skipped.**

Invoke `/ruckus:review` (or the project's review command) with a description of what was built. This dispatches code-reviewer, static-analysis, and silent-failure-hunter in parallel.

Fix critical findings and re-run review (max 2 review-fix cycles; if still failing, present findings to human).

**Gate:** "Review complete. Proceed to verification? (yes / list warnings to address [then re-review once] / abort)"

Compact context before verification. Preserve: feature summary, files changed, review verdict, any deferred warnings.

---

## STAGE 7: VERIFY

**MANDATORY — this stage cannot be skipped.**

Invoke `/ruckus:verify-all` (or the project's verify-all command). Fix failures and re-run until clean.

**Gate:** "Verification passed. Ready to commit? (yes / additional checks / abort)"

Compact context before wrap-up. Preserve: feature summary, files changed, task completion count, verification verdict.

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
5. Ask: "Did this work reveal any new pitfalls or conventions for `.ruckus/known-pitfalls.md`?" If yes, dispatch `doc-writer` agent.

---

## MATURITY CHECKS (run at wrap-up)

Read `.ruckus/workflow-upgrades` (create if missing).

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
If no `investigator-v1-added` in `.ruckus/workflow-upgrades` AND source file count > 50 AND not declined:
> "This project has [N] source files but the investigator agent isn't enabled. It improves bug diagnosis for `/ruckus:fix`. Enable it? (yes / not yet / never)"
If yes: record `investigator-v1-added YYYY-MM-DD` in `.ruckus/workflow-upgrades`. The agent definition ships with the plugin — no file copy needed.

**Check: pitfalls-organized-v1:**
If `.ruckus/known-pitfalls.md` > 80 lines AND no `pitfalls-organized-v1` within last 30 days:
> "known-pitfalls.md has grown to [N] lines. Deduplicate and organize?"

**Check: test-verify-v1:**
If test config exists AND verify-all test step is placeholder AND not declined:
> "A test suite is configured. Add test execution to verify-all?"

**Check: stop-hook-v1:**
If `.claude/settings.json` has no `Stop` hook AND verify-all has at least 2 meaningful checks AND not declined:
> "Verification is robust enough to enforce. Add a Stop hook?"

---

## ABORT HANDLING

When the human selects "abort" at any gate, respond based on how far the pipeline progressed:

**Stages 1-2 (no files written):** Acknowledge abort. No cleanup needed.

**Stages 3-4 (plan written, no implementation):** Ask: "Delete the plan file at [path]? (yes / keep it)"
- If yes: delete the plan file
- Clear any TodoWrite entries created for this pipeline run

**Stages 5-7 (implementation started):** Offer rollback:
> "Implementation is in progress. Options:
> 1. `git stash -u` — stash all uncommitted changes including new files (recoverable via `git stash pop`)
> 2. `git reset --hard HEAD && git clean -fd` — discard all uncommitted changes (staged and unstaged) and remove new files (**irreversible — cannot be undone**)
> 3. Keep changes as-is — leave working tree dirty for manual review"

If the human selects option 2, require explicit re-confirmation: "This will permanently delete all uncommitted changes. Type 'discard' to confirm."

Wait for human choice. Execute their selection. Then:
- Clear all TodoWrite entries for this pipeline run
- Delete the plan file only if the human also confirms

**Always on abort:** End with a clear message: "Pipeline aborted at Stage [N]. [cleanup summary]."
