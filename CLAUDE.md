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

If you announce a skill, follow it completely. Every phase, every gate. If you announce "targeted fix," do not secretly run requirements-gatherer or skip committing.

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

Structured code review producing a [CRIT]/[WARN]/[INFO] severity report. Runs as a subagent (context: fork, agent: code-reviewer) so the diff does not persist in the main context.

Routes by input:
- No arguments: reviews local git diff (branch vs main, or working tree)
- GitHub PR URL or `owner/repo#N`: fetches via `gh` CLI, reviews remotely
- File path: reviews that specific file

Reads `skills/review/references/dimensions.md` for the 9-dimension checklist and `skills/review/references/severity-and-format.md` for severity definitions, output format, and rules.

Never posts to GitHub. Read-only.

### git-workflow

Conventional commits, feature branches, rebase over merge, force-with-lease.

After ANY code change: commit immediately. Do not declare "Done" without committing. The stop-gate hook blocks this.

### troubleshoot

Phased systematic debugging (Phase 0-3: triage, investigate, hypothesize, fix). Loads reference files for methodology, stack trace handling, and interaction policy. Dispatches tool-researcher for unfamiliar tools. Hard phase gates for unfamiliar systems; skippable with evidence for obvious issues. 2-strike escalation: if a fix fails twice, stop, research deeper, and report.

### retro

Two modes: "log" captures observations to ~/.claude/retros/log.md. "review" analyzes accumulated entries for patterns and proposes skill improvements.

### sumo-search

Sumo Logic Search Query Language reference and best practices. Provides comprehensive SumoQL guidance -- search operators, parse operators, aggregation, time-series analysis, enrichment, pattern detection, and query optimization. Backed by 214 official Sumo Logic documentation files.

Invoke with `/search` when writing or debugging Sumo Logic queries.

### temporal

Temporal platform documentation and operational reference. Provides comprehensive guidance on workflow definitions, activities, deployment, configuration, monitoring, and best practices across Go, Java, Python, TypeScript, PHP, .NET, and Ruby SDKs. Backed by 266 official Temporal documentation files.

Invoke with `/temporal` when working with Temporal workflows, designing temporal solutions, or troubleshooting operational issues.

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

The review skill applies 9 dimensions in priority order (Code Review Pyramid -- spend most time on correctness/security, least on style):

1. Correctness -- off-by-one, null handling, boundary conditions, race conditions, resource leaks, logic errors
2. Security -- injection (CWE-89, CWE-78), XSS (CWE-79), auth/authz (CWE-862/863), hardcoded secrets (CWE-798), deprecated crypto, deserialization (CWE-502), SSRF (CWE-918), timing attacks
3. Error handling -- swallowed errors [CRIT], missing context [WARN], overly broad catches [WARN], retry without backoff, fail-fast principle
4. Performance -- N+1 queries [CRIT], O(n^2) in nested loops [WARN], unbounded allocations [WARN], sync blocking in async [CRIT]
5. Defensiveness -- input validation at trust boundaries, preconditions, resource pairing, timeouts on external calls
6. Readability -- cyclomatic complexity (<=10 ok, >20 [CRIT]), cognitive complexity (<=15 ok), function length (<=40 ok, >100 [CRIT]), nesting depth (<=3 ok)
7. Testability -- constructor doing real work, Law of Demeter violations, global state, SRP violations
8. Consistency -- codebase pattern adherence, DRY (rule of three), abstraction level alignment
9. API design -- backward compatibility, idempotency, Hyrum's Law awareness, error response structure

Severity:
- [CRIT]: Would cause a production incident. Bugs, security vulnerabilities, data loss, race conditions.
- [WARN]: Should fix before or shortly after merge. Design concerns, performance issues, missing tests, excessive complexity.
- [INFO]: Take it or leave it. Naming, docs, minor simplification.

Style (formatting, whitespace, import order) is NOT a review finding. It belongs to linters.

Maximum 15 findings per review. If more exist, report the 15 highest-severity and note omissions. Never fabricate findings -- PASS with zero findings is a valid and good outcome.

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
