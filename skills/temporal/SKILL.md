---
name: temporal
description: Temporal durable execution assistant. Activates on /temporal or auto-detects Temporal usage (imports, stack traces, config files). Helps with workflow authoring, troubleshooting, code review, and general questions across all SDKs (Go, .NET, TypeScript, Python, Java, PHP, Ruby).
---

# Temporal

Comprehensive assistant for the Temporal durable execution platform.

## Activation

### Explicit
User invokes `/temporal` with a question or task.

### Auto-detect
Activate when you observe any of:
- Temporal SDK imports (`go.temporal.io/sdk`, `Temporalio.*`, `@temporalio/*`, `temporalio`, etc.)
- Temporal stack traces or error messages (e.g. `NonDeterministicError`, `WorkflowTaskFailed`)
- Temporal config files, Task Queue references, or Workflow/Activity definitions
- User mentions Temporal concepts (Workflow, Activity, Worker, Signal, Query, etc.)

When auto-detecting, assist naturally without announcing the skill activation.

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
| **Nexus** | Cross-namespace/team communication via Nexus Endpoints, Services, and Operations. GA in Cloud and self-hosted. |
| **Schedule** | Cron-like feature to start Workflows at intervals or specific times. |
| **Timer** | Durable sleep — persisted, survives crashes, resource-light. |

## Determinism Constraints (CRITICAL)

Workflow code MUST be deterministic because it replays from Event History. Violations cause `NonDeterministicError`.

**Never do these in Workflow code:**
- I/O (network, disk, stdio) — use Activities instead
- Access system clock — use SDK time APIs
- Use random — use SDK random APIs
- Thread/goroutine creation — use SDK concurrency APIs
- Access mutable external state

### Go-specific
- `workflow.Now()` not `time.Now()`
- `workflow.Sleep()` not `time.Sleep()`
- `workflow.Go()` not `go` statement
- `workflow.Channel` not `chan`
- `workflow.Selector` not `select`
- `workflow.GetLogger()` to avoid duplicate logs on replay
- Do NOT iterate maps with `range` (random order) — sort keys first

### .NET-specific
- `Workflow.DelayAsync()` not `Task.Delay` or `Thread.Sleep`
- `Workflow.WhenAnyAsync()` not `Task.WhenAny`
- `Workflow.WhenAllAsync()` not `Task.WhenAll`
- `Workflow.RunTaskAsync()` not `Task.Run`
- Do NOT use `ConfigureAwait(false)` — use `ConfigureAwait(true)` or omit
- Do NOT use `DateTime.Now` — SDK provides deterministic time
- Do NOT use `System.Threading.Semaphore/Mutex` — use `Temporalio.Workflows.Semaphore/Mutex`
- Use `.workflow.cs` extension and custom `.editorconfig` to suppress misleading analyzer warnings

### TypeScript-specific
- Workflows run in a sandboxed V8 isolate — no `Date.now()`, `Math.random()`, `setTimeout`
- Use `workflow.sleep()`, `workflow.condition()`, `workflow.random()`

### Python-specific
- Use `workflow.sleep()` not `asyncio.sleep()`
- Use `workflow.random()` not `random`
- Use `workflow.time()` not `time.time()`

## SDK Quick Reference

| Feature | Go | .NET | TypeScript | Python |
|---------|-----|------|-----------|--------|
| Workflow def | Exported function | `[Workflow]` class + `[WorkflowRun]` | `async function` exported | `@workflow.defn` class + `@workflow.run` |
| Activity def | Function or struct method | `[Activity]` method | Function | `@activity.defn` function |
| Execute Activity | `workflow.ExecuteActivity()` | `Workflow.ExecuteActivityAsync()` | `proxyActivities()` | `workflow.execute_activity()` |
| Worker | `worker.New(client, queue, opts)` | `new TemporalWorker(client, opts)` | `Worker(client, opts)` | `Worker(client, queue)` |
| Signal | `workflow.GetSignalChannel()` | `[WorkflowSignal]` method | `wf.signal()` / `defineSignal` | `@workflow.signal` |
| Query | Return value from handler | `[WorkflowQuery]` method/property | `defineQuery` + handler | `@workflow.query` |
| Update | N/A (use Signal+Query) | `[WorkflowUpdate]` + optional `[WorkflowUpdateValidator]` | `defineUpdate` + handler | `@workflow.update` |

## Timeouts

- **StartToCloseTimeout**: Max time for a single Activity attempt. REQUIRED (or ScheduleToClose).
- **ScheduleToCloseTimeout**: Max time from scheduling to completion, including retries.
- **ScheduleToStartTimeout**: Max time waiting in Task Queue.
- **HeartbeatTimeout**: Max time between heartbeats — set this for long-running Activities.
- **WorkflowExecutionTimeout**: Max time for entire Workflow including retries and Continue-As-New chain.
- **WorkflowRunTimeout**: Max time for a single Workflow run.

## Retry Policy Defaults

```
InitialInterval:    1s
BackoffCoefficient: 2.0
MaximumInterval:    100 * InitialInterval
MaximumAttempts:    unlimited
```

Activities retry by default. Workflows do NOT retry by default.

## Code Review Checklist

When reviewing Temporal code, check for:

1. **Determinism violations** — Any non-deterministic calls in Workflow code?
2. **Missing timeouts** — Activities must have StartToClose or ScheduleToClose set.
3. **No heartbeats on long Activities** — Long-running Activities need `Heartbeat()` + `HeartbeatTimeout`.
4. **Large payloads** — Activity inputs/outputs are stored in Event History. Keep them small (<2MB per arg, <4MB total gRPC message).
5. **Missing error handling** — Activity failures don't auto-fail Workflows. Handle errors explicitly.
6. **Versioning** — Changed Workflow code for running executions? Use Patching or Worker Versioning.
7. **Continue-As-New** — Long-running or looping Workflows should use Continue-As-New to avoid unbounded Event History growth. Check `ContinueAsNewSuggested`.
8. **Signal/Update handler completion** — Wait for `AllHandlersFinished` before completing or continuing-as-new.
9. **Idempotent Activities** — Activities may be retried; ensure they are safe to re-execute.
10. **Task Queue mismatch** — Workers must register the exact Workflow/Activity types they poll for.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `NonDeterministicError` | Workflow code changed for running execution | Use Patching API or Worker Versioning |
| Workflow stuck / not progressing | No Worker polling the Task Queue | Start a Worker registered for the correct types and Task Queue |
| Activity retrying forever | Transient error + unlimited retries | Set `MaximumAttempts` or `ScheduleToCloseTimeout`, or throw non-retryable error |
| `WorkflowTaskFailed` repeating | Bug in Workflow code (panic, unhandled exception) | Check Worker logs, fix code, redeploy |
| Cancellation not received | Activity not heartbeating | Add heartbeats and set HeartbeatTimeout |
| Large Event History warning | Looping Workflow without Continue-As-New | Implement Continue-As-New |
| Update timeout | No Worker online or Worker too slow | Ensure Workers are running and healthy |

## Design Patterns

- **Saga**: Sequence of Activities with compensating actions on failure. Use try/catch to unwind.
- **Entity Workflow**: Long-lived Workflow accumulating state via Signals/Updates. Use Continue-As-New periodically.
- **Human-in-the-Loop**: Workflow waits for Signal from human action. Use Timers for reminders/escalation.
- **Polling**: Activity polls external system. Use heartbeats and backoff.
- **Fan-out/Fan-in**: Start multiple Activities/Child Workflows in parallel, await all results.

## Rules

- Always identify the SDK language before giving code examples.
- If the SDK is unclear, ask which language they're using.
- Provide idiomatic code for the target SDK — don't transliterate from another language.
- When reviewing, prioritize determinism violations and missing timeouts above all else.
- For troubleshooting, check Worker logs and Event History first.
- Reference Temporal docs at `https://docs.temporal.io` for deep dives.
