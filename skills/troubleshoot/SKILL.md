---
name: troubleshoot
description: Phased systematic debugging with tool-researcher integration and 2-strike escalation. Auto-activates after a failed fix attempt or when debugging unfamiliar tools.
---

# Troubleshoot

**Announce at start:** `[SKILL:troubleshoot] Researching before fixing.`

## Activation

Auto-activates when:
- A fix did not work and you are about to try another
- User reports a fix failed for the 2nd+ time
- Debugging unfamiliar tools/APIs/libraries
- User invokes `/troubleshoot`

## Step 1: Classify and Load

Classify the problem to determine what references to load and where to start:

| Category | Evidence | References to Load | Action |
|----------|----------|-------------------|--------|
| Obvious fix | Syntax error, missing import, config typo, clear stack trace pointing to one line | None | Skip to Phase 3 with `[TROUBLESHOOT:SKIP Phase 0-2]` and evidence |
| Stack trace | Multi-frame stack trace, unclear origin | `references/stack-trace-handling.md` | Phase 0 |
| Unfamiliar tool | Error mentions unknown library/framework | `references/debugging-methodology.md` | Phase 0 + background tool-researcher |
| Complex/multi-component | Multiple error sources, distributed failure | All 3 references | Phase 0 |

Only load references that match the classification. Do not load all 3 unconditionally.

## Step 2: Background Research (if unfamiliar tool)

If the classification is "unfamiliar tool," launch `tool-researcher` in the BACKGROUND (Task tool with run_in_background: true). Continue with Phase 0 locally. Merge research results when they return (check before Phase 2).

For tool-researcher dispatch, provide:
- Subject: the tool/library/API
- Problem: what is going wrong
- Failed attempts: what was tried and why it failed (if any)

## Phase 0: Triage and Scope

Announce: `[TROUBLESHOOT:PHASE-0]`

Launch `troubleshoot-investigator` (Task tool, subagent_type: general-purpose, model: sonnet) with:
- Phase: 0
- Error context: exact message, stack trace, error codes
- Reference files to read (from Step 1 classification)

**Gate:** Investigator must return error summary, classification, and blast radius. If report is incomplete, ask one blocking question and stop.

**Multi-component parallel probes:** If Phase 0 identifies multiple affected components, dispatch parallel investigators:
- Agent A: logs and error traces for component 1
- Agent B: source code in error path for component 2
- Agent C: config/env/infrastructure
Merge reports before proceeding.

## Phase 1: Root Cause Investigation

Announce: `[TROUBLESHOOT:PHASE-1]`

Launch `troubleshoot-investigator` with:
- Phase: 1
- Phase 0 report
- Relevant file paths from Phase 0

**Gate:** Investigator must explain root cause with evidence (file:line, data flow). If not, dispatch tool-researcher for deeper research.

## Phase 2: Pattern Analysis and Hypothesis

Announce: `[TROUBLESHOOT:PHASE-2]`

If tool-researcher was launched in background, check for results now and include them.

Launch `troubleshoot-investigator` with:
- Phase: 2
- Phase 1 report
- Tool-researcher results (if available)

**Gate:** At least one hypothesis with evidence and a proposed fix. If none, dispatch tool-researcher.

## Phase 3: Fix and Verify

Announce: `[TROUBLESHOOT:PHASE-3]`

This phase runs in MAIN context (must write code and run tests).

1. Make the smallest change to test the hypothesis -- one variable at a time.
2. If feasible, create a failing test first.
3. Implement a single fix for the root cause.
4. Verify locally: re-run tests, confirm the issue is resolved.
5. Check for regressions in adjacent functionality.
6. Report using the fix completion template from `references/interaction-policy.md`.

If the fix fails: return to Phase 2 with a new hypothesis. Do NOT stack fixes. Count this as one strike.

## 2-Strike Escalation

After 2 failed fix attempts at the same problem:

1. **Stop.** Announce `[TROUBLESHOOT:ESCALATE]`.
2. Dispatch tool-researcher with all failed attempts as context.
3. Assess whether the approach is fundamentally viable.
4. Report to user using the escalation template from `references/interaction-policy.md`.

Do NOT silently try a 3rd, 4th, 5th variation. The strike counter persists in main context across phase agent dispatches.

## Rules

- Phase announcements are mandatory. Every phase transition gets announced.
- Repo-first: check the repository before asking the user.
- Validate locally: test with bash/scripts, never use the user as a test runner.
- Never guess: if you cannot explain WHY it is broken, research more.
- One blocking question per response, then stop.
- Remove diagnostic instrumentation from the final fix.
