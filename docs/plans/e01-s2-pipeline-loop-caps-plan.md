# Implementation Plan: S2 — Pipeline Loop Caps

## Context

Four pipeline loops in build/SKILL.md and fix/SKILL.md have no bound or incorrect bounds that could cause infinite retry loops. This story adds iteration caps and disambiguates gate options. All changes are inline text edits — no structural changes.

**Line budget:** build starts at 289, fix at 294. Hard limit is 300. Net change target: +1 line per file maximum. All edits must use terse wording.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| skills/build/SKILL.md | Modify | T1, T2, T3, T4 |
| skills/fix/SKILL.md | Modify | T1, T2, T3, T4 |

## Tasks

### T1: Stage 4 — Change "consecutive" to "total" in review-plan retry (~1 min)
**Files:** skills/build/SKILL.md (line 100), skills/fix/SKILL.md (line 109)
**Action:** Replace "2 consecutive" with "2 total" in both files
**Details:**

In **build/SKILL.md line 100**, replace:
```
Repeat until PASS or until 2 consecutive NEEDS REVISION verdicts
```
with:
```
Repeat until PASS or until 2 total NEEDS REVISION verdicts
```

In **fix/SKILL.md line 109**, identical replacement:
```
Repeat until PASS or until 2 consecutive NEEDS REVISION verdicts
```
with:
```
Repeat until PASS or until 2 total NEEDS REVISION verdicts
```

**Verify:** grep -n "consecutive" skills/build/SKILL.md skills/fix/SKILL.md — should return zero matches
**Net lines:** 0 (inline word replacement)
**UI:** no

### T2: Stage 5c — Add question re-dispatch cap (~1 min)
**Files:** skills/build/SKILL.md (line 168), skills/fix/SKILL.md (line 177)
**Action:** Append iteration cap to re-dispatch instruction in both files
**Details:**

In **build/SKILL.md line 168**, replace:
```
- If the subagent returned questions: answer them, re-dispatch.
```
with:
```
- If the subagent returned questions: answer them, re-dispatch (max 2; then escalate to human).
```

In **fix/SKILL.md line 177**, identical replacement (same text).

**Verify:** grep -n "re-dispatch" skills/build/SKILL.md skills/fix/SKILL.md — both should show "max 2" on the matching line
**Net lines:** 0 (inline append)
**UI:** no

### T3: Stage 6 — Add review-fix loop cap (~2 min)
**Files:** skills/build/SKILL.md (line 194), skills/fix/SKILL.md (line 199)
**Action:** Add iteration cap to review-fix instruction in both files
**Details:**

In **build/SKILL.md line 194**, replace:
```
Fix any critical findings. Re-run review until clean.
```
with:
```
Fix critical findings and re-run review (max 2 review-fix cycles; if still failing, present findings to human).
```

In **fix/SKILL.md line 199** — note the text differs slightly. Replace:
```
Invoke `/ruckus:review` with a description of the fix. Fix any critical findings. Re-run until clean.
```
with:
```
Invoke `/ruckus:review` with a description of the fix. Fix critical findings and re-run (max 2 review-fix cycles; if still failing, present findings to human).
```

**Verify:** grep -n "until clean" skills/build/SKILL.md skills/fix/SKILL.md — should return zero matches
**Net lines:** 0 in build (inline reword), 0 in fix (inline reword, same line)
**UI:** no

### T4: Stage 6 — Disambiguate gate option (~1 min)
**Files:** skills/build/SKILL.md (line 196), skills/fix/SKILL.md (line 201)
**Action:** Replace ambiguous "address warnings" gate option with specific behavior
**Details:**

In **build/SKILL.md line 196**, replace:
```
**Gate:** "Review complete. Proceed to verification? (yes / address warnings / abort)"
```
with:
```
**Gate:** "Review complete. Proceed to verification? (yes / list warnings to address [then re-review once] / abort)"
```

In **fix/SKILL.md line 201**, identical replacement (same text).

**Verify:** grep -n "address warnings" skills/build/SKILL.md skills/fix/SKILL.md — should return zero matches
**Net lines:** 0 (inline reword)
**UI:** no

## Line Budget Verification

| File | Before | T1 | T2 | T3 | T4 | After | Limit | Headroom |
|------|--------|----|----|----|-----|-------|-------|----------|
| build/SKILL.md | 289 | 0 | 0 | 0 | 0 | 289 | 300 | 11 |
| fix/SKILL.md | 294 | 0 | 0 | 0 | 0 | 294 | 300 | 6 |

All four changes are inline rewording — net zero lines added.

## Blast Radius

- Do NOT modify: any file other than skills/build/SKILL.md and skills/fix/SKILL.md
- Watch for: line wrapping — all replacement text must stay on a single line to maintain net-zero line count

## Conventions

- ADR-007: Two-stage review runs after every task — loop caps don't change this, only bound retries
- ADR-001: Review-plan dispatched as blocking subagent — cap applies to re-dispatches, not the mechanism
- Epic line budget: fix/SKILL.md must stay at or under 300 lines after all S1-S4 changes (currently 294, S2 is net-zero)

## Acceptance Criteria (from epic)

- [ ] Stage 4 says "2 total" not "2 consecutive" in both build and fix
- [ ] Stage 5c has explicit 2-attempt cap with human escalation in both build and fix
- [ ] Stage 6 review-fix loop has 2-cycle cap with human escalation in both build and fix
- [ ] Stage 6 gate option is unambiguous — specifies what "address warnings" does and limits it
