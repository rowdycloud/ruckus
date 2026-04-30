#!/usr/bin/env bash
# Stop hook: structural verify-all for the ruckus plugin.
# Fires after every Claude turn. Non-blocking — informational only.
# Outputs JSON with systemMessage when drift is detected; silent otherwise.

set -e
shopt -s nullglob  # globs that match nothing expand to empty, not literal pattern

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$ROOT" ] || [ ! -f "$ROOT/.claude-plugin/plugin.json" ]; then
  exit 0  # not in the ruckus repo — silent no-op
fi
cd "$ROOT"

issues=""

# Path drift: agents/ should not reference legacy .ruckus/known-pitfalls
if rg -q '\.ruckus/known-pitfalls' agents/ 2>/dev/null; then
  issues="${issues}- stale .ruckus/known-pitfalls reference in agents/ (S2.3 drift)\n"
fi

# Skill line cap (300)
for f in skills/*/SKILL.md; do
  n=$(wc -l < "$f")
  [ "$n" -gt 300 ] && issues="${issues}- $f: $n lines exceeds 300 cap\n"
done

# Agent word cap (500)
for f in agents/*.md; do
  n=$(wc -w < "$f")
  [ "$n" -gt 500 ] && issues="${issues}- $f: $n words exceeds 500 cap\n"
done

# HTML comment integrity in agent-preamble.md
preamble="agents/agent-preamble.md"
opens=$(grep -c '<!--' "$preamble" 2>/dev/null || echo 0)
closes=$(grep -c '\-\->' "$preamble" 2>/dev/null || echo 0)
if [ "$opens" != "1" ] || [ "$closes" != "1" ]; then
  issues="${issues}- agent-preamble.md HTML comment broken: $opens openers, $closes closers\n"
fi

emit_drift_json() {
  local m="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -nc --arg m "$m" '{systemMessage: $m}'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; print(json.dumps({"systemMessage": sys.argv[1]}))' "$m"
  fi
  # If neither is available, drop the structured output rather than emit
  # malformed JSON. The hook still exits 0 below; drift is detected on
  # the next run when a JSON encoder is available.
}

if [ -n "$issues" ]; then
  msg=$(printf 'verify-all drift detected:\n%b' "$issues")
  emit_drift_json "$msg" || true
fi
exit 0
