---
name: tdd
description: Test-driven development with isolated subagents. Orchestrates RED-GREEN-REFACTOR cycle. Each phase runs in a fresh context to prevent contamination.
---

# Test-Driven Development

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
  3. Write tests covering each criterion. Include error/edge cases.
  4. Run the tests. They MUST FAIL.
  5. Report: test file path, test names, failure output.

  Do NOT write implementation code. Do NOT read implementation plans.
model: sonnet
```

**Gate:** Do not proceed unless tests fail. If they pass, the feature may already exist — investigate.

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

**Gate:** Do not proceed unless all tests pass.

## REFACTOR — Clean Up

Launch via Task tool:
```
description: "TDD REFACTOR phase"
prompt: |
  Test file: [path]
  Implementation: [path(s) from GREEN]

  1. Run tests — confirm green baseline.
  2. Review for: duplication, complexity, naming, missing error context.
  3. If clean: report "No refactoring needed" and stop.
  4. If refactoring: one change at a time, run tests after each.
  5. If tests break: revert immediately.

  Do NOT modify test files. Do NOT change behavior.
model: sonnet
```

"No refactoring needed" is a valid and good outcome.

## After REFACTOR
1. Run the full test suite for the affected area.
2. Present results to the user.
3. If git-workflow is active, commit:
   ```
   test(scope): add tests for [feature]
   feat(scope): implement [feature]
   ```

## Rules
- Each phase runs in a separate Task (fresh context). Non-negotiable.
- Phase gates are mandatory. RED before GREEN. GREEN before REFACTOR.
- The test file is the contract. Never modify after RED.
