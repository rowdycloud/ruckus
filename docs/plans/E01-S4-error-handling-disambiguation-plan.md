# Implementation Plan: E01.S4 — Error handling disambiguation

## Context

Two error handling paths in the build/fix pipeline skills are ambiguous — agents encounter `fix the issue OR re-dispatch` and guess which path to take. A third file (review-plan) silently fails when CLAUDE.md doesn't exist. This story disambiguates all three.

## File Table

| File | Action | Task(s) | Current Lines | Post-S4 Lines |
|------|--------|---------|---------------|---------------|
| `skills/build/SKILL.md` | Edit L174 | T1 | 294 | 294 (net 0) |
| `skills/fix/SKILL.md` | Edit L183 | T2 | 299 | 299 (net 0) |
| `skills/review-plan/SKILL.md` | Edit L17, L19 | T3 | 90 | ~92 (+2) |

## Tasks

### T1: Disambiguate Stage 5c quality check in build/SKILL.md (~2 min)
**Files:** `skills/build/SKILL.md`
**Action:** Replace the ambiguous quality check retry line with explicit priority ordering
**Details:**
At line 174, replace:
```
- If it fails: fix the issue OR re-dispatch the subagent with the error
```
With:
```
- If it fails on files this task owns: attempt auto-fix (max 2 attempts). If it fails on files outside this task's scope or on environmental issues (missing dependency, config error): escalate to human immediately.
```
This is a single-line replacement (net zero lines). It establishes: (1) auto-fix only for task-owned files, (2) 2-attempt cap, (3) immediate escalation for external/environmental failures.
**Verify:** Count lines in `skills/build/SKILL.md` — must be ≤300. Grep for the old text to confirm it's gone.
**UI:** no

### T2: Disambiguate Stage 5c quality check in fix/SKILL.md (~2 min)
**Files:** `skills/fix/SKILL.md`
**Depends on:** T1 (to confirm exact replacement text)
**Action:** Apply identical replacement as T1 to the fix pipeline
**Details:**
At line 183, replace:
```
- If it fails: fix the issue OR re-dispatch the subagent with the error
```
With the identical text from T1:
```
- If it fails on files this task owns: attempt auto-fix (max 2 attempts). If it fails on files outside this task's scope or on environmental issues (missing dependency, config error): escalate to human immediately.
```
Single-line replacement (net zero). fix/SKILL.md is at 299 lines — the binding constraint. Net-zero keeps it at 299.
**Verify:** Count lines in `skills/fix/SKILL.md` — must be ≤300. Confirm text matches build/SKILL.md exactly.
**UI:** no

### T3: Harden review-plan for missing project files (~3 min)
**Files:** `skills/review-plan/SKILL.md`
**Action:** Add `.ruckus/` path prefix and graceful missing-file handling
**Details:**
Two edits in the Input section (lines 15-19):

**Edit 1 — Line 17:** Replace:
```
- The project's CLAUDE.md and known-pitfalls.md
```
With:
```
- The project's CLAUDE.md and .ruckus/known-pitfalls.md
```

**Edit 2 — Line 19:** Replace:
```
Read all three before starting verification.
```
With:
```
Read all three before starting verification. If CLAUDE.md is missing, return NEEDS REVISION with verdict: "CLAUDE.md not found — run /ruckus:setup first." If .ruckus/known-pitfalls.md is missing, note the gap in your report but proceed — it is informational, not blocking.
```

**Verify:** Read back lines 15-20 to confirm both edits applied correctly. Count total lines.
**UI:** no

## Blast Radius
- Do NOT modify: `skills/build/implementer-prompt.md`, `skills/build/spec-reviewer-prompt.md`, any agent files, any ADRs
- Watch for: build/fix text drift (T1 and T2 must produce identical replacement text)

## Conventions
- ADR-007: Two-stage review structure unchanged — this clarifies retry behavior within Stage 2 only
- ADR-003: Spec-reviewer shared checklist — already verified clean, no changes needed
- Line budget: 300-line limit per skill body (CLAUDE.md convention)

## Acceptance Criteria Mapping
| AC | Task | How verified |
|----|------|-------------|
| Quality check distinguishes auto-fixable from unfixable | T1, T2 | Text inspection |
| Auto-fix capped at 2 attempts | T1, T2 | Text inspection |
| Review-plan NEEDS REVISION when CLAUDE.md missing | T3 | Text inspection |
| Review-plan notes missing known-pitfalls as informational | T3 | Text inspection |
| Spec-reviewer reference verified clean | N/A | Verified in discovery (zero matches) |
| fix/SKILL.md ≤300 lines | T2 | `wc -l` after edit |

## Verification
1. `wc -l skills/build/SKILL.md skills/fix/SKILL.md skills/review-plan/SKILL.md` — all within limits
2. `grep -n "fix the issue OR re-dispatch" skills/build/SKILL.md skills/fix/SKILL.md` — zero matches (old text gone)
3. `grep -n "auto-fix" skills/build/SKILL.md skills/fix/SKILL.md` — matches at expected lines
4. `grep -n "spec-reviewer-prompt.md" skills/*/SKILL.md` — zero matches (AC #5)
5. Diff build L174 vs fix L183 — identical text (no drift)
6. Read review-plan lines 15-20 — `.ruckus/` prefix present, missing-file handling present
