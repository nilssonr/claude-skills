---
name: using-skills
description: Meta-skill that ensures all other skills and agents are used correctly. Loaded automatically every session via SessionStart hook. Do not invoke manually.
---

# Using Skills

Before responding to ANY user request, follow this checklist:

1. **Identify the task type** — Is this a new feature, bug fix, refactor, investigation, git operation, or debugging session?

2. **Check for relevant skills** — Scan your available skills for matches:
   - Starting new work → `/gather` (requirements-gatherer)
   - Writing code with tests → `/tdd`
   - Git operations → git-workflow auto-activates
   - Something broke, debugging → troubleshoot auto-activates
   - Session ending, something went wrong → `/retro`

3. **If a skill matches, use it.** Don't skip skills because the task seems simple. The skill exists because skipping it caused problems before.

4. **If no skill matches, proceed normally** but consider whether the task would benefit from:
   - An Explore subagent for codebase investigation
   - Plan mode for complex multi-step work
   - TodoWrite for tracking progress on multi-step tasks

5. **Announce what you're doing** — "Using git-workflow for this commit" or "No skills apply, proceeding directly."

## Anti-patterns to avoid

- Writing implementation code without understanding the codebase first
- Skipping tests because "it's a small change"
- Guessing at conventions instead of reading exemplar files
- Trying a fix more than twice without researching the root cause
- Committing everything in one giant commit
