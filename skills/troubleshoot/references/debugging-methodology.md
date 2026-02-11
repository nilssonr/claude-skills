# Debugging Methodology

Four phases with gates. Phases run in main context (not isolated) because debugging requires accumulated context.

## Phase 0: Triage and Scope

**Actions:**
- Capture the exact error: message, stack trace, error codes, correlation IDs
- Classify the problem: crash, wrong output, performance, flaky, build/CI failure
- Scope the impact: single test, one endpoint, system-wide, environment-specific
- Preflight scan: check README, docs, config, test commands -- cite file paths used

**Gate:** You can state the error, its classification, and its blast radius. If not, ask one blocking question.

## Phase 1: Root Cause Investigation

No fixes in this phase.

**Actions:**
- Read errors/warnings completely (full stack trace, file/line, error codes)
- Reproduce consistently, or gather steps/data to do so
- Check recent changes: diffs, config, environment
- Trace data flow back to the source of the bad value/state
- If multi-component: add minimal diagnostics at boundaries to identify where it breaks
- Build a mental model: explain WHY it is broken, not just WHERE

**Gate:** You can explain the root cause with evidence (file paths, line numbers, data flow). If you cannot explain WHY, you are not ready to fix.

**Skip condition:** Root cause is immediately obvious from the error alone (e.g., typo in import path, missing env var). Announce `[TROUBLESHOOT:SKIP Phase 0-1]` with the evidence.

Invalid skip reasons:
- "I think I know" -- thinking is not evidence
- "It's probably X" -- probability is not proof
- "This usually means" -- generalities do not apply to specific codebases

## Phase 2: Pattern Analysis and Hypothesis

**Actions:**
- Find working examples in the repo and compare line-by-line
- Identify all differences and dependencies (config, env, versions, assumptions)
- Form ranked hypotheses: "I think X because Y" (evidence required)
- State a single hypothesis to test first

**Gate:** At least one hypothesis with supporting evidence. If no hypothesis, research deeper (dispatch tool-researcher).

## Phase 3: Fix and Verify

**Actions:**
- Make the smallest change to test the hypothesis; one variable at a time
- If feasible, create a failing test first
- Implement a single fix for the root cause (not symptoms)
- Re-run tests/verification and confirm the issue is resolved
- Check for regressions in adjacent functionality

**Gate:** Fix passes verification and does not introduce regressions.

If the fix fails: form a new hypothesis (return to Phase 2). Do NOT stack fixes.

## Phase Gate Rules

- Hard gates (never skip): Phase 1 gate for unfamiliar tools/systems, Phase 3 verification
- Skippable gates: Phase 0-1 can be collapsed when root cause is obvious with evidence
- Every skip must be announced with `[TROUBLESHOOT:SKIP]` and the justifying evidence

## Escalation Protocol (2-Strike)

After 2 failed fix attempts at the same problem:

1. **Stop.** Do not try a 3rd variation.
2. **Assess:** Is the approach fundamentally viable?
3. **Research deeper:** Dispatch tool-researcher with failed attempts as context.
4. **Report to user** using the escalation template from interaction-policy.md.

The 2-strike counter resets when:
- The problem changes (new error, different root cause)
- tool-researcher returns new information that changes the approach
- User provides new context that invalidates previous attempts

## Diagnostics Guidance

- Prefer temporary, minimal instrumentation; remove it once the failing component is identified
- For flaky or environment-dependent issues, capture environment details and timing data before changing code
- Never leave diagnostic code in the final fix
