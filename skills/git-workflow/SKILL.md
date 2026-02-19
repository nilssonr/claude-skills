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

## Worktrees

Worktrees enable parallel Claude Code sessions. Each worktree is a separate checkout on its own branch, sharing git history with the main checkout.

### Create

When the user requests a worktree (e.g., "create a worktree for oauth", "set up a parallel session for the payment refactor"):

```bash
# Derive paths
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
BRANCH_NAME="type/description"  # same convention as Branching
WORKTREE_DIR="../${REPO_NAME}-${BRANCH_NAME##*/}"

# Create worktree with new branch
git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" main
```

The worktree directory is created as a sibling of the repo root (e.g., `../myapp-add-oauth`). This keeps worktrees out of the repo itself.

After creation, bootstrap the environment:

```bash
# Copy env file if it exists
[[ -f .env ]] && cp .env "$WORKTREE_DIR/.env"

# Stack-specific setup (run whichever apply)
[[ -f "$WORKTREE_DIR/package.json" ]] && (cd "$WORKTREE_DIR" && npm install --silent)
[[ -f "$WORKTREE_DIR/go.mod" ]] && (cd "$WORKTREE_DIR" && go mod download)
[[ -f "$WORKTREE_DIR/*.csproj" ]] && (cd "$WORKTREE_DIR" && dotnet restore --verbosity quiet)
```

If the user specifies a port (e.g., "use port 3001"), write or update `PORT=` in the worktree's `.env`.

After setup, tell the user:

```
Worktree ready: ../myapp-add-oauth (branch: feat/add-oauth)
To start a parallel session: cd ../myapp-add-oauth && claude
```

### List

```bash
git worktree list
```

### Remove

After work is merged or discarded:

```bash
git worktree remove "../${WORKTREE_DIR}"
git branch -d "$BRANCH_NAME"  # or -D if unmerged and user confirms
```

Always confirm with the user before removing. Check if the branch has unmerged changes first:

```bash
git branch --no-merged main | grep "$BRANCH_NAME"
```

If unmerged, warn the user and require explicit confirmation.

### Rules

- Each worktree gets its own branch. Never check out the same branch in two worktrees.
- Worktrees are siblings of the repo root, not subdirectories within it.
- All other git-workflow rules (conventional commits, rebase over merge, small logical commits) apply equally in worktrees.
- The `/resume` picker in Claude Code shows sessions across all worktrees of the same repo.

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
- **MANDATORY: After EVERY push to a feature branch**, run:
  ```bash
  gh pr view --json state,url 2>/dev/null
  ```
  This is NOT optional. User saying "push" does NOT skip this step -- it is part of the push workflow.
  - PR exists and open: note the PR URL. The push updated it.
  - PR exists but merged/closed: inform the user. Do nothing.
  - No PR: offer to create one. If yes, follow the Pull Requests section.
- **When user says "merge" and a PR is open**: ALWAYS use `gh pr merge`, not local `git merge`. The PR is the active context. Only do a local merge if explicitly requested or if no PR exists.

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

Detect if currently in a worktree:

```bash
git rev-parse --git-common-dir 2>/dev/null | grep -q "\.git/worktrees" && echo "worktree" || echo "main checkout"
```

Present exactly these options:

- **Create PR** (only if a remote exists) -- push and open a pull request
- **Merge to main** -- rebase onto main and fast-forward merge locally
- **Discard branch** -- delete the branch and return to main
- **Remove worktree** (only if currently in a worktree) -- remove the worktree and optionally delete the branch

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

### Remove worktree

Only shown when the current checkout is a worktree. Run the cleanup from the Worktrees section:

```bash
WORKTREE_DIR=$(git rev-parse --show-toplevel)
BRANCH_NAME=$(git branch --show-current)

# Navigate out of the worktree first
cd "$(git rev-parse --git-common-dir | sed 's|/\.git/worktrees/.*|/|')"

# Remove worktree and branch
git worktree remove "$WORKTREE_DIR"
git branch -d "$BRANCH_NAME"  # or -D if unmerged and user confirms
```

If the branch has unmerged changes (`git branch --no-merged main | grep "$BRANCH_NAME"`), warn the user and require explicit confirmation before using `-D`.

## Rules
- Rebase over merge. Always.
- Check `git status` before committing.
- Small, logical commits > big batched ones.
- **After any code change is complete (implementation, fix, refactor): commit immediately.** Do not declare "Done" or present a summary without committing first. The stop-gate hook will block completion if code changes are uncommitted.
