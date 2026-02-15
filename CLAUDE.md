# CLAUDE.md

## Identity

This project uses a skills-based development plugin. Skills define workflows. Hooks enforce them. Agents execute in isolated contexts. You follow the skills -- they are not suggestions.

## Workflow: Classify, Announce, Execute

Before responding to ANY request, classify the task and announce your decision. The announcement is your first output -- before code, before questions, before investigation.

| Classification | Skill | Announcement |
|---|---|---|
| Targeted fix (specific file:line, known change) | None | `[SKILL:none] Targeted fix -- proceeding directly.` |
| New feature / unclear scope | requirements-gatherer | `[SKILL:requirements-gatherer] Defining scope.` |
| Test-first development | tdd | `[SKILL:tdd] Starting RED phase.` |
| Git operation | git-workflow | `[SKILL:git-workflow] Active.` |
| Debugging / 2nd failed attempt | troubleshoot | `[SKILL:troubleshoot] Researching before fixing.` |
| Something went wrong | retro | `[SKILL:retro] Logging observation.` |
| Review requested or verifying work | review | `[SKILL:review] Reviewing [scope].` |
| Sumo Logic query or log analysis | sumo-search | `[SKILL:search] Querying SumoQL.` |
| Temporal workflow questions | temporal | `[SKILL:temporal] Consulting Temporal reference.` |
| Frontend UI/component building | frontend-design | `[SKILL:frontend-design] Designing interface.` |

If you announce a skill, follow it completely. Every phase, every gate. If you announce "targeted fix," do not secretly run requirements-gatherer or skip committing.

## Skills

### requirements-gatherer

Launches repo-scout and codebase-analyzer in parallel, delegates synthesis to requirements-synthesizer agent (haiku). Produces blocking questions, then a SPEC. Use for new features or unclear scope. Do NOT use for targeted fixes.

### tdd

RED-GREEN+REFACTOR-COMMIT. RED phase in isolated sonnet agent (parallel fan-out for 3+ independent criteria). GREEN+REFACTOR merged into single haiku agent. COMMIT in main context.

- RED: Write tests that FAIL. This gate is non-negotiable.
- GREEN+REFACTOR: Minimum implementation, then cleanup. Tests must pass at exit.
- COMMIT: Commit using git-workflow conventions. Uncommitted work is unfinished work.

### review

Structured code review with size-based routing. Small reviews (<=20 files, <=3000 lines) use a single code-reviewer agent. Large reviews fan out to parallel agents grouped by security-sensitivity and directory. Never posts to GitHub. Read-only.

### git-workflow

Conventional commits, feature branches, rebase over merge, force-with-lease. Delegates PR composition to pr-composer agent (haiku). PR-aware: checks for PR after push, routes merge through `gh pr merge` when PR exists.

After ANY code change: commit immediately. Do not declare "Done" without committing. The stop-gate hook blocks this.

### troubleshoot

Classification gate determines reference loading (saves tokens on obvious issues). Phases 0-2 dispatched as troubleshoot-investigator agents (sonnet). Phase 3 (fix) stays in main context. Background tool-researcher for unfamiliar tools. 2-strike escalation.

### retro

Two modes: "log" captures observations to ~/.claude/retros/log.md. "review" delegates to retro-analyzer agent (haiku) for pattern analysis and improvement proposals.

### sumo-search

Sumo Logic Search Query Language reference and best practices. Provides comprehensive SumoQL guidance -- search operators, parse operators, aggregation, time-series analysis, enrichment, pattern detection, and query optimization. Backed by 214 official Sumo Logic documentation files.

Invoke with `/search` when writing or debugging Sumo Logic queries.

### temporal

Temporal platform documentation and operational reference. Provides comprehensive guidance on workflow definitions, activities, deployment, configuration, monitoring, and best practices across Go, Java, Python, TypeScript, PHP, .NET, and Ruby SDKs. Backed by 266 official Temporal documentation files.

Invoke with `/temporal` when working with Temporal workflows, designing temporal solutions, or troubleshooting operational issues.

### frontend-design

Creates distinctive, production-grade frontend interfaces with bold aesthetic direction. Guides typography, color, motion, spatial composition, and visual detail choices. Avoids generic AI aesthetics.

Invoke with `/frontend-design` when building web components, pages, or applications.

## Hooks (always running)

| Hook | Event | What it does |
|---|---|---|
| session-start | SessionStart | Injects branch, stack, and skill reminder into context |
| skill-eval | UserPromptSubmit | Detects targeted fixes (file paths with extensions or line numbers) to skip requirements-gatherer; otherwise reminds to evaluate skills |
| auto-format | PostToolUse (Write/Edit) | Runs language-appropriate formatter (gofmt, rustfmt, prettier, dotnet-format) |
| commit-validator | PreToolUse (Bash) | Blocks non-conventional commit messages. Blocks commits to main/master. |
| stop-gate | Stop | Runs test suite (auto-detects pnpm/yarn/bun/npm). Blocks if tests fail. Blocks if code changes are uncommitted. |
| pre-compact | PreCompact | Saves branch, recent commits, and uncommitted file list before context compaction |

Hooks provide baseline enforcement regardless of which skill is active. You do not need to duplicate what hooks do (e.g., do not manually run the test suite at the end of a task -- stop-gate does this).

## Review Standards

The review skill applies 9 dimensions (Code Review Pyramid). Full checklist in `skills/review/references/dimensions.md`. Severity definitions in `skills/review/references/severity-and-format.md`. Maximum 15 findings. Style belongs to linters, not reviews.

## Git Conventions

- Branch naming: `type/description` (e.g., `feat/add-oauth`, `fix/timing-safe-compare`)
- Commit format: `type(scope): description` -- types: feat, fix, docs, style, refactor, test, chore
- Breaking changes: `type(scope)!: description`
- Rebase over merge. Always.
- Push after rebase: `git push --force-with-lease` (never `--force`)
- Small logical commits over big batched ones
- Use HEREDOC for multi-line commit messages to avoid escaping issues

## Constraints

- Never use emoji in any output -- code, docs, skills, or conversation.
- Never commit to main/master. Create a feature branch first.
- Never post review comments to GitHub. Reviews are local-only.
- Never skip TDD phase gates. RED must fail before GREEN. REFACTOR must run. COMMIT must happen.
- Never declare "Done" with uncommitted code.
- Never run the test suite manually at the end of a task -- the stop-gate hook handles this.
- Never use `--force` for git push. Use `--force-with-lease`.

## Rationalization Detection

If you catch yourself thinking any of these, you are about to violate the workflow:
- "This is too simple for a skill" -- Maybe. But announce your decision explicitly.
- "I already know the answer" -- Announce "targeted fix" and proceed.
- "The user seems impatient" -- Skills save time by preventing rework.
- "I'll just do it quickly" -- That's how tests get skipped and commits get forgotten.
- "The tests already pass" -- Then you wrote the wrong tests. RED means they must FAIL first.
- "No refactoring needed so I'll skip the phase" -- The phase must RUN. "No changes" is the outcome, not the reason to skip.
- "I'll commit later" -- No. Commit now. The stop-gate will block you anyway.
