# Interaction Policy

Response format, communication rules, and reporting templates for the troubleshoot skill.

## Default Response Style

- Concise: 1-4 bullets or 2-5 short sentences per phase
- Finding-first: lead with the conclusion, then evidence
- Do not use multi-section outputs unless the problem is multi-component
- No filler, no hedging ("it seems like", "it might be")

## Phase Announcements

Every phase transition must be announced:

| Announcement | When |
|---|---|
| `[TROUBLESHOOT:PHASE-0]` | Starting triage and scope |
| `[TROUBLESHOOT:PHASE-1]` | Starting root cause investigation |
| `[TROUBLESHOOT:PHASE-2]` | Starting pattern analysis and hypothesis |
| `[TROUBLESHOOT:PHASE-3]` | Starting fix and verify |
| `[TROUBLESHOOT:SKIP Phase N-M]` | Skipping phases with evidence |
| `[TROUBLESHOOT:ESCALATE]` | 2-strike escalation triggered |
| `[TROUBLESHOOT:DISPATCH tool-researcher]` | Dispatching tool-researcher agent |

Announcements are mandatory. They are not suggestions.

## Question Policy

- Ask at most one blocking question per response, then stop
- Before asking, check the repo first: README, docs, config, test scripts
- Blocking questions (require answer before proceeding): reproduction steps, environment details, access to logs
- Directional questions (can proceed with assumption): "I'll assume X unless you say otherwise"
- Never use the user as a test runner when you can verify locally

## Reporting Templates

### Investigation Report (end of Phase 1)

```
INVESTIGATION:
  Error: [type]: [message]
  Root cause: [explanation with evidence]
  Files: [list of relevant file:line references]
  Hypothesis: [what to fix and why]
```

### Fix Completion Report (end of Phase 3)

```
FIX:
  Root cause: [one sentence]
  Change: [what was changed and why]
  Verification: [how it was verified]
  Regressions checked: [what adjacent functionality was confirmed]
```

### Escalation Report (2-strike)

```
ESCALATION:
  Problem: [one sentence]
  Attempt 1: [what was tried] -> [why it failed]
  Attempt 2: [what was tried] -> [why it failed]
  Assessment: [is the approach viable?]
  Alternatives:
  - [option] -- [tradeoff]
  Recommendation: [next step]
```

## Rules

- Repo-first: always check the repository before asking the user
- Validate locally: test assumptions with bash/scripts, not user manual testing
- Never guess: if you cannot explain why something is broken, research more
- Phase announcements are mandatory even for quick fixes
