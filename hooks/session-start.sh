#!/usr/bin/env bash
# .claude/hooks/session-start.sh
# Injected into context on startup, resume, clear, and compact.
set -euo pipefail

cat /dev/stdin > /dev/null  # consume stdin

# Project context
BRANCH=$(git branch --show-current 2>/dev/null || echo "no-git")
COMMIT=$(git log --oneline -1 2>/dev/null || echo "no commits")
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
STACK=""
[ -f go.mod ] && STACK="$STACK Go"
[ -f Cargo.toml ] && STACK="$STACK Rust"
[ -f angular.json ] && STACK="$STACK Angular"
[ -f package.json ] && STACK="$STACK Node/TS"
[ -n "$(ls *.csproj 2>/dev/null)" ] && STACK="$STACK C#"
STACK=$(echo "$STACK" | xargs)  # trim

cat <<EOF
<project-context>
Branch: $BRANCH | Last commit: $COMMIT | Uncommitted files: $DIRTY
Stack: ${STACK:-unknown}
</project-context>

<skill-reminder>
Before responding, check if a skill applies:
- New work → /gather (requirements-gatherer)
- Code with tests → /tdd
- Git ops → git-workflow (auto)
- Debugging → troubleshoot (auto)
- Session end → /retro
If none apply, proceed normally.
</skill-reminder>
EOF
