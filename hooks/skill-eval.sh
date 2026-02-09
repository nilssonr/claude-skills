#!/usr/bin/env bash
# .claude/hooks/skill-eval.sh
# Forces skill evaluation on every user prompt.
set -euo pipefail

cat /dev/stdin > /dev/null  # consume stdin

cat <<'EOF'
BEFORE responding, quickly evaluate: does this request match a skill?
- requirements/planning/new feature → requirements-gatherer
- writing tests first / TDD → tdd
- git commit/branch/PR → git-workflow
- debugging / fix failed → troubleshoot
- something went wrong → retro
If YES → follow the skill. If NO → proceed normally.
EOF
