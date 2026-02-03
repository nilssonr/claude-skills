# TypeScript SDK Determinism Reference

## Determinism Constraints

Workflows run in a **sandboxed V8 isolate** that restricts non-deterministic operations.

**Forbidden in Workflow code:**
- `Date.now()` / `new Date()`
- `Math.random()`
- `setTimeout()` / `setInterval()`
- `fetch()` / network calls
- File system access
- Global state mutation

Use these SDK APIs instead:

| Instead of | Use |
|------------|-----|
| `Date.now()` | Implicit (SDK handles time) |
| `Math.random()` | `workflow.random()` |
| `setTimeout()` | `workflow.sleep()` |
| `Promise.race()` | `workflow.condition()` |

## Workflow Definition

Workflows are just async functions exported from a workflow file:

```typescript
// workflows.ts
import * as workflow from '@temporalio/workflow';
import type * as activities from './activities';

const { greet } = workflow.proxyActivities<typeof activities>({
  startToCloseTimeout: '10 seconds',
});

// Use an interface for parameters (allows adding fields later)
interface GreetingWorkflowInput {
  name: string;
  language?: string;
}

interface GreetingWorkflowOutput {
  greeting: string;
  timestamp: number;
}

export async function greetingWorkflow(
  input: GreetingWorkflowInput
): Promise<GreetingWorkflowOutput> {
  const greeting = await greet(input.name);
  return {
    greeting,
    timestamp: Date.now(), // Safe - SDK intercepts this
  };
}
```

## Activity Definition

Activities are regular async functions. They CAN do I/O:

```typescript
// activities.ts
import { Context } from '@temporalio/activity';

export async function greet(name: string): Promise<string> {
  // Activities CAN do network calls, file I/O, etc.
  const response = await fetch(`https://api.example.com/greet/${name}`);
  return response.text();
}

// Long-running activity with heartbeat
export async function processLargeFile(filePath: string): Promise<void> {
  const ctx = Context.current();

  for (let i = 0; i < 1000; i++) {
    // Check for cancellation
    ctx.heartbeat(`Processing chunk ${i}`);

    // Do work...
    await processChunk(filePath, i);
  }
}
```

## Execute Activities with proxyActivities

```typescript
// workflows.ts
import * as workflow from '@temporalio/workflow';
import type * as activities from './activities';

// Create activity proxies with default options
const { greet, processLargeFile } = workflow.proxyActivities<typeof activities>({
  startToCloseTimeout: '30 seconds',
  // For long-running activities:
  // heartbeatTimeout: '10 seconds',
});

export async function myWorkflow(): Promise<string> {
  // Call activities like regular functions
  const result = await greet('World');
  return result;
}
```

### Activity Options

```typescript
const activities = workflow.proxyActivities<typeof activities>({
  // Required: at least one of these
  startToCloseTimeout: '30 seconds',
  // OR
  scheduleToCloseTimeout: '5 minutes',

  // Optional
  scheduleToStartTimeout: '10 seconds',
  heartbeatTimeout: '10 seconds',

  // Retry policy
  retry: {
    initialInterval: '1 second',
    backoffCoefficient: 2,
    maximumInterval: '30 seconds',
    maximumAttempts: 5,
    nonRetryableErrorTypes: ['InvalidInputError'],
  },
});
```

## Signals

```typescript
// Define signal type (shared between workflow and client)
import * as wf from '@temporalio/workflow';

interface ApproveInput {
  approverName: string;
}

export const approveSignal = wf.defineSignal<[ApproveInput]>('approve');

export async function approvalWorkflow(): Promise<string> {
  let approved = false;
  let approverName = '';

  // Set up signal handler
  wf.setHandler(approveSignal, (input: ApproveInput) => {
    // Signal handlers mutate state but cannot return a value
    approved = true;
    approverName = input.approverName;
  });

  // Wait for approval
  await wf.condition(() => approved);

  return `Approved by ${approverName}`;
}
```

### Sending Signals from Client

```typescript
// client.ts
import { Client } from '@temporalio/client';
import { approveSignal } from './workflows';

const client = new Client();
const handle = client.workflow.getHandle('workflow-id');

await handle.signal(approveSignal, { approverName: 'Alice' });
```

## Queries

```typescript
import * as wf from '@temporalio/workflow';

interface GetStatusInput {
  detailed: boolean;
}

export const getStatusQuery = wf.defineQuery<string, [GetStatusInput]>('getStatus');

export async function myWorkflow(): Promise<void> {
  let status = 'starting';

  // Query handlers must be synchronous and cannot mutate state
  wf.setHandler(getStatusQuery, (input: GetStatusInput) => {
    if (input.detailed) {
      return `Status: ${status} (detailed view)`;
    }
    return status;
  });

  status = 'running';
  await wf.sleep('1 hour');
  status = 'completed';
}
```

## Updates

```typescript
import * as wf from '@temporalio/workflow';

export const setLanguageUpdate = wf.defineUpdate<string, [string]>('setLanguage');

export async function myWorkflow(): Promise<string> {
  let language = 'en';
  const supported = ['en', 'es', 'fr', 'de'];

  wf.setHandler(
    setLanguageUpdate,
    (newLanguage: string) => {
      // Update handlers CAN mutate state and return a value
      const previous = language;
      language = newLanguage;
      return previous;
    },
    {
      // Optional validator - reject before writing to history
      validator: (newLanguage: string) => {
        if (!supported.includes(newLanguage)) {
          throw new Error(`Unsupported language: ${newLanguage}`);
        }
      },
    }
  );

  await wf.condition(() => language === 'done');
  return `Final language: ${language}`;
}
```

## Versioning with patched()

Use `patched()` to make backward-compatible changes:

```typescript
import * as wf from '@temporalio/workflow';

export async function myWorkflow(): Promise<void> {
  if (wf.patched('my-change-id')) {
    // New code path (workflows started after this change)
    await newActivity();
  } else {
    // Old code path (workflows started before this change)
    await oldActivity();
  }
}
```

### Deprecating Patches

After all old workflows complete:

```typescript
export async function myWorkflow(): Promise<void> {
  wf.deprecatePatch('my-change-id');
  // Only new code remains
  await newActivity();
}
```

## Error Handling

```typescript
import * as wf from '@temporalio/workflow';
import { ApplicationFailure, ActivityFailure, TimeoutFailure } from '@temporalio/workflow';

export async function myWorkflow(): Promise<string> {
  try {
    return await myActivity();
  } catch (err) {
    if (err instanceof ActivityFailure) {
      const cause = err.cause;

      if (cause instanceof ApplicationFailure) {
        // Application-level error from activity
        return `Activity failed: ${cause.message}`;
      }

      if (cause instanceof TimeoutFailure) {
        // Activity timed out
        return `Activity timed out: ${cause.timeoutType}`;
      }
    }
    throw err;
  }
}
```

### Throwing Non-Retryable Errors from Activities

```typescript
// activities.ts
import { ApplicationFailure } from '@temporalio/activity';

export async function validateInput(input: string): Promise<void> {
  if (!input) {
    // This error will NOT be retried
    throw ApplicationFailure.nonRetryable('Input cannot be empty', 'ValidationError');
  }
}
```

## Worker Setup

```typescript
// worker.ts
import { Worker } from '@temporalio/worker';
import * as activities from './activities';

async function run() {
  const worker = await Worker.create({
    workflowsPath: require.resolve('./workflows'),
    activities,
    taskQueue: 'my-task-queue',
  });

  await worker.run();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

## Child Workflows

```typescript
import * as wf from '@temporalio/workflow';
import { childWorkflow } from './child-workflows';

export async function parentWorkflow(): Promise<string> {
  const result = await wf.executeChild(childWorkflow, {
    args: ['child-input'],
    workflowId: 'child-workflow-id',
  });

  return `Child result: ${result}`;
}
```

## Continue-As-New

Use when workflow history grows large:

```typescript
import * as wf from '@temporalio/workflow';

interface WorkflowState {
  counter: number;
  data: string[];
}

export async function longRunningWorkflow(state: WorkflowState): Promise<void> {
  for (let i = 0; i < 100; i++) {
    // Do work...
    state.counter++;
  }

  // Check if we should continue-as-new
  if (wf.workflowInfo().continueAsNewSuggested) {
    await wf.continueAsNew<typeof longRunningWorkflow>(state);
  }
}
```

## Timers and Conditions

```typescript
import * as wf from '@temporalio/workflow';

export async function myWorkflow(): Promise<string> {
  let approved = false;

  // Durable sleep - survives crashes
  await wf.sleep('24 hours');

  // Wait for condition with timeout
  const wasApproved = await wf.condition(() => approved, '1 hour');

  if (!wasApproved) {
    return 'Timed out waiting for approval';
  }

  return 'Approved!';
}
```

## Async Signal/Update Handlers

Signal and Update handlers can be async:

```typescript
import * as wf from '@temporalio/workflow';
import type * as activities from './activities';

const { processData } = wf.proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
});

export const processSignal = wf.defineSignal<[string]>('process');

export async function myWorkflow(): Promise<void> {
  wf.setHandler(processSignal, async (data: string) => {
    // Can execute activities from signal handler
    await processData(data);
  });

  // Wait for all handlers to complete before finishing
  await wf.condition(wf.allHandlersFinished);
}
```

**Important:** Always wait for handlers to complete before using Continue-As-New or completing the workflow using `wf.condition(wf.allHandlersFinished)`.

## Cancellation

```typescript
import * as wf from '@temporalio/workflow';
import { CancelledFailure } from '@temporalio/workflow';

export async function cancellableWorkflow(): Promise<string> {
  try {
    await wf.sleep('1 hour');
    return 'Completed normally';
  } catch (err) {
    if (wf.isCancellation(err)) {
      // Perform cleanup
      await cleanupActivity();
      return 'Cancelled and cleaned up';
    }
    throw err;
  }
}
```
