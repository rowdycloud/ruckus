# Debate: Review Findings Pushback

Three findings from the Ruckus plugin review have been challenged. For each, evaluate both sides and provide a final recommendation. Read the relevant skill files before responding.

---

## Debate 1: Finding #4 — Fix-specific spec-reviewer-prompt

**Review position (critical):** Fix tasks may need different compliance criteria (regression testing emphasis) but share the same prompt designed for build. Create `skills/fix/spec-reviewer-prompt.md` with fix-specific compliance criteria.

**Counter-position (suggestion, not critical):** The spec compliance check asks "did the subagent do what the task said?" — that question is identical whether building or fixing. Fix-specific context (root cause, regression risk, acceptance criteria) is already captured in the plan itself, which the reviewer reads. A separate prompt adds maintenance burden (two files to keep in sync) for marginal gain. Document why it's intentionally shared rather than forking it.

**Your task:** Read `skills/build/spec-reviewer-prompt.md` and `skills/fix/SKILL.md`. Determine whether the current shared prompt actually misses fix-specific concerns, or whether the plan's fix context makes a separate prompt unnecessary. Provide a concrete example of something the current prompt would miss on a fix task that it catches on a build task — or state that no such gap exists.

**Recommend:** Keep shared (with documentation note) / Create fix-specific version / Other approach

---

## Debate 2: Finding #6 — .ruckus-version tracking

**Review position (critical):** No mechanism to detect when the plugin version itself changed. Create `docs/claude/.ruckus-version` during setup. Upgrade reads stored vs. current version.

**Counter-position (warning, simpler approach):** The plugin version is already in `.claude-plugin/plugin.json`. Instead of a separate file, store a single line in `.workflow-upgrades`: `ruckus-version 0.1.0 2026-04-20`. Upgrade reads the installed plugin.json for current version, compares against the stored version in the existing tracking file. One fewer file to manage, same information.

**Your task:** Read `skills/upgrade/SKILL.md` and `skills/setup/SKILL.md`. Determine whether the single-line-in-upgrades approach works technically, or whether a separate file is genuinely needed (e.g., because upgrades reads `.workflow-upgrades` differently than version checking requires).

**Recommend:** Separate .ruckus-version file / Single line in .workflow-upgrades / Other approach

---

## Debate 3: Finding #28 — Per-task two-stage review diminishing returns

**Review position (warning):** Tasks 5-8 rarely fail differently from tasks 1-3. Per-task two-stage review wastes ~2-3K tokens per run. Batch quality checks for tasks 4-8.

**Counter-position (keep per-task type check, reduce spec review):** The type check after each task is cheap (~100 tokens) and catches cascading errors — a type error in task 4 that goes unreviewed until task 8 means tasks 5-7 built on broken foundations. However, the spec compliance review (dispatching a subagent to check "did the task do what it said?") is expensive and has diminishing returns after the first few tasks. Proposal: keep per-task type check always; drop spec compliance subagent dispatch after task 3 and only re-enable it for tasks flagged as high-risk in the plan.

**Your task:** Read `skills/build/SKILL.md` Stage 5 and `skills/build/spec-reviewer-prompt.md`. Consider:
- What does the spec compliance review actually catch that the type check doesn't?
- Is there a meaningful difference in catch rate between task 2 and task 7?
- What's the realistic token cost of the spec compliance subagent per dispatch?
- Would a "high-risk task" flag in the plan be reliable, or would agents just mark everything as low-risk to avoid the review?

**Recommend:** Keep full two-stage for all tasks / Keep type check + batch spec review / Keep type check + drop spec review after task 3 / Other approach

---

## Output Format

For each debate:

```
## Debate [N]: [Title]

**Winner:** [which position]
**Confidence:** high / medium / low
**Reasoning:** [2-3 sentences citing evidence from the actual files]
**Recommended action:** [specific change or explicit "no change needed" with documentation note]
```
