# Cheatsheet

## Commands (you type these)

| Command | When | What happens |
|---------|------|-------------|
| `/gather [task]` | Starting any new work | Scouts repo → analyzes codebase → asks blocking questions → produces SPEC → enters plan mode |
| `/tdd [feature]` | Implementing with tests first | RED (failing tests) → GREEN (minimal impl) → REFACTOR → commit |
| `/retro` | Something went wrong | Logs observation with severity to ~/.claude/retros/log.md |
| `/retro review` | Periodically (weekly) | Analyzes retro log → finds patterns → proposes skill edits → applies with confirmation |
| `/review` | Before merging a branch | Thorough code review: spec compliance, correctness, tests, security, conventions |

## Auto-activating skills (you don't invoke these)

| Skill | Triggers on | What it does |
|-------|------------|-------------|
| git-workflow | Any git commit/branch/PR operation | Enforces conventional commits, feature branches, rebase, force-with-lease |
| troubleshoot | 2nd failed fix attempt, unfamiliar tool debugging | Forces research-first via tool-researcher, 2-strike escalation |
| using-skills | Every session (via SessionStart hook) | Reminds Claude to check skills before responding |

## Hooks (always running)

| Hook | Event | Effect |
|------|-------|--------|
| session-start.sh | Every session start/resume/compact | Injects branch, stack, skill reminder into context |
| skill-eval.sh | Every user message | Forces skill evaluation before responding |
| auto-format.sh | Every file Write/Edit | Runs gofmt/rustfmt/prettier/dotnet-format |
| commit-validator.sh | Any `git commit -m` | Blocks non-conventional commits. Blocks commits to main. |
| stop-gate.sh | Claude tries to finish | Runs test suite. Blocks if tests fail. Suggests self-review. |
| pre-compact.sh | Before context compaction | Saves branch, recent commits, uncommitted files |

## Agents (called by skills, not by you)

| Agent | Called by | Model | Purpose |
|-------|----------|-------|---------|
| repo-scout | requirements-gatherer | haiku | Fast repo mapping (1 bash call) |
| codebase-analyzer | requirements-gatherer | haiku | Conventions + domain in one pass |
| tool-researcher | troubleshoot | sonnet | Web research on unfamiliar tools |
| self-reviewer | stop-gate hook | sonnet | Semantic review (plan mode, read-only) |
| code-reviewer | /review command | sonnet | Thorough PR-style review (plan mode) |

## Typical workflows

**New feature:**
```
/gather add user authentication
→ (answers questions)
→ SPEC produced
→ "Begin planning" → EnterPlanMode
→ plan approved → context cleared
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
→ fix applied
→ stop-gate runs tests
→ commit via git-workflow
```

**Quick change:**
```
"fix the typo in header.tsx"
→ no skills needed, direct edit
→ auto-format runs
→ stop-gate checks tests
→ user decides to commit or not
```
