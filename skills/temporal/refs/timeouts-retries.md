# Timeouts and Retry Policies Reference

## Activity Timeouts

### Timeout Types

```
                    ScheduleToCloseTimeout
├──────────────────────────────────────────────────────────────┤

│◀──ScheduleToStart──▶│◀──────StartToClose──────▶│

┌─────────────────────┬──────────────────────────┬────────────┐
│   Waiting in        │   Activity Executing     │  Complete  │
│   Task Queue        │                          │            │
└─────────────────────┴──────────────────────────┴────────────┘
       │                      │           │
       │                      │◀─────────▶│
       │                      │ Heartbeat │
       │                      │  Timeout  │
```

### ScheduleToCloseTimeout

**What it controls:** Maximum time from when Activity is scheduled until it completes (including all retries).

**When to use:**
- Set as an upper bound for the entire Activity lifecycle
- Useful when you have a hard deadline for completion

**Example:** "This payment must complete within 24 hours"

### StartToCloseTimeout (REQUIRED)

**What it controls:** Maximum time for a single Activity attempt (from Worker picking it up to completion).

**When to use:**
- ALWAYS set this (or ScheduleToCloseTimeout)
- Base it on expected Activity duration + buffer
- Consider worst-case scenarios (slow network, large data)

**Example:** "Each attempt to call the API should complete within 30 seconds"

### ScheduleToStartTimeout

**What it controls:** Maximum time Activity can wait in Task Queue before a Worker picks it up.

**When to use:**
- Detect Worker availability issues
- Useful for time-sensitive operations
- Default is unlimited (waits forever)

**Example:** "If no Worker picks this up within 5 minutes, something is wrong"

### HeartbeatTimeout

**What it controls:** Maximum time between heartbeat calls from a running Activity.

**When to use:**
- Long-running Activities (minutes to hours)
- Activities that process items in a loop
- Activities where you want early failure detection

**Why it matters:**
- Without heartbeats, you won't know if Activity is stuck until StartToCloseTimeout
- Heartbeats enable faster failure detection
- Heartbeats allow progress tracking via heartbeat details
- Required for Activity cancellation to be detected

**Example:** "If the file processing Activity doesn't heartbeat within 30 seconds, it's probably stuck"

## Workflow Timeouts

### WorkflowExecutionTimeout

**What it controls:** Maximum time for entire Workflow Execution, including:
- All retries (if Workflow has retry policy)
- Continue-As-New chain (all runs combined)

**When to use:**
- Hard deadline for entire business process
- Rarely needed for most use cases

### WorkflowRunTimeout

**What it controls:** Maximum time for a single Workflow run.

**When to use:**
- Limit individual run before Continue-As-New
- Detect stuck Workflows

### WorkflowTaskTimeout

**What it controls:** Maximum time for Workflow Task (Worker processing Workflow code).

**Default:** 10 seconds

**When to use:**
- Rarely changed
- Increase if Workflow code is computationally heavy (not recommended)

## Retry Policies

### Default Retry Policy

```
InitialInterval:      1 second
BackoffCoefficient:   2.0
MaximumInterval:      100 × InitialInterval (100 seconds)
MaximumAttempts:      Unlimited
NonRetryableErrors:   None
```

**Note:** Activities retry by default. Workflows do NOT retry by default.

### Retry Policy Fields

| Field | Description | Default |
|-------|-------------|---------|
| `InitialInterval` | Wait time before first retry | 1s |
| `BackoffCoefficient` | Multiplier for subsequent retry intervals | 2.0 |
| `MaximumInterval` | Cap on retry interval | 100 × InitialInterval |
| `MaximumAttempts` | Total attempts (including first). 0 = unlimited | 0 (unlimited) |
| `NonRetryableErrorTypes` | Error types that should not be retried | [] |

### Retry Timing Example

With defaults (InitialInterval=1s, BackoffCoefficient=2.0, MaximumInterval=100s):

| Attempt | Wait Before | Cumulative Time |
|---------|-------------|-----------------|
| 1 | 0s | 0s |
| 2 | 1s | 1s |
| 3 | 2s | 3s |
| 4 | 4s | 7s |
| 5 | 8s | 15s |
| 6 | 16s | 31s |
| 7 | 32s | 63s |
| 8 | 64s | 127s |
| 9 | 100s (capped) | 227s |
| 10 | 100s (capped) | 327s |

### When NOT to Retry

Configure `NonRetryableErrorTypes` or throw non-retryable errors for:

- **Validation errors:** Invalid input won't become valid on retry
- **Authorization errors:** Missing permissions won't appear
- **Not found errors:** Resource won't magically exist
- **Business logic failures:** Invalid state transitions

```python
# Python - throw non-retryable error
from temporalio.exceptions import ApplicationError

raise ApplicationError(
    "User not found",
    type="UserNotFoundError",
    non_retryable=True
)
```

```go
// Go - throw non-retryable error
return temporal.NewNonRetryableApplicationError(
    "User not found",
    "UserNotFoundError",
    nil,
)
```

```typescript
// TypeScript - throw non-retryable error
import { ApplicationFailure } from '@temporalio/activity';

throw ApplicationFailure.nonRetryable('User not found', 'UserNotFoundError');
```

## Best Practices

### Activity Timeout Guidelines

1. **Always set StartToCloseTimeout** — It's required and protects against stuck Activities

2. **Set HeartbeatTimeout for long Activities** — Any Activity over 1 minute should heartbeat
   ```
   StartToCloseTimeout: 2 hours
   HeartbeatTimeout: 30 seconds
   ```

3. **Use ScheduleToCloseTimeout for hard deadlines** — When business requirements dictate a maximum time

4. **ScheduleToStartTimeout for Worker health** — Detect when Workers are down or overloaded

### Retry Policy Guidelines

1. **Be explicit about MaximumAttempts** — Unlimited retries can cause issues
   ```
   MaximumAttempts: 5  // or appropriate for your use case
   ```

2. **Use ScheduleToCloseTimeout as a backstop** — Limits total time even with unlimited retries

3. **Define NonRetryableErrorTypes** — Don't retry errors that will never succeed

4. **Consider idempotency** — Activities may be retried; ensure they're safe to re-execute

### Common Timeout Configurations

**Quick API call:**
```
StartToCloseTimeout: 30 seconds
RetryPolicy:
  MaximumAttempts: 3
```

**Database operation:**
```
StartToCloseTimeout: 5 minutes
RetryPolicy:
  InitialInterval: 1 second
  MaximumAttempts: 5
```

**File processing (long-running):**
```
StartToCloseTimeout: 2 hours
HeartbeatTimeout: 30 seconds
RetryPolicy:
  MaximumAttempts: 2
```

**External system with rate limits:**
```
StartToCloseTimeout: 5 minutes
ScheduleToCloseTimeout: 1 hour
RetryPolicy:
  InitialInterval: 5 seconds
  BackoffCoefficient: 1.5
  MaximumInterval: 5 minutes
  MaximumAttempts: 10
```

## Troubleshooting

### Activity keeps retrying forever

**Cause:** No MaximumAttempts and no ScheduleToCloseTimeout set.

**Fix:** Set one or both:
```
MaximumAttempts: 5
ScheduleToCloseTimeout: 1 hour
```

### Activity retrying when it shouldn't

**Cause:** Error type not in NonRetryableErrorTypes.

**Fix:** Either:
1. Add error type to NonRetryableErrorTypes
2. Throw a non-retryable ApplicationError from the Activity

### Cancellation not reaching Activity

**Cause:** Activity not heartbeating.

**Fix:** Add heartbeats and set HeartbeatTimeout:
```python
@activity.defn
async def my_activity():
    while processing:
        activity.heartbeat()  # Check for cancellation
        # ... do work
```

### Workflow stuck waiting for Activity

**Cause:** Worker down and no ScheduleToStartTimeout.

**Fix:** Set ScheduleToStartTimeout to detect Worker issues early.
