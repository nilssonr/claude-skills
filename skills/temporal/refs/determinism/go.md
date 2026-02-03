# Go SDK Determinism Reference

## Determinism Constraints

Workflow code must be deterministic. Use these SDK APIs instead of standard Go equivalents:

| Instead of | Use |
|------------|-----|
| `time.Now()` | `workflow.Now(ctx)` |
| `time.Sleep()` | `workflow.Sleep(ctx, duration)` |
| `go func()` | `workflow.Go(ctx, func(ctx workflow.Context) { ... })` |
| `chan` | `workflow.Channel` |
| `select` | `workflow.Selector` |
| `rand.Int()` | `workflow.SideEffect()` for random values |
| `log.Println()` | `workflow.GetLogger(ctx).Info()` |

### Map Iteration Warning

Do NOT iterate maps with `range` directly — Go randomizes iteration order:

```go
// BAD - non-deterministic
for k, v := range myMap {
    // Order changes on replay!
}

// GOOD - deterministic
keys := make([]string, 0, len(myMap))
for k := range myMap {
    keys = append(keys, k)
}
sort.Strings(keys)
for _, k := range keys {
    v := myMap[k]
    // Process in deterministic order
}
```

**Exception:** Map iteration IS safe inside Query handlers (they don't replay).

## Workflow Definition

```go
package yourapp

import (
    "go.temporal.io/sdk/workflow"
)

// Use a struct for parameters (allows adding fields later)
type YourWorkflowParam struct {
    ParamX string
    ParamY int
}

type YourWorkflowResult struct {
    ResultX string
    ResultY int
}

// First parameter must be workflow.Context
func YourWorkflow(ctx workflow.Context, param YourWorkflowParam) (*YourWorkflowResult, error) {
    logger := workflow.GetLogger(ctx)
    logger.Info("Workflow started", "param", param)

    // Workflow logic here...

    return &YourWorkflowResult{
        ResultX: "done",
        ResultY: 42,
    }, nil
}
```

## Activity Definition

```go
package yourapp

import (
    "context"
)

type YourActivityParam struct {
    Input string
}

type YourActivityResult struct {
    Output string
}

// Activities use standard context.Context (not workflow.Context)
func YourActivity(ctx context.Context, param YourActivityParam) (*YourActivityResult, error) {
    // Activities CAN do I/O, network calls, etc.
    return &YourActivityResult{
        Output: "processed: " + param.Input,
    }, nil
}
```

## Execute Activity

```go
func YourWorkflow(ctx workflow.Context, param YourWorkflowParam) (*YourWorkflowResult, error) {
    // Activity options - StartToCloseTimeout is REQUIRED
    ao := workflow.ActivityOptions{
        StartToCloseTimeout: 10 * time.Second,
        // For long-running activities, add heartbeat:
        // HeartbeatTimeout: 2 * time.Second,
    }
    ctx = workflow.WithActivityOptions(ctx, ao)

    var result YourActivityResult
    err := workflow.ExecuteActivity(ctx, YourActivity, YourActivityParam{Input: "hello"}).Get(ctx, &result)
    if err != nil {
        return nil, err
    }

    return &YourWorkflowResult{ResultX: result.Output}, nil
}
```

## Signals

```go
const MySignalName = "my-signal"

type MySignalPayload struct {
    Message string
}

func YourWorkflow(ctx workflow.Context) error {
    var signalData MySignalPayload

    // Blocking receive
    signalChan := workflow.GetSignalChannel(ctx, MySignalName)
    signalChan.Receive(ctx, &signalData)

    // Or non-blocking with selector
    selector := workflow.NewSelector(ctx)
    selector.AddReceive(signalChan, func(c workflow.ReceiveChannel, more bool) {
        c.Receive(ctx, &signalData)
    })
    selector.Select(ctx)

    return nil
}
```

## Queries

```go
const MyQueryName = "my-query"

func YourWorkflow(ctx workflow.Context) error {
    currentState := "initial"

    // Register query handler
    err := workflow.SetQueryHandler(ctx, MyQueryName, func() (string, error) {
        // Query handlers must NOT mutate state
        return currentState, nil
    })
    if err != nil {
        return err
    }

    // ... workflow logic that updates currentState ...

    return nil
}
```

## Updates

```go
const MyUpdateName = "my-update"

type MyUpdateInput struct {
    Value string
}

func YourWorkflow(ctx workflow.Context) error {
    state := ""

    err := workflow.SetUpdateHandler(ctx, MyUpdateName,
        func(ctx workflow.Context, input MyUpdateInput) (string, error) {
            // Updates CAN mutate state and return a result
            state = input.Value
            return "updated to: " + state, nil
        },
    )
    if err != nil {
        return err
    }

    // Wait for workflow completion signal or condition
    workflow.Await(ctx, func() bool { return state == "done" })

    return nil
}
```

## Waiting for Handlers to Complete

Before completing or using Continue-As-New, wait for all in-flight signal/update handlers:

```go
func YourWorkflow(ctx workflow.Context) error {
    // ... workflow logic ...

    // Wait for all handlers to complete before finishing
    if err := workflow.Await(ctx, func() bool {
        return workflow.AllHandlersFinished(ctx)
    }); err != nil {
        return err
    }

    return nil
}

// For Continue-As-New:
func LongRunningWorkflow(ctx workflow.Context, state State) error {
    for {
        // ... do work ...

        if workflow.GetInfo(ctx).GetContinueAsNewSuggested() {
            // Wait for handlers before continuing
            workflow.Await(ctx, func() bool {
                return workflow.AllHandlersFinished(ctx)
            })
            return workflow.NewContinueAsNewError(ctx, LongRunningWorkflow, state)
        }
    }
}
```

**Important:** Always wait for handlers to complete before using Continue-As-New or completing the workflow.

## Versioning with GetVersion

Use `GetVersion` to make backward-compatible changes to running workflows:

```go
func YourWorkflow(ctx workflow.Context) error {
    // changeID: unique identifier for this change
    // minSupported: minimum version still supported
    // maxSupported: current version
    v := workflow.GetVersion(ctx, "Step1-ActivityChange", workflow.DefaultVersion, 1)

    var result string
    if v == workflow.DefaultVersion {
        // Old code path (workflows started before this change)
        err := workflow.ExecuteActivity(ctx, OldActivity).Get(ctx, &result)
        if err != nil {
            return err
        }
    } else {
        // New code path (v == 1)
        err := workflow.ExecuteActivity(ctx, NewActivity).Get(ctx, &result)
        if err != nil {
            return err
        }
    }

    return nil
}
```

### Adding Another Version

```go
v := workflow.GetVersion(ctx, "Step1-ActivityChange", workflow.DefaultVersion, 2)
if v == workflow.DefaultVersion {
    err = workflow.ExecuteActivity(ctx, OldActivity).Get(ctx, &result)
} else if v == 1 {
    err = workflow.ExecuteActivity(ctx, NewActivity).Get(ctx, &result)
} else {
    // v == 2 (newest)
    err = workflow.ExecuteActivity(ctx, NewestActivity).Get(ctx, &result)
}
```

### Deprecating Old Versions

After all workflows on old versions complete:

```go
// Changed minSupported from DefaultVersion to 1
v := workflow.GetVersion(ctx, "Step1-ActivityChange", 1, 2)
if v == 1 {
    err = workflow.ExecuteActivity(ctx, NewActivity).Get(ctx, &result)
} else {
    err = workflow.ExecuteActivity(ctx, NewestActivity).Get(ctx, &result)
}
```

## Error Handling

```go
err := workflow.ExecuteActivity(ctx, YourActivity, input).Get(ctx, &result)
if err != nil {
    var applicationErr *temporal.ApplicationError
    if errors.As(err, &applicationErr) {
        // Handle application error
        // applicationErr.Error() - message
        // applicationErr.Type() - error type
        // applicationErr.Details(&detailVar) - extract details
    }

    var canceledErr *temporal.CanceledError
    if errors.As(err, &canceledErr) {
        // Handle cancellation
    }

    var timeoutErr *temporal.TimeoutError
    if errors.As(err, &timeoutErr) {
        switch timeoutErr.TimeoutType() {
        case enumspb.TIMEOUT_TYPE_SCHEDULE_TO_START:
            // No worker picked up the task
        case enumspb.TIMEOUT_TYPE_START_TO_CLOSE:
            // Activity took too long
        case enumspb.TIMEOUT_TYPE_HEARTBEAT:
            // Activity stopped heartbeating
        }
    }

    return err
}
```

## Worker Setup

```go
package main

import (
    "log"

    "go.temporal.io/sdk/client"
    "go.temporal.io/sdk/worker"

    "yourapp"
)

func main() {
    c, err := client.Dial(client.Options{})
    if err != nil {
        log.Fatalln("Unable to create client", err)
    }
    defer c.Close()

    w := worker.New(c, "your-task-queue", worker.Options{})

    // Register workflows and activities
    w.RegisterWorkflow(yourapp.YourWorkflow)
    w.RegisterActivity(yourapp.YourActivity)

    err = w.Run(worker.InterruptCh())
    if err != nil {
        log.Fatalln("Unable to start worker", err)
    }
}
```

## Child Workflows

```go
func ParentWorkflow(ctx workflow.Context) error {
    cwo := workflow.ChildWorkflowOptions{
        WorkflowID: "child-workflow-id",
    }
    ctx = workflow.WithChildOptions(ctx, cwo)

    var result ChildResult
    err := workflow.ExecuteChildWorkflow(ctx, ChildWorkflow, childInput).Get(ctx, &result)
    if err != nil {
        return err
    }

    return nil
}
```

## Continue-As-New

Use when workflow history grows large (check `workflow.GetInfo(ctx).GetContinueAsNewSuggested()`):

```go
func LongRunningWorkflow(ctx workflow.Context, state WorkflowState) error {
    for i := 0; i < 100; i++ {
        // Do work...
        state.Counter++
    }

    // Check if we should continue-as-new
    if workflow.GetInfo(ctx).GetContinueAsNewSuggested() {
        return workflow.NewContinueAsNewError(ctx, LongRunningWorkflow, state)
    }

    return nil
}
```

## Timers

```go
func YourWorkflow(ctx workflow.Context) error {
    // Durable sleep - survives crashes
    err := workflow.Sleep(ctx, 24*time.Hour)
    if err != nil {
        return err
    }

    // Or use NewTimer for cancellable timers
    timer := workflow.NewTimer(ctx, 1*time.Hour)

    selector := workflow.NewSelector(ctx)
    selector.AddFuture(timer, func(f workflow.Future) {
        // Timer fired
    })
    selector.AddReceive(signalChan, func(c workflow.ReceiveChannel, more bool) {
        // Signal received - could cancel timer
    })
    selector.Select(ctx)

    return nil
}
```
