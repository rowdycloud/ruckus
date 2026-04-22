# Task: Comprehensive Review of the Ruckus Plugin

## Context

Ruckus is a Claude Code plugin that implements gated development pipelines with subagent-per-task execution. It was just built from specs. Before publishing, it needs a thorough review across multiple dimensions.

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

**Cross-References:**
- Does every skill that references an agent (e.g., "dispatch the discovery agent") reference an agent that actually exists in `agents/`?
- Does every skill that references another skill (e.g., "invoke /ruckus:review") reference a skill that actually exists in `skills/`?
- Are all file paths referenced in skills/agents consistent with the actual directory structure?
- Does the README document every skill and agent that exists?

**Completeness:**
- Are there any skills referenced in README but not implemented?
- Are there any agents referenced in skills but not defined?
- Are there any template files referenced by setup that don't exist?

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

**Gate Integrity:**
- Is every stage followed by an explicit human gate?
- Can any stage be skipped by the orchestrating agent? Look for ambiguous language that an LLM might interpret as permission to skip (e.g., "if appropriate" or "optionally").
- Is review-plan dispatched as a subagent (blocking) or invoked as a skill (skippable)? It MUST be a subagent dispatch.
- Is implementation blocked until review-plan completes? Look for the MANDATORY marker and Prerequisite callout.
- After each implementation subagent returns, does two-stage review actually happen? Or could the orchestrator skip straight to the next task?

**Subagent Dispatch Quality:**
- Are implementation subagent prompts specific enough that a fresh agent with zero project context can execute them?
- Do subagent prompts include all necessary context (CLAUDE.md, known-pitfalls, task details)?
- Is the UI detection (frontend-design skill loading) correctly conditional on the task's UI flag?
- Are subagent model selections appropriate (sonnet for implementation, opus only for epic-reviewer)?

**Error Handling:**
- What happens if a subagent fails or returns an error?
- What happens if verification fails after implementation?
- What happens if the human says "abort" at any gate? Is cleanup handled?
- What happens if the plan file doesn't exist or is malformed?

**Pipeline Consistency:**
- Are build and fix structurally consistent where they should be (stages 3-8)?
- Are they appropriately different where they should be (stages 1-2)?
- Do maturity checks match between build and fix?

Report format per finding:
- **File**: path
- **Stage**: which pipeline stage
- **Category**: gate-integrity / subagent-quality / error-handling / consistency
- **Severity**: critical / warning / suggestion
- **Issue**: description
- **Fix**: specific suggestion
```

---

## Agent 3: Context Budget & Token Efficiency Review

**Prompt:**

```
You are reviewing a Claude Code plugin for context window efficiency and token usage. Every token wasted in a skill or agent prompt is a token unavailable for actual project work.

Read every SKILL.md and every agent .md file. Measure and analyze:

**Prompt Size:**
- Count the approximate word count of each skill and agent prompt
- Flag any skill over 250 words or agent over 400 words — these are approaching the budget ceiling
- Are there any skills that inline large prompt templates that should instead reference separate files?

**Context Accumulation Risk:**
- In the build pipeline, how much context accumulates across 8 stages? The orchestrator carries conversation history from Stage 1 through Stage 8.
- Does the pipeline use /compact or any context management between stages?
- Are subagent results summarized before being added to the orchestrator's context, or do full reports get appended?
- For audit-epic with 15+ stories dispatched in parallel, how much context returns to the orchestrator in Stage 5 (synthesis)?

**Redundancy:**
- Are there instructions repeated across multiple skills that could be factored into a shared reference?
- Do multiple agents have nearly identical preambles (e.g., "Read CLAUDE.md and known-pitfalls.md") that inflate every dispatch?
- Are there skills that load context they don't actually use?

**Model Selection Efficiency:**
- Are expensive models (Opus) used only where they genuinely add value?
- Could any Sonnet tasks be routed to Haiku for cost savings?
- In subagent-per-task implementation, is Haiku viable for simple tasks (as Superpowers suggests)?

**Diminishing Returns:**
- Are there features or checks that cost significant tokens but rarely catch real issues?
- Is the two-stage review after each task (spec compliance + quality) worth the token cost, or would a single combined review suffice?
- Are maturity checks at wrap-up adding value proportional to their token cost on every single run?
- Could any per-task review be batched (e.g., review every 3 tasks instead of every 1)?

Report format per finding:
- **File**: path
- **Category**: prompt-size / context-accumulation / redundancy / model-selection / diminishing-returns
- **Severity**: critical / warning / suggestion
- **Token Impact**: estimated tokens saved if addressed (rough order of magnitude)
- **Issue**: description
- **Fix**: specific suggestion
```

---

## Agent 4: Setup & Upgrade Robustness Review

**Prompt:**

```
You are reviewing the setup and upgrade skills of a Claude Code plugin. These are the first things users experience — if they fail, nothing else works.

Read skills/setup/SKILL.md, skills/upgrade/SKILL.md, and all template files in skills/setup/templates/.

**Setup Quality:**
- Does setup actually enforce the required fields (stack, build command, type check, test command, convention, domain)? Or does the language allow the agent to proceed without them?
- What happens if the user provides minimal answers ("React" for stack, "npm run build" for build)? Is that sufficient, or should setup probe deeper?
- Can setup be re-run safely on a project that's already set up? Does it detect existing files and offer to enrich rather than overwrite?
- Does setup handle the case where CLAUDE.md already exists with custom content that shouldn't be lost?
- Does setup create the .workflow-upgrades file?
- Does setup explain what it's doing and why, or does it silently create files?

**Template Quality:**
- Are the template files (.claudeignore, CLAUDE.md, known-pitfalls.md, settings.json) well-structured starting points?
- Does the .claudeignore cover the right patterns for common stacks?
- Is the settings.json template valid JSON with appropriate placeholder markers?
- Will the CLAUDE.md template be under 150 lines after placeholder replacement?

**Upgrade Robustness:**
- How does upgrade distinguish between structural changes (from plugin updates) and project-specific customizations (from setup)?
- What happens if upgrade runs but no changes are needed? Does it say so clearly?
- What happens if upgrade encounters a file it doesn't recognize (a user-created custom skill)?
- Does upgrade handle the case where the plugin version is newer than what was installed?
- Can upgrade break a working setup? What's the worst case?

**Edge Cases:**
- What happens if setup runs in an empty directory (no git, no package.json)?
- What happens if setup runs in a monorepo?
- What happens if the user's formatter isn't detected?
- What happens if .claude/settings.json already has hooks from another plugin?

Report format per finding:
- **File**: path
- **Category**: setup-quality / template-quality / upgrade-robustness / edge-case
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

**README Quality:**
- Can a new user understand what the plugin does in 30 seconds?
- Is the installation instruction clear and complete?
- Is the quick start path obvious (install → setup → first build)?
- Are all 9 skills documented with when/why to use each?
- Are all 7 agents documented with what each does?
- Is the maturity level system explained clearly?
- Is the self-upgrading behavior documented?
- Are there examples of actual command invocations for common workflows?

**Workflow Clarity:**
- Is it clear when to use /ruckus:build vs /ruckus:fix?
- Is it clear when to use /ruckus:review-epic vs /ruckus:audit-epic?
- Is the relationship between skills explained (build invokes review-plan, which invokes review, etc.)?
- Is the human gate system explained? Will users understand what "gate" means and what their options are?

**Onboarding Experience:**
- If a user installs the plugin and runs /ruckus:setup, will they understand the questions being asked?
- Is there guidance on what constitutes a good vs weak CLAUDE.md?
- Are there examples of known-pitfalls.md entries so users understand the format?

**Missing Documentation:**
- Is there a troubleshooting section? (What to do when review-plan gets skipped, when context overflows, when subagents fail)
- Is there a "how it works" section explaining the subagent-per-task architecture?
- Is there guidance on token usage expectations? ("A typical /ruckus:build run uses approximately X tokens")
- Is there a migration guide for users coming from manual workflows or the workflow-kit predecessor?

**Tone & Branding:**
- Does the documentation voice match "Rowdy Cloud" (loud, action-oriented, tech-nerd)?
- Is it opinionated without being hostile?
- Does it avoid generic AI-tool marketing language?

Report format per finding:
- **File**: path (or "missing")
- **Category**: readme / workflow-clarity / onboarding / missing-docs / tone
- **Severity**: critical / warning / suggestion
- **Issue**: description
- **Fix**: specific suggestion
```

---

## Synthesis

After all 5 agents return, synthesize into:

```
# Ruckus Plugin Review

**Reviewed:** [date]
**Files:** [total in repo]
**Skills:** [count] | **Agents:** [count]

## Verdict: [Ready to publish / Needs revision / Needs significant work]

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
[From Agent 3, ordered by estimated token savings]

## Suggestions
[Deduplicated]

## What's Strong
[What the review found well-designed — this matters for knowing what NOT to change]

## Recommended Fix Order
1. [Ordered by severity and dependency]
```

This is a **read-only review**. Do NOT modify any files.
