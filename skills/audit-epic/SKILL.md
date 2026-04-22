---
name: audit-epic
description: "Post-implementation epic audit. Parses stories, maps to files via git history, dispatches per-story review subagents, cross-cutting review, and AC verification. Does not modify source code — only writes the audit report."
---

# Epic Audit

Audit a completed epic's implementation against its specification. This is a post-implementation review that verifies acceptance criteria are met and implementation quality is consistent across stories.

**This skill does NOT modify any source code. It only writes the audit report file.**

## Input

Epic file: $ARGUMENTS

If `$ARGUMENTS` is empty, ask: **"Which epic file should I audit? (provide path)"**

---

## STEP 1: PARSE EPIC

Read the epic file. Extract:
- All stories/tasks with their IDs
- Acceptance criteria per story
- Technical requirements and constraints
- Expected file/component outputs

Display: story count, AC count, scope summary.

---

## STEP 2: MAP STORIES TO FILES

For each story, identify the implementing files using git history:

```bash
git log --all --oneline --grep="[story ID]" --name-only
```

If commit messages don't reference story IDs, fall back to:
1. Check plan files in `docs/plans/` for file mappings
2. Use the epic's technical approach section to identify likely files
3. Search for recent commits touching files mentioned in the epic

Build a mapping: `Story ID → [file list]`

Display the mapping for human confirmation.

**Gate:** "File mapping complete. [N] stories mapped to [M] files. Correct? (yes / adjust / proceed anyway)"

---

## STEP 3: PER-STORY REVIEW

Dispatch review subagents in parallel (one per story, model: `sonnet`). Each receives:

**Per-story subagent prompt:**
```
You are auditing the implementation of a single story. You do NOT modify files.

## Story
ID: [story ID]
Title: [story title]
Acceptance Criteria:
[list of ACs]

## Implementing Files
[file list from mapping]

## Instructions
1. Read each implementing file
2. For each acceptance criterion, determine: MET / PARTIALLY MET / NOT MET
3. Note any implementation quality concerns
4. Check for missing error handling, edge cases, or test coverage

## Output
### [Story ID]: [title]
| AC | Status | Evidence |
|----|--------|----------|
| [AC text] | MET/PARTIALLY MET/NOT MET | [file:line or explanation] |

**Quality notes:** [any concerns]
**Missing coverage:** [gaps found]
```

Compact context after all per-story subagents return. Preserve: epic title, story ID list, per-story AC status table (MET/PARTIALLY MET/NOT MET per AC), quality flags and missing coverage notes. Full evidence citations and file:line references from subagent reports are NOT needed for cross-cutting analysis — the status verdicts carry the signal.

---

## STEP 4: CROSS-CUTTING REVIEW

After all per-story reviews return, perform a cross-cutting analysis:

1. **Consistency** — Do stories that share files implement patterns consistently?
2. **Integration** — Do stories that depend on each other integrate correctly?
3. **Gaps** — Are there acceptance criteria that no story fully addresses?
4. **Regressions** — Could any story's implementation break another's?

---

## STEP 5: AUDIT REPORT

Synthesize all findings into a final audit report:

```
# Epic Audit: [epic title]

**Date:** [today]
**Stories audited:** [N]
**Acceptance criteria:** [total] — [met] MET, [partial] PARTIAL, [not met] NOT MET

## Summary
[One paragraph overall assessment]

## Per-Story Results
[Table or section per story with AC status]

## Cross-Cutting Findings
- [consistency/integration/gap/regression findings]

## Recommendations
- [prioritized list of issues to address]
```

Save the audit report alongside the epic:
- If epic is at `docs/epics/E02.md`, save at `docs/epics/E02-audit.md`

Ask: **"Audit complete. [summary stats]. Review findings or take action on recommendations?"**
