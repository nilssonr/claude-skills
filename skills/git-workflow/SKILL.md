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
- Doesn't exist -> ask user. If yes, check for a PR template first:
  ```bash
  # Check standard template locations
  cat .github/pull_request_template.md 2>/dev/null \
    || cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null \
    || cat docs/pull_request_template.md 2>/dev/null \
    || cat PULL_REQUEST_TEMPLATE.md 2>/dev/null
  ```
  If a template exists, read it and fill in every section. Do not skip sections or restructure the template.
  If no template exists, use the default format:
  ```bash
  git push -u origin HEAD
  gh pr create \
    --title "type(scope): description" \
    --body "$(cat <<'EOF'
  ## What

  [1-2 sentences: what this PR does]

  ## Why

  [1-2 sentences: why this change is needed]

  ## Changes

  - [concrete change 1]
  - [concrete change 2]

  ## Testing

  [how it was tested, or "N/A" if no testable behavior]
  EOF
  )"
  ```
  Title must follow conventional commit format. Body must be human-readable.
- Highlight any odd tradeoffs in the PR description.

## Branch Completion

After implementation is committed on a feature branch, present the user with next steps. Check for a remote first:

```bash
git remote 2>/dev/null | head -1
```

Present exactly these options:

- **Create PR** (only if a remote exists) -- push and open a pull request
- **Merge to main** -- rebase onto main and fast-forward merge locally
- **Discard branch** -- delete the branch and return to main

Wait for the user to choose. Then execute:

### Create PR

Check for a repository PR template first:
```bash
cat .github/pull_request_template.md 2>/dev/null \
  || cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null \
  || cat docs/pull_request_template.md 2>/dev/null \
  || cat PULL_REQUEST_TEMPLATE.md 2>/dev/null
```
If a template exists, read it and fill in every section. Do not skip sections or restructure the template.

If no template exists, use the default format:
```bash
git push -u origin HEAD
gh pr create \
  --title "type(scope): description" \
  --body "$(cat <<'EOF'
## What

[1-2 sentences: what this PR does]

## Why

[1-2 sentences: why this change is needed]

## Changes

- [concrete change 1]
- [concrete change 2]

## Testing

[how it was tested, or "N/A" if no testable behavior]
EOF
)"
```
Title follows conventional commit format. Body is composed by Claude from the actual changes -- not auto-filled from commit messages.

### Merge to main
```bash
git checkout main
git pull --rebase 2>/dev/null
git rebase main <branch> 2>/dev/null || git checkout <branch> && git rebase main
git checkout main
git merge --ff-only <branch>
git branch -d <branch>
```
If fast-forward fails, stop and tell the user -- do not force merge.

### Discard branch
```bash
git checkout main
git branch -D <branch>
```
Confirm with the user before executing. This is destructive.

## Rules
- Rebase over merge. Always.
- Check `git status` before committing.
- Small, logical commits > big batched ones.
- **After any code change is complete (implementation, fix, refactor): commit immediately.** Do not declare "Done" or present a summary without committing first. The stop-gate hook will block completion if code changes are uncommitted.
