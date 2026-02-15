#!/usr/bin/env bash
# .claude/hooks/skill-eval.sh
# Forces skill evaluation on every user prompt.
# Includes complexity gate: targeted fixes skip requirements-gatherer.
set -euo pipefail

input=$(cat)

# Extract the user's prompt text from the hook JSON
prompt=$(echo "$input" | jq -r '.prompt // .message // empty' 2>/dev/null || echo "")

# Complexity gate: if prompt references a specific file path with line number
# or extension, it's a targeted fix — don't suggest requirements-gatherer.
is_targeted=false
if echo "$prompt" | grep -qE '\.[a-z]{1,4}:[0-9]+|line [0-9]+|\.ts\b|\.go\b|\.rs\b|\.cs\b' 2>/dev/null; then
  is_targeted=true
fi

if [ "$is_targeted" = "true" ]; then
  cat <<'EOF'
BEFORE responding, quickly evaluate: does this request match a skill?
This looks like a TARGETED FIX (specific file/line referenced).
- Do NOT use requirements-gatherer for targeted fixes. Proceed directly.
- If this is a multi-file change or has unclear scope, use /requirements-gatherer instead.
- writing tests first / TDD → tdd
- git commit/branch/PR → git-workflow (auto-commits after implementation)
- debugging / fix failed → troubleshoot
- Temporal workflows → /temporal
- Frontend UI → /frontend-design
- something went wrong → retro
If NO skill matches → implement directly. git-workflow will handle the commit.
EOF
else
  cat <<'EOF'
BEFORE responding, quickly evaluate: does this request match a skill?
- new feature / unclear scope / multi-file → /requirements-gatherer
- writing tests first / TDD → tdd
- git commit/branch/PR → git-workflow
- debugging / fix failed → troubleshoot
- Temporal workflows → /temporal
- Frontend UI → /frontend-design
- something went wrong → retro
If YES → follow the skill. If NO → proceed normally.
EOF
fi
