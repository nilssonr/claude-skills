---
name: plan-writer
description: Takes a SPEC from /requirements-gatherer and produces a TDD-explicit, step-by-step implementation plan with commit boundaries. Validates the spec, runs subagents to gather repo context, and synthesizes an ordered plan where each step is a red-green TDD cycle. Triggers on "write a plan", "plan this", or when a SPEC is ready for planning.
---

# Plan Writer

Takes a validated SPEC and produces a TDD-explicit implementation plan with commit boundaries.

## Core Principle

**Never generate a plan from an incomplete spec. Validate first, plan second.**

## Invocation

User provides a SPEC (output of `/requirements-gatherer`) and asks to plan the implementation.

If no SPEC is provided, tell the user to run `/requirements-gatherer` first.

## Input

The SPEC format from requirements-gatherer with these required sections:
- GOAL
- SCOPE (In/Out)
- DECISIONS
- CONSTRAINTS
- DONE WHEN

## Subagents

You delegate to these subagents (they must be installed in `~/.claude/agents/` or `.claude/agents/`):

| Agent | Purpose | Model | max_turns |
|-------|---------|-------|-----------|
| `repo-scout` | File paths, structure, stack | haiku | 8 |
| `pattern-analyzer` | Conventions, test patterns, naming | haiku | 8 |
| `domain-investigator` | Existing code in task domain | haiku | 8 |

**Always set `max_turns`** when launching subagents.

## Workflow

### 1. Validate SPEC

Check that all required sections exist and are non-empty:
- GOAL — present and specific
- SCOPE — has In and Out
- DECISIONS — each labeled DECISION/REPO/DEFAULT
- CONSTRAINTS — references specific files
- DONE WHEN — contains testable criteria

If any section is missing or incomplete, **stop immediately** and report:
> "SPEC is incomplete. Missing or insufficient sections:
> - [section]: [what's wrong]
>
> Run /requirements-gatherer to complete the spec."

Do not proceed with a partial spec.

### 2. Assess Complexity and Run Agents

Use the same decision tree as requirements-gatherer:

**Lightweight path** — Scout reports stubs, scaffolding, or empty files:
- Run repo-scout only
- Skip pattern-analyzer and domain-investigator

**Standard path** — Small-to-medium repo with real code:
- Run repo-scout, then pattern-analyzer and domain-investigator (can run in parallel)

**Full path** — Large repo, monorepo, or complex task:
- Run repo-scout first
- Run pattern-analyzer with scout context
- Run domain-investigator with scout + pattern context

Pass SPEC context to all agents so they focus on relevant areas.

If any agent returns `INSUFFICIENT_CONTEXT`, note the gap and ask the user before proceeding.

### 3. Check Scope Size

If the SPEC scope is large enough that the plan would exceed ~10 steps, suggest splitting:
> "This scope is large. I recommend splitting into multiple plans:
> - Plan A: [subset]
> - Plan B: [subset]
>
> Which should I plan first?"

### 4. Synthesize Plan

Combine SPEC decisions + agent findings into ordered steps:

1. Map each DONE WHEN criterion to one or more implementation steps
2. Order steps by dependency (what must exist before what)
3. Each step is a single TDD cycle: write failing test → implement → verify
4. Group related changes into commit boundaries
5. Use conventions discovered by pattern-analyzer (test file naming, assertion style, file structure)
6. Reference specific files from domain-investigator and repo-scout

### 5. Output Plan

Display the plan directly in the conversation using this format:

```
PLAN: [task-id from SPEC]
Repo: [path]
SPEC: [reference to spec]
Generated: [timestamp]

## Workflow Reminder
Branch → TDD (red-green) → Commit after each step → Verify all checks → PR
(Git conventions from `git-workflow` skill apply)

## Steps

### Step 1: [title]
**Files**: [files to create/modify]
**Test**: [write failing test for X — be specific about what to assert]
**Implement**: [make test pass by doing Y — reference specific patterns/conventions]
**Verify**: [run tests, expected result]
**Commit**: `type(scope): description`

### Step 2: ...
[continue for all steps]

## Verification
[Map each DONE WHEN criterion to how it's verified — which steps cover it]
```

**Output rules:**
- Every step must have all five fields: Files, Test, Implement, Verify, Commit
- Test field describes what to assert, not just "write a test"
- Implement field references specific patterns from pattern-analyzer
- Commit messages follow conventional commits
- Verification section maps every DONE WHEN item to specific steps

## Failure Modes to Avoid

- **Planning from incomplete specs.** Always validate first.
- **Vague test descriptions.** "Write tests" is not a test field. Say what to assert.
- **Ignoring repo conventions.** If pattern-analyzer found test patterns, use them.
- **Monolithic steps.** Each step should be one focused TDD cycle, not "implement the feature."
- **Missing commit boundaries.** Every step ends with a commit.

## Integration

### Upstream
Receives SPEC from `/requirements-gatherer`. The spec is the contract — if it's complete, no follow-up questions should be needed.

### Downstream
Plan is executed by user or Claude Code. Git conventions (branching, commit messages, PR workflow) are handled by the `git-workflow` skill, which auto-activates during implementation.

### Failure Attribution
- Plan-writer asks questions → requirements gap (spec was incomplete)
- Plan diverges from spec → planning gap
- Code diverges from plan → execution gap
