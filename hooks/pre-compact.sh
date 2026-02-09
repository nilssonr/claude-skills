#!/usr/bin/env bash
# .claude/hooks/pre-compact.sh
# Saves critical context before compaction.
set -euo pipefail

cat /dev/stdin > /dev/null

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
STATUS=$(git status --porcelain 2>/dev/null | head -5)
LAST_COMMITS=$(git log --oneline -5 2>/dev/null || echo "no commits")

cat <<EOF
<pre-compaction-state>
Branch: $BRANCH
Recent commits:
$LAST_COMMITS
Uncommitted:
$STATUS
</pre-compaction-state>

Remember: check CLAUDE.md and TodoRead for current task context after compaction.
EOF
