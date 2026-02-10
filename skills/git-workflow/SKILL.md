---
name: git-workflow
description: Git conventions for branching, commits, and PRs. Auto-activates on git operations. Enforced by PreToolUse hook for commit message validation.
---

# Git Workflow

**Announce at start:** `[SKILL:git-workflow] Active for [operation].`

Auto-activates when performing git operations. Follow the rules below.

## Branching
- On main/master → create `type/description` branch (e.g. `feat/add-oauth`)
- Already on feature branch → confirm and continue. Don't create nested branches.
- NEVER commit to main/master.

## Commits
- Commit after each logical step. Never batch a whole plan into one commit.
- Use conventional commits:
  ```
  type(scope): description
  ```
  Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
  Breaking changes: `feat(auth)!: remove password login`

- Use HEREDOC to avoid escaping issues:
  ```bash
  git commit -m "$(cat <<'EOF'
  feat(auth): add OAuth2 PKCE flow

  Implements authorization code flow with PKCE for public clients.
  EOF
  )"
  ```

- Ad-hoc one-off requests ("fix X real quick") → don't auto-commit. Let user decide.

## Pushing
- After rebase: `git push --force-with-lease` (NEVER `--force`)
- If rejected: someone else pushed. Fetch and re-examine.

## Pull Requests
- Check if PR exists: `gh pr view 2>/dev/null`
- Exists → push new commits. Don't create another.
- Doesn't exist → ask user. If yes:
  ```bash
  git push -u origin HEAD
  gh pr create --fill
  ```
- Highlight any odd tradeoffs in the PR description.

## Rules
- Rebase over merge. Always.
- Check `git status` before committing.
- Small, logical commits > big batched ones.
- **After any code change is complete (implementation, fix, refactor): commit immediately.** Do not declare "Done" or present a summary without committing first. The stop-gate hook will block completion if code changes are uncommitted.
