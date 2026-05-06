# Roughly Roadmap

**Current:** v0.1.4 · **Updated:** 2026-05-01

## Thesis

Structure beats vibes. The pipeline's value is enforcement: gated stages, fresh subagents per task, mandatory plan and code review.

Primary user through v1.0: solo dev first, teams second. Team adoption is downstream of solo-dev credibility — a tech lead won't standardize on Roughly while it has known silent-failure modes. Solo trust and ergonomics through v0.2.x; team and governance after the core is airtight.

## Release map

| Release | Theme | Effort |
|---|---|---|
| v0.1.5 | Trust hardening + ergonomics + CI | 6-7 wk |
| v0.2.0 | Cost-aware pipeline (Haiku routing, plan format v2) | 4-5 wk |
| v0.3.0 | Monorepo support | 6-8 wk |
| v0.4.0 | Team governance | 4-6 wk |
| v0.4.x | Migration-code cleanup (opportunistic) | trivial |
| v1.0 | Stability commitment | mid-2027 |

## Sequencing notes

- **CI in v0.1.5, not v0.2.0.** Trust hardening without regression coverage is theater.
- **v0.1.5 bundles trust + ergonomics.** Original split was artificial.
- **v0.2.0 bundles cost work + plan format v2.** Both touch plan format. One migration, one ADR.
- **v0.3.0 stays at v0.3.0.** Monorepo is inferred-but-not-blocking. The worktree-by-epic workflow already handles runtime workspace inference, so v0.3.0 ships smaller than first scoped.
- **Cleanup is opportunistic.** Triggered by next unrelated touch of `upgrade/SKILL.md`, not its own release.

## Path to v1.0

1. Two consecutive minors without a silent-failure regression.
2. Self-test CI catching real regressions for ≥3 months.
3. ≥1 team adoption surviving a quarter without direct intervention.
4. ADR backbone unchanged for ≥6 months.
5. roughly.dev complete enough that a stranger gets the pipeline without reading SKILL.md.

## Docs cadence

Continuous from v0.1.5. Every release's DoD includes a docs update for user-visible changes. Floor for v0.1.5: landing page, pipeline overview, commands reference, setup walkthrough.

## Deferred investigations

Process and quality observations surfaced during execution but out of scope for the work that surfaced them are tracked in [docs/deferred-investigations.md](deferred-investigations.md). Distinct from this roadmap (which is committed work) — investigations are noticed-but-not-yet-evaluated. Pull from the catalog when scoping each release.

---

# Release scope

PM handoff: detail level sufficient for an epic-writing agent to expand into stories. Effort = wall-clock weeks part-time.

## v0.1.5 — Trust + ergonomics + CI

**Effort:** 6-7 wk · **Scope:** FROZEN. New items → v0.1.6.

### Trust hardening
1. **Plan-mode auto-detect/exit at Stage 1 of build/fix.** Without this, ADR-001 is unenforced.
2. **Finish stop-hook-v1 maturity check** integration into `/roughly:upgrade`.
3. **Retire test-verify-v1 and pitfalls-organized-v1.** ✅ Done — triggers folded into doc-writer's known-pitfalls write path (E03.S3).
4. **Pre-flight migration check in remaining 2 skills** (currently 6/9, upgrade excluded by design).
5. **Document Edit `replace_all` dual-semantic-token failure** in CONTRIBUTING.md. Prose-only.
6. **Plan-format version field.** Added now, read in v0.2.0.

### Ergonomics
7. **In-session maturity offers at Stage 1**, not just Stage 8 wrap-up.
8. **`/roughly:help` command.** 10th command. Structured overview of commands and pipeline state.
9. **Situation-specific abort prose** at every pipeline failure point.
10. **Retry-loop tuning.** Audit caps at Stages 5c (quality), 5c (questions), 6 (review-fix). Raise on cheap checks or replace hard escalation with prompt.

### CI
11. **Plugin self-test CI.** GitHub Actions running dogfood through scripted build/fix on push. Happy path minimum. **Architecturally novel** — plugin tests itself against the repo containing the plugin. Probably needs its own story.

### Docs
12. **roughly.dev v0.1.5.** Landing, pipeline overview, commands reference, setup walkthrough.

### Out of scope (→ v0.1.6 if surfaced)
- Plan format changes beyond the version field
- Setup flow changes
- New agents
- Cost optimization

---

## v0.2.0 — Cost-aware pipeline

**Effort:** 4-5 wk · **Depends on:** v0.1.5 (CI before format changes).

1. **Complexity flag in plan format.** `Task N (Complexity: simple|standard|complex)`. Plan template + plan-reviewer validation.
2. **Haiku routing for simple tasks.** Sonnet default; Opus stays exclusive to epic-reviewer (ADR-008).
3. **Plan format v2.** Activate the v0.1.5 version field. v2 = complexity flag + any small wins surfaced during v0.1.5.
4. **ADR-009.** Complexity flag, routing rules, plan format v2.
5. **Pre-compaction trim.** Audit Stages 1-4 burn (~20-40K). Target 5-10K recovery via tighter compaction lists.
6. **`/roughly:upgrade` migration step** for plan format v1 → v2.
7. **roughly.dev v0.2.0.** Cost model page; updated commands reference; ADR-009 published.

### Out of scope
- Monorepo (v0.3.0)
- Per-field CLAUDE.md merge (v0.3.0)
- Governance (v0.4.0)

---

## v0.3.0 — Monorepo support

**Effort:** 6-8 wk · **Depends on:** v0.2.0.

Targets Duff, DGF, HuntReady. Today's setup misclassifies them and generates one CLAUDE.md for everything.

1. **Detection in setup.** Trigger on (a) workspace manifest (`pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`, `rush.json`, `Cargo.toml [workspace]`, `go.work`) or (b) ≥2 distinct stack markers at depth ≥1 (`package.json`, `Cargo.toml`, `Package.swift`, `pyproject.toml`, `setup.py`, `go.mod`, `Gemfile`, `composer.json`, `mix.exs`). Root marker becomes "root workspace" if present; doesn't count toward (b).
2. **Setup prompt on detection.** Three options: monorepo (per-workspace setup), single project (today's behavior), edit workspace list.
3. **Hierarchical CLAUDE.md.** Root for shared conventions; workspace for overrides.
4. **CLAUDE.md format restructure.** YAML frontmatter for merged fields (`build_command`, `test_command`, `type_check`, `lint`, `commit_convention`, `formatter`, `architecture`); prose for non-merged (pitfalls, architecture notes, domain). ADR-010.
5. **Field-level merge.** Workspace-defined fields fully replace root for that field; undefined fields inherit.
6. **`/roughly:upgrade` migration** for CLAUDE.md format. Auto-migrate flat → frontmatter+prose; monorepo users re-run setup to opt in.
7. **Cwd-based workspace inference at Stage 1.** Cwd inside a workspace → use that workspace. Cwd at root → ask or default to root-only. Cross-workspace features get a "specify workspaces" affordance, not deep optimization.
8. **Stop hook workspace awareness** for agent-preamble drift check.
9. **roughly.dev v0.3.0.** Monorepo guide; CLAUDE.md format reference; per-workspace setup walkthrough; ADR-010.

### Out of scope
- Per-field merge in non-monorepo enrich (v0.4.0; that's the team-shared case)
- Cross-workspace feature optimization (until real usage demands it)
- Governance (v0.4.0)

### Resolve before implementation
- **False-positive handling** for vendored libs / example apps with their own stack markers. Probably the "edit workspace list" option; exercise against real repos.
- **HuntReady's MCP server: peer or sub-component?** Match Nick's mental model.

---

## v0.4.0 — Team governance

**Effort:** 4-6 wk · **Depends on:** v0.3.0.

1. **Per-field merge in non-monorepo enrich.** Currently all-or-nothing. Reuses v0.3.0 merge machinery.
2. **Fallback context source.** `.roughly/commands.md` for teams whose CLAUDE.md is governed externally. Skills read as secondary source.
3. **Governed CLAUDE.md mode.** Setup option: "CLAUDE.md is managed externally." Roughly writes only to `.roughly/`.
4. **Upgrade-available notifications.** GitHub release check on `/roughly:setup` and `/roughly:build`. Cached, opt-out.
5. **roughly.dev v0.4.0.** Team adoption guide; governed mode walkthrough; notification config.

### Out of scope
- Telemetry / usage analytics
- Multi-user permission models
- Anything requiring a server component

---

## v0.4.x — Cleanup (opportunistic)

Triggered by next unrelated touch of `upgrade/SKILL.md`.

1. Remove pre-flight migration checks from 9 skills.
2. Drop v0.1.2 + v0.1.4 migration steps from `upgrade/SKILL.md`.
3. Prune Stop hook legacy-`.ruckus/` detection.
4. Decide: keep CHANGELOG `### Migration` convention or move to CONTRIBUTING.md.

---

## v1.0

Stability commitment. Ships when the five criteria above are met.

---

## Deferred

Surfaced during planning, consciously not on the roadmap:

- **Maturity model rework beyond file count.** Revisit if real-world misclassification surfaces post-v0.3.0.
- **Edit `replace_all` code-level defense.** Prose-only in v0.1.5; code defense waits for a second occurrence.
- **`docs/planning/**` gitignore policy.** Unresolved; default gitignored.
- **Stop hook enforcing mode (exit-1).** Breaking change for contributors. No scheduled release.
- **Telemetry.** Trust + complexity cost too high at current scale.
