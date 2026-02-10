---
name: retro
description: Capture and review retrospective observations. Two modes — "log" captures what went wrong, "review" analyzes patterns and proposes skill improvements. Use /retro to log, /retro review to analyze.
---

# Retro

## Mode 1: Log (default — `/retro`)

**Announce at start:** `[SKILL:retro] Logging observation.`

Capture an observation while context is fresh.

Ask the user:
1. **Which skill/agent?** — list known ones as options
2. **What happened?** — brief description
3. **Severity?** — high (wasted significant time), medium (needed correction), low (minor)
4. **Fix idea?** — optional

Auto-gather: timestamp, repo path, branch.

Ensure `~/.claude/retros/` exists. Append to `~/.claude/retros/log.md`:

```
## [YYYY-MM-DD HH:MM]
- **Skill**: [name]
- **Severity**: [high|medium|low]
- **Repo**: [path]
- **Branch**: [branch]
- **What happened**: [observation]
- **Fix idea**: [suggestion or "None"]
```

Confirm logged. Done.

## Mode 2: Review (`/retro review`)

**Announce at start:** `[SKILL:retro:review] Analyzing patterns.`

Analyze accumulated entries and propose skill improvements.

1. Read `~/.claude/retros/log.md`. If empty, say so and stop.

2. Group by skill/agent. Within each group, find:
   - Repeated problems (same issue, multiple entries)
   - Related problems (different symptoms, same root cause)
   - One-offs

3. Score: impact = frequency × severity (high=3, medium=2, low=1)

4. For each pattern (highest impact first):
   ```
   ### 1. [Title]
   - **Skill**: [name]
   - **Pattern**: [what keeps happening] ([N] entries, avg severity: [level])
   - **Impact**: [score]
   - **File to edit**: [exact path]
   - **Change**: [specific addition/modification to the skill file]
   ```

5. Ask: "Which improvements should I apply?"
   - Apply all / specific numbers / review only

6. If applying: make targeted edits. Show diff. Confirm before saving.

## Rules
- Never modify `log.md` (append-only for log, read-only for review).
- Be specific about changes. "Improve the prompt" is not actionable.

