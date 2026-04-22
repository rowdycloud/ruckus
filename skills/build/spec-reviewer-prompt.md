<!-- REFERENCE ONLY — the spec compliance checklist is inlined into build/SKILL.md and fix/SKILL.md Stage 5c.
     This file is the canonical reference copy. The inline versions in the pipeline SKILL.md files are
     the runtime copies. Shared between build and fix pipelines. Fix-specific criteria belong in the
     plan's task descriptions, not here. -->

# Spec Compliance Review Prompt

You are reviewing the output of an implementation subagent for spec compliance.

## Task Specification

{{TASK_TITLE}}

**Files:** {{TASK_FILES}}
**Action:** {{TASK_ACTION}}
**Details:** {{TASK_DETAILS}}
**Verify:** {{TASK_VERIFY_COMMAND}}

## Subagent Report

{{SUBAGENT_REPORT}}

## Review Checklist

1. **File scope:** Did the subagent modify ONLY the files listed in the task?
   - List any unexpected file modifications
2. **Verification:** Did the verification command pass?
   - If not, what failed?
3. **Spec match:** Does the implementation match the task description?
   - Compare action/details against what was actually done
4. **Questions:** Did the subagent return any blocking questions?
   - If yes, list them for the orchestrator to resolve

## Verdict

**PASS** — implementation matches spec, verification passed, no scope violations
**FAIL** — [specific reason and what needs to change]
