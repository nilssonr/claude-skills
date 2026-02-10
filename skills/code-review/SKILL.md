---
name: code-review
description: Structured code review skill producing a grepable report with [CRIT]/[WARN]/[INFO] severity tags. Language-agnostic, advisory-only. Covers correctness, security, performance, error handling, readability, consistency, defensiveness, testability, and API design. Invoked via /review or after TDD/implementation completion.
---

# Code Review

**Announce at start:** `[SKILL:code-review] Reviewing [scope].`

## Activation

- User invokes `/review`
- User asks for a review of changes, a file, or a branch
- After TDD COMMIT phase (optional verification step)
- After any implementation task where quality verification is warranted

## Scope

Determine what to review:

```bash
# If on a branch, diff against main
git diff main...HEAD --name-only 2>/dev/null

# If no branch (uncommitted work), diff working tree
git diff --name-only 2>/dev/null
git diff --cached --name-only 2>/dev/null
```

If the user specified files or concerns, constrain to those. Otherwise review all changed files.

Read each changed file in full. Read adjacent unchanged files when needed to understand context (callers, interfaces, types).

## Review order

Follow the Code Review Pyramid — spend the most analysis time on what matters most, the least on what linters handle:

1. **Correctness** — Does it work? Logic errors, edge cases, invariants.
2. **Security** — Is it safe? Injection, auth, secrets, trust boundaries.
3. **Error handling** — Does it fail well? Swallowed errors, missing context, crash vs degrade.
4. **Performance** — Is it efficient? N+1, unbounded ops, blocking in async.
5. **Defensiveness** — Is it robust? Input validation, contracts, resource cleanup.
6. **Readability** — Is it understandable? Complexity, naming, nesting, length.
7. **Testability** — Is it testable? Coupling, hidden deps, global state, coverage.
8. **Consistency** — Does it fit? Codebase conventions, patterns, abstraction levels.
9. **API design** — Is the interface sound? Backward compat, idempotency, naming.

Style issues (formatting, whitespace, import order) are not review findings. They belong to linters and auto-formatters.

## Dimension checklists

Work through each dimension. Not every check applies to every diff. Skip dimensions that have zero findings. Never fabricate findings to fill a report.

### 1. Correctness

- Off-by-one errors in loops, slices, indexes, ranges
- Null/nil/undefined handling at API boundaries and return values
- Boundary conditions: empty collections, zero-length strings, max/min values, single-element inputs
- Logic errors: wrong boolean operators, De Morgan violations, operator precedence mistakes
- Race conditions: shared mutable state without synchronization, TOCTOU
- Deadlock risk: inconsistent lock ordering, holding locks across I/O
- Resource leaks: unclosed handles, missing finally/defer/using, early returns bypassing cleanup
- Integer overflow/underflow in arithmetic, especially on user-supplied values
- Every return value checked. Every code path returns or throws.

### 2. Security

Map findings to CWE numbers when applicable.

- Injection: string concatenation in SQL, OS commands, LDAP, XPath (CWE-89, CWE-78)
- XSS: unencoded user input in HTML/JS output (CWE-79)
- Auth/authz: missing authorization checks, IDOR without ownership validation (CWE-862, CWE-863)
- Secrets: hardcoded credentials, API keys, tokens in source (CWE-798)
- Cryptography: deprecated algorithms (MD5, SHA1, DES, RC4), non-CSPRNG random, timing-unsafe comparison
- Deserialization: untrusted data into ObjectInputStream, pickle, unserialize (CWE-502)
- Path traversal: user input in file paths without canonicalization (CWE-22)
- SSRF: user-controlled URLs in server-side requests (CWE-918)
- Missing CSRF protection on state-changing endpoints (CWE-352)
- Sensitive data in logs, error messages, or stack traces

### 3. Error handling

- Swallowed errors: empty catch/except blocks, ignored return values = [CRIT]
- Missing error context: bare re-throw or return without wrapping = [WARN]
- Overly broad catches: catching base Exception/Error type = [WARN]
- Panic/crash on expected conditions: reserve crash for invariant violations only
- Retry without backoff: retries on transient failures must use exponential backoff + jitter + max attempts
- Error type confusion: infrastructure errors leaking to users, domain errors lost in translation
- Fail-fast principle: detect and report errors immediately, do not accumulate

### 4. Performance

- N+1 queries: database/API call inside a loop iterating over query results = [CRIT]
- O(n^2) hidden in nested loops: .find/.filter/.includes/.indexOf inside a loop = [WARN]
- Unbounded allocations: SELECT without LIMIT, loading full datasets, missing pagination = [WARN]
- Synchronous blocking in async: blocking calls in event loops or async handlers = [CRIT]
- Missing caching: repeated expensive computation or I/O for identical inputs
- Unnecessary serialization/deserialization in hot paths
- String concatenation in tight loops (use builders/buffers)

### 5. Defensiveness

- Input validation at trust boundaries: type, range, length, format
- Allowlist over denylist for input validation
- Preconditions checked at function entry (fail fast)
- Resources acquired in matching pairs: open/close, lock/unlock, begin/commit
- Timeouts on all external calls (HTTP, DB, file I/O, locks)
- Immutable data preferred where thread safety matters
- Default/fallback cases in switch/match statements

### 6. Readability

Apply these thresholds as heuristics, not laws:

- Cyclomatic complexity: <=10 acceptable, 11-15 [INFO], 16-20 [WARN], >20 [CRIT]
- Cognitive complexity (nesting-aware): <=15 acceptable, >15 [WARN]
- Function length: <=40 lines acceptable, 41-60 [INFO], 61-100 [WARN], >100 [CRIT]
- Nesting depth: <=3 levels acceptable, 4 [WARN], >4 [CRIT]
- Naming: functions describe actions, variables describe content, booleans read as predicates
- Comments explain WHY, not WHAT. Code requiring WHAT comments should be simplified.
- Principle of least surprise: function does exactly what its name suggests, no hidden side effects

### 7. Testability

- Constructor does real work (I/O, complex logic, deep object graphs)
- Law of Demeter violations: long method chains coupling to internal structure
- Global state or singletons creating hidden dependencies
- Class does too much (needs "and" to describe its purpose = SRP violation)
- Critical paths untested: auth, payment, data mutation, error recovery
- Tests test implementation details instead of behavior (brittle)

### 8. Consistency

- New code matches existing codebase patterns for: error handling, naming, DI, file structure
- DRY: code repeated 3+ times should be extracted (but premature abstraction is worse than duplication)
- Abstraction level: functions at the same level of abstraction within a module
- Style guide conformance (defer to whatever linter/formatter the project uses)

### 9. API design

Only when the diff modifies public APIs, endpoints, or interfaces:

- Backward compatibility: removed/renamed fields, changed types, new required parameters are breaking
- Idempotency: PUT replaces fully, POST supports idempotency keys for retry safety
- Naming: consistent with existing API surface, predictable from domain
- Error responses: structured (not string-only), stable format, include enough context for callers
- Hyrum's Law awareness: minimize observable surface area, don't expose internals

## Severity classification

[CRIT] — Bugs, security vulnerabilities, data loss risk, race conditions, broken error handling on critical paths, breaking API changes. Would cause an incident in production.

[WARN] — Design concerns, performance issues, missing tests, excessive complexity, non-idiomatic patterns, potential maintenance burden. Should be addressed before or shortly after merge.

[INFO] — Naming improvements, documentation gaps, minor simplification opportunities, educational observations. Take it or leave it.

## Output format

```
REVIEW: [scope description]
Branch: [branch name]
Files reviewed: [count]
---

[CRIT] path/to/file.ts:42 — [dimension]: [description] (CWE-NNN if applicable)
  -> [suggested fix, concrete and specific]

[WARN] path/to/other.go:118 — [dimension]: [description]
  -> [suggested fix]

[INFO] path/to/util.rs:7 — [dimension]: [description]
  -> [suggestion]

---
SUMMARY: [N] critical, [N] warnings, [N] info
VERDICT: PASS | CONCERNS | FAIL

  PASS     — Zero critical, <=2 warnings. Ship it.
  CONCERNS — Zero critical, >2 warnings OR findings that need discussion. Address before merge.
  FAIL     — Any critical finding. Must fix.
```

## Rules

1. Be specific. Every finding includes: file, line number, dimension, description, and a concrete fix.
2. Never fabricate findings. If the code is good, report PASS with zero findings. A clean review is a valid and good outcome.
3. Read the actual code. Do not guess or infer from file names alone.
4. Stay in scope. Do not request changes to code outside the diff. File separate issues for pre-existing problems.
5. Style is not a review finding. Formatting, whitespace, and import order belong to linters.
6. Severity must be calibrated. A typo in a log message is not [CRIT]. An SQL injection is not [INFO]. If uncertain, downgrade one level.
7. The review is advisory. Present findings with clear reasoning. The developer decides what to fix.
8. Maximum 15 findings. If there are more, report the 15 highest-severity ones and note "N additional lower-severity findings omitted."
9. Do not bikeshed. If you catch yourself writing about variable naming while ignoring a race condition, reprioritize.
10. When the code improves overall system health — even if imperfect — say so.
