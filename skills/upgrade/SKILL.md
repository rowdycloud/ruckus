---
name: upgrade
description: "Update installed Roughly files from latest plugin templates. Diffs installed vs source, classifies changes, applies structural updates while preserving project customizations. Never overwrites without asking."
---

# Roughly Upgrade

Compare installed Roughly files against the latest plugin templates. Apply structural updates while preserving project-specific customizations.

**Never overwrites without asking.**

---

## STEP 1: INVENTORY

**Migration check:** If `docs/claude/` directory exists in the project:
> "Roughly renamed `docs/claude/` to `.roughly/`. Migrate existing files? (yes / abort)"
If abort: stop the upgrade. Display: "Migration is required before upgrading — all v0.1.2+ paths use `.roughly/`. Re-run `/roughly:upgrade` when ready to migrate."
If yes: create `.roughly/` directory if it doesn't exist. Move (preserving content) `docs/claude/known-pitfalls.md` to `.roughly/known-pitfalls.md`, move `docs/claude/.workflow-upgrades` to `.roughly/workflow-upgrades`. If `docs/claude/CLAUDE.md` exists but root `CLAUDE.md` does not, move it to root `CLAUDE.md`. If both exist and differ, show the diff and ask the user which to keep. If both exist and are identical, or only root exists, delete `docs/claude/CLAUDE.md`. Remove `docs/claude/` only if empty after moves. If any source file doesn't exist, skip that move and note it in the migration summary. Then update root `CLAUDE.md`: replace any remaining `docs/claude/known-pitfalls.md` with `.roughly/known-pitfalls.md` and `docs/claude/.workflow-upgrades` with `.roughly/workflow-upgrades`.

**v0.1.4 migration check:** If `.ruckus/` directory exists in the project (legacy v0.1.3 installation):

1. **Detection and method choice:** If `.ruckus/` does not exist, skip this step entirely. Otherwise detect git status with `git rev-parse --git-dir 2>/dev/null` — a silent failure (non-zero exit, no output) means non-git. Use `git mv` inside a git repo; use plain `mv` otherwise. Do NOT attempt `git mv` and fall back on failure — the error output is confusing to users.

2. **Conflict check or partial-failure resume:** If `.roughly/` already exists alongside `.ruckus/`:
   - If `.ruckus/.migration-in-progress` exists, set `mode = resume` (skip step 3's marker write; the existing marker is preserved) and proceed — steps 5–7 are idempotent so resume is safe.
   - Otherwise, prompt:
     > "Both `.ruckus/` and `.roughly/` exist (no in-progress marker). Show diff and ask which to keep? (diff / keep .roughly / keep .ruckus / abort)"
     Record the choice as `conflict_action` for application at step 5 (after the marker is written). On `abort`: stop the upgrade entirely with:
     > "Migration is required before upgrading — re-run `/roughly:upgrade` when ready to migrate."
     No marker was written, so re-running re-prompts.

3. **Marker file:** Skip if `mode = resume` (existing marker is preserved). Otherwise, write a marker at `.ruckus/.migration-in-progress` containing the current ISO date and the plugin version performing the migration (one line, plain text). The marker signals that a migration started but may not have finished, and is removed at step 9 once migration is complete. If the marker write fails (read-only filesystem, restrictive permissions, disk full): abort immediately with:
   > "Cannot write marker to `.ruckus/.migration-in-progress` — check directory permissions or filesystem state."
   No file moves have been attempted at this point, so no partial state is created. The user can fix permissions and re-run `/roughly:upgrade`.

4. **Co-existence of `docs/claude/` and `.ruckus/`:** If both legacy directories exist, the v0.1.2 migration step above ran first and wrote to `.roughly/`. The v0.1.4 step then encounters non-empty `.roughly/` per the conflict check at step 2. Handle as step 2.

5. **Move (idempotent):** First apply any `conflict_action` recorded at step 2:
   - `keep .ruckus` → rename `.roughly/` to `.roughly.backup-[date]/` (this serves as backup AND clears the destination — `git mv`/`mv` cannot overwrite an existing non-empty directory, so a separate copy-then-overwrite would deadlock). Then move `.ruckus/` to `.roughly/` using the command from step 1; the standard per-file moves below skip silently because `.ruckus/` no longer exists.
   - `keep .roughly` → identify any files present in both `.ruckus/` and `.roughly/`; log: `"Discarded from .ruckus/ in favor of .roughly/: [X, Y, Z]"` (omit if none conflict). Then move only files from `.ruckus/` that do not already exist in `.roughly/`.
   - `diff` → per-file user choice.

   Ensure `.roughly/` exists — create it with `mkdir .roughly` if absent (required for the no-conflict path, where `.roughly/` doesn't exist yet; in conflict paths the directory is already present from step 2 or created by the `keep .ruckus` rename). Then perform standard moves: `.ruckus/known-pitfalls.md` → `.roughly/known-pitfalls.md` and `.ruckus/workflow-upgrades` → `.roughly/workflow-upgrades` using the command determined in step 1. For each move: if the source does not exist AND the destination exists, skip silently (already moved). If the source does not exist AND the destination is also missing, abort immediately: `"Possible data loss: neither .ruckus/[file] nor .roughly/[file] found — the marker will stay in place for inspection."` If both source and destination exist (resume case after a partial move), keep the destination and delete the source. If the move command returns non-zero, surface the error output verbatim and abort the migration step — the marker stays in place so a future re-run can resume from step 2.

6. **Content rewrites inside moved files (idempotent):**
   - In `.roughly/workflow-upgrades`: if the file does not exist (e.g., data-loss path from step 5 was escalated), skip — STEP 6 of the outer upgrade later recreates the file from scratch. Otherwise, rename the version-line identifier from `ruckus-version` to `roughly-version` in-place. Preserve the existing version number and date — STEP 6 of the upgrade later updates the version digits. If the line already reads `roughly-version` (resume case), skip silently.
   - In `.roughly/known-pitfalls.md`: rewrite the boilerplate header line. Match anchored to start-of-line: `^Pitfalls.*\/ruckus:build.*\/ruckus:fix.*$` — replace `/ruckus:build` with `/roughly:build` and `/ruckus:fix` with `/roughly:fix`. Leave all user-authored pitfall entries unchanged. If the pattern does not match (line was customized or commands reordered), skip silently AND log a warning to the upgrade summary: `"Custom boilerplate line in .roughly/known-pitfalls.md preserved verbatim — check for stale /ruckus:* tokens manually."` On resume where the line already reads `/roughly:*`, the pattern won't match; the silent-skip plus warning is acceptable and harmless.

7. **Update root CLAUDE.md path references (literal substring, with counts):** Replace `.ruckus/known-pitfalls.md` → `.roughly/known-pitfalls.md` and `.ruckus/workflow-upgrades` → `.roughly/workflow-upgrades` using literal-substring match (not regex). Display before/after match counts in the upgrade summary, e.g.: `"Updated 2 path references in CLAUDE.md (1 known-pitfalls.md, 1 workflow-upgrades)."` If no matches, display: `"No .ruckus/ path references in root CLAUDE.md — skipped."` and continue.

8. **Extra files in `.ruckus/` (interactive):** After the standard moves at step 5, list any files remaining in `.ruckus/` beyond the marker file. If the list is non-empty, prompt:
   > "Files [X, Y, Z] exist in `.ruckus/` beyond the standard `known-pitfalls.md` and `workflow-upgrades`. Move them to `.roughly/` as well? (move / leave for me to handle)"
   On `move`: move all listed files to `.roughly/` using the same command from step 1. On `leave`: print each path and continue without moving. On unexpected input or Ctrl-C: treat as `leave` and print: `"Treating as 'leave for me to handle.'"`

9. **Cleanup:** Remove the marker file at `.ruckus/.migration-in-progress` AND at `.roughly/.migration-in-progress` (the latter only exists if the `keep .ruckus` branch at step 5 relocated it via the whole-directory rename). Both removals are silent if the file is absent. If `.ruckus/` is empty after removing the marker, remove the directory. If `.ruckus/` is still non-empty (user chose `leave` at step 8), do NOT remove `.ruckus/`; print: `"Files remain in .ruckus/. Move or delete them when ready."` and continue.

10. **Idempotency:** A successful migration removes the marker at step 9; re-running the upgrade finds no `.ruckus/` and skips this step at step 1. A mid-migration failure leaves the marker in place; re-running detects it at step 2 and resumes from step 5. Exception: if the user chose `leave` at step 8, `.ruckus/` remains non-empty after cleanup; re-running the upgrade will re-enter step 2 and re-prompt for the conflict — this is expected and safe.

**Version check:** Read `.roughly/workflow-upgrades` and extract the `roughly-version` line. Read `.claude-plugin/plugin.json` for the current plugin version. If they differ:
> "Plugin version changed: [installed] → [current]. Structural diffs below may include changes from the version bump, not just your edits."

If `.roughly/workflow-upgrades` is missing or has no version line, warn:
> "No installed version recorded. Run `/roughly:setup` to initialize, or proceeding will compare against current plugin templates."

After displaying the version status, enumerate all template files in the plugin's `skills/setup/templates/` directory dynamically. For each template, determine its installed counterpart:

**Known mappings:**
| Template | Installs to |
|----------|-------------|
| `CLAUDE.md.template` | `CLAUDE.md` |
| `known-pitfalls.md.template` | `.roughly/known-pitfalls.md` |
| `claudeignore.template` | `.claudeignore` |
| `settings.json.template` | `.claude/settings.json` |

For any new templates not in this table, infer the install path from the filename (strip `.template` suffix, place in `.roughly/` or `.claude/` as appropriate).

**Agent files are plugin-shipped** — they are loaded via `subagent_type` (e.g., `roughly:code-reviewer`) directly from the plugin cache. Do NOT inventory plugin `agents/` for installation to `.claude/agents/` — never classify agent files as "New" in STEP 2 and never offer to create them in STEP 5.

**Preamble drift check:** For each installed agent in `.claude/agents/`, verify its context-loading step references both `CLAUDE.md` and `.roughly/known-pitfalls.md` consistent with `agents/agent-preamble.md`. Flag any agent where either file reference is missing or uses a stale path (excluding exceptions: static-analysis, doc-writer). Note: inlined copies in `build/SKILL.md` and `fix/SKILL.md` Stage 5b are not checked here — verify those manually when updating the preamble.

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

**For settings.json:** Preserve all existing user-added hook entries — they may be from other plugins or custom workflows. Only add or update hooks defined in the plugin template. If a previously-installed plugin hook is no longer in the current template, flag it to the user rather than silently removing or preserving it.

---

## STEP 5: NEW FILES

For files classified as **New**:
> "New plugin file available: [file]. Purpose: [description]. Install? (yes / skip)"

---

## STEP 6: UPDATE VERSION

Update the `roughly-version` line in `.roughly/workflow-upgrades` to match the current plugin version. Do this regardless of whether the user accepted or declined changes — the version tracks "last reviewed," not "last applied." File-content comparison in STEP 2 will still surface any unmerged diffs on future runs.
```
roughly-version [current version from plugin.json] [today's date]
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
