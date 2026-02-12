---
name: git-workflow
description: Git conventions for branching, commits, and PRs. Auto-activates on git operations. Enforced by PreToolUse hook for commit message validation.
---

# Git Workflow

**Announce at start:** `[SKILL:git-workflow] Active for [operation].`

Auto-activates when performing git operations. Follow the rules below.

## Branching
- On main/master -> create `type/description` branch (e.g. `feat/add-oauth`)
- Already on feature branch -> confirm and continue. Don't create nested branches.
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

- Ad-hoc one-off requests ("fix X real quick") -> don't auto-commit. Let user decide.

## Pushing
- After rebase: `git push --force-with-lease` (NEVER `--force`)
- If rejected: someone else pushed. Fetch and re-examine.
- After any push to a feature branch, check for an existing PR:
  ```bash
  gh pr view --json state,url 2>/dev/null
  ```
  - PR exists and open: note the PR URL. The push updated it.
  - PR exists but merged/closed: inform the user. Do nothing.
  - No PR: offer to create one. If yes, follow the Pull Requests section.

## Pull Requests

- Check if PR exists: `gh pr view 2>/dev/null`
- Exists -> push new commits. Don't create another.
- Doesn't exist -> ask user. If yes:

Launch `pr-composer` (Task tool, subagent_type: general-purpose, model: haiku) with the branch name and base branch. The agent reads the PR template (if any), git log, and diff summary, then returns a composed title and body.

Parse the agent's output and run:
```bash
git push -u origin HEAD
gh pr create --title "<title from agent>" --body "<body from agent>"
```

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

Launch `pr-composer` as described in the Pull Requests section. Use its output for `gh pr create`.

### Merge to main

First, check for an open PR on this branch:
```bash
gh pr view --json state,number 2>/dev/null
```

**If an open PR exists**, merge via GitHub:
```bash
gh pr merge <number> --delete-branch
```
Ask the user for merge strategy: `--merge`, `--squash`, or `--rebase`. Do not choose silently.

**If no PR exists**, merge locally:
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
