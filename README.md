# Claude Skills

A collection of skills, agents, and hooks for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Structure

```
skills/     Each subdirectory is a skill (installed to ~/.claude/skills/)
agents/     Each .md file is an agent (installed to ~/.claude/agents/)
hooks/      Shell scripts run automatically on Claude Code events
```

## Installation

```sh
make install    # Copy everything to ~/.claude/
make link       # Symlink instead (edits in repo are live immediately)
make status     # Show what's installed
make validate   # Verify installation is correct
make uninstall  # Remove everything from ~/.claude/
```

## Skills

### User-invoked

| Skill | When | What happens |
|-------|------|-------------|
| requirements-gatherer | Starting any new work | Scouts repo, analyzes codebase, asks blocking questions, produces SPEC, enters plan mode |
| tdd | Implementing with tests first | RED (failing test) → GREEN (minimal impl) → REFACTOR → commit |
| review | Before merging, or to verify work | Structured review across 9 dimensions with [CRIT]/[WARN]/[INFO] severity report. Supports local diffs, specific files, and GitHub PRs |
| retro | Something went wrong | Logs observation with severity to ~/.claude/retros/log.md. Run with `review` arg to analyze patterns and propose skill improvements |

### Auto-activating

These activate automatically — you don't invoke them.

| Skill | Triggers on | What it does |
|-------|------------|-------------|
| git-workflow | Any git commit/branch/PR operation | Enforces conventional commits, feature branches, rebase, force-with-lease |
| troubleshoot | 2nd failed fix attempt, unfamiliar tool debugging | Forces research-first via tool-researcher, 2-strike escalation |
| using-skills | Every session (via SessionStart hook) | Reminds Claude to check skills before responding |

## Hooks

Always running in the background.

| Hook | Event | Effect |
|------|-------|--------|
| session-start.sh | Session start/resume/compact | Injects branch, stack, skill reminder into context |
| skill-eval.sh | Every user message | Forces skill evaluation before responding |
| auto-format.sh | Every file Write/Edit | Runs gofmt/rustfmt/prettier/dotnet-format |
| commit-validator.sh | Any `git commit -m` | Blocks non-conventional commits and commits to main |
| stop-gate.sh | Claude tries to finish | Runs test suite. Blocks if tests fail or code is uncommitted |
| pre-compact.sh | Before context compaction | Saves branch, recent commits, uncommitted files |

## Agents

Called by skills, not by you directly.

| Agent | Called by | Model | Purpose |
|-------|----------|-------|---------|
| repo-scout | requirements-gatherer | haiku | Fast repo mapping |
| codebase-analyzer | requirements-gatherer | haiku | Conventions and domain analysis in one pass |
| tool-researcher | troubleshoot | sonnet | Web research on unfamiliar tools |
| code-reviewer | /review | sonnet | Structured review via review skill |

## Workflows

**New feature:**
```
/gather add user authentication
→ answer questions → SPEC produced → plan mode
→ /tdd [first criterion]
→ repeat for remaining criteria
→ /review
→ git push, PR
```

**Bug fix:**
```
describe the bug
→ troubleshoot auto-activates if needed
→ tool-researcher investigates
→ fix applied → stop-gate runs tests → commit
```

**Targeted fix:**
```
"use crypto.timingSafeEqual in handler.ts:45"
→ direct implementation → auto-format → stop-gate → commit
```
