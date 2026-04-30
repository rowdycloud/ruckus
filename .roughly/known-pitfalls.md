# Known Pitfalls

Project: Roughly
Domain: Roughly is a Claude Code plugin that implements gated development pipelines with subagent-per-task execution.

Pitfalls discovered through development. Updated by `/roughly:build` and `/roughly:fix` wrap-up stages.

---

## Domain-Specific

- **Agent files are plugin-shipped, not project-installed.** All 7 agents are loaded via `subagent_type` (e.g., `roughly:code-reviewer`) from the plugin cache. The upgrade skill must never classify agent files as "New" or offer to copy them to `.claude/agents/`. The only valid agent-related check during upgrade is preamble drift on pre-existing `.claude/agents/` files.

- **Plan mode (Claude Code's built-in) hijacks the build/fix pipeline.** When `/roughly:build` or `/roughly:fix` runs with plan mode active, plan-mode's workflow (Phase 1–5 → ExitPlanMode) substitutes for the build skill's Stages 1–4. The build skill's preamble warns about this, but it can still happen via auto-engagement at SessionStart. Most common silent failure: Stage 4 (`/roughly:review-plan` dispatch) gets skipped because plan-mode's generic `Plan` subagent looks like it fulfills the design-review step — it does NOT. The `Plan` agent designs implementations; `/roughly:review-plan` returns a structured PASS/NEEDS REVISION verdict against the codebase. If plan mode is active when invoking a Roughly pipeline, exit plan mode and re-invoke; or explicitly dispatch `/roughly:review-plan` to recover.

## Data & State

- **CLAUDE.md as the source of truth for verify-all commands has two known failure modes.** Teams with mandated CLAUDE.md formats may not permit Roughly's Commands table, and third-party agents (claude-mem and others) that rewrite CLAUDE.md programmatically can clobber it. Session-length compaction is *not* a failure mode — skills explicitly `Read` CLAUDE.md at runtime per ADR-006, so the disk file is authoritative regardless of what was autoloaded. If breakage is reported, the clean fix is an additive `.roughly/commands.md` fallback that skills check first, falling back to CLAUDE.md — strictly additive, no migration. Stay on CLAUDE.md until that happens to avoid a two-source-of-truth mental model.

## Integration

<!-- Pitfalls related to APIs, third-party services, cross-system communication -->

## Build & Deploy

- **Pre-implementation review (review-epic, review-plan) catches design issues but not always execution bugs.** A spec can pass two `/roughly:review-epic` iterations and a `/roughly:review-plan` pass yet still contain logic bugs that only execution-tracing catches in code review. Example: the S2.2 v0.1.4 migration step had "marker write before conflict check" ordering that made the conflict-prompt branch unreachable on first run — pre-implementation reviewers read the steps as a bullet list; only the Stage 6 code-reviewer noticed by tracing execution order. Don't treat spec-faithfulness as a substitute for code review. Stage 6 catches what Stages 2–4 miss.

- **Grep-based ACs are authoritative over a spec's line-enumeration tables.** When an epic specifies "zero `\bRuckus\b` matches in skills/" alongside an enumerated list of lines to edit, the AC is the contract — the line list is a (sometimes incomplete) implementation hint. Plans should reconcile the AC against `rg -n` output during plan-write and add any missing lines to the substitution table. S2.2 had two reconciled gaps: setup/SKILL.md L40 (mixed-content line, caught by plan-reviewer) and L3 frontmatter descriptions (caught at plan-write time). Pattern: trust the regex, not the line number.

- **Splitting a doc-only rename from a runtime-directory rename leaves the dogfood repo silently broken between merges.** When an epic partitions paired path renames into separate stories — e.g., S2.3 (agent docs reference `.roughly/known-pitfalls.md`) and S2.6 (this repo's `.ruckus/` → `.roughly/` directory rename) — merging the doc-only story first means every agent in *this dogfood repo* reads from a path that does not exist on disk until S2.6 lands. Claude Code's file read on a missing path returns empty silently, so agents proceed without project context with no error signal. When designing future split renames, either bundle the paired stories into one PR or land them in immediate succession; if they must be sequenced, document the silent-failure window in the commit message so reviewers can decide whether to merge or hold.

- **Appending text to an HTML comment block where `-->` is inline shifts the closing-delimiter line number.** When an existing HTML comment ends with `... last sentence. -->` on a single line and you insert a new sentence on its own line before `-->`, the closing delimiter migrates to a new line number along with the new content. Any sync notes, line-citation comments, or downstream references to "L13" (or wherever `-->` used to be) become stale. Pattern: when citing the line of an HTML-comment-internal note, cite the line containing the new content (where `-->` now lives), not the line where `-->` historically lived. Verify with `rg -n '<!--|-->'` after the edit — must show exactly one of each, and the new line numbers must match what surrounding documentation claims.

- **Prose-only grep filters silently miss rename tokens inside code fences.** When sweeping a file for a rename token (e.g., `Ruckus` → `Roughly`), filtering matches by Markdown context — excluding fenced blocks to "stay in prose" — will skip tokens embedded in code fences, directory trees, sample paths, and comment lines inside fences. In S02.5, `README.md` L287 contained the directory label `ruckus/` inside a `text` code fence; a fence-aware filter that excluded fenced content would surface L1, L3, L20, and others but skip L287 entirely, leaving a stale token in a high-visibility section. The corrective pattern: use plain `rg -n '<token>' <file>` with no Markdown-context filter and review every match individually — fence content is in scope unless an explicit "Migrating from X to Y" carve-out exists. Confirm the rename is complete by re-running the same unfiltered grep and verifying only intentional legacy-name references remain.

- **Append-only edits to immutable documents must use `Edit`, not `Write`, to guarantee zero deletions.** When a task is strictly additive — such as appending a footnote to an ADR — using the `Write` tool with the full new file content risks producing `-` lines in the diff if any prior line is imperceptibly changed (trailing whitespace collapse, line-ending re-encoding, missing final newline). In S02.5 T4, four ADRs each received a v0.1.4 footnote append; a `Write`-based approach would have failed the "zero deletions" acceptance check even if the content was correct. The corrective pattern: use the `Edit` tool with `old_string` set to the file's current last line (read the file first to confirm) and `new_string` set to that same last line followed by `\n\n<new content>` — every preceding line is then byte-identical post-edit. Verify with `git diff <file>` showing only `+` lines and no `-` lines, and `tail -1 <file>` matching the appended content. This pattern generalizes to CHANGELOGs, audit logs, and any append target with immutability constraints.

## Testing

<!-- Pitfalls related to test reliability, test data, flaky tests -->
