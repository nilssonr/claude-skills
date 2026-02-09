#!/usr/bin/env bash
# .claude/hooks/commit-validator.sh
# Validates conventional commit format before git commit executes.
set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only intercept git commit commands
if [[ ! "$command" == *"git commit"* ]] || [[ ! "$command" == *"-m"* ]]; then
  exit 0
fi

# Extract commit message (handles both single and double quotes)
msg=$(echo "$command" | grep -oP '(?<=-m\s?["\x27])[^"\x27]+' | head -1)

if [ -z "$msg" ]; then
  exit 0
fi

# Validate conventional commit format
if [[ ! "$msg" =~ ^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?\!?:\ .+ ]]; then
  echo "Commit message must follow conventional commits: type(scope): description" >&2
  echo "Types: feat, fix, docs, style, refactor, test, chore" >&2
  echo "Got: $msg" >&2
  exit 2
fi

# Block commits to main/master
branch=$(git branch --show-current 2>/dev/null || echo "unknown")
if [[ "$branch" == "main" || "$branch" == "master" ]]; then
  echo "Cannot commit directly to $branch. Create a feature branch first." >&2
  exit 2
fi

exit 0
