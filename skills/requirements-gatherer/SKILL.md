---
name: requirements-gatherer
description: Gathers complete requirements before code planning begins. Invoke manually at the start of any code-related workflow (new feature, bug fix, refactor, architecture decision) or reactively when ambiguity surfaces mid-conversation. Orchestrates focused agents to explore the repository, identify patterns, investigate the task domain, and synthesize questions. Produces a spec then transitions to native plan mode for implementation planning. Triggers on "let's gather requirements", "what do we need to know", "before we start", or when unresolved ambiguity is detected.
disable-model-invocation: true
---

# Requirements Gatherer

Orchestrates subagents to gather complete, unambiguous requirements before code planning begins.

## Core Principle

**Never produce a spec until all blocking questions are resolved.**

## Invocation

### Manual
User explicitly starts: "Let's gather requirements for adding a user endpoint."

### Reactive
Triggered mid-conversation when ambiguity surfaces. Always start with:
> "What is the current goal right now? (one sentence)"

## Subagents

You delegate to these subagents (they must be installed in `~/.claude/agents/` or `.claude/agents/`):

| Agent | Purpose | Model | max_turns |
|-------|---------|-------|-----------|
| `repo-scout` | Structure, stack, entry points | haiku | 8 |
| `pattern-analyzer` | Conventions, patterns | haiku | 8 |
| `domain-investigator` | Domain-specific code, gaps | haiku | 8 |
| `question-synthesizer` | Prioritize questions | sonnet | 1 |

**Always set `max_turns`** when launching subagents. This is the only reliable way to enforce tool call budgets.

## Workflow

### 1. Confirm Goal
If reactive invocation, ask: "What is the current goal right now?"

Get repo path and task description from user.

### 2. Run Repo Scout
Delegate to `repo-scout` with the repo path and task context.

Review the report. If status is `INSUFFICIENT_CONTEXT`, ask the blocking question before continuing.

**Important:** When passing context to subsequent agents, include the file list and structure from repo-scout's findings so they don't re-explore the repo.

### 3. Assess Complexity and Choose Path

Based on scout report, decide how to proceed:

**Lightweight path** — Scout reports stubs, scaffolding, or empty files:
- Skip pattern-analyzer and domain-investigator
- Pass scout findings directly to question-synthesizer
- Don't waste time searching empty directories

**Standard path** — Small-to-medium repo with real code:
- Run pattern-analyzer and domain-investigator
- Can run them together or sequentially
- Pass all reports to question-synthesizer

**Full path** — Large repo, monorepo, or complex task:
- Run pattern-analyzer first
- Run domain-investigator with pattern context
- Pass all reports to question-synthesizer

### 4. Run Question Synthesizer
Always runs, regardless of path.

Delegate to `question-synthesizer` with **all content inline in the prompt** (not as file references). The synthesizer has no tools — it cannot read files. You must embed:
- The full text of all reports gathered so far
- Task goal
- Any facts user already provided
- A `files_read` manifest listing every file the previous agents examined

Set `max_turns: 1` — the synthesizer must produce its output in a single response.

### 5. Ask Questions
Ask blocking questions one at a time. An answer may resolve multiple questions.

If user says "I don't know," propose options with tradeoffs:
> "I need to know X. Options are:
> - A: [tradeoff]
> - B: [tradeoff]
> Which fits best?"

Never halt. Always propose options.

### 6. Resolution Hierarchy
A question is resolved when:
1. User explicitly answers
2. Repo confirms and user doesn't contradict
3. Documented default exists and user accepts

### 7. Produce Spec
Only when all blocking questions are resolved.

```
SPEC: [task-id]
Repo: [path]
Commit: [hash]
Generated: [timestamp]

GOAL
[What we're doing and why]

SCOPE
In: [included]
Out: [excluded]

DECISIONS
- DECISION: [thing] — [user chose]
- REPO: [thing] — [code confirms]
- DEFAULT: [thing] — [assumed because X]

CONSTRAINTS
[Pin to specific files, not categories]

DONE WHEN
[Concrete, testable acceptance criteria]
```

**Output rules:**
- Labels (DECISION/REPO/DEFAULT) are mandatory
- CONSTRAINTS reference specific files
- DONE WHEN must be testable
- No unlabeled assumptions

### 8. Transition to Planning

After producing the SPEC, present choices using AskUserQuestion:

question: "SPEC complete. How would you like to proceed?"
options:
  - label: "Begin planning"
    description: "Enter plan mode to create an implementation plan from this SPEC"
  - label: "Revise requirements"
    description: "Provide feedback and update the SPEC"

**Behavior per choice:**

| Choice | Action |
|--------|--------|
| Begin planning | Call `EnterPlanMode` tool. Native plan mode will use the SPEC in context to produce an implementation plan. |
| Revise requirements | Ask "What would you like to change?" then update the SPEC accordingly. Re-present choices after revision. |
| Custom | Follow user direction. |

**Note:** Native plan mode will handle:
- Implementation plan creation
- Approval UX (implement, reject, edit)
- Context clearing option
- Plan file persistence to `~/.claude/plans/`

## Failure Modes to Avoid

- **Running all agents on empty repos.** If scout says stubs, skip the detailed analysis.
- **Re-asking what user told you.** Pass user facts to question-synthesizer.
- **Accepting vague answers.** "Just make it work" is not a resolution.
- **Hidden assumptions.** Every assumption needs a label.

## Integration

### Handoff to Plan Mode
The SPEC is the interface. After user selects "Begin planning", `EnterPlanMode` is called. Native plan mode uses the SPEC to produce an implementation plan with:
- Approval UX (implement, reject, edit)
- Optional context clearing
- Plan file persistence to `~/.claude/plans/`

### Failure Attribution
- Plan mode asks questions not answered by SPEC → requirements gap
- Plan diverges from SPEC → planning gap
- Code diverges from plan → execution gap
