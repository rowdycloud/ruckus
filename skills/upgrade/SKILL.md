---
name: upgrade
description: "Update installed Ruckus files from latest plugin templates. Diffs installed vs source, classifies changes, applies structural updates while preserving project customizations. Never overwrites without asking."
---

# Ruckus Upgrade

Compare installed Ruckus files against the latest plugin templates. Apply structural updates while preserving project-specific customizations.

**Never overwrites without asking.**

---

## STEP 1: INVENTORY

**Migration check:** If `docs/claude/` directory exists in the project:
> "Ruckus v0.1.2 renamed `docs/claude/` to `.ruckus/`. Migrate existing files? (yes / abort)"
If abort: stop the upgrade. Display: "Migration is required before upgrading — all v0.1.2+ paths use `.ruckus/`. Re-run `/ruckus:upgrade` when ready to migrate."
If yes: create `.ruckus/` directory if it doesn't exist. Move (preserving content) `docs/claude/known-pitfalls.md` to `.ruckus/known-pitfalls.md`, move `docs/claude/.workflow-upgrades` to `.ruckus/workflow-upgrades`. If `docs/claude/CLAUDE.md` exists but root `CLAUDE.md` does not, move it to root `CLAUDE.md`. If both exist and differ, show the diff and ask the user which to keep. If both exist and are identical, or only root exists, delete `docs/claude/CLAUDE.md`. Remove `docs/claude/` only if empty after moves. If any source file doesn't exist, skip that move and note it in the migration summary. Then update root `CLAUDE.md`: replace any remaining `docs/claude/known-pitfalls.md` with `.ruckus/known-pitfalls.md` and `docs/claude/.workflow-upgrades` with `.ruckus/workflow-upgrades`.

**Version check:** Read `.ruckus/workflow-upgrades` and extract the `ruckus-version` line. Read `.claude-plugin/plugin.json` for the current plugin version. If they differ:
> "Plugin version changed: [installed] → [current]. Structural diffs below may include changes from the version bump, not just your edits."

If `.ruckus/workflow-upgrades` is missing or has no version line, warn:
> "No installed version recorded. Run `/ruckus:setup` to initialize, or proceeding will compare against current plugin templates."

After displaying the version status, enumerate all template files in the plugin's `skills/setup/templates/` directory dynamically. For each template, determine its installed counterpart:

**Known mappings:**
| Template | Installs to |
|----------|-------------|
| `CLAUDE.md.template` | `CLAUDE.md` |
| `known-pitfalls.md.template` | `.ruckus/known-pitfalls.md` |
| `claudeignore.template` | `.claudeignore` |
| `settings.json.template` | `.claude/settings.json` |

For any new templates not in this table, infer the install path from the filename (strip `.template` suffix, place in `.ruckus/` or `.claude/` as appropriate).

Also check for agent files in `.claude/agents/` that may need updates against plugin `agents/` directory.

**Preamble drift check:** For each installed agent in `.claude/agents/`, verify its context-loading step references both `CLAUDE.md` and `.ruckus/known-pitfalls.md` consistent with `agents/agent-preamble.md`. Flag any agent where either file reference is missing or uses a stale path (excluding exceptions: static-analysis, doc-writer). Note: inlined copies in `build/SKILL.md` and `fix/SKILL.md` Stage 5b are not checked here — verify those manually when updating the preamble.

---

## STEP 2: CLASSIFY CHANGES

For each file, classify as:

- **New** — exists in plugin source but not installed. Offer to create.
- **Changed** — plugin source has structural updates not in installed version. Show diff.
- **Unchanged** — installed matches plugin structure (customizations preserved).
- **Local-only** — exists in project but not in plugin source. Leave alone.

Display the classification table.

---

## STEP 3: REVIEW CHANGES

For each file classified as **Changed**, show:
1. What the plugin update adds/modifies (structural changes)
2. What project customizations exist (will be preserved)
3. The proposed merged result

**Structural changes** (apply automatically):
- New sections added to templates
- Updated ignore patterns in .claudeignore
- New hook configurations
- Updated agent prompts (structural, not project-specific)

**Project customizations** (always preserved):
- Filled `{{PLACEHOLDER}}` values
- Added conventions, pitfalls, architecture notes
- Custom ignore patterns added by the user
- Project-specific hook configurations

---

## STEP 4: APPLY UPDATES

For each changed file, ask:
> "[file]: Plugin has structural updates. Apply? (yes / show diff / skip)"

Apply approved updates. For each applied update:
1. Create a backup: `[file].backup-[date]`
2. Merge structural changes with preserved customizations
3. Verify the merged file is valid

---

## STEP 5: NEW FILES

For files classified as **New**:
> "New plugin file available: [file]. Purpose: [description]. Install? (yes / skip)"

---

## STEP 6: UPDATE VERSION

Update the `ruckus-version` line in `.ruckus/workflow-upgrades` to match the current plugin version. Do this regardless of whether the user accepted or declined changes — the version tracks "last reviewed," not "last applied." File-content comparison in STEP 2 will still surface any unmerged diffs on future runs.
```
ruckus-version [current version from plugin.json] [today's date]
```

If the file doesn't exist, create it with the version line.

---

## STEP 7: SUMMARY

```
# Upgrade Summary

| File | Status | Action Taken |
|------|--------|--------------|
| [file] | Updated | Merged structural changes |
| [file] | Skipped | User declined |
| [file] | New | Installed |
| [file] | Unchanged | No action needed |

**Plugin version:** [previous] → [current] (or "unchanged")
**Backups created:** [list or "none"]
```
