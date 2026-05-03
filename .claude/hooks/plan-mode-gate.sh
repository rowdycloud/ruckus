#!/usr/bin/env bash
# UserPromptSubmit hook: block /roughly:build and /roughly:fix when Claude Code
# plan mode is active. Plan mode substitutes its own pipeline for Roughly's,
# causing Stage 4 (/roughly:review-plan) to be silently skipped.
#
# Safety posture: this is a SAFETY GATE. On any unexpected condition (no stdin,
# malformed JSON, missing tools), the script must FAIL CLOSED — emit the block
# JSON when there's any chance plan mode is active and the prompt targets
# build/fix. A silent pass-through that opens the gate is worse than a
# false-positive block.

set -uo pipefail

stdin_json="$(cat 2>/dev/null || true)"

# No stdin at all — fail closed. We have zero information: cannot tell whether
# the prompt is a roughly invocation, cannot tell whether plan mode is active.
# Emitting a block JSON here makes any silent harness-payload-drop visible to
# the user (they see the block message and investigate) instead of letting
# the gate silently open. Direct manual invocations (debug/testing) will see
# this output too — acceptable cost for the safety guarantee.
if [ -z "$stdin_json" ]; then
  reason="Roughly plan-mode-gate received empty stdin — failing closed. If you are running this manually, pipe a JSON payload via stdin. If this fired during a real Claude Code session, your hook harness may be dropping payloads — investigate before disabling."
  printf '{"decision":"block","reason":"%s"}\n' "$reason"
  exit 0
fi

prompt=""
permission_mode=""

# Try jq first; fall back to grep-based parsing on any failure.
parsed_with_jq=0
if command -v jq >/dev/null 2>&1; then
  if jq_prompt="$(printf '%s' "$stdin_json" | jq -r '.prompt // ""' 2>/dev/null)" \
     && jq_mode="$(printf '%s' "$stdin_json" | jq -r '.permission_mode // ""' 2>/dev/null)"; then
    prompt="$jq_prompt"
    permission_mode="$jq_mode"
    parsed_with_jq=1
  fi
fi

if [ "$parsed_with_jq" = "0" ]; then
  # Fallback: regex on raw JSON, tolerant of whitespace and basic escaping.
  # The prompt-end character class [^a-zA-Z0-9] rejects /roughly:builder,
  # /roughly:building, etc. — matches only /roughly:build or /roughly:fix
  # followed by a word boundary (space, quote, etc.).
  if printf '%s' "$stdin_json" | grep -qE '"permission_mode"[[:space:]]*:[[:space:]]*"plan"'; then
    permission_mode="plan"
  fi
  if printf '%s' "$stdin_json" | grep -qE '"prompt"[[:space:]]*:[[:space:]]*"/roughly:(build|fix)[^a-zA-Z0-9]'; then
    prompt="/roughly:build-or-fix"  # placeholder — only used to pass the next check
  fi
fi

# Short-circuit cheaply on non-roughly prompts. Empty prompt also short-circuits
# (we only block specific commands, never block by mode alone). The pattern
# requires the command to be exactly /roughly:build or /roughly:fix, optionally
# followed by a space and arguments — rejects /roughly:builder etc.
case "$prompt" in
  "/roughly:build"|"/roughly:build "*|"/roughly:fix"|"/roughly:fix "*|"/roughly:build-or-fix") ;;  # continue
  *) exit 0 ;;
esac

# Only block when plan mode is active.
if [ "$permission_mode" != "plan" ]; then
  exit 0
fi

# Emit block decision. printf fallback ensures we NEVER silently pass through
# when both prompt-match and plan-mode are confirmed.
reason="Roughly pipelines cannot run while Claude Code's plan mode is active. Exit plan mode (Shift+Tab in terminal, or your client's plan-mode toggle) and re-invoke."
if command -v jq >/dev/null 2>&1; then
  jq -nc --arg r "$reason" '{"decision":"block","reason":$r}' 2>/dev/null \
    || printf '{"decision":"block","reason":"%s"}\n' "$reason"
elif command -v python3 >/dev/null 2>&1; then
  python3 -c 'import json,sys; print(json.dumps({"decision":"block","reason":sys.argv[1]}))' "$reason" 2>/dev/null \
    || printf '{"decision":"block","reason":"%s"}\n' "$reason"
else
  # No encoder available — emit a hand-built JSON. The reason text contains no
  # characters that need JSON escaping under this exact usage.
  printf '{"decision":"block","reason":"%s"}\n' "$reason"
fi

exit 0
