# Implementation Plan: E01.S5 Agent Preamble Drift Documentation and Detection

## File Table
| File | Action | Task(s) |
|------|--------|---------|
| `agents/agent-preamble.md` | Edit | T1 |
| `skills/build/implementer-prompt.md` | Edit | T2 |
| `skills/upgrade/SKILL.md` | Edit | T3 |

## Tasks

### T1: Expand agent-preamble.md exception rationale (~2 min)
**Files:** agents/agent-preamble.md
**Action:** Replace lines 9-10 of the HTML comment with expanded explanations of WHY static-analysis and doc-writer don't use the preamble
**Details:**
Replace:
```
     Not used by: static-analysis (reads CLAUDE.md for commands only, not conventions),
     doc-writer (writes to these files — reads them for deduplication, not execution context). -->
```
With (from epic spec):
```
     Not used by: static-analysis (reads CLAUDE.md for commands only — it runs type check,
     lint, and build commands but does not need project conventions or pitfall patterns since
     it reports raw tool output, not convention-aware analysis),
     doc-writer (writes to CLAUDE.md and known-pitfalls.md — reads them for deduplication
     context to avoid adding duplicate entries, not as execution guidance). -->
```
This expands 2 lines to 5 lines (+3 net). File goes from 15 to 18 lines.
**Verify:** `grep -c "convention-aware analysis" agents/agent-preamble.md` returns 1; `grep -c "deduplication" agents/agent-preamble.md` returns 1
**UI:** no

### T2: Add sync comment to implementer-prompt.md (~1 min)
**Files:** skills/build/implementer-prompt.md
**Action:** Add an HTML comment before the context-loading line (line 20) noting its relationship to agent-preamble.md
**Details:**
Before line 20 (`Read CLAUDE.md and .ruckus/known-pitfalls.md before implementing.`), insert:
```
<!-- Abbreviated agent-preamble. Source of truth: agents/agent-preamble.md -->
```
File goes from 37 to 38 lines.
**Verify:** `grep -c "agent-preamble.md" skills/build/implementer-prompt.md` returns 1
**UI:** no

### T3: Add preamble drift check to upgrade/SKILL.md STEP 1 (~3 min)
**Files:** skills/upgrade/SKILL.md
**Action:** Insert a preamble drift check paragraph after line 39 ("Also check for agent files...") and before the `---` separator at line 41
**Details:**
After line 39 (`Also check for agent files in `.claude/agents/` that may need updates against plugin `agents/` directory.`), insert:
```

**Preamble drift check:** Compare the context-loading instruction in each agent file against `agents/agent-preamble.md`. Flag any agent where the instruction text differs from the canonical version (excluding agents listed as exceptions in the preamble header: static-analysis, doc-writer).
```
This adds 2 lines (blank + paragraph). File goes from 122 to 124 lines. Well within 300-line limit.

Important: The drift check must detect **semantic drift** (wrong paths, missing files), not exact string match. Agent files use varying formats (bold bullets, prose, numbered list) — that's expected. The check should flag agents referencing wrong paths (e.g., stale `docs/claude/` instead of `.ruckus/`) or missing the instruction entirely.
**Verify:** `grep -c "Preamble drift check" skills/upgrade/SKILL.md` returns 1
**UI:** no

## Blast Radius
- Do NOT modify: any agent `.md` files (code-reviewer, discovery, etc.), build/SKILL.md, fix/SKILL.md, any ADRs
- Watch for: the upgrade/SKILL.md insertion must go between line 39 and the `---` at line 41 — not inside STEP 2

## Conventions
- ADR-003: Shared-reference pattern — preamble is inlined, not auto-included. This story adds documentation and detection, not auto-sync.
- ADR-006: Runtime context, not baked in. The drift check is a prose instruction to the upgrade orchestrator, consistent with the pattern.
- CLAUDE.md: Agent prompts under 500 words, skill bodies under 300 lines. All files stay within limits.
