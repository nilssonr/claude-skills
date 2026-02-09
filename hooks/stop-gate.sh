#!/usr/bin/env bash
# .claude/hooks/stop-gate.sh
# Blocks completion if tests fail or code needs review.
set -euo pipefail

input=$(cat)
stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active // false')

# Prevent infinite loop
if [ "$stop_hook_active" = "true" ]; then
  exit 0
fi

# Check for modified code files
changed=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only --cached 2>/dev/null || echo '')
code_changed=$(echo "$changed" | grep -E '\.(go|rs|ts|tsx|cs|js|jsx)$' || true)

if [ -z "$code_changed" ]; then
  exit 0
fi

# Run tests for detected stack
if [ -f 'go.mod' ]; then
  go test ./... 2>&1 | tail -5 || { echo "Go tests failing. Fix before completing." >&2; exit 2; }
fi
if [ -f 'Cargo.toml' ]; then
  cargo test 2>&1 | tail -10 || { echo "Rust tests failing. Fix before completing." >&2; exit 2; }
fi
if [ -f 'package.json' ] && grep -q '"test"' package.json 2>/dev/null; then
  npm test -- --passWithNoTests 2>&1 | tail -10 || { echo "Node tests failing. Fix before completing." >&2; exit 2; }
fi
if ls *.csproj 1>/dev/null 2>&1; then
  dotnet test --no-build 2>&1 | tail -10 || { echo ".NET tests failing. Fix before completing." >&2; exit 2; }
fi

# If tests passed but code changed, suggest self-review
echo "Tests pass. Consider running self-reviewer for semantic review: Task(subagent_type: 'self-reviewer')" >&2

exit 0
