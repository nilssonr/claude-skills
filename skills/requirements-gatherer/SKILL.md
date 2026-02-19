---
name: requirements-gatherer
description: Gathers requirements before planning. Orchestrates repo-scout and codebase-analyzer in parallel, delegates synthesis to requirements-synthesizer agent, produces a SPEC. Triggers on "let's gather requirements", "before we start", or when ambiguity is detected.
---

# Requirements Gatherer

**Announce at start:** `[SKILL:requirements-gatherer] Defining scope for [task].`

## Core Principle
**Never produce a spec until all blocking questions are resolved.**

## Workflow

### 1. Confirm Goal
Ask: "What are we building? (one sentence)"
Get the repo path if not obvious from cwd.

### 2. Scout the Repo (parallel)
Launch BOTH agents in parallel via Task tool (two Task calls in a single response):

- `repo-scout` with the repo path
- `codebase-analyzer` with the repo path, task goal, and domain keywords extracted from the goal

If repo-scout returns EMPTY_REPO: skip codebase-analyzer results (may not have returned yet) and go to step 3 with minimal questions.

If repo is small (<500 files) and task is focused, you may ignore codebase-analyzer results and proceed with repo-scout findings alone.

### 3. Synthesize Questions (agent)
Launch `requirements-synthesizer` (Task tool, subagent_type: general-purpose, model: haiku) with:
- Both scout reports (or just repo-scout if codebase-analyzer was skipped)
- The user's goal statement
- Any context the user already provided

The synthesizer returns a categorized question list (blocking + directional with defaults).

### 4. Ask Questions
Present blocking questions from the synthesizer. One at a time. If user says "I don't know," propose options:
> "Options: A) [tradeoff] or B) [tradeoff]. Which fits?"

For directional questions, present the synthesizer's proposed defaults:
> "I'll assume [X] based on [evidence]. Object if wrong."

### 5. Produce SPEC (agent)
Launch `requirements-synthesizer` again with:
- Both scout reports
- The user's goal
- All resolved answers

The synthesizer produces the SPEC and persists it to `.claude/specs/<slug>.md`. Review it for completeness, then present to the user.

The SPEC file survives `/clear`, `/compact`, and session restarts. After any context reset, recover the SPEC by reading from `.claude/specs/`.

### 6. Transition
Present options:
1. **Plan** -- Call `EnterPlanMode`. Plan mode will use the SPEC to create implementation steps.
2. **TDD** -- Use `/tdd` with the SPEC's DONE WHEN criteria.
3. **Revise** -- Update SPEC based on feedback.

## Rules
- Don't run codebase-analyzer on empty repos.
- Don't ask what the user already told you.
- Every assumption gets a label (DECISION/REPO/DEFAULT).
- DONE WHEN must be testable, not vibes.
- If the task adds, removes, or significantly modifies a skill, check whether README.md needs updating. Include it in SCOPE and DONE WHEN.
