# Severity Classification

[CRIT] -- Bugs, security vulnerabilities, data loss risk, race conditions, broken error handling on critical paths, breaking API changes. Would cause an incident in production.

[WARN] -- Design concerns, performance issues, missing tests, excessive complexity, non-idiomatic patterns, potential maintenance burden. Should be addressed before or shortly after merge.

[INFO] -- Naming improvements, documentation gaps, minor simplification opportunities, educational observations. Take it or leave it.

# Verdict

PASS     -- Zero critical, <=2 warnings. Ship it.
CONCERNS -- Zero critical, >2 warnings OR findings that need discussion. Address before merge.
FAIL     -- Any critical finding. Must fix.

# Output Format

Each finding follows this structure:

```
[SEVERITY] path/to/file.ext:LINE -- dimension: description (CWE-NNN if applicable)
  -> suggested fix, concrete and specific
```

# Report Structure

## Local review (git diff)

```
REVIEW: [scope description]
Branch: [branch name]
Files reviewed: [count]
---

[findings]

---
SUMMARY: [N] critical, [N] warnings, [N] info
VERDICT: PASS | CONCERNS | FAIL
```

## GitHub PR review

```
REVIEW: [PR title]
PR: [owner/repo#number]
Author: [author]
Branch: [head] -> [base]
Changed: [N] files, +[additions] -[deletions]
URL: [full PR URL]
---

[findings]

---
PR-LEVEL OBSERVATIONS:
  [scope, commits, description, coverage, breaking change observations -- if any]

---
SUMMARY: [N] critical, [N] warnings, [N] info
VERDICT: PASS | CONCERNS | FAIL
```

# Rules

1. Be specific. Every finding includes: file, line number, dimension, description, and a concrete fix.
2. Stay in scope. Do not request changes to code outside the diff. File separate issues for pre-existing problems.
3. Style is not a review finding. Formatting, whitespace, and import order belong to linters.
4. Severity must be calibrated. A typo in a log message is not [CRIT]. An SQL injection is not [INFO]. If uncertain, downgrade one level.
5. Maximum 15 findings. If there are more, report the 15 highest-severity ones and note "N additional lower-severity findings omitted."
