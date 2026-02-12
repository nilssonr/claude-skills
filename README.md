# Claude Skills

**Turn Claude Code into an opinionated engineering partner.**

Out of the box, Claude Code is capable but freeform -- it'll do whatever you ask, however it feels like. This project gives it structure. Skills define *how* work gets done. Hooks enforce the rules automatically. The result: Claude follows real engineering workflows instead of winging it.

Tests before code. Commits after every change. Research before guessing. No exceptions.

## What's in the box

```
skills/     Workflows that Claude follows step-by-step
agents/     Specialized sub-models that skills dispatch for focused work
hooks/      Shell scripts that enforce the rules -- always on, no opt-out
```

## Get started

```sh
make install    # Copy everything to ~/.claude/
make link       # Or symlink -- edits in this repo go live immediately
make status     # See what's installed
make validate   # Verify everything is wired up correctly
make uninstall  # Clean removal
```

That's it. Next time you open Claude Code, the skills are active.

## Skills you invoke

These are your commands. Type them and Claude switches into that workflow.

| Skill | Command | What happens |
|-------|---------|-------------|
| **requirements-gatherer** | `/requirements-gatherer` | Scouts the repo with parallel agents, surfaces blocking questions, produces a SPEC, enters plan mode. Use this before building anything non-trivial. |
| **tdd** | `/tdd` | RED -- write a failing test. GREEN -- minimum code to pass. REFACTOR -- clean up. COMMIT. Every phase is enforced. No skipping. |
| **review** | `/review` | 9-dimension code review with [CRIT]/[WARN]/[INFO] severity. Works on local diffs, specific files, or GitHub PRs via `gh`. Read-only -- never posts comments. |
| **retro** | `/retro` | Logs what went wrong. Run `/retro review` later to analyze patterns and propose skill improvements. Your feedback loop. |
| **sumo-search** | `/search` | Sumo Logic Search Query Language reference. Covers search operators, parsing, aggregation, time-series, enrichment, pattern detection, and query optimization. Backed by 214 official docs. |
| **temporal** | `/temporal` | Temporal platform documentation and operational reference. Covers workflow definitions, activities, deployment, configuration, monitoring, and best practices across Go, Java, Python, TypeScript, PHP, .NET, and Ruby SDKs. Backed by 266 official docs. |

## Skills that activate themselves

You don't call these -- they kick in when the situation demands it.

| Skill | Triggers on | What it does |
|-------|------------|-------------|
| **git-workflow** | Any git operation | Conventional commits, feature branches, rebase over merge, `--force-with-lease`. No commits to main. PR-aware push and merge. |
| **troubleshoot** | Failed fix, unfamiliar tool, or `/troubleshoot` | Four-phase systematic debugging (triage, investigate, hypothesize, fix). Dispatches tool-researcher for unfamiliar tools. Two strikes and it escalates with a full report. |
| **using-skills** | Every session start | The meta-skill. Reminds Claude to check which skill applies before doing anything. |

## Hooks (the guardrails)

These run in the background on every session. They don't care what skill is active -- they enforce the baseline.

| Hook | Fires on | What it enforces |
|------|----------|-----------------|
| **session-start** | Session start, resume, compact | Injects branch context and skill reminder |
| **skill-eval** | Every user message | Forces Claude to evaluate which skill applies before responding |
| **auto-format** | Every file write or edit | Runs the right formatter (gofmt, rustfmt, prettier, dotnet-format) |
| **commit-validator** | Any `git commit -m` | Blocks non-conventional commit messages and commits to main |
| **stop-gate** | Claude tries to finish | Runs the test suite. Blocks if tests fail. Blocks if code is uncommitted. |
| **pre-compact** | Before context compaction | Saves branch state so nothing is lost when the context window rotates |

## Agents (the specialists)

Skills dispatch these as isolated sub-models. They do one thing well and report back.

| Agent | Dispatched by | Model | Job |
|-------|--------------|-------|-----|
| **repo-scout** | requirements-gatherer | haiku | Fast repo structure mapping |
| **codebase-analyzer** | requirements-gatherer | haiku | Convention and domain analysis in a single pass |
| **tool-researcher** | troubleshoot | sonnet | Web research on unfamiliar tools, libraries, and error messages |
| **code-reviewer** | review | sonnet | Structured 9-dimension code review |

## Workflows in practice

**Building a feature:**
```
/requirements-gatherer add user authentication
  --> answer a few blocking questions --> SPEC produced --> plan mode
/tdd first acceptance criterion
  --> RED --> GREEN --> REFACTOR --> committed
/tdd next criterion
  --> repeat until done
/review
  --> 9-dimension review of everything on the branch
git push, open PR
```

**Fixing a bug:**
```
"Login fails when email has a plus sign"
  --> troubleshoot activates if needed
  --> tool-researcher investigates the root cause
  --> fix applied --> stop-gate runs tests --> committed
```

**One-liner:**
```
"use crypto.timingSafeEqual in handler.ts:45"
  --> direct fix --> auto-format --> stop-gate --> committed
```

## Philosophy

This project exists because "just ask Claude to do it" doesn't scale. When the workflows are explicit and the guardrails are automatic, you spend less time correcting and more time building. The skills aren't suggestions -- they're the way work gets done.

Fork it. Adapt it. Make it yours.
