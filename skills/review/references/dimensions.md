# Review Dimensions

Work through each dimension in order. Not every check applies to every diff. Skip dimensions with zero findings. Never fabricate findings.

## 1. Correctness

- Off-by-one errors in loops, slices, indexes, ranges
- Null/nil/undefined handling at API boundaries and return values
- Boundary conditions: empty collections, zero-length strings, max/min values, single-element inputs
- Logic errors: wrong boolean operators, De Morgan violations, operator precedence mistakes
- Race conditions: shared mutable state without synchronization, TOCTOU
- Deadlock risk: inconsistent lock ordering, holding locks across I/O
- Resource leaks: unclosed handles, missing finally/defer/using, early returns bypassing cleanup
- Integer overflow/underflow in arithmetic, especially on user-supplied values
- Every return value checked. Every code path returns or throws.

## 2. Security

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

## 3. Error handling

- Swallowed errors: empty catch/except blocks, ignored return values = [CRIT]
- Missing error context: bare re-throw or return without wrapping = [WARN]
- Overly broad catches: catching base Exception/Error type = [WARN]
- Panic/crash on expected conditions: reserve crash for invariant violations only
- Retry without backoff: retries on transient failures must use exponential backoff + jitter + max attempts
- Error type confusion: infrastructure errors leaking to users, domain errors lost in translation
- Fail-fast principle: detect and report errors immediately, do not accumulate

## 4. Performance

- N+1 queries: database/API call inside a loop iterating over query results = [CRIT]
- O(n^2) hidden in nested loops: .find/.filter/.includes/.indexOf inside a loop = [WARN]
- Unbounded allocations: SELECT without LIMIT, loading full datasets, missing pagination = [WARN]
- Synchronous blocking in async: blocking calls in event loops or async handlers = [CRIT]
- Missing caching: repeated expensive computation or I/O for identical inputs
- Unnecessary serialization/deserialization in hot paths
- String concatenation in tight loops (use builders/buffers)

## 5. Defensiveness

- Input validation at trust boundaries: type, range, length, format
- Allowlist over denylist for input validation
- Preconditions checked at function entry (fail fast)
- Resources acquired in matching pairs: open/close, lock/unlock, begin/commit
- Timeouts on all external calls (HTTP, DB, file I/O, locks)
- Immutable data preferred where thread safety matters
- Default/fallback cases in switch/match statements

## 6. Readability

Apply these thresholds as heuristics, not laws:

- Cyclomatic complexity: <=10 acceptable, 11-15 [INFO], 16-20 [WARN], >20 [CRIT]
- Cognitive complexity (nesting-aware): <=15 acceptable, >15 [WARN]
- Function length: <=40 lines acceptable, 41-60 [INFO], 61-100 [WARN], >100 [CRIT]
- Nesting depth: <=3 levels acceptable, 4 [WARN], >4 [CRIT]
- Naming: functions describe actions, variables describe content, booleans read as predicates
- Comments explain WHY, not WHAT. Code requiring WHAT comments should be simplified.
- Principle of least surprise: function does exactly what its name suggests, no hidden side effects

## 7. Testability

- Constructor does real work (I/O, complex logic, deep object graphs)
- Law of Demeter violations: long method chains coupling to internal structure
- Global state or singletons creating hidden dependencies
- Class does too much (needs "and" to describe its purpose = SRP violation)
- Critical paths untested: auth, payment, data mutation, error recovery
- Tests test implementation details instead of behavior (brittle)

## 8. Consistency

- New code matches existing codebase patterns for: error handling, naming, DI, file structure
- DRY: code repeated 3+ times should be extracted (but premature abstraction is worse than duplication)
- Abstraction level: functions at the same level of abstraction within a module
- Style guide conformance (defer to whatever linter/formatter the project uses)

## 9. API design

Only when the diff modifies public APIs, endpoints, or interfaces:

- Backward compatibility: removed/renamed fields, changed types, new required parameters are breaking
- Idempotency: PUT replaces fully, POST supports idempotency keys for retry safety
- Naming: consistent with existing API surface, predictable from domain
- Error responses: structured (not string-only), stable format, include enough context for callers
- Hyrum's Law awareness: minimize observable surface area, don't expose internals

---

Review order follows the Code Review Pyramid: spend the most analysis time on correctness and security (top), the least on consistency and style (bottom). Style issues (formatting, whitespace, import order) are NOT review findings -- they belong to linters and auto-formatters.
