---
name: temporal
description: Comprehensive Temporal durable execution assistant. Helps with workflow authoring, SDK-specific guidance, code review, troubleshooting, and general questions across all SDKs (Go, Python, TypeScript, .NET, Java, PHP, Ruby). Manual invocation only.
---

# Temporal

Comprehensive assistant for the Temporal durable execution platform.

## Activation

### Explicit Only
User invokes `/temporal` with a question or task.

This skill does NOT auto-activate. Users must explicitly invoke it.

## Core Concepts

| Concept | What it is |
|---------|-----------|
| **Workflow** | Durable, deterministic function defining business logic. Survives crashes via Event History replay. |
| **Activity** | Non-deterministic unit of work (I/O, APIs, DB calls). Auto-retried on failure. |
| **Worker** | Process polling a Task Queue to execute Workflows and Activities. Runs YOUR code — Temporal Service never sees your data. |
| **Temporal Service** | Orchestrator that persists Event History and schedules Tasks. Does NOT run your code. |
| **Signal** | Async message sent to a running Workflow to change state. |
| **Query** | Sync read-only request to get Workflow state. Must not mutate state. |
| **Update** | Sync request that can mutate Workflow state and return a result. |
| **Child Workflow** | Workflow started from another Workflow for composability/partitioning. |
| **Continue-As-New** | Atomically closes a Workflow and starts a new one with same ID, fresh Event History. Use when history grows large. |
| **Timer** | Durable sleep — persisted, survives crashes, resource-light. |
| **Schedule** | Cron-like feature to start Workflows at intervals or specific times. |
| **Nexus** | Cross-namespace/team communication via Nexus Endpoints, Services, and Operations. |

## Determinism (CRITICAL)

Workflow code MUST be deterministic because it replays from Event History. Violations cause `NonDeterministicError`.

**Never do these in Workflow code:**
- I/O (network, disk, stdio) — use Activities instead
- Access system clock — use SDK time APIs
- Use random — use SDK random APIs
- Thread/goroutine creation — use SDK concurrency APIs
- Access mutable external state
- Iterate maps without sorting keys (random order)

For SDK-specific determinism rules and code examples, read the appropriate reference file:
- Go: `refs/determinism/go.md`
- Python: `refs/determinism/python.md`
- TypeScript: `refs/determinism/typescript.md`
- .NET: `refs/determinism/dotnet.md`
- Java: `refs/determinism/java.md`
- PHP: `refs/determinism/php.md`
- Ruby: `refs/determinism/ruby.md`

## When to Read Reference Files

Use this decision tree:

1. **SDK-specific question?** → Read `refs/determinism/{sdk}.md`
2. **Design pattern question?** → Read `refs/patterns.md`
3. **Timeout/retry question?** → Read `refs/timeouts-retries.md`
4. **Nexus question?** → Read `refs/nexus.md`
5. **Error/debugging question?** → Read `refs/troubleshooting.md`

## Delegation to Agents

For complex tasks, delegate to specialized agents:

| Task | Agent | When to use |
|------|-------|-------------|
| Code review | `temporal-reviewer` | User asks to review Temporal code, or you're about to review a PR/file with Temporal code |
| Debugging | `temporal-debugger` | User reports an error, workflow stuck, or unexpected behavior |

## Quick Reference

### Timeouts

| Timeout | What it controls |
|---------|-----------------|
| **StartToCloseTimeout** | Max time for a single Activity attempt. REQUIRED (or ScheduleToClose). |
| **ScheduleToCloseTimeout** | Max time from scheduling to completion, including retries. |
| **ScheduleToStartTimeout** | Max time waiting in Task Queue. |
| **HeartbeatTimeout** | Max time between heartbeats — set for long-running Activities. |
| **WorkflowExecutionTimeout** | Max time for entire Workflow including retries and Continue-As-New chain. |
| **WorkflowRunTimeout** | Max time for a single Workflow run. |

### Retry Policy Defaults

```
InitialInterval:    1s
BackoffCoefficient: 2.0
MaximumInterval:    100 * InitialInterval
MaximumAttempts:    unlimited
```

Activities retry by default. Workflows do NOT retry by default.

## Rules

1. **Always identify the SDK language** before giving code examples.
2. **If SDK is unclear, ask** which language they're using.
3. **Provide idiomatic code** for the target SDK — don't transliterate from another language.
4. **Read the appropriate ref file** before giving SDK-specific advice.
5. **Prioritize determinism violations** and missing timeouts when reviewing code.
6. **For troubleshooting**, check Worker logs and Event History first.
7. **Delegate to agents** for code review and debugging tasks.
