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

## Step 1: Load References

Read these files using the Read tool before proceeding:
- `references/debugging-methodology.md` -- phase definitions, gates, skip conditions, escalation
- `references/stack-trace-handling.md` -- stack trace parsing and triage
- `references/interaction-policy.md` -- response format, announcements, templates

## Step 2: Classify the Problem

Route based on classification:

| Classification | Action |
|---|---|
| Unfamiliar tool/library/API | Dispatch tool-researcher (Task tool, subagent_type: tool-researcher), then continue at Phase 0 |
| Repo-familiar code | Proceed to Phase 0 inline |
| Obvious root cause with evidence | Skip to Phase 3 with `[TROUBLESHOOT:SKIP Phase 0-2]` and the evidence |

For tool-researcher dispatch, provide:
- Subject: the tool/library/API
- Problem: what is going wrong
- Phase context: current phase and what is known so far
- Failed attempts: what was tried and why it failed (if any)

## Phase 0: Triage and Scope

Announce: `[TROUBLESHOOT:PHASE-0]`

1. Capture the exact error: message, stack trace, error codes
2. If a stack trace is present, parse it per `references/stack-trace-handling.md` and produce a triage summary
3. Classify: crash, wrong output, performance, flaky, build/CI failure
4. Scope: single test, one endpoint, system-wide, environment-specific
5. Preflight scan: check README, docs, config, test commands -- cite file paths

**Gate:** Can state the error, classification, and blast radius. If not, ask one blocking question and stop.

## Phase 1: Root Cause Investigation

Announce: `[TROUBLESHOOT:PHASE-1]`

No fixes in this phase.

1. Read errors/warnings completely
2. Reproduce consistently or gather steps to do so
3. Check recent changes (diffs, config, environment)
4. Trace data flow to the source of the bad value/state
5. If multi-component, add minimal diagnostics at boundaries
6. Build a mental model: explain WHY, not just WHERE

**Gate:** Can explain root cause with evidence (file:line, data flow, reproduction). If not, dispatch tool-researcher for deeper research.

## Phase 2: Pattern Analysis and Hypothesis

Announce: `[TROUBLESHOOT:PHASE-2]`

1. Find working examples in the repo, compare line-by-line
2. Identify differences and dependencies
3. Form ranked hypotheses: "I think X because Y"
4. Select one hypothesis to test

**Gate:** At least one hypothesis with evidence. If none, dispatch tool-researcher.

## Phase 3: Fix and Verify

Announce: `[TROUBLESHOOT:PHASE-3]`

1. Make the smallest change to test the hypothesis -- one variable at a time
2. If feasible, create a failing test first
3. Implement a single fix for the root cause
4. Verify locally: re-run tests, confirm the issue is resolved
5. Check for regressions in adjacent functionality
6. Report using the fix completion template from `references/interaction-policy.md`

If the fix fails: return to Phase 2 with a new hypothesis. Do NOT stack fixes. Count this as one strike.

## 2-Strike Escalation

After 2 failed fix attempts at the same problem:

1. **Stop.** Announce `[TROUBLESHOOT:ESCALATE]`.
2. Dispatch tool-researcher with all failed attempts as context.
3. Assess whether the approach is fundamentally viable.
4. Report to user using the escalation template from `references/interaction-policy.md`.

Do NOT silently try a 3rd, 4th, 5th variation.

## Rules

- Phase announcements are mandatory. Every phase transition gets announced.
- Repo-first: check the repository before asking the user.
- Validate locally: test with bash/scripts, never use the user as a test runner.
- Never guess: if you cannot explain WHY it is broken, research more.
- One blocking question per response, then stop.
- Remove diagnostic instrumentation from the final fix.
