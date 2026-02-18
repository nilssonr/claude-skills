---
name: review
description: Structured code review with [CRIT]/[WARN]/[INFO] severity report. Reviews local changes (git diff) or remote GitHub PRs (via gh CLI). Language-agnostic, advisory-only, never posts to GitHub. Use /review for local, /review [url] for PRs.
context: fork
agent: code-reviewer
---

# Code Review

**Announce at start:** `[SKILL:review] Reviewing [scope].`

## Activation

- `/review` -- review local changes (branch diff or working tree)
- `/review https://github.com/owner/repo/pull/123` -- review a GitHub PR
- `/review owner/repo#123` -- shorthand for GitHub PR
- `/review path/to/file.ts` -- review a specific file
- After TDD COMMIT phase (optional verification step)

## Step 1: Acquire and Route

### Determine source

**GitHub PR** (arguments contain `github.com/.../pull/N`, `owner/repo#N`, or `owner/repo N`):

Verify `gh` CLI is available:
```bash
gh auth status 2>/dev/null
```
If not available, stop: `gh CLI required. Install: https://cli.github.com -- then: gh auth login`

Fetch metadata and line-numbered diff in parallel (two Bash calls in a single response):
```bash
gh pr view $PR_NUM --repo $OWNER_REPO --json \
  title,body,state,baseRefName,headRefName,\
  author,createdAt,additions,deletions,\
  changedFiles,labels,reviewDecision,commits
```
```bash
gh pr diff $PR_NUM --repo $OWNER_REPO | awk '
/^diff |^index |^--- / { print; next }
/^\+\+\+ /             { print; next }
/^@@ / { split($3,a,/[+,]/); nr=a[2]+0; print; next }
/^-/   { print; next }
       { printf "%d\t%s\n", nr, $0; nr++ }
'
```
The awk script annotates every context and added line with its actual file line number (derived from `@@` hunk headers). Removed lines (`-`) are not numbered. Use these prefixed numbers as the canonical line reference in all findings.

Use the **GitHub PR** report header from `references/severity-and-format.md`.

**Local** (arguments are empty or contain local paths):

```bash
# Branch diff against main (with line numbers)
git diff main...HEAD 2>/dev/null | awk '
/^diff |^index |^--- / { print; next }
/^\+\+\+ /             { print; next }
/^@@ / { split($3,a,/[+,]/); nr=a[2]+0; print; next }
/^-/   { print; next }
       { printf "%d\t%s\n", nr, $0; nr++ }
'

# Or uncommitted work (same awk pipeline)
git diff 2>/dev/null | awk '...'       # unstaged
git diff --cached 2>/dev/null | awk '...'  # staged
```

If the user specified files, constrain with `-- path/to/file`. Otherwise review all changed files.

Use the **local review** report header from `references/severity-and-format.md`.

### Measure scope and route

Count changed files and total diff lines.

- **Small review** (<=20 files AND <=3000 diff lines): dispatch a single `code-reviewer` agent with the full diff.
- **Large review** (>20 files OR >3000 diff lines): fan-out (see below).

### Fan-out strategy (large reviews)

Group changed files:
- Group 1: Security-sensitive paths (auth, crypto, payment, session, middleware)
- Groups 2-N: Remaining files grouped by directory, max 15 files per group

Dispatch one `code-reviewer` agent per group (all in parallel via multiple Task calls). Each agent receives:
- Its file list
- The diff for those files (plus 10 lines of surrounding context)
- A note that it is reviewing a subset

After all agents return, merge findings:
1. Deduplicate (same file:line, same dimension)
2. Rank by severity
3. Enforce 30-finding cap (highest severity kept)
4. Note omissions if any

## Step 2: Analyze

The code-reviewer agent reads `references/dimensions.md` and `references/severity-and-format.md`, then applies every applicable dimension checklist.

### PR-level checks (GitHub PRs only)

After the code-reviewer returns, evaluate and add under PR-LEVEL OBSERVATIONS:

- **PR scope**: Is this PR doing one thing? Multiple unrelated changes reduce reviewability.
- **Commit hygiene**: Do commits tell a coherent story? Fixup commits that should be squashed?
- **Description quality**: Does the PR description explain what and why?
- **Test coverage**: Are test files in the diff? Do new code paths have corresponding tests?
- **Breaking changes**: Public API, schema, config, or wire protocol changes without migration/versioning?

## Step 3: Report

Produce the structured report per `references/severity-and-format.md`. Line numbers in findings come from the annotated diff prefix -- they are already actual file line numbers.

**Constraint: never run `gh pr comment`, `gh pr review`, or any write command. This skill is read-only.**
