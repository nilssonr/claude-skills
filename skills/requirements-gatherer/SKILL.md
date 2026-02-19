---
name: requirements-gatherer
description: Gathers requirements before planning. Orchestrates repo-scout then codebase-analyzer (sequential), delegates synthesis to requirements-synthesizer agent, produces a SPEC. Triggers on "let's gather requirements", "before we start", or when ambiguity is detected.
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
Launch `repo-scout` with the repo path and the task goal. Wait for it to return.

If repo-scout returns EMPTY_REPO: skip codebase-analyzer and go to step 3 with minimal questions.

If repo is small (<500 files) and task is focused, you may skip codebase-analyzer and proceed with repo-scout findings alone.

### 3. Analyze the Domain
Using the repo-scout report, compose a targeted prompt for `codebase-analyzer` that includes:

- The repo path and task goal
- The **stack** from repo-scout (e.g., "React/TypeScript with shadcn/ui") so the agent knows which language modes and patterns to use
- The **roots** from repo-scout (e.g., "features in `src/features/`, UI components in `src/core/components/ui/`") so the agent knows where to search
- Domain keywords extracted from the user's goal

The better the prompt, the better the analysis. Don't just forward the user's raw question -- reframe it using what repo-scout found.

### 4. Synthesize Questions (agent)
Launch `requirements-synthesizer` (Task tool, subagent_type: general-purpose, model: haiku) with:
- Both reports (repo-scout + codebase-analyzer), or just repo-scout if codebase-analyzer was skipped
- The user's goal statement
- Any context the user already provided

The synthesizer returns a categorized question list (blocking + directional with defaults).

### 5. Ask Questions
Present blocking questions from the synthesizer. One at a time. If user says "I don't know," propose options:
> "Options: A) [tradeoff] or B) [tradeoff]. Which fits?"

For directional questions, present the synthesizer's proposed defaults:
> "I'll assume [X] based on [evidence]. Object if wrong."

### 6. Produce SPEC (agent)
Launch `requirements-synthesizer` again with:
- Both reports (repo-scout + codebase-analyzer)
- The user's goal
- All resolved answers

The synthesizer produces the SPEC and persists it to `~/.claude/specs/<org>/<repo>/<slug>.md`. Review it for completeness, then present to the user.

The SPEC file survives `/clear`, `/compact`, and session restarts. After any context reset, recover the SPEC by reading from `~/.claude/specs/<org>/<repo>/`.

### 7. Transition
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
