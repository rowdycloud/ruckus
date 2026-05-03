# S1 Verification Harness: UserPromptSubmit Hook Under Plan Mode

This harness verifies the load-bearing assumption underlying E03.S1's hook-based plan-mode detection mechanism. Specifically, it checks whether the `UserPromptSubmit` hook event fires when Claude Code is running in plan mode and whether the stdin JSON it receives contains a `permission_mode` field set to `"plan"`. The result (PASS / FAIL / INCONCLUSIVE) determines whether S1 ships a hook-based detector or falls back to a preamble-only warning approach. (The spike findings doc originally named this event `UserPromptExpansion`; the spike-doc correction note in Section 2 captures the drift.)

Estimated time: 5 minutes to read, 5–10 minutes to execute.

---

## 1. Hook Script Body

Save this as `.claude/hooks/log-stdin.sh` in the test directory (see Step 3 below). It is intentionally non-blocking: it produces no stdout output and exits 0 unconditionally so it cannot interfere with the plan-mode session under test.

```bash
#!/usr/bin/env bash
# Non-blocking stdin logger — appends raw stdin JSON to a temp log file.
# Must produce NO stdout output (no JSON, no text) to avoid blocking hooks.
input=$(cat)
printf '%s\n' "$input" >> /tmp/uphook-test.log
exit 0
```

**Critical:** do not add any `echo` or `printf` to stdout. If the script outputs a JSON object that includes `"decision": "block"`, it will alter plan-mode behavior and invalidate the test result.

---

## 2. Settings.json — Global Form (Test This First)

> **Spike-doc correction (recorded during S1 dogfood, 2026-05-02):** the actual hook event is **`UserPromptSubmit`**, not `UserPromptExpansion` as the spike findings doc states. Earlier runs of this harness against `UserPromptExpansion` produced empty logs because no such event exists in Claude Code's hooks system. ADR-009 captures this drift.

This registration fires `log-stdin.sh` on every `UserPromptSubmit` event with no matcher restriction. Use this form for the primary test.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/tmp/s1-verify/.claude/hooks/log-stdin.sh"
          }
        ]
      }
    ]
  }
}
```

---

## 3. Per-Skill Scoping (Inside the Script, Not via Matcher)

The Claude Code `matcher` field only supports tool names (e.g., `Bash`, `Edit|Write`); it does NOT support slash-command matching. Per-skill scoping for `/roughly:build` and `/roughly:fix` therefore happens **inside the hook script** by inspecting the `prompt` field in the stdin JSON. The production hook (`.claude/hooks/plan-mode-gate.sh`) short-circuits cheaply on prompts that don't match `/roughly:(build|fix)`. Skip this section for the primary test — the global registration in Section 2 is what you run.

---

## 4. Step-by-Step Protocol

Follow each step exactly. Commands are copy-paste ready.

1. Open a new terminal tab or window that is **separate from any currently running Claude Code session**. Do not run these steps inside an existing Claude Code session.

2. Create an isolated test directory and navigate into it:

   ```bash
   mkdir -p /tmp/s1-verify/.claude/hooks && cd /tmp/s1-verify
   ```

3. Create the hook script and make it executable. **Note:** these commands use `printf` rather than a heredoc so they are safe to copy-paste regardless of indentation (heredoc terminators must land at column 0 in the shell, which fails when the markdown nests them under a numbered list).

   ```bash
   printf '%s\n' '#!/usr/bin/env bash' 'input=$(cat)' 'printf "%s\n" "$input" >> /tmp/uphook-test.log' 'exit 0' > /tmp/s1-verify/.claude/hooks/log-stdin.sh
   chmod +x /tmp/s1-verify/.claude/hooks/log-stdin.sh
   ```

   Verify the file is correct: `cat /tmp/s1-verify/.claude/hooks/log-stdin.sh` should print exactly 4 lines: shebang, `input=$(cat)`, the inner `printf`, `exit 0`.

4. Create the settings file using the global form from Section 2:

   ```bash
   printf '%s\n' '{' '  "hooks": {' '    "UserPromptSubmit": [' '      {' '        "hooks": [' '          {' '            "type": "command",' '            "command": "/tmp/s1-verify/.claude/hooks/log-stdin.sh"' '          }' '        ]' '      }' '    ]' '  }' '}' > /tmp/s1-verify/.claude/settings.json
   ```

   Verify it parses: `cat /tmp/s1-verify/.claude/settings.json | python3 -m json.tool` (or `jq .`) should print the JSON with no error.

5. Clear any prior log content so the test starts clean:

   ```bash
   truncate -s 0 /tmp/uphook-test.log
   ```

6. Start a fresh Claude Code session in plan mode from the test directory:

   ```bash
   cd /tmp/s1-verify && claude --permission-mode plan
   ```

   Confirm that plan mode is active before proceeding (Claude Code should indicate it in the session UI or opening message).

7. In the new Claude Code session, type any short user prompt and wait for a response. A minimal prompt works fine:

   ```
   hi
   ```

   Wait for Claude to finish responding before moving to the next step.

8. In your **original terminal** (outside the Claude Code session), inspect the log:

   ```bash
   cat /tmp/uphook-test.log
   ```

9. Examine the output:
   - Did the hook fire? (Is the log non-empty?)
   - What stdin JSON was received? (Print the full contents.)
   - Is `permission_mode` present as a field?
   - If present, what is its value? Is it `"plan"`?

---

## 5. Verdict Criteria

Apply exactly one verdict. These are mutually exclusive.

**PASS**
The log file `/tmp/uphook-test.log` is non-empty and contains a JSON entry that includes `"permission_mode": "plan"` (exact string, tolerating any whitespace around the colon or quotes — e.g., `"permission_mode":"plan"` is also a PASS).

**FAIL**
Any of the following:
- The log file is empty (the hook did not fire at all).
- The log file has content but the JSON lacks a `permission_mode` field entirely.
- The `permission_mode` field is present but its value is not `"plan"` (e.g., `"default"`, `null`, or an empty string).

**INCONCLUSIVE**
Any other anomaly, including:
- The hook fires partially or intermittently (some prompts log, others do not).
- The log file contains an error message or shell traceback rather than JSON.
- Plan mode did not actually engage despite the `--permission-mode plan` flag (e.g., Claude Code accepted the flag but ran in default mode).
- The `claude` binary was unavailable or refused to start in plan mode.

Per epic E03 line 134's fallback rule: INCONCLUSIVE is treated as FAIL by the build pipeline. S1 will fall back to preamble-only detection if the verdict is anything other than PASS.

---

## 6. Bonus Test (Optional, Informational — Not a Gate)

This is relevant to ADR-009. Skip if any complication arises; it does not affect the primary PASS/FAIL verdict.

While still in the plan-mode session from Step 6 above, ask the model to attempt calling the `ExitPlanMode` tool — for example, type:

```
Please try calling ExitPlanMode now.
```

Observe and record:
- Does it exit cleanly to default mode with no user interaction required?
- Does it present an interactive confirmation prompt the user must accept before exiting?
- Does it appear to be a no-op or unavailable (tool not found, silently ignored)?

Capture whichever outcome you see. This informs how S1 can (or cannot) use `ExitPlanMode` as a plan-mode enforcement mechanism.

---

## 7. What to Paste Back to the Build Pipeline Orchestrator

Report all three of the following:

1. **Full log contents** — the complete output of `cat /tmp/uphook-test.log` (paste even if it is empty; an empty paste is a FAIL signal).
2. **One-word verdict** — exactly one of: `PASS`, `FAIL`, or `INCONCLUSIVE`.
3. **Bonus ExitPlanMode notes** (optional) — a sentence or two on what you observed. Omit if you skipped the bonus test.

---

## 8. Cleanup

After the verdict has been reported to the build pipeline, remove the test artifacts:

```bash
rm -rf /tmp/s1-verify /tmp/uphook-test.log
```
