---
name: review
description: "Parallel 3-agent code review: code-reviewer, static-analysis, and silent-failure-hunter. Synthesizes findings into severity-grouped report. Use after implementation or standalone."
disable-model-invocation: true
---

# Code Review

Dispatch three review agents in parallel, synthesize their findings, and present a unified report.

## Input

Review scope: $ARGUMENTS

If `$ARGUMENTS` is empty, review all uncommitted changes:
!`git diff --name-only HEAD 2>/dev/null || echo "no changes"`

---

## STEP 1: DISPATCH AGENTS

Launch all three agents in parallel (single message, multiple tool calls):

### Agent 1: `code-reviewer`
Dispatch the `code-reviewer` agent with:
- The review scope description
- List of changed files
- Instruction to read CLAUDE.md and .ruckus/known-pitfalls.md first

### Agent 2: `static-analysis`
Dispatch the `static-analysis` agent with:
- List of changed files
- Instruction to run type check, lint, and build commands from CLAUDE.md

### Agent 3: `silent-failure-hunter`
Dispatch the `silent-failure-hunter` agent with:
- List of changed files
- Instruction to read .ruckus/known-pitfalls.md for domain-specific risk patterns

---

## STEP 2: SYNTHESIZE REPORT

When all agents return, merge findings into a single report grouped by severity:

```
# Review Report

**Scope:** [description of what was reviewed]
**Changed files:** [count]

## Critical (must fix)
- [finding — source: agent name]

## Warning (should fix)
- [finding — source: agent name]

## Info (consider)
- [finding — source: agent name]

## Clean
- [areas that passed all three reviews]
```

**Deduplication:** If multiple agents flag the same issue, merge into one finding and note which agents caught it.

---

## STEP 3: KNOWN PITFALLS UPDATE

Ask: **"Did this review reveal patterns that should be added to `.ruckus/known-pitfalls.md`?"**

If yes, dispatch the `doc-writer` agent with the new pitfall description.

---

## STEP 4: VERDICT

If critical findings exist:
> "Review found [N] critical issues. These must be fixed before proceeding. Re-invoke `/ruckus:review` after fixing to confirm resolution."

If only warnings/info:
> "Review passed with [N] warnings. Proceed or address warnings?"

If clean:
> "Review passed clean across all three agents."
