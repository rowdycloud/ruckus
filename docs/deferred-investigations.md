# Deferred investigations

Process and quality observations surfaced during normal work that are **consequential but out of scope** for the work that surfaced them. Tracked here so they don't get lost between epics.

This is NOT:

- A roadmap of features ([docs/ROADMAP.md](ROADMAP.md))
- A pitfalls catalog of patterns to avoid in code ([.roughly/known-pitfalls.md](../.roughly/known-pitfalls.md))
- A design-decision record ([docs/adrs/](adrs/))

This IS:

- Things noticed during execution that warrant investigation but weren't worth blocking the in-flight work to chase
- Each entry is "what we saw, why it matters, what investigating would look like" — not a committed action

Entries are not prioritized. When picking up an investigation, evaluate freshness first — observations decay fast.

---

## DI-001: Stage 6 review depth vs external review tools

**Date noticed:** 2026-05-05
**Surfaced during:** [E03.S2 stop-hook-v1 maturity check completion](planning/epics/E03-trust-and-ergonomics.md) (branch `feat/S03.2-stop-hook-v1-maturity-check`)

**Observation:**
The build pipeline's Stage 6 (parallel `code-reviewer` + `static-analysis` + `silent-failure-hunter` agents) ran 2 review cycles on S03.2 and closed 7 findings before commit. Post-commit, 6 successive `cubic review --json` rounds surfaced ~12 additional findings. All cubic findings were valid, all in the same conceptual buckets the Stage 6 reviewers were ostensibly looking at (orphan-on-failure, branch-cleanup completeness, type-validity guards, contract violations through default tooling like `set -e`, gate-text precision).

**Evidence:**

- E03.S2 commit history: 1 feat + 9 fix/docs commits on branch (1 + 1 docs at wrap-up + 8 post-commit cubic rounds)
- Each cubic round closed 1-5 findings
- Findings clustered in 3-4 buckets that overlap the documented [.roughly/known-pitfalls.md](../.roughly/known-pitfalls.md) entries

**Why it matters:**

- Cubic's findings were detectable in principle — they fit existing pitfalls, hit code paths the Stage 6 reviewers walked, and were closed with minimal-edit fixes
- If Stage 6 had matching depth, post-commit fix labor (8+ commits) collapses to in-pipeline iterations under a single feat commit
- Trust thesis (per [ROADMAP.md](ROADMAP.md) line 9): "a tech lead won't standardize on Roughly while it has known silent-failure modes." A Stage 6 that misses 60%+ of findings external tools catch undermines that thesis directly.

**Possible causes (untested hypotheses):**

1. **Agent prompts are too narrow.** Each Stage 6 agent has a focused brief; cubic may run a broader scan.
2. **Model tier.** Stage 6 agents run on `sonnet` per [ADR-008](adrs/ADR-008-opus-for-epic-reviewer-only.md). Cubic may use a higher-tier model.
3. **Iteration count.** Stage 6 caps at 2 review-fix cycles; cubic ran 6 rounds before saturating.
4. **Review dimensions missing.** Stage 6's three lenses (code review / static / silent-failure) may not cover what cubic covers (e.g., "every conditional branch enumerates state cleanup," "tool prerequisites validated before mutations" — both already in our pitfalls catalog but not explicitly in the agent briefs).
5. **Pre-implementation reviewers (review-plan, review-epic) catch design issues but not execution bugs** — already a documented pitfall ([.roughly/known-pitfalls.md](../.roughly/known-pitfalls.md) "Build & Deploy" section). Stage 6 may have the inverse problem: it catches obvious execution bugs but misses systematic categories the pitfalls already document.

**Investigation directions:**

- Diff Stage 6 reviewer prompts vs the [.roughly/known-pitfalls.md](../.roughly/known-pitfalls.md) entries the cubic findings hit. If the pitfalls aren't surfaced into the agent briefs, that's a leak — agent prompts should reference the pitfalls catalog explicitly or have the pitfalls patterns baked in.
- Run Stage 6 reviewers in isolation against a reverted version of S03.2 (HEAD~9) and measure recall against the 12 cubic findings. If recall is <50%, the gap is real and tunable.
- Evaluate cost of switching code-reviewer / silent-failure-hunter to opus. ADR-008 reserves opus for epic-reviewer; the rationale was cost. Re-evaluate if depth gap justifies the spend.
- Increase max review-fix cycles from 2 to 3 or 4 and measure whether the additional rounds close the gap or hit diminishing returns.

**Out of scope of:**

- E03.S2 (the surfacing story; fixing it now would balloon scope)
- v0.1.5 (frozen per ROADMAP.md)

**Candidate placement:** v0.1.6 (ROADMAP.md sequencing: v0.1.5 is FROZEN with overflow → v0.1.6, see ROADMAP.md `## v0.1.5` "Out of scope (→ v0.1.6 if surfaced)" subsection at line 76), or a dedicated trust-hardening epic if findings repeat across v0.1.5 stories.
