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

## Step 1: Determine source and acquire diff

### If arguments contain a GitHub PR reference

Detect any of: `github.com/.../pull/N`, `owner/repo#N`, or `owner/repo N`.

Verify `gh` CLI is available:
```bash
gh auth status 2>/dev/null
```
If not available, stop: `gh CLI required. Install: https://cli.github.com -- then: gh auth login`

Fetch metadata:
```bash
gh pr view $PR_NUM --repo $OWNER_REPO --json \
  title,body,state,baseRefName,headRefName,\
  author,createdAt,additions,deletions,\
  changedFiles,labels,reviewDecision,commits
```

Fetch diff:
```bash
gh pr diff $PR_NUM --repo $OWNER_REPO
```

If the diff exceeds ~3000 lines or >50 files, note the constraint in the report header and triage: prioritize security-sensitive paths (auth, crypto, payment, session, middleware), files with the most changes, and error handling / API boundary files.

For files where diff context is insufficient (need surrounding function, types, callers):
```bash
gh api repos/$OWNER_REPO/contents/$FILE_PATH?ref=$HEAD_BRANCH \
  --jq '.content' | base64 -d
```
Only fetch selectively. The diff is usually enough.

**Constraint: never run `gh pr comment`, `gh pr review`, or any write command. This skill is read-only.**

Use the **GitHub PR** report header from severity-and-format.md.

### If arguments are empty or contain local paths

```bash
# Branch diff against main
git diff main...HEAD --name-only 2>/dev/null

# Or uncommitted work
git diff --name-only 2>/dev/null
git diff --cached --name-only 2>/dev/null
```

If the user specified files, constrain to those. Otherwise review all changed files.

Read each changed file in full. Read adjacent unchanged files when context is needed (callers, interfaces, types).

Use the **local review** report header from severity-and-format.md.

## Step 2: Analyze

Read `references/dimensions.md` using the Read tool. Apply every applicable dimension checklist to the acquired diff.

Read `references/severity-and-format.md` using the Read tool. Use its severity classification, output format, and rules.

### PR-level checks (GitHub PRs only)

After running the dimension checklists, evaluate and report under PR-LEVEL OBSERVATIONS:

- **PR scope**: Is this PR doing one thing? Multiple unrelated changes reduce reviewability.
- **Commit hygiene**: Do commits tell a coherent story? Fixup commits that should be squashed?
- **Description quality**: Does the PR description explain what and why?
- **Test coverage**: Are test files in the diff? Do new code paths have corresponding tests?
- **Breaking changes**: Public API, schema, config, or wire protocol changes without migration/versioning?

## Step 3: Report

Produce the structured report per severity-and-format.md. Line numbers refer to actual file line numbers (not diff hunk offsets). For GitHub PRs, use the `+` side of the diff for added-line references.
