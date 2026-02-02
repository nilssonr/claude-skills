---
name: review-retros
description: Review accumulated retrospective observations from ~/.claude/retros/log.md. Groups entries by skill/agent, identifies recurring patterns, and proposes concrete, prioritized improvements.
---

# Review Retros

Synthesize retrospective entries into actionable improvements.

## Behavior

1. Read `~/.claude/retros/log.md`.
   - If the file is missing or empty, tell the user: "No retro entries found yet. Use `/retro` to log observations."
   - Then stop.

2. Parse all entries from the log.

3. **Group by skill/agent.** Collect all observations that reference the same skill or agent.

4. **Identify patterns.** Within each group, look for:
   - Repeated observations (same problem reported multiple times)
   - Related observations (different symptoms, same root cause)
   - Single one-off observations

5. **Propose improvements.** For each pattern (prioritize recurring over one-off):
   - State the pattern: what keeps going wrong
   - Identify the file to change (e.g., `skills/retro/SKILL.md` or `agents/repo-scout/AGENT.md`)
   - Describe the concrete change: what to add, remove, or modify
   - Note how many entries support this pattern

6. **Output a prioritized list**, most impactful first. Impact = frequency x severity. Format:

```
### 1. [Short title]
- **Skill/Agent**: [name]
- **Pattern**: [what keeps happening] ([N] entries)
- **File**: [path to edit]
- **Proposed change**: [what to add/modify]

### 2. ...
```

7. After presenting the list, ask the user which improvements they want to act on.

## Rules

- Read-only on the log file — never modify `~/.claude/retros/log.md`.
- If there's only one entry for a skill, still include it but label it as a single observation rather than a pattern.
- Don't fabricate patterns. If entries are unrelated, say so.
- Be specific about file paths and changes. "Improve the prompt" is not actionable. "Add a rule to `skills/retro/SKILL.md` that says X" is.
