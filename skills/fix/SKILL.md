---
name: fix
description: "Bug/issue fix pipeline: investigate → plan → review plan → implement (subagent-per-task with two-stage review) → review → verify build. Self-upgrades investigator agent when project reaches 50+ files."
disable-model-invocation: true
---

# Fix Pipeline

You are the fix orchestrator. Drive this pipeline sequentially with human gates at each stage. You coordinate — subagents implement.

## Context
- Changed files: !`git diff --name-only HEAD 2>/dev/null || echo "clean"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "no branch"`

Issue to fix: $ARGUMENTS

---

## STAGE 1: INTAKE

Parse `$ARGUMENTS`. Expected formats:
- File reference + issue ID: `docs/issues/uat-issues.md ISSUE-001`
- Direct description: `"Login fails when session expires"`
- File reference only: `docs/bugs/crash-report.md`

If it references a file, read it. If an issue ID is provided, extract that specific issue's details.

Display: issue summary, reproduction steps (if available), affected area.

Ask: **"Is this the correct issue? (yes / adjust / abort)"**

---

## STAGE 2: INVESTIGATE

First, compact context to preserve headroom for investigation (investigation involves extensive search/read operations).

Dispatch the `investigator` agent (if it exists at `.claude/agents/investigator.md`) with the issue description.

If the investigator agent does NOT exist, perform investigation inline:
1. Search for relevant code using the issue description
2. Trace the execution path
3. Identify the root cause or narrow candidates
4. Document findings

When investigation completes, display the report: root cause hypothesis, affected files, proposed fix approach.

**Gate:** "Investigation complete. Root cause: [summary]. Proceed to planning? (yes / investigate further / abort)"

---

## STAGE 3: PLAN

Using the investigation report, write a fix plan. Same format as `/ruckus:build` plans:

```markdown
# Fix Plan: [issue ID or short description]

## Root Cause
[One paragraph explaining why the bug exists]

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| src/auth/session.ts | Modify | T1 |
| src/auth/session.test.ts | Create | T2 |

## Tasks

### T1: [short title] (~3 min)
**Files:** [file paths]
**Action:** [what to change]
**Details:** [specific implementation — enough for a fresh subagent]
**Verify:** [command to confirm the fix]
**UI:** no

### T2: [short title] (~3 min)
**Files:** [file paths]
**Depends on:** T1
**Action:** [add regression test]
**Details:** [specific test to write]
**Verify:** [test command]
**UI:** no

## Blast Radius
- Do NOT modify: [files outside scope]
- Watch for: [side effects]
```

Write the plan to: `docs/plans/fix-<issue-id-or-name>-plan.md` (e.g., `fix-GH-42-plan.md`)

**Gate:** "Fix plan drafted with [N] tasks. Proceed to plan review? (yes / revise plan / abort)"

---

## STAGE 4: REVIEW PLAN

**MANDATORY — this stage cannot be skipped.**

**Pre-check:** Before dispatching, verify the plan file from Stage 3:
1. Confirm the file exists at the expected path
2. Confirm it contains a `## Tasks` section with at least one task (T1)
3. If either check fails: warn the human and loop back to Stage 3

Dispatch a subagent to review the plan. Use model `sonnet`. Read `skills/review-plan/SKILL.md` and use its content as the subagent prompt. Pass the plan file path from Stage 3 as the input.

When the subagent returns, display its findings.

**If PASS:** proceed to gate.
**If NEEDS REVISION:** apply the suggested edits to the plan file, show the human what changed, then re-dispatch the review-plan subagent against the updated plan. Repeat until PASS or until 2 consecutive NEEDS REVISION verdicts — at that point, present findings to the human and let them decide.

**Gate (only after PASS or human override):** "Plan review complete. [summary]. Ready to implement? (yes / revise further / abort)"

Compact context before implementation. Preserve: issue summary with root cause, plan file path, PASS verdict. The plan file on disk contains all implementation details — re-read it in Stage 5.

---

## STAGE 5: IMPLEMENT (subagent-per-task)

**Prerequisite:** Stage 4 must have completed and been approved.

### 5a. Create task tracking

Read the verified plan. Create a TodoWrite entry for each task. Note task dependencies — do not dispatch a task until its dependencies are marked complete.

### 5b. Execute tasks

For each task in order, dispatch a fresh implementation subagent. Use model `sonnet`.

Read `skills/build/implementer-prompt.md` and fill in the template variables for this specific task.

### 5c. Two-stage review after each task

After each subagent returns:

**Stage 1 — Spec compliance (orchestrator performs inline):**
Follow the checklist in `skills/build/spec-reviewer-prompt.md`:
- Did the subagent modify only the files listed in the task?
- Did the verification command pass?
- Does the implementation match the task description?
- If the subagent returned questions: answer them, re-dispatch.

**Stage 2 — Quick quality check (orchestrator performs inline):**
- Run the project's type check / lint command
- If it fails: fix the issue OR re-dispatch the subagent with the error

**If both stages pass:** mark task complete, proceed to next task.
**If spec compliance fails:** re-dispatch with clarified instructions OR escalate to human.
**If quality check fails repeatedly (>2 attempts):** escalate to human.

### 5d. Completion

**Gate:** "Fix implemented. [N] tasks executed, all passing. Summary: [task list with status]. Proceed to review? (yes / adjust / abort)"

Compact context before review. Preserve: issue summary, list of all files changed, task completion count, any verification warnings or deviations.

---

## STAGE 6: REVIEW

**MANDATORY — this stage cannot be skipped.**

Invoke `/ruckus:review` with a description of the fix. Fix any critical findings. Re-run until clean.

**Gate:** "Review complete. Proceed to verification? (yes / address warnings / abort)"

Compact context before verification. Preserve: issue summary, files changed, review verdict, any deferred warnings.

---

## STAGE 7: VERIFY

**MANDATORY — this stage cannot be skipped.**

Invoke `/ruckus:verify-all`. Fix failures and re-run until clean.

**Gate:** "Verification passed. Ready to commit? (yes / additional checks / abort)"

---

## STAGE 8: WRAP-UP

1. `git add` changed files
2. Draft commit message:
   ```
   fix: [short description]

   Root cause: [one line]
   Issue: [issue ID if provided]
   Changes: [file list with one-line descriptions]
   Tested: [verification summary]
   ```
3. Show commit for approval. Commit but do NOT push.
4. Run maturity checks (see below).
5. Ask: "Did this fix reveal any new pitfalls for `docs/claude/known-pitfalls.md`?" If yes, dispatch `doc-writer` agent.

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
Read CLAUDE.md. If missing build command, type check command, or stack summary, warn:
> "CLAUDE.md is missing [fields]. This reduces the quality of every Ruckus skill. Run `/ruckus:setup` to fix, or provide the missing info now."
Continue with whatever the human provides — not a hard block, but a visible gap.

**Check: investigator-v1:**
If `.claude/agents/investigator.md` does NOT exist AND source file count > 50 AND not declined:
> "This project has [N] source files but no investigator agent. It improves bug diagnosis — especially for `/ruckus:fix`. Create one?"

**Check: pitfalls-organized-v1:**
If `docs/claude/known-pitfalls.md` > 80 lines AND no `pitfalls-organized-v1` within last 30 days:
> "known-pitfalls.md has grown to [N] lines. Deduplicate and organize?"

**Check: test-verify-v1:**
If test config exists AND verify-all test step is placeholder AND not declined:
> "A test suite is configured. Add test execution to verify-all?"

**Check: stop-hook-v1:**
If `.claude/settings.json` has no `Stop` hook AND verify-all has 2+ meaningful checks AND not declined:
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
