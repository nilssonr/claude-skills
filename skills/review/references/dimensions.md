# Review Dimensions

Work through every dimension. Do not skip any. Report order in findings follows the Code Review Pyramid: invest the most analysis time in Correctness and Security; the least in Consistency and Style. Style (formatting, whitespace, import order) is never a finding — that belongs to linters.

---

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
- Every error path either propagates, wraps with context, or is intentionally discarded with a comment explaining why

---

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

---

## 3. Error Handling

- Swallowed errors: empty catch/except blocks, ignored return values = [CRIT]
- Missing error context: bare re-throw or return without wrapping = [WARN]
- Overly broad catches: catching base Exception/Error type = [WARN]
- Panic/crash on expected conditions: reserve crash for invariant violations only
- Retry without backoff: retries on transient failures must use exponential backoff + jitter + max attempts
- Error type confusion: infrastructure errors leaking to users, domain errors lost in translation
- Fail-fast principle: detect and report errors as close to the source as possible

---

## 4. Performance

- N+1 queries: database/API call inside a loop iterating over query results = [CRIT]
- O(n²) hidden in nested loops: .find/.filter/.includes/.indexOf inside a loop = [WARN]
- Unbounded allocations: SELECT without LIMIT, loading full datasets, missing pagination = [WARN]
- Synchronous blocking in async: blocking calls in event loops or async handlers = [CRIT]
- Missing caching: repeated expensive computation or I/O for identical inputs
- Unnecessary serialization/deserialization in hot paths
- String concatenation in tight loops (use builders/buffers)

---

## 5. Defensiveness

- Input validation at trust boundaries: type, range, length, format
- Allowlist over denylist for input validation
- Preconditions checked at function entry (fail fast)
- Resources acquired in matching pairs: open/close, lock/unlock, begin/commit
- Timeouts on all external calls (HTTP, DB, file I/O, locks)
- Immutable data preferred where thread safety matters
- Default/fallback cases in switch/match statements

---

## 6. Readability

Apply thresholds as graduated signals, not binary gates.

### Structural complexity

- Cyclomatic complexity: ≤ 10 acceptable; 11–15 = [INFO]; 16–20 = [WARN]; > 20 = [CRIT]
- Cognitive complexity (SonarSource nesting-weighted metric): ≤ 15 acceptable; > 15 = [WARN]
- Function length: ≤ 40 lines acceptable; 41–60 = [INFO]; 61–100 = [WARN]; > 100 = [CRIT]
- Nesting depth: ≤ 3 acceptable (Linux kernel, Code Complete); 4 = [WARN]; > 4 = [CRIT]
  - Remedies by nesting cause (see Dimension 6a below)

### Naming

- Functions describe actions; variables describe content; booleans read as predicates
- Synonyms within a module should be eliminated: pick one verb per semantic operation. `getUser` / `fetchUser` / `findUser` for the same operation in the same layer = [WARN]
- Names must describe side effects (see Dimension 10): `processUser` that writes to a database should be `saveUser`

### Comments

- Comments explain WHY, not WHAT
- A function that requires a WHAT comment to be understood is itself a finding (simplify the function)
- Do not flag absence of comments on self-explanatory code

---

## 6a. Nested Conditional Remedies

When nesting depth exceeds threshold, the appropriate refactoring depends on the structure. Emit the specific remedy in the `-> suggested fix` line.

| Structure | Remedy |
|---|---|
| Precondition / validation guards nested | Guard clauses — early return at function top, keep happy path at base indentation (Fowler, *Refactoring* p. 266) |
| Complex condition expression, hard to parse | Decompose Conditional — extract condition and branches into named functions (Fowler p. 260) |
| Same type-dispatch conditional in multiple methods | Replace Conditional with Polymorphism (Fowler p. 272) |
| Multiple algorithm variants, runtime-selectable | Strategy Pattern (Kerievsky, *Refactoring to Patterns*) |
| Many input-to-output mappings (20+ cases) | Table-driven method — data table keyed on input (McConnell, *Code Complete* ch. 18) |
| Multiple related booleans encoding state | Explicit state machine — replace boolean cluster with a single enum; make invalid states unrepresentable |
| Null propagation scattered throughout | Null Object / Special Case pattern (Fowler) |

---

## 7. Cognitive Load

These patterns increase the mental effort required to read and reason about code independent of structural complexity metrics. Each is a concrete, detectable signal.

### Parameter lists

Thresholds (Clean Code / Code Complete consensus):
- 0–2 parameters: ideal
- 3 parameters: acceptable, no comment needed
- 4–6 parameters: code smell = [WARN]; investigate whether a Parameter Object or options struct applies
- 7+ parameters: almost always requires refactoring = [WARN] (escalate to [CRIT] if parameters share a type, enabling silent ordering bugs)

Remedies:
- **Introduce Parameter Object** — group parameters that always travel together into a named struct/class (Fowler, *Refactoring* p. 140)
- **Preserve Whole Object** — pass the source object instead of extracting individual fields from it
- **Builder Pattern** — for constructors with many optional parameters
- **Replace Parameter with Query** — remove parameters derivable from others already available
- **Context/Options Object** — for functions with many optional settings

### Boolean flag parameters

A boolean parameter is a declaration that the function does two things (Clean Code Tip #12). It is also opaque at every call site: `process(data, true, false)` requires navigation to decode. = [WARN]

Remedy: split into two named functions, or replace with an enum.

### Mixed abstraction levels (SLAP violation)

A function that contains both high-level orchestration (`placeOrder`, `notifyUser`) and low-level implementation (`string.split(','`, `buf.write(bytes)`) forces the reader to context-switch between "what" and "how" within a single scope. = [WARN]

Remedy: extract low-level operations into private helpers; the outer function should read as a sequence of same-level operations.

### Implicit state machines

Multiple related boolean fields (`isLoading`, `isError`, `isSuccess`, `isDirty`) create 2^N possible states where most combinations are invalid (e.g., `isLoading && isSuccess`). The reader must mentally track all combinations. = [WARN]

Remedy: replace boolean cluster with a single enum. Invalid states become unrepresentable by construction.

### Temporal coupling

Methods that must be called in a specific sequence, with no structural enforcement, create invisible contracts. Signals: `init()`/`setup()`/`configure()` methods that must precede other calls; setters with required ordering; methods that fail if called "too early." = [WARN]

Remedy: make objects valid at construction time. Move required initialization into the constructor or a factory. Use the type system to enforce sequencing where possible.

### Nested functions and closures

Thresholds:
- Closure nesting depth > 2: = [WARN]
- Closure body > 15 lines: = [INFO] (closure should be extracted to a named function)
- Captured variables > 4 from outer scope: = [WARN] (hidden dependencies; pass values as explicit parameters instead)
- Closure mutates captured variables: = [WARN] (creates action-at-a-distance; document explicitly if intentional)

Additional risks:
- **Memory retention**: closures sharing a lexical scope retain all variables in that scope, even those the surviving closure never references. Flag closures capturing large objects stored in long-lived references (event listeners, timers, caches).
- **Testability**: closures cannot be tested in isolation. If a closure contains non-trivial logic, extract it to a named function that takes captured values as parameters.

### Primitive obsession

Using raw strings, ints, or booleans where a domain type (`EmailAddress`, `UserId`, `Money`) would encode the constraint and prevent misuse. = [INFO] for isolated cases; = [WARN] when the primitive crosses module boundaries or appears in multiple signatures.

---

## 8. Testability

- Constructor does real work (I/O, complex logic, deep object graphs): makes instantiation in tests difficult
- Law of Demeter violations: long method chains coupling to internal structure
- Global state or singletons creating hidden dependencies
- Class does too much (needs "and" to describe its purpose = SRP violation)
- Critical paths untested: auth, payment, data mutation, error recovery
- Tests test implementation details instead of behavior (brittle)
- Impure functions at the core of business logic (see Dimension 10): pure business logic should be testable without mocking external services

---

## 9. Consistency

Consistency operates at two scopes. Distinguish them in findings.

### Within-diff consistency

The changeset must be internally uniform regardless of the surrounding codebase:
- All new names use the same convention throughout the diff
- Error handling follows one pattern in new code (not mixed)
- Abstraction levels are consistent across new functions at the same layer
- Test style matches within the new test files

### Cross-codebase consistency

New code must match established patterns. **Detection technique from a diff:** expand context, check imports for divergence from established dependencies, use Grep/Glob to find 2–3 peer implementations.

Check for:
- **Naming synonyms**: `getUser` in new code when the codebase uses `fetchUser` for equivalent operations = [WARN]
- **Error handling strategy**: each architectural layer should have one strategy (exceptions vs. error codes vs. Result types). Mixing strategies within a layer = [WARN]. If the codebase wraps errors with context at the service layer, new code in the same layer that does a bare re-throw is inconsistent.
- **Dependency injection pattern**: new code that reaches into a service locator when the codebase uses constructor injection = [WARN]
- **File/module structure**: new file placed in a directory inconsistent with established conventions = [INFO]
- **Abstraction pattern**: new code using raw queries when the layer uses a repository = [WARN]

When a peer search returns no results, or the diff context is insufficient to confirm the codebase pattern, mark the finding `(unverified: limited diff context)` and do not escalate severity.

### DRY

- Code repeated 3+ times should be extracted
- Note: premature abstraction is worse than duplication. Only flag duplication that is semantically identical, not superficially similar.

---

## 10. Side Effects & Purity

### Command-Query Separation (CQS)

Originated by Bertrand Meyer; articulated for review by Martin Fowler: every method should either return a result without changing state (query) or change state without returning a meaningful result (command). Mixing both in one function is a CQS violation.

Detection: for each function in the diff, compare what the name promises against what the body does.

- A function named `get*`, `find*`, `is*`, `has*`, or `calculate*` that modifies state = [WARN] (CQS violation)
- A command that returns a meaningful value beyond an error indicator = [WARN]

Fowler acknowledges rare justified exceptions (e.g., stack `.pop()`). These require a comment.

### Hidden side effects catalog

Each of these is detectable from the diff:

- **Mutation of input arguments**: a function modifies a passed collection, map, or object instead of returning a new one. Detect: mutation methods (`.push()`, `.append()`, property assignment on) called on parameters. = [WARN]
- **Global/static state modification**: writes to variables not declared locally and not passed as parameters. = [WARN]; escalate to [CRIT] in concurrent code.
- **I/O inside pure-looking functions**: file writes, network calls, or database operations inside functions named `calculate*`, `transform*`, `validate*`, or `parse*`. = [WARN]
- **Getters that mutate state**: lazy initialization, cache population, counter increments, or logging inside `get*` methods. = [WARN]
- **Non-determinism sources not injected**: `Date.now()`, `Math.random()`, `uuid()`, environment variable reads embedded directly in business logic rather than passed as parameters or injected as dependencies. = [INFO] for isolated cases; [WARN] when in a function claimed to be deterministic or when it blocks testing.

### Naming rule

Names must describe side effects (Clean Code heuristic N7). A function named `validateEmail` that also sends a verification email violates this rule. = [WARN]

### Functional core / imperative shell

The functional core (pure business logic) should be testable without mocking external services. If new business logic cannot be unit-tested without mocking a database, file system, or network call, side effects have leaked into the core. = [WARN]

This is the testability check from Dimension 8, applied from a side-effects lens: if you need to mock to test business logic, the boundary is wrong.

---

## 11. API Design

Apply only when the diff modifies public APIs, endpoints, library interfaces, or exported types.

- **Backward compatibility**: removed/renamed fields, changed types, new required parameters are breaking changes. = [CRIT] if unversioned.
- **Idempotency**: PUT replaces fully; POST supports idempotency keys for retry safety
- **Naming**: consistent with existing API surface, predictable from domain
- **Error responses**: structured (not string-only), stable format, include enough context for callers
- **Hyrum's Law**: minimize observable surface area; do not expose internals. Every observable behavior becomes a dependency someone relies on.

---

## Review priority order

Spend analysis time proportionally:

1. Correctness, Security (highest — would cause incidents)
2. Error Handling, Side Effects & Purity (high — silent failure modes)
3. Performance, Defensiveness (medium — operational risk)
4. Cognitive Load, Readability (medium — maintenance burden)
5. Testability, API Design (context-dependent)
6. Consistency (lowest — important but rarely critical)

Style is not a finding. Formatting, whitespace, and import order belong to linters and auto-formatters.
