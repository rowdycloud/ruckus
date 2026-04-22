# Task: Comprehensive Review of the Ruckus Plugin (Post-Phase 5)

## Context

Ruckus is a Claude Code plugin that implements gated development pipelines with subagent-per-task execution. It has been through 5 phases of revision based on a prior review. This is a fresh review to catch remaining issues, regressions from the changes, and anything the prior review missed.

Read `README.md` and `.claude-plugin/plugin.json` first to understand the plugin's structure and intent.

## Review Architecture

Dispatch **5 review subagents in parallel**, each focused on a different dimension. After all return, synthesize into a single report.

---

## Agent 1: Structural & Plugin Standards Review

**Prompt:**

```
You are reviewing a Claude Code plugin for structural correctness and adherence to plugin standards.

Read every file in the repo. Check:

**Plugin Structure:**
- Does `.claude-plugin/plugin.json` have valid JSON with name, description, version?
- Does `marketplace.json` correctly reference the plugin?
- Are all skills in `skills/<name>/SKILL.md` format?
- Are all agents in `agents/<name>.md` format?
- Does every SKILL.md have valid YAML frontmatter with `name` and `description`?
- Does every agent have valid YAML frontmatter with `name`, `description`, `tools`, `model`?
- Are `disable-model-invocation: true` set on pipeline skills (build, fix) that should only be user-invoked?

**Cross-References (critical — changes in Phases 1-5 may have broken references):**
- Does every skill that references an agent (e.g., "dispatch the discovery agent") reference an agent that actually exists in `agents/`?
- Does every skill that references another skill (e.g., "invoke /ruckus:review") reference a skill that actually exists in `skills/`?
- Are all file paths referenced in skills/agents consistent with the actual directory structure?
- Does the README document every skill and agent that exists? Are counts accurate?
- Does `agents/agent-preamble.md` exist and is it referenced correctly by agents that use it?
- Is `skills/build/spec-reviewer-prompt.md` referenced correctly from both build and fix pipelines?

**Completeness:**
- Are there any skills referenced in README but not implemented?
- Are there any agents referenced in skills but not defined?
- Are there any template files referenced by setup that don't exist?
- Does the CHANGELOG reflect the Phase 1-5 changes?

Report format per finding:
- **File**: path
- **Category**: structure / cross-reference / completeness
- **Severity**: critical / warning / suggestion
- **Issue**: description
- **Fix**: specific suggestion
```

---

## Agent 2: Pipeline Logic & Gate Integrity Review

**Prompt:**

```
You are reviewing the pipeline logic of a Claude Code plugin that implements gated development workflows. Focus on the two main pipelines: build (skills/build/SKILL.md) and fix (skills/fix/SKILL.md).

Read both pipeline skills completely. Also read review-plan, review, and verify-all since the pipelines invoke them.

**Already resolved (verify these fixes are correctly implemented, then move on):**
- Abort handling sections should exist in both build and fix
- Plan auto-edits should trigger re-review (re-dispatch review-plan subagent)
- Plan file validation should happen before Stage 4 dispatch
- Stages 6 and 7 should have MANDATORY markers
- Context compaction instructions should exist after Stages 4, 5, 6

Verify each of the above is present and correctly implemented. If any is missing or broken, flag as a regression.

**Focus your NEW analysis on:**

**Gate Integrity:**
- Can any stage be skipped by the orchestrating agent? Look for ambiguous language that an LLM might interpret as permission to skip.
- Is review-plan dispatched as a subagent (blocking) or invoked as a skill (skippable)?
- Do the compaction instructions (added in Phase 4) risk losing critical context needed by later stages?
- Does the abort handling section correctly distinguish between stages with and without filesystem changes?

**Subagent Dispatch Quality:**
- Are implementation subagent prompts specific enough that a fresh agent with zero project context can execute them?
- Do subagent prompts include the agent-preamble.md reference?
- Is the UI detection (frontend-design skill loading) correctly conditional on the task's UI flag?
- Are subagent model selections appropriate?

**Error Handling:**
- What happens if a subagent fails or returns an error?
- What happens if review-plan returns NEEDS REVISION more than twice?
- What happens if the plan file path is wrong after compaction resets context?

**Pipeline Consistency:**
- Are build and fix structurally consistent where they should be (stages 3-8)?
- Do maturity checks match between build and fix?
- Do both pipelines reference the same spec-reviewer-prompt.md?

Report format per finding:
- **File**: path
- **Stage**: which pipeline stage
- **Category**: gate-integrity / subagent-quality / error-handling / consistency / regression
- **Severity**: critical / warning / suggestion
- **Issue**: description
- **Fix**: specific suggestion
```

---

## Agent 3: Context Budget & Token Efficiency Review

**Prompt:**

```
You are reviewing a Claude Code plugin for context window efficiency and token usage. Every token wasted in a skill or agent prompt is a token unavailable for actual project work.

Read every SKILL.md and every agent .md file. Measure and analyze.

**Already resolved (do not re-analyze):**
- Per-task two-stage review is intentionally kept for all tasks (spec compliance is inline at ~100-200 tokens/task, not a subagent dispatch)
- Spec-reviewer-prompt is intentionally shared between build and fix pipelines
- Context compaction boundaries have been added after Stages 4, 5, 6
- Agent preamble duplication has been addressed via agent-preamble.md
- Implementer prompt has been reduced to ~94 words

Verify these optimizations are correctly implemented. If any is missing or incorrectly done, flag as a regression.

**Focus your NEW analysis on:**

**Prompt Size:**
- Count the approximate word count of each skill and agent prompt
- Flag any skill over 250 words or agent over 400 words
- Has the implementer-prompt reduction introduced any loss of necessary specificity?
- Does agent-preamble.md actually reduce duplication, or do agents still inline their own preambles?

**Context Accumulation Risk:**
- Do the compaction boundaries after Stages 4, 5, 6 preserve the right context? What's at risk of being lost?
- Are subagent results summarized before being added to the orchestrator's context?
- For audit-epic with 15+ stories dispatched in parallel, how much context returns to the orchestrator in synthesis?

**Remaining Optimization Opportunities:**
- Audit-epic unbatched synthesis (3K-5K tokens)
- Fix pipeline compact usage (mentioned but not implemented?)
- 3 review agents loading identical file contents (1K-1.5K tokens)
- known-pitfalls loaded by every agent (500-800 tokens)
- Maturity checks running on bloated Stage 8 context (500-800 tokens)
- Could simple implementation tasks be routed to Haiku?

**New Issues from Phase 1-5 Changes:**
- Did abort handling add significant prompt length?
- Did plan file validation add redundant checks?
- Did the compaction instructions add context overhead that partially offsets their savings?

Report format per finding:
- **File**: path
- **Category**: prompt-size / context-accumulation / redundancy / model-selection / diminishing-returns / regression
- **Severity**: critical / warning / suggestion
- **Token Impact**: estimated tokens saved if addressed
- **Issue**: description
- **Fix**: specific suggestion
```

---

## Agent 4: Setup & Upgrade Robustness Review

**Prompt:**

```
You are reviewing the setup and upgrade skills of a Claude Code plugin. These are the first things users experience — if they fail, nothing else works.

Read skills/setup/SKILL.md, skills/upgrade/SKILL.md, and all template files in skills/setup/templates/.

**Already resolved (verify these are correctly implemented):**
- Setup creates .workflow-upgrades with ruckus-version line
- Setup always creates settings.json (with overwrite protection on re-run)
- Root CLAUDE.md is created as explicit copy (not symlink)
- Upgrade reads version from .workflow-upgrades for version detection

Verify each is present. Flag regressions if any is missing.

**Focus your NEW analysis on:**

**Setup Quality:**
- Does setup actually enforce the required fields (stack, build command, type check, test command, convention, domain)? Or does the language allow the agent to proceed without them?
- Are there example answers for each setup question (especially the "convention" question)?
- What happens if the user provides minimal answers? Is that sufficient?
- Can setup be re-run safely? Does it detect existing files and offer to enrich?
- What happens if setup is skipped entirely — do skills warn clearly?

**Template Quality:**
- Does .claudeignore have stack-aware comments (Phase 5)?
- Does known-pitfalls.md template have example entries (Phase 5)?
- Is the settings.json template valid JSON?
- Will the CLAUDE.md template be under 150 lines after replacement?

**Upgrade Robustness:**
- How does upgrade distinguish structural changes from customizations?
- Does upgrade preserve custom hooks in settings.json?
- What happens if upgrade runs with no changes needed?
- Can upgrade break a working setup?

**Edge Cases:**
- Empty directory (no git, no package.json)
- Monorepo
- Formatter not detected
- settings.json with hooks from another plugin
- .claude/ exists but docs/claude/ doesn't

Report format per finding:
- **File**: path
- **Category**: setup-quality / template-quality / upgrade-robustness / edge-case / regression
- **Severity**: critical / warning / suggestion
- **Issue**: description
- **Fix**: specific suggestion
```

---

## Agent 5: Documentation & User Experience Review

**Prompt:**

```
You are reviewing a Claude Code plugin's documentation and user experience. The audience is solo developers and small teams who want structured AI-assisted development pipelines.

Read README.md, all SKILL.md files (focus on user-facing text), and any CHANGELOG.md.

**Already resolved (verify these exist and are accurate, then move on):**
- Gates are defined with examples
- Troubleshooting guide exists
- Token usage table exists
- How It Works section exists with subagent architecture explanation
- Skills Reference and Agent dispatch context documented
- Installation context explained
- Workflow decision matrix exists
- Input formats explained

Verify each exists and is accurate. Flag regressions if content is missing or incorrect.

**Focus your NEW analysis on:**

**Accuracy of New Documentation:**
- Does the Gates section accurately describe how gates work in the actual skill files?
- Does the Token Usage table reflect the optimizations from Phase 4 (compaction, reduced prompts)?
- Does the How It Works section accurately describe the subagent-per-task architecture as implemented?
- Does the Troubleshooting guide cover the right failure modes?
- Is the workflow decision matrix complete and accurate?

**Remaining Documentation Gaps:**
- Self-upgrading section: does it explain file location (.workflow-upgrades) and decline handling (yes/not yet/never)?
- Quick Start: does it explain what files setup creates?
- Relationship between /ruckus:review and /ruckus:review-plan: is this explained?
- CLAUDE.md template: do sections have example content?
- Migration guide from predecessor workflows: does it exist?
- Context management guidance: does it exist?

**Tone & Branding:**
- Does the documentation voice match "Rowdy Cloud" (loud, action-oriented, tech-nerd)?
- Is it opinionated without being hostile?
- Does it avoid generic AI-tool marketing language?
- Is the tone consistent across README, skill descriptions, and agent descriptions?

**First-Run Experience:**
- If a brand new user installs and runs /ruckus:setup, will they succeed?
- Are there any jargon terms used without explanation (subagent, maturity, gate, orchestrator)?
- Is the path from install to first successful /ruckus:build obvious and documented?

Report format per finding:
- **File**: path (or "missing")
- **Category**: accuracy / remaining-gap / tone / first-run / regression
- **Severity**: critical / warning / suggestion
- **Issue**: description
- **Fix**: specific suggestion
```

---

## Synthesis

After all 5 agents return, synthesize into:

```
# Ruckus Plugin Review (Post-Phase 5)

**Reviewed:** [date]
**Files:** [total in repo]
**Skills:** [count] | **Agents:** [count]
**Prior Review Phases:** 5 completed (gate integrity, setup robustness, documentation, token optimization, polish)

## Verdict: [Ready to publish / Needs revision / Needs significant work]

## Regressions from Phase 1-5 Changes
[Any issues introduced by the fixes — these are highest priority]

## Summary Table

| Dimension | Findings | Critical | Warning | Suggestion |
|-----------|----------|----------|---------|------------|
| Structure & Standards | ... | ... | ... | ... |
| Pipeline Logic & Gates | ... | ... | ... | ... |
| Context & Token Efficiency | ... | ... | ... | ... |
| Setup & Upgrade | ... | ... | ... | ... |
| Documentation & UX | ... | ... | ... | ... |

## Critical Issues (must fix before publishing)
[All critical findings, deduplicated, grouped by dimension]

## Warnings (should fix)
[Deduplicated]

## Token Optimization Opportunities
[From Agent 3, ordered by estimated token savings — only NEW opportunities]

## Suggestions
[Deduplicated]

## What's Strong
[What the review found well-designed — include BOTH original strengths and improvements from Phases 1-5]

## Recommended Fix Order
1. [Ordered by severity and dependency]

## Publish Readiness
[Explicit statement: is this ready for v0.1.0 public release? If not, what specifically blocks it?]
```

This is a **read-only review**. Do NOT modify any files.