# Contributing to Roughly

This project follows the [Contributor Covenant Code of Conduct](./CODE_OF_CONDUCT.md). By participating, you agree to uphold it.

## Getting Started

1. Fork and clone the repo
2. Test locally from a scratch project: `claude --plugin-dir /path/to/your/roughly-clone`
3. Run `/roughly:setup` in the scratch project to verify the bootstrap flow
4. Try `/roughly:build` on a small feature to see the full pipeline

## What to Contribute

Improvements to Roughly — built with Roughly. Use `/roughly:build` to implement your changes.

- Bug reports with reproduction steps (include Claude Code version)
- Documentation improvements (README, ADRs, CLAUDE.md)
- New agent definitions
- Template improvements (setup templates, ignore patterns)
- Maturity check additions (with versioned IDs)

## What NOT to Contribute Without Discussion

These are covered by ADRs and require an ADR amendment before changing:

- Pipeline stage structure — number, order, or gating behavior (ADR-001, ADR-002)
- Subagent dispatch model — how tasks are scoped and coordinated (ADR-002)
- Adding new pipeline commands — build and fix are intentionally the only two (ADR-004)
- Removing `disable-model-invocation: true` from coordinator skills (see CLAUDE.md)

Open an issue to discuss before submitting a PR for these areas.

## PR Process

1. For non-trivial changes, open an issue first to discuss the approach
2. Fork → branch → PR against `main`
3. Include an updated CHANGELOG entry under `[Unreleased]`
4. If the change involves a design decision, draft an ADR (see `docs/adrs/README.md`)
5. Ensure skills stay under 300 lines and agents under 500 words

## Code Standards

All conventions are documented in [CLAUDE.md](CLAUDE.md). The key ones:

- Skills: YAML frontmatter with `name`, `description`; pipeline/coordinator skills need `disable-model-invocation: true`
- Agents: YAML frontmatter with `name`, `description`, `tools`, `model`
- Templates: use `{{PLACEHOLDER}}` markers — never hardcode project-specific values
- Maturity check IDs must be versioned (e.g., `investigator-v1`)

## Testing

There is no automated test suite — this is pure markdown. To verify changes:

1. Run `claude --plugin-dir /path/to/your/roughly-clone` in a test project
2. Exercise the skill you changed (e.g., `/roughly:build` for build changes)
3. Check that frontmatter is valid YAML
4. Check that cross-references (agent names in skills, file paths) are accurate
5. Verify line/word limits: skills < 300 lines, agents < 500 words

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
