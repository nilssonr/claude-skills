---
name: git-workflow
description: Git workflow conventions for branching, commits, and PRs. Auto-activates when performing git operations during implementation (branching, committing, creating PRs) or when executing a plan.
---

# Git Workflow

Enforces consistent git conventions for branching, commits, and pull requests.

## Activation

### Explicit
User invokes `/git-workflow`.

### Auto-detect
Activate when you observe any of:
- About to create a branch for implementation work
- About to commit changes
- About to create or update a pull request
- Executing a plan from `/plan-writer`

When auto-detecting, do not announce the skill — just follow the rules below.

## Rules

### 1. Branching
- If already on a non-primary branch (i.e. not `main`/`master`), confirm with the user and continue on that branch — do NOT create a new one
- If on a primary branch, create a new branch using `type/description` naming (e.g. `feat/add-oauth-support`, `fix/login-redirect`)
- NEVER commit directly to main/master

### 2. Commit Often
- Commit after each logical step or closely related group of changes
- Never batch an entire plan into a single commit
- Use conventional commits:
  ```
  <type>[optional scope]: <description>
  ```
  Types: feat, fix, docs, style, refactor, test, chore
  Scope clarifies the affected area, e.g. `feat(auth): add OAuth support`
  Mark breaking changes with `!` after type/scope or `BREAKING CHANGE:` in footer
- When executing a single ad-hoc request (e.g. "fix X real quick") without a multi-step plan, do NOT commit automatically — let the user decide

### 3. Pull Requests
- After all checks pass, check if a PR already exists for the current branch (e.g. `gh pr view`)
- If a PR exists, push the new commits to the branch — do NOT create a new PR
- If no PR exists, ask the user: "Would you like me to create a PR now?"
  - If yes, push the branch and create a PR with:
    - Brief overview of what was done
    - If any strange or odd trade-offs were made, highlight them and link to the relevant code
- Use rebase, never merge. Maintain a clean linear history.

### 4. General Preferences
- Always use rebase over merge
- Prefer small, logical commits over large batched ones
- Never commit on main
