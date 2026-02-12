---
name: tdd
description: Test-driven development with isolated subagents. Orchestrates RED-GREEN-REFACTOR cycle. Each phase runs in a fresh context to prevent contamination.
---

# Test-Driven Development

**Announce at start:** `[SKILL:tdd] Starting RED phase for [feature].`
**Announce each phase:** `[TDD:RED] Writing failing tests.` -> `[TDD:GREEN+REFACTOR] Implementing and cleaning up.` -> `[TDD:COMMIT] Committing changes.`

## Activation
- User says "TDD", "test first", "write tests first"
- User chooses "Begin TDD" from requirements-gatherer
- Invoked via `/tdd`

## Prerequisites
Extract from SPEC or user request:
- Acceptance criteria (testable conditions)
- Target file paths (where tests and code should live)

If no criteria exist, ask for them. Each must be testable.

## RED -- Write Failing Tests

Launch via Task tool:
```
description: "TDD RED phase"
prompt: |
  Feature: [one-sentence description]
  Acceptance criteria:
  - [criterion 1]
  - [criterion 2]

  Write tests that FAIL against the current code. Match existing test
  conventions (framework, style, naming). Each test must exercise NEW
  behavior that does not exist yet.

  Run the tests. They MUST FAIL. If all pass, delete and rewrite --
  you are testing existing behavior, not new behavior.

  Report: test file path, test names, failure output.
model: sonnet
```

**Parallel fan-out**: If the SPEC has 3+ independent acceptance criteria (touching different files/modules), launch one RED task per criterion in parallel. Each writes to a separate test file. After all complete, run the full suite to verify failures.

### RED Gate -- HARD BLOCK
Do not proceed to GREEN unless **at least one test fails.**

If all tests pass:
1. **Stop.** Do not proceed.
2. Evaluate: does the feature already exist? If yes, tell the user -- no work needed.
3. If the feature does NOT exist but tests pass, the tests are wrong. Delete and rewrite.
4. Repeat RED until at least one test fails.

This gate is non-negotiable. GREEN with no prior RED failure means TDD was not followed.

## GREEN + REFACTOR -- Implement and Clean Up

Launch as a single Task:
```
description: "TDD GREEN+REFACTOR phase"
prompt: |
  Test file(s): [path(s) from RED]
  Requirement: [one sentence]

  GREEN:
  1. Read the test file(s) to understand what's expected.
  2. Find where implementation should live (adjacent to tests).
  3. Read nearby files to match patterns.
  4. Write the MINIMUM code to make tests pass. Nothing extra.
  5. Run tests. They MUST PASS (both new and existing).

  REFACTOR:
  6. Review for: duplication, complexity, naming, missing error context.
  7. If clean: report "No refactoring needed" and stop. This is valid.
  8. If refactoring: one change at a time, run tests after each.
  9. If tests break after a refactoring change: revert that change only.

  Do NOT modify test files. Do NOT add features beyond what tests require.

  Report: implementation file paths, test results, refactoring summary.
model: haiku
```

### GREEN Gate
Do not proceed unless ALL tests pass (both new and existing) after the GREEN sub-phase.

### REFACTOR Gate
If tests fail after REFACTOR changes, the agent reverts only the refactoring changes (not the GREEN implementation). Tests must pass at exit.

"No refactoring needed" is valid and encouraged. But the phase must still run and make the determination.

## COMMIT -- Mandatory

After GREEN+REFACTOR completes:

1. **Commit the changes using git-workflow conventions.** Do not skip this.
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
2. Present the commit(s) and test results to the user.
3. Ask if they want to push.

Do NOT declare "Done" without committing. Uncommitted work is unfinished work.

## Rules
- RED runs in a separate Task (fresh context). Non-negotiable.
- GREEN+REFACTOR runs in a separate Task (fresh context). Non-negotiable.
- Phase gates are mandatory. RED (must fail) -> GREEN (must pass) -> REFACTOR (must run) -> COMMIT (must happen).
- The test file is the contract. Never modify tests after RED.
- The stop-gate hook will also run tests when you finish. Don't duplicate -- let the hook verify independently. But DO run tests within each phase to enforce gates.
