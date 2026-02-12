# Global Rules

These rules apply to all projects when claude-skills is installed. Project-level CLAUDE.md files can extend these but should not contradict them.

## Identity

You use a skills-based development system. Skills define workflows. Hooks enforce them. Agents execute in isolated contexts. Follow the skills -- they are not suggestions.

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

If you announce a skill, follow it completely. Every phase, every gate. If you announce "targeted fix," do not secretly run requirements-gatherer or skip committing.

## Implementation Workflow

When executing a plan (e.g. from /requirements-gatherer), follow this workflow:

### 1. Implement with TDD
- Follow red-green TDD: write a failing test first, then implement the code to make it pass
- TDD applies to all runnable code including frontend components and styling/design token changes
- TDD does NOT apply to configuration files, manifests, or other non-runnable files
- If a test does not pass after implementation, investigate and fix until it does

### 2. Verify (definition of done)
- Run linters, formatters, build, and tests
- If anything fails, fix it and recommit automatically
- Implementation is not complete until all checks pass

## Skills

### requirements-gatherer

Orchestrates parallel subagents (repo-scout, codebase-analyzer) to explore the repository, then synthesizes blocking questions into a SPEC. Use for new features or unclear scope. Do NOT use for targeted fixes where the file, line, and change are already known.

### tdd

RED-GREEN-REFACTOR-COMMIT. Each phase runs as a separate Task (isolated context).

- RED: Write tests that FAIL against current code. Tests must exercise NEW behavior. If all tests pass, they are wrong -- delete and rewrite. This gate is non-negotiable.
- GREEN: Write MINIMUM code to make tests pass. Do not modify tests. Do not add features beyond what tests require.
- REFACTOR: Mandatory phase. "No refactoring needed" is valid, but the phase must run.
- COMMIT: Commit using git-workflow conventions. Uncommitted work is unfinished work.

### review

Structured code review producing a [CRIT]/[WARN]/[INFO] severity report. Runs as a subagent so the diff does not persist in the main context.

Routes by input:
- No arguments: reviews local git diff (branch vs main, or working tree)
- GitHub PR URL or `owner/repo#N`: fetches via `gh` CLI, reviews remotely
- File path: reviews that specific file

Never posts to GitHub. Read-only.

### git-workflow

Conventional commits, feature branches, rebase over merge, force-with-lease. PR-aware: checks for PR after push, routes merge through `gh pr merge` when PR exists.

After ANY code change: commit immediately. Do not declare "Done" without committing. The stop-gate hook blocks this.

### troubleshoot

Phased systematic debugging (Phase 0-3: triage, investigate, hypothesize, fix). Dispatches tool-researcher for unfamiliar tools. Hard phase gates for unfamiliar systems; skippable with evidence for obvious issues. 2-strike escalation: if a fix fails twice, stop, research deeper, and report.

### retro

Two modes: "log" captures observations to ~/.claude/retros/log.md. "review" analyzes accumulated entries for patterns and proposes skill improvements.

### sumo-search

Sumo Logic Search Query Language reference and best practices. Invoke with `/search` when writing or debugging Sumo Logic queries.

### temporal

Temporal platform documentation and operational reference. Invoke with `/temporal` when working with Temporal workflows or troubleshooting operational issues.

## Hooks (always running)

| Hook | Event | What it does |
|---|---|---|
| session-start | SessionStart | Injects branch, stack, and skill reminder into context |
| skill-eval | UserPromptSubmit | Detects targeted fixes to skip requirements-gatherer; otherwise reminds to evaluate skills |
| auto-format | PostToolUse (Write/Edit) | Runs language-appropriate formatter (gofmt, rustfmt, prettier, dotnet-format) |
| commit-validator | PreToolUse (Bash) | Blocks non-conventional commit messages. Blocks commits to main/master. |
| stop-gate | Stop | Runs test suite (auto-detects pnpm/yarn/bun/npm). Blocks if tests fail. Blocks if code changes are uncommitted. |
| pre-compact | PreCompact | Saves branch, recent commits, and uncommitted file list before context compaction |

Hooks provide baseline enforcement regardless of which skill is active. Do not duplicate what hooks do (e.g., do not manually run the test suite at the end of a task -- stop-gate does this).

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
