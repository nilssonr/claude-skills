---
name: tdd
description: Test-driven development with isolated subagents. Orchestrates RED-GREEN-REFACTOR cycle. Each phase runs in a fresh context to prevent contamination.
---

# Test-Driven Development

**Announce at start:** `[SKILL:tdd] Starting RED phase for [feature].`
**Announce each phase:** `[TDD:RED] Writing failing tests.` → `[TDD:GREEN] Writing minimal implementation.` → `[TDD:REFACTOR] Cleaning up.` → `[TDD:COMMIT] Committing changes.`

## Activation
- User says "TDD", "test first", "write tests first"
- User chooses "Begin TDD" from requirements-gatherer
- Invoked via `/tdd`

## Prerequisites
Extract from SPEC or user request:
- Acceptance criteria (testable conditions)
- Target file paths (where tests and code should live)

If no criteria exist, ask for them. Each must be testable.

## RED — Write Failing Tests

Launch via Task tool:
```
description: "TDD RED phase"
prompt: |
  You are a test writer. You do NOT know how the feature will be implemented.

  Feature: [description]
  Acceptance criteria:
  - [criterion 1]
  - [criterion 2]

  1. Find ONE existing test file to match conventions:
     find . -name '*_test.go' -o -name '*.spec.ts' -o -name '*.test.ts' -o -name '*Tests.cs' | head -5
  2. Read it. Match the framework, style, assertions, naming.
  3. Write tests that WILL FAIL against the current code. Each test must exercise
     the NEW behavior that does not exist yet. If the change is replacing an
     implementation strategy (e.g., switching from !== to timingSafeEqual), test
     for the NEW behavior specifically — mock or assert the new function is called,
     or test a property only the new implementation provides.
  4. Run the tests. They MUST FAIL.
  5. Report: test file path, test names, failure output.

  CRITICAL: If all tests PASS, you wrote the wrong tests. The tests are validating
  existing behavior, not new behavior. Delete them and write tests that actually
  exercise the change. A test that passes before AND after the implementation change
  proves nothing.

  Do NOT write implementation code. Do NOT read implementation plans.
model: sonnet
```

### RED Gate — HARD BLOCK
Do not proceed to GREEN unless **at least one test fails.**

If all tests pass:
1. **Stop.** Do not proceed to GREEN.
2. Evaluate: does the feature already exist? If yes, tell the user — no work needed.
3. If the feature does NOT exist but tests pass, the tests are wrong. They test existing behavior, not the new requirement. Delete them and rewrite.
4. Repeat RED until at least one test fails.

This gate is non-negotiable. GREEN with no prior RED failure means TDD was not followed.

## GREEN — Write Minimal Implementation

Launch via Task tool:
```
description: "TDD GREEN phase"
prompt: |
  Test file: [path from RED]
  Requirement: [one sentence]

  1. Read the test file to understand what's expected.
  2. Find where implementation should live (adjacent to tests).
  3. Read nearby files to match patterns.
  4. Write the MINIMUM code to make tests pass. Nothing extra.
  5. Run tests. They MUST PASS.
  6. Run the broader test suite to check regressions.

  Do NOT modify test files. Do NOT add features beyond what tests require.
model: sonnet
```

### GREEN Gate
Do not proceed unless ALL tests pass (both new and existing).

## REFACTOR — Clean Up

**This phase is MANDATORY. Always run it. Never skip it.**

Launch via Task tool:
```
description: "TDD REFACTOR phase"
prompt: |
  Test file: [path]
  Implementation: [path(s) from GREEN]

  1. Run tests — confirm green baseline.
  2. Review for: duplication, complexity, naming, missing error context.
  3. If clean: report "No refactoring needed" and stop. This is a valid outcome.
  4. If refactoring: one change at a time, run tests after each.
  5. If tests break: revert immediately.

  Do NOT modify test files. Do NOT change behavior.
model: sonnet
```

"No refactoring needed" is valid and encouraged. But the phase must still run and make the determination.

## COMMIT — Mandatory

After REFACTOR completes:

1. Run the full test suite one final time.
2. **Commit the changes using git-workflow conventions.** Do not skip this.
   - Check branch: if on main/master, create a feature branch first.
   - Stage and commit with separate logical commits:
     ```
     test(scope): add tests for [feature]
     ```
     ```
     feat(scope): implement [feature]
     ```
   - Or a single commit if the change is atomic:
     ```
     fix(scope): [description]
     ```
3. Present the commit(s) and test results to the user.
4. Ask if they want to push.

Do NOT declare "Done" without committing. Uncommitted work is unfinished work.

## Rules
- Each phase runs in a separate Task (fresh context). Non-negotiable.
- Phase gates are mandatory. RED (must fail) → GREEN (must pass) → REFACTOR (must run) → COMMIT (must happen).
- The test file is the contract. Never modify tests after RED.
- The stop-gate hook will also run tests when you finish. Don't duplicate — let the hook verify independently. But DO run tests within each phase to enforce gates.
