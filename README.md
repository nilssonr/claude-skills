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

## Prerequisites

- [ast-grep](https://ast-grep.github.io/) -- structural code search used by codebase-analyzer. Install: `brew install ast-grep`

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
| **requirements-gatherer** | `/requirements-gatherer` | Scouts the repo with parallel agents, delegates synthesis to requirements-synthesizer (haiku), surfaces blocking questions, produces a SPEC, enters plan mode. |
| **tdd** | `/tdd` | RED (sonnet, parallel fan-out for 3+ criteria) -- GREEN+REFACTOR (single haiku agent) -- COMMIT. Every phase gate is enforced. No skipping. |
| **review** | `/review` | 11-dimension code review with size-based routing. Small diffs get one agent; large diffs fan out to parallel agents. Works on local diffs, files, GitHub PRs, or full repository snapshots (`/review repo`). Read-only. |
| **retro** | `/retro` | Logs what went wrong. Run `/retro review` to delegate pattern analysis to retro-analyzer (haiku) and propose skill improvements. |
| **sumo-search** | `/search` | Sumo Logic Search Query Language reference. Covers search operators, parsing, aggregation, time-series, enrichment, pattern detection, and query optimization. Backed by 214 official docs. |
| **temporal** | `/temporal` | Temporal platform documentation and operational reference. Covers workflow definitions, activities, deployment, configuration, monitoring, and best practices across Go, Java, Python, TypeScript, PHP, .NET, and Ruby SDKs. Backed by 266 official docs. |
| **frontend-design** | `/frontend-design` | Creates distinctive, production-grade frontend interfaces with bold aesthetic direction. Avoids generic AI aesthetics. Works with HTML/CSS/JS, React, Vue, etc. |

## Skills that activate themselves

You don't call these -- they kick in when the situation demands it.

| Skill | Triggers on | What it does |
|-------|------------|-------------|
| **git-workflow** | Any git operation | Conventional commits, feature branches, worktrees for parallel sessions, rebase over merge, `--force-with-lease`. Delegates PR composition to pr-composer (haiku). PR-aware push and merge. |
| **troubleshoot** | Failed fix, unfamiliar tool, or `/troubleshoot` | Classification gate loads only needed references. Phases 0-2 dispatched as troubleshoot-investigator agents (sonnet). Background tool-researcher for unfamiliar tools. Two strikes and it escalates. |
| **using-skills** | Every session start | The meta-skill. Reminds Claude to check which skill applies before doing anything. |

## Hooks (the guardrails)

These run in the background on every session. They don't care what skill is active -- they enforce the baseline.

| Hook | Fires on | What it enforces |
|------|----------|-----------------|
| **session-start** | Session start, resume, compact | Injects branch and stack context |
| **auto-format** | Every file write or edit | Runs the right formatter (gofmt, rustfmt, prettier, dotnet-format) |
| **commit-validator** | Any `git commit -m` | Blocks non-conventional commit messages and commits to main |
| **stop-gate** | Claude tries to finish | Runs the test suite. Blocks if tests fail. Blocks if code is uncommitted. |
| **pre-compact** | Before context compaction | Saves branch state so nothing is lost when the context window rotates |

## Agents (the specialists)

Skills dispatch these as isolated sub-models. They do one thing well and report back.

| Agent | Dispatched by | Model | Job |
|-------|--------------|-------|-----|
| **repo-scout** | requirements-gatherer | haiku | Fast repo structure mapping |
| **codebase-analyzer** | requirements-gatherer | haiku | Convention and domain analysis with ast-grep structural search |
| **requirements-synthesizer** | requirements-gatherer | haiku | Synthesizes scout reports into questions and SPEC |
| **tool-researcher** | troubleshoot | sonnet | Web research on unfamiliar tools, libraries, and error messages |
| **troubleshoot-investigator** | troubleshoot | sonnet | Runs a single troubleshoot phase (0-2), returns concise report |
| **code-reviewer** | review | sonnet | Structured 11-dimension code review (diff-hunk preference) |
| **pr-composer** | git-workflow | haiku | Composes PR title and body from branch context |
| **retro-analyzer** | retro | haiku | Analyzes retro log for patterns, proposes improvements |

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
  --> 11-dimension review of everything on the branch
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
