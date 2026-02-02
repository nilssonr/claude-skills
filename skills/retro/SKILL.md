---
name: retro
description: Capture a retrospective observation about a skill or agent that didn't work well or could be improved. Appends a structured entry to ~/.claude/retros/log.md for later review.
---

# Retro

Capture an observation about a skill or agent in the moment, while context is fresh.

## Behavior

1. Ask the user (using AskUserQuestion with appropriate options where possible):
   - **Which skill/agent was involved?** — List installed skills/agents as options if possible, otherwise ask as free text.
   - **What were you trying to do?** — Brief task description.
   - **What went wrong or could be better?** — The observation.
   - **Do you have a concrete improvement idea?** — Optional suggested fix.

2. Gather context automatically:
   - **Timestamp**: Current date/time
   - **Repo**: Current working directory
   - **Branch**: Current git branch (if in a git repo)

3. Ensure `~/.claude/retros/` directory exists (create if needed).

4. Append the entry to `~/.claude/retros/log.md` using this format:

```
## [YYYY-MM-DD HH:MM]
- **Skill/Agent**: [name]
- **Repo**: [repo path]
- **Branch**: [branch]
- **Task**: [what the user was trying to do]
- **Observation**: [what went wrong or could be better]
- **Suggested fix**: [concrete improvement idea, or "None provided"]
```

5. Confirm to the user that the entry was logged.

## Rules

- Never skip asking for the observation — that's the whole point.
- Keep entries concise. Don't editorialize or rewrite what the user said.
- If not in a git repo, set Branch to "N/A".
- Append only — never overwrite or modify existing entries in the log.
