# .NET SDK Determinism Reference

## Determinism Constraints

Workflow code must be deterministic. The .NET SDK has specific Task-related gotchas.

**Forbidden in Workflow code:**

| Instead of | Use |
|------------|-----|
| `Task.Run()` | `Workflow.RunTaskAsync()` |
| `Task.Delay()` | `Workflow.DelayAsync()` |
| `Thread.Sleep()` | `Workflow.DelayAsync()` |
| `Task.WhenAny()` | `Workflow.WhenAnyAsync()` |
| `Task.WhenAll()` | `Workflow.WhenAllAsync()` |
| `ConfigureAwait(false)` | `ConfigureAwait(true)` or omit |
| `DateTime.Now` / `DateTime.UtcNow` | (SDK provides deterministic time) |
| `Random` | `Workflow.Random` |
| `Guid.NewGuid()` | `Workflow.NewGuid()` |
| `System.Threading.Semaphore` | `Temporalio.Workflows.Semaphore` |
| `System.Threading.Mutex` | `Temporalio.Workflows.Mutex` |
| `CancellationTokenSource.CancelAsync` | `CancellationTokenSource.Cancel` |

### Task Scheduler Warning

The .NET SDK requires `TaskScheduler.Current` (not `TaskScheduler.Default`). Many .NET APIs implicitly use the default scheduler, which causes non-determinism.

The SDK includes a runtime check that throws `InvalidWorkflowOperationException` when workflow code accidentally starts a task on the wrong scheduler.

### Recommended File Extension

Use `.workflow.cs` for workflow files and add this `.editorconfig`:

```ini
[*.workflow.cs]
dotnet_diagnostic.CA1024.severity = none  # Allow getter methods for queries
dotnet_diagnostic.CA1822.severity = none  # Allow instance methods
dotnet_diagnostic.CA2007.severity = none  # Don't require ConfigureAwait
dotnet_diagnostic.CA2008.severity = none  # Don't require explicit scheduler
dotnet_diagnostic.CA5394.severity = none  # Allow Workflow.Random
dotnet_diagnostic.CS1998.severity = none  # Allow async without await
dotnet_diagnostic.VSTHRD105.severity = none  # Allow TaskScheduler.Current
```

## Workflow Definition

```csharp
using Temporalio.Workflows;

// Use records for parameters (immutable, easy to extend)
public record MyWorkflowParams(string Name, int Value);
public record MyWorkflowResult(string Output, int Count);

[Workflow]
public class MyWorkflow
{
    [WorkflowRun]
    public async Task<MyWorkflowResult> RunAsync(MyWorkflowParams input)
    {
        // Workflow logic here
        var result = await Workflow.ExecuteActivityAsync(
            (MyActivities a) => a.ProcessAsync(input.Name),
            new() { StartToCloseTimeout = TimeSpan.FromMinutes(5) });

        return new MyWorkflowResult(result, input.Value);
    }
}
```

## Activity Definition

```csharp
using Temporalio.Activities;

public record ProcessParams(string Input);

public class MyActivities
{
    // Activities CAN do I/O, network calls, etc.
    [Activity]
    public async Task<string> ProcessAsync(string input)
    {
        // Network call is fine in activities
        using var client = new HttpClient();
        var response = await client.GetStringAsync($"https://api.example.com/{input}");
        return response;
    }

    // Sync activities work too
    [Activity]
    public string ProcessSync(string input) => $"Processed: {input}";
}
```

### Activity with Heartbeat

```csharp
using Temporalio.Activities;

public class MyActivities
{
    [Activity]
    public async Task ProcessLargeFileAsync(string filePath)
    {
        for (var i = 0; i < 1000; i++)
        {
            // Report progress and check for cancellation
            ActivityExecutionContext.Current.Heartbeat($"Processing chunk {i}");

            // Check if cancelled
            ActivityExecutionContext.Current.CancellationToken.ThrowIfCancellationRequested();

            await ProcessChunkAsync(filePath, i);
        }
    }
}
```

## Execute Activity

```csharp
[Workflow]
public class MyWorkflow
{
    [WorkflowRun]
    public async Task<string> RunAsync(string input)
    {
        // Lambda syntax - type-safe
        var result = await Workflow.ExecuteActivityAsync(
            (MyActivities a) => a.ProcessAsync(input),
            new ActivityOptions
            {
                StartToCloseTimeout = TimeSpan.FromMinutes(5),
                // For long-running activities:
                // HeartbeatTimeout = TimeSpan.FromSeconds(30),
                RetryPolicy = new RetryPolicy
                {
                    InitialInterval = TimeSpan.FromSeconds(1),
                    BackoffCoefficient = 2,
                    MaximumInterval = TimeSpan.FromSeconds(30),
                    MaximumAttempts = 5,
                },
            });

        return result;
    }
}
```

## Signals

```csharp
[Workflow]
public class ApprovalWorkflow
{
    public record ApproveInput(string ApproverName);

    private bool _approved;
    private string _approverName = "";

    [WorkflowSignal]
    public async Task ApproveAsync(ApproveInput input)
    {
        // Signal handlers mutate state but cannot return a value
        _approved = true;
        _approverName = input.ApproverName;
    }

    [WorkflowRun]
    public async Task<string> RunAsync()
    {
        // Wait for approval signal
        await Workflow.WaitConditionAsync(() => _approved);
        return $"Approved by {_approverName}";
    }
}
```

## Queries

```csharp
[Workflow]
public class MyWorkflow
{
    private string _status = "starting";

    // Query as method
    [WorkflowQuery]
    public string GetStatus() => _status;

    // Query as property
    [WorkflowQuery]
    public string Status => _status;

    // Query with input
    [WorkflowQuery]
    public string GetDetailedStatus(bool verbose) =>
        verbose ? $"Status: {_status} (detailed)" : _status;

    [WorkflowRun]
    public async Task RunAsync()
    {
        _status = "running";
        await Workflow.DelayAsync(TimeSpan.FromHours(1));
        _status = "completed";
    }
}
```

## Updates

```csharp
[Workflow]
public class MyWorkflow
{
    private string _language = "en";
    private readonly HashSet<string> _supported = new() { "en", "es", "fr" };

    // Validator - rejects update before writing to history
    [WorkflowUpdateValidator(nameof(SetLanguageAsync))]
    public void ValidateSetLanguage(string language)
    {
        if (!_supported.Contains(language))
        {
            throw new ApplicationFailureException($"Unsupported: {language}");
        }
    }

    // Update handler - can mutate state and return value
    [WorkflowUpdate]
    public async Task<string> SetLanguageAsync(string language)
    {
        var previous = _language;
        _language = language;
        return previous;
    }

    [WorkflowRun]
    public async Task<string> RunAsync()
    {
        await Workflow.WaitConditionAsync(() => _language == "done");
        return $"Final: {_language}";
    }
}
```

## Versioning with Patched()

```csharp
[Workflow]
public class MyWorkflow
{
    [WorkflowRun]
    public async Task RunAsync()
    {
        if (Workflow.Patched("my-change-id"))
        {
            // New code path
            await Workflow.ExecuteActivityAsync(
                (MyActivities a) => a.NewActivityAsync(),
                new() { StartToCloseTimeout = TimeSpan.FromMinutes(5) });
        }
        else
        {
            // Old code path
            await Workflow.ExecuteActivityAsync(
                (MyActivities a) => a.OldActivityAsync(),
                new() { StartToCloseTimeout = TimeSpan.FromMinutes(5) });
        }
    }
}
```

### Deprecating Patches

After all old workflows complete:

```csharp
[Workflow]
public class MyWorkflow
{
    [WorkflowRun]
    public async Task RunAsync()
    {
        Workflow.DeprecatePatch("my-change-id");
        // Only new code remains
        await Workflow.ExecuteActivityAsync(
            (MyActivities a) => a.NewActivityAsync(),
            new() { StartToCloseTimeout = TimeSpan.FromMinutes(5) });
    }
}
```

## Error Handling

```csharp
using Temporalio.Exceptions;

[Workflow]
public class MyWorkflow
{
    [WorkflowRun]
    public async Task<string> RunAsync()
    {
        try
        {
            return await Workflow.ExecuteActivityAsync(
                (MyActivities a) => a.ProcessAsync(),
                new() { StartToCloseTimeout = TimeSpan.FromMinutes(5) });
        }
        catch (ActivityFailureException ex)
        {
            switch (ex.InnerException)
            {
                case ApplicationFailureException appEx:
                    return $"Activity failed: {appEx.Message}";

                case TimeoutFailureException timeoutEx:
                    return $"Activity timed out: {timeoutEx.TimeoutType}";

                case CanceledFailureException:
                    return "Activity was cancelled";

                default:
                    throw;
            }
        }
    }
}
```

### Throwing Non-Retryable Errors from Activities

```csharp
[Activity]
public async Task ValidateInputAsync(string input)
{
    if (string.IsNullOrEmpty(input))
    {
        // This error will NOT be retried
        throw new ApplicationFailureException(
            "Input cannot be empty",
            nonRetryable: true);
    }
}
```

## Worker Setup

```csharp
using Temporalio.Client;
using Temporalio.Worker;

var client = await TemporalClient.ConnectAsync(new("localhost:7233"));

using var worker = new TemporalWorker(
    client,
    new TemporalWorkerOptions("my-task-queue")
        .AddWorkflow<MyWorkflow>()
        .AddAllActivities(new MyActivities()));

await worker.ExecuteAsync(cancellationToken);
```

## Child Workflows

```csharp
[Workflow]
public class ParentWorkflow
{
    [WorkflowRun]
    public async Task<string> RunAsync()
    {
        var result = await Workflow.ExecuteChildWorkflowAsync(
            (ChildWorkflow wf) => wf.RunAsync("input"),
            new ChildWorkflowOptions { Id = "child-workflow-id" });

        return $"Child result: {result}";
    }
}

[Workflow]
public class ChildWorkflow
{
    [WorkflowRun]
    public async Task<string> RunAsync(string input) => $"Processed: {input}";
}
```

## Continue-As-New

Use when workflow history grows large:

```csharp
public record WorkflowState(int Counter, List<string> Data);

[Workflow]
public class LongRunningWorkflow
{
    [WorkflowRun]
    public async Task RunAsync(WorkflowState state)
    {
        for (var i = 0; i < 100; i++)
        {
            // Do work...
            state = state with { Counter = state.Counter + 1 };
        }

        // Check if we should continue-as-new
        if (Workflow.ContinueAsNewSuggested)
        {
            throw Workflow.CreateContinueAsNewException(
                (LongRunningWorkflow wf) => wf.RunAsync(state));
        }
    }
}
```

## Timers and Conditions

```csharp
[Workflow]
public class MyWorkflow
{
    private bool _approved;

    [WorkflowRun]
    public async Task<string> RunAsync()
    {
        // Durable delay - survives crashes
        await Workflow.DelayAsync(TimeSpan.FromHours(24));

        // Wait for condition with timeout
        var wasApproved = await Workflow.WaitConditionAsync(
            () => _approved,
            TimeSpan.FromHours(1));

        if (!wasApproved)
        {
            return "Timed out waiting for approval";
        }

        return "Approved!";
    }
}
```

## Async Signal/Update Handlers

Signal and Update handlers can be async and execute activities:

```csharp
[Workflow]
public class MyWorkflow
{
    private bool _processing;

    [WorkflowSignal]
    public async Task ProcessDataAsync(string data)
    {
        _processing = true;
        // Can execute activities from signal handler
        await Workflow.ExecuteActivityAsync(
            (MyActivities a) => a.ProcessAsync(data),
            new() { StartToCloseTimeout = TimeSpan.FromMinutes(5) });
        _processing = false;
    }

    [WorkflowRun]
    public async Task RunAsync()
    {
        // Wait for all handlers to complete before finishing
        await Workflow.WaitConditionAsync(() => !_processing);
    }
}
```

**Important:** Always wait for handlers to complete before using Continue-As-New or completing the workflow using `Workflow.WaitConditionAsync(Workflow.AllHandlersFinished)`.

## Cancellation

```csharp
[Workflow]
public class CancellableWorkflow
{
    [WorkflowRun]
    public async Task<string> RunAsync()
    {
        try
        {
            await Workflow.DelayAsync(TimeSpan.FromHours(1));
            return "Completed normally";
        }
        catch (CanceledFailureException)
        {
            // Perform cleanup
            await Workflow.ExecuteActivityAsync(
                (MyActivities a) => a.CleanupAsync(),
                new() { StartToCloseTimeout = TimeSpan.FromMinutes(1) });
            return "Cancelled and cleaned up";
        }
    }
}
```
