# Severity Classification

## Levels

**[CRIT]** — Bugs, security vulnerabilities, data loss risk, race conditions, broken error handling on critical paths, breaking API changes without versioning, blocking synchronous calls in async contexts. Would cause or risk an incident in production. Must fix before merge.

**[WARN]** — Design concerns, performance issues, missing tests on critical paths, CQS violations, excessive complexity, hidden side effects, non-idiomatic patterns, consistency violations, cognitive load anti-patterns. Should be addressed before or shortly after merge.

**[INFO]** — Naming improvements, documentation gaps, minor simplification opportunities, primitive obsession in isolated cases, small closure size overruns, educational observations. Take it or leave it.

## Calibration rules

1. A typo in a log message is not [CRIT]. An SQL injection is not [INFO].
2. Downgrade one level when confidence is not high (e.g., could not verify cross-codebase pattern).
3. Unverified consistency findings cap at [WARN] regardless of apparent severity.
4. Do not upgrade severity on unverified findings.
5. When two dimensions both apply to the same finding, use the higher severity and note both dimensions.

---

# Finding Format

Each finding:

```
[SEVERITY] path/to/file.ext:LINE -- dimension: description (CWE-NNN if applicable) (unverified: reason if applicable)
  -> suggested fix, concrete and specific
```

Examples:

```
[CRIT] src/auth/login.go:142 -- security: password compared with == instead of constant-time comparison (CWE-208)
  -> replace with crypto/subtle.ConstantTimeCompare

[WARN] src/orders/service.ts:87 -- side-effects: getOrderTotal() writes to audit log, violating CQS; name implies pure query
  -> rename to recordAndReturnOrderTotal(), or extract the audit write to the caller

[WARN] src/users/repo.go:203 -- consistency: uses raw sql.Query while all peer repositories in this layer use the repository pattern (unverified: limited diff context)
  -> confirm whether this file predates the pattern or is an intentional exception; if the latter, add a comment

[INFO] src/billing/invoice.ts:34 -- cognitive-load: closure captures 6 variables from outer scope (userId, planId, startDate, endDate, currency, taxRate)
  -> extract to a named function receiving these as parameters; improves testability and reduces scope tracking overhead
```

---

# Report Structure

## Local review

```
REVIEW: [scope description]
Branch: [branch name or "working tree"]
Files reviewed: [N]
---
[findings, ordered by severity: CRIT first, then WARN, then INFO]
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
[findings, ordered by severity]
---
PR-LEVEL OBSERVATIONS:
  Scope: [one thing or multiple concerns?]
  Commits: [coherent story, or fixups that should be squashed?]
  Description: [explains what and why, or absent/vague?]
  Test coverage: [test files in diff? new paths covered?]
  Breaking changes: [any API/schema/config/protocol changes?]
---
SUMMARY: [N] critical, [N] warnings, [N] info
VERDICT: PASS | CONCERNS | FAIL
```

---

# Verdict

| Verdict | Condition |
|---|---|
| PASS | Zero critical findings, ≤ 2 warnings |
| CONCERNS | Zero critical findings, > 2 warnings OR findings requiring discussion before merge |
| FAIL | Any critical finding |

---

# Rules

1. **Be specific.** Every finding includes file, line number, dimension, description, and a concrete fix.
2. **Stay in scope.** Do not request changes to code outside the diff. File separate issues for pre-existing problems.
3. **Style is not a finding.** Formatting, whitespace, and import order belong to linters.
4. **Calibrate severity.** See calibration rules above.
5. **Maximum 30 findings.** If there are more, report the 30 highest-severity and append: `N additional lower-severity findings omitted.`
6. **Never write to GitHub.** Do not run `gh pr comment`, `gh pr review`, or any write command.
7. **Do not fabricate patterns.** If you could not verify a cross-codebase pattern with Grep/Glob, say so.
8. **A clean PASS is valid.** Do not manufacture findings to appear thorough.
