---
name: requirements-gatherer
description: Gathers requirements before planning. Orchestrates repo-scout and codebase-analyzer, synthesizes questions, produces a SPEC. Triggers on "let's gather requirements", "before we start", or when ambiguity is detected.
---

# Requirements Gatherer

**Announce at start:** `[SKILL:requirements-gatherer] Defining scope for [task].`

## Core Principle
**Never produce a spec until all blocking questions are resolved.**

## Workflow

### 1. Confirm Goal
Ask: "What are we building? (one sentence)"
Get the repo path if not obvious from cwd.

### 2. Scout the Repo
Launch `repo-scout` via Task tool. Review its report.
- If EMPTY_REPO: skip to step 4 with minimal questions.
- If PARTIAL/OK: continue.

### 3. Analyze Codebase
If repo-scout found real code (not stubs), launch `codebase-analyzer` via Task tool with:
- The repo-scout report
- The task goal
- Domain keywords extracted from the goal

If repo is small (<500 files) and task is focused, you can skip this and proceed with repo-scout findings alone.

### 4. Synthesize Questions
This is YOUR job — not a separate agent. Using the reports:

1. Collect all unknowns from reports
2. Check if one report answers another's unknown
3. Check what the user already told you — don't re-ask
4. Deduplicate

Categorize each as **blocking** or **directional**:

**Blocking:** Can't write correct code without it. Changes interfaces, persistence, or security. High rework cost if wrong.

**Directional:** Has a reasonable default from the repo. Affects style not correctness. Changeable later.

### 5. Ask Questions
Present blocking questions. One at a time. If user says "I don't know," propose options:
> "Options: A) [tradeoff] or B) [tradeoff]. Which fits?"

For directional questions, propose defaults:
> "I'll assume [X] based on [evidence]. Object if wrong."

### 6. Produce SPEC

```
SPEC: [task-id]
Repo: [path] @ [commit hash]

GOAL
[What and why — one paragraph]

SCOPE
In: [specific files/modules]
Out: [explicitly excluded]

DECISIONS
- DECISION: [thing] — [user chose]
- REPO: [thing] — [code confirms]
- DEFAULT: [thing] — [assumed, reason]

CONSTRAINTS
- [specific file]: [constraint]

DONE WHEN
- [ ] [testable criterion]
- [ ] [testable criterion]
- [ ] All existing tests pass
```

### 7. Transition
Present options:
1. **Plan** → Call `EnterPlanMode`. Plan mode will use the SPEC to create implementation steps.
2. **TDD** → Use `/tdd` with the SPEC's DONE WHEN criteria.
3. **Revise** → Update SPEC based on feedback.

## Rules
- Don't run codebase-analyzer on empty repos.
- Don't ask what the user already told you.
- Every assumption gets a label (DECISION/REPO/DEFAULT).
- DONE WHEN must be testable, not vibes.
