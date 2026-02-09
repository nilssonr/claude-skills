---
name: using-skills
description: Meta-skill that ensures all other skills and agents are used correctly. Loaded automatically every session via SessionStart hook. Do not invoke manually.
---

# Using Skills

Before responding to ANY user request, follow this sequence:

## 1. Classify → Match → Announce

Classify the task, match to a skill, and **announce your decision before doing anything else.** The announcement is your first output — before code, before questions, before investigation.

| Classification | Skill | Announcement |
|---|---|---|
| Targeted fix (specific file:line, known change) | None — proceed directly | `[SKILL:none] Targeted fix — proceeding directly.` |
| New feature / unclear scope | requirements-gatherer | `[SKILL:requirements-gatherer] Defining scope.` |
| Test-first requested | tdd | `[SKILL:tdd] Starting RED phase.` |
| Git operation | git-workflow | `[SKILL:git-workflow] Active.` |
| Debugging / 2nd failed attempt | troubleshoot | `[SKILL:troubleshoot] Researching before fixing.` |
| Something went wrong, session end | retro | `[SKILL:retro] Logging observation.` |

**The announcement is mandatory.** It commits you to following the skill. If you announce TDD, you follow all TDD phases. If you announce "targeted fix," you don't secretly run requirements-gatherer.

## 2. Follow through

After announcing:
- **If a skill was announced:** read and follow that skill exactly. Every phase, every gate.
- **If no skill (targeted fix):** implement directly. git-workflow and stop-gate hooks still apply.

## 3. Don't over-apply

A one-line fix doesn't need requirements gathering. A known bug with a known fix doesn't need TDD. Match the process to the complexity. The hooks provide baseline enforcement regardless.

## 4. Always commit after code changes

Don't declare "Done" with uncommitted code. The stop-gate hook blocks this, but don't wait for the hook — commit proactively using git-workflow conventions.

## Rationalization detection

If you catch yourself thinking any of these, you're about to skip a skill:
- "This is too simple for a skill" → Maybe. But announce your decision.
- "I already know the answer" → Announce "targeted fix" and proceed.
- "The user seems impatient" → Skills save time by preventing rework.
- "I'll just do it quickly" → That's how tests get skipped and commits get forgotten.
