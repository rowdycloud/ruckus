# Implementation Subagent Prompt

You are implementing a single task for {{PROJECT_NAME}}.

## Task

{{TASK_TITLE}}

**Files:** {{TASK_FILES}}
**Action:** {{TASK_ACTION}}
**Details:** {{TASK_DETAILS}}
**Verify:** {{TASK_VERIFY_COMMAND}}

## Context

Read CLAUDE.md and docs/claude/known-pitfalls.md before implementing.

{{#IF_UI_TASK}}
## UI Task

Invoke `frontend-design` skill. Apply design system from CLAUDE.md.
{{/IF_UI_TASK}}

## Rules

- Implement ONLY this task; do NOT modify files outside the task's file list
- Run verification after changes: {{TASK_VERIFY_COMMAND}} — fix failures before returning
- If unclear or blocked, return a question instead of guessing

## Return

Files changed, verification result (pass/fail), any deviations or blocking questions.
