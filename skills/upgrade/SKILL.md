---
name: upgrade
description: "Update installed Ruckus files from latest plugin templates. Diffs installed vs source, classifies changes, applies structural updates while preserving project customizations. Never overwrites without asking."
---

# Ruckus Upgrade

Compare installed Ruckus files against the latest plugin templates. Apply structural updates while preserving project-specific customizations.

**Never overwrites without asking.**

---

## STEP 1: INVENTORY

**Version check:** Read `docs/claude/.workflow-upgrades` and extract the `ruckus-version` line. Read `.claude-plugin/plugin.json` for the current plugin version. If they differ:
> "Plugin version changed: [installed] → [current]. Structural diffs below may include changes from the version bump, not just your edits."

If `docs/claude/.workflow-upgrades` is missing or has no version line, warn:
> "No installed version recorded. Run `/ruckus:setup` to initialize, or proceeding will compare against current plugin templates."

After displaying the version status, enumerate all template files in the plugin's `skills/setup/templates/` directory dynamically. For each template, determine its installed counterpart:

**Known mappings:**
| Template | Installs to |
|----------|-------------|
| `CLAUDE.md.template` | `docs/claude/CLAUDE.md` |
| `known-pitfalls.md.template` | `docs/claude/known-pitfalls.md` |
| `claudeignore.template` | `.claudeignore` |
| `settings.json.template` | `.claude/settings.json` |

For any new templates not in this table, infer the install path from the filename (strip `.template` suffix, place in `docs/claude/` or `.claude/` as appropriate).

Also check for agent files in `.claude/agents/` that may need updates against plugin `agents/` directory.

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
4. If the file is `docs/claude/CLAUDE.md`: also copy the merged result to the project root `CLAUDE.md` (required for Claude Code auto-loading and agent reads)

---

## STEP 5: NEW FILES

For files classified as **New**:
> "New plugin file available: [file]. Purpose: [description]. Install? (yes / skip)"

---

## STEP 6: UPDATE VERSION

Update the `ruckus-version` line in `docs/claude/.workflow-upgrades` to match the current plugin version. Do this regardless of whether the user accepted or declined changes — the version tracks "last reviewed," not "last applied." File-content comparison in STEP 2 will still surface any unmerged diffs on future runs.
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
