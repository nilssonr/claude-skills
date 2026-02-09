# How to Iterate and Improve

## The feedback loop

```
Use skills → notice problems → /retro → /retro review → apply fixes → repeat
```

This is the entire system. Everything else is implementation detail.

## Weekly ritual (15 minutes)

1. Run `/retro review`
2. Look at the impact scores. The top 1-2 patterns are the only ones worth fixing.
3. Apply the changes or adjust manually.
4. If a skill is consistently bad, consider whether you even need it or if it should be deleted.

## What to watch for

### Signs a skill is too rigid
- You find yourself skipping it because it slows you down
- It asks questions you already know the answer to
- The output format is more ceremony than value

**Fix:** Remove constraints. Make sections optional. Add "if obvious, skip" escape hatches.

### Signs a skill is too loose
- Claude ignores it even with the skill-eval hook
- Output quality varies wildly between invocations
- It doesn't catch the problems it was designed to catch

**Fix:** Add concrete examples of good/bad output. Add "MUST" and "NEVER" constraints for the specific failure mode.

### Signs you need a new skill
- You've corrected Claude on the same thing 3+ times
- You have a retro pattern with impact score > 6
- You find yourself typing the same instructions repeatedly

**Fix:** Write a skill. Start minimal (under 50 lines). Add constraints only after you see specific failures.

### Signs you should delete a skill
- It has zero retro entries (nobody uses it)
- It duplicates what CLAUDE.md already handles
- The hook enforcement annoys more than it helps

**Fix:** Delete it. Fewer skills = each skill gets more attention from the model.

## How to test skill changes

1. Make the edit
2. Start a fresh Claude Code session (skills load at session start)
3. Give it a task that should trigger the skill
4. Check: Did it activate? Did the output match what you wanted?
5. If not, check the skill-eval hook output (verbose mode: `claude --verbose`)

## Model selection guide

| Role | Model | Why |
|------|-------|-----|
| Discovery/scouting | haiku | Fast, cheap, doesn't need reasoning for grep+read |
| Implementation/review | sonnet | Good balance of speed and quality for code tasks |
| Your main session | opus (when available) | Architecture, complex reasoning, multi-step planning |

Don't use opus for agents that just grep and read files. Don't use haiku for agents that need to reason about code quality.

## File organization

```
~/.claude/                          # Global (all projects)
├── CLAUDE.md                       # ≤15 lines. Personal coding philosophy only.
├── agents/                         # Your agents (shared across projects)
├── skills/                         # Your skills (shared across projects)
├── commands/                       # Your slash commands
└── retros/
    └── log.md                      # Retro observations

your-project/
├── CLAUDE.md                       # ≤80 lines. Project-specific conventions.
├── .claude/
│   ├── settings.json               # Hooks config
│   ├── settings.local.json         # Personal overrides (gitignored)
│   ├── hooks/                      # Hook scripts
│   ├── agents/                     # Project-specific agents (override global)
│   ├── skills/                     # Project-specific skills (override global)
│   └── commands/                   # Project-specific commands
└── src/
```

Project-level skills/agents override global ones with the same name. Use global for your pipeline, project-level for project-specific conventions.

## The #1 rule

**If you change a skill and it doesn't improve your next 3 sessions, revert it.**

Skills are not aspirational documents. They're operational tools. If a rule doesn't change behavior, it's wasting tokens.
