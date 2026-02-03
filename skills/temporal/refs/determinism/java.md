# Java SDK Determinism Reference

## Determinism Constraints

Workflow code must be deterministic. Violations cause `NonDeterministicWorkflowException`.

**Forbidden in Workflow code:**
- I/O operations (network, disk, stdio)
- System clock access (`System.currentTimeMillis()`, `LocalDateTime.now()`)
- Random number generation (`Math.random()`, `new Random()`)
- Threading (`new Thread()`, `ExecutorService`)
- Mutable global state access
- Non-deterministic iteration (HashMap iteration order)

Use SDK-provided alternatives:
- `Workflow.currentTimeMillis()` for time
- `Workflow.newRandom()` for random numbers
- `Workflow.sleep()` for delays
- `Async.function()` / `Async.procedure()` for concurrent execution

## Workflow Definition

Workflows require an interface with `@WorkflowInterface` and implementation:

```java
import io.temporal.workflow.WorkflowInterface;
import io.temporal.workflow.WorkflowMethod;

// Interface (required)
@WorkflowInterface
public interface MyWorkflow {
    @WorkflowMethod
    String processOrder(OrderInput input);
}

// Use a class for parameters (allows adding fields later)
public class OrderInput {
    private String orderId;
    private int quantity;
    // getters, setters, constructors...
}

// Implementation
public class MyWorkflowImpl implements MyWorkflow {
    @Override
    public String processOrder(OrderInput input) {
        // Workflow logic here
        return "Processed: " + input.getOrderId();
    }
}
```

## Activity Definition

```java
import io.temporal.activity.ActivityInterface;
import io.temporal.activity.ActivityMethod;

@ActivityInterface
public interface MyActivities {
    // Activities CAN do I/O, network calls, etc.
    @ActivityMethod
    String processItem(String itemId);

    @ActivityMethod(name = "custom_activity_name")
    void sendNotification(NotificationInput input);
}

// Implementation
public class MyActivitiesImpl implements MyActivities {
    @Override
    public String processItem(String itemId) {
        // Network call, DB access, etc. is fine here
        return "Processed: " + itemId;
    }

    @Override
    public void sendNotification(NotificationInput input) {
        // Send email, SMS, etc.
    }
}
```

## Execute Activity

```java
import io.temporal.activity.ActivityOptions;
import io.temporal.workflow.Workflow;

public class MyWorkflowImpl implements MyWorkflow {
    // Create activity stub with options
    private final MyActivities activities = Workflow.newActivityStub(
        MyActivities.class,
        ActivityOptions.newBuilder()
            .setStartToCloseTimeout(Duration.ofMinutes(5))
            // For long-running activities:
            // .setHeartbeatTimeout(Duration.ofSeconds(30))
            .setRetryOptions(RetryOptions.newBuilder()
                .setInitialInterval(Duration.ofSeconds(1))
                .setBackoffCoefficient(2.0)
                .setMaximumInterval(Duration.ofSeconds(30))
                .setMaximumAttempts(5)
                .build())
            .build());

    @Override
    public String processOrder(OrderInput input) {
        String result = activities.processItem(input.getOrderId());
        return result;
    }
}
```

## Signals

```java
@WorkflowInterface
public interface ApprovalWorkflow {
    @WorkflowMethod
    String run();

    @SignalMethod
    void approve(String approverName);
}

public class ApprovalWorkflowImpl implements ApprovalWorkflow {
    private boolean approved = false;
    private String approverName = "";

    @Override
    public String run() {
        // Wait for approval signal
        Workflow.await(() -> approved);
        return "Approved by " + approverName;
    }

    @Override
    public void approve(String approverName) {
        // Signal handlers mutate state
        this.approved = true;
        this.approverName = approverName;
    }
}
```

## Queries

```java
@WorkflowInterface
public interface MyWorkflow {
    @WorkflowMethod
    void run();

    @QueryMethod
    String getStatus();

    @QueryMethod(name = "detailed_status")
    StatusInfo getDetailedStatus();
}

public class MyWorkflowImpl implements MyWorkflow {
    private String status = "starting";

    @Override
    public void run() {
        status = "running";
        Workflow.sleep(Duration.ofHours(1));
        status = "completed";
    }

    @Override
    public String getStatus() {
        // Query handlers must NOT mutate state
        return status;
    }

    @Override
    public StatusInfo getDetailedStatus() {
        return new StatusInfo(status, Workflow.currentTimeMillis());
    }
}
```

## Updates

```java
@WorkflowInterface
public interface MyWorkflow {
    @WorkflowMethod
    String run();

    @UpdateMethod
    String setLanguage(String language);

    @UpdateValidatorMethod(updateName = "setLanguage")
    void validateSetLanguage(String language);
}

public class MyWorkflowImpl implements MyWorkflow {
    private String language = "en";
    private final Set<String> supported = Set.of("en", "es", "fr");

    @Override
    public String run() {
        Workflow.await(() -> language.equals("done"));
        return "Final: " + language;
    }

    @Override
    public void validateSetLanguage(String language) {
        // Validator - reject before writing to history
        if (!supported.contains(language)) {
            throw new IllegalArgumentException("Unsupported: " + language);
        }
    }

    @Override
    public String setLanguage(String language) {
        // Update handler - can mutate state and return value
        String previous = this.language;
        this.language = language;
        return previous;
    }
}
```

## Versioning with getVersion

```java
public class MyWorkflowImpl implements MyWorkflow {
    @Override
    public void run() {
        int version = Workflow.getVersion("my-change-id", Workflow.DEFAULT_VERSION, 1);

        if (version == Workflow.DEFAULT_VERSION) {
            // Old code path
            activities.oldActivity();
        } else {
            // New code path (version == 1)
            activities.newActivity();
        }
    }
}
```

### Deprecating Versions

After all old workflows complete:

```java
int version = Workflow.getVersion("my-change-id", 1, 1);
// Only new code - minVersion changed from DEFAULT_VERSION to 1
activities.newActivity();
```

## Error Handling

```java
import io.temporal.failure.ActivityFailure;
import io.temporal.failure.ApplicationFailure;
import io.temporal.failure.TimeoutFailure;
import io.temporal.failure.CanceledFailure;

public class MyWorkflowImpl implements MyWorkflow {
    @Override
    public String run() {
        try {
            return activities.processItem("item-1");
        } catch (ActivityFailure e) {
            Throwable cause = e.getCause();

            if (cause instanceof ApplicationFailure) {
                ApplicationFailure appFailure = (ApplicationFailure) cause;
                return "Activity failed: " + appFailure.getOriginalMessage();
            }

            if (cause instanceof TimeoutFailure) {
                TimeoutFailure timeout = (TimeoutFailure) cause;
                return "Activity timed out: " + timeout.getTimeoutType();
            }

            if (cause instanceof CanceledFailure) {
                return "Activity was cancelled";
            }

            throw e;
        }
    }
}
```

### Throwing Non-Retryable Errors from Activities

```java
@Override
public void validateInput(String input) {
    if (input == null || input.isEmpty()) {
        // This error will NOT be retried
        throw ApplicationFailure.newNonRetryableFailure(
            "Input cannot be empty",
            "ValidationError"
        );
    }
}
```

## Worker Setup

```java
import io.temporal.client.WorkflowClient;
import io.temporal.serviceclient.WorkflowServiceStubs;
import io.temporal.worker.Worker;
import io.temporal.worker.WorkerFactory;

public class WorkerMain {
    public static void main(String[] args) {
        WorkflowServiceStubs service = WorkflowServiceStubs.newLocalServiceStubs();
        WorkflowClient client = WorkflowClient.newInstance(service);
        WorkerFactory factory = WorkerFactory.newInstance(client);

        Worker worker = factory.newWorker("my-task-queue");

        // Register workflows
        worker.registerWorkflowImplementationTypes(MyWorkflowImpl.class);

        // Register activities
        worker.registerActivitiesImplementations(new MyActivitiesImpl());

        factory.start();
    }
}
```

## Child Workflows

```java
public class ParentWorkflowImpl implements ParentWorkflow {
    @Override
    public String run() {
        ChildWorkflow child = Workflow.newChildWorkflowStub(
            ChildWorkflow.class,
            ChildWorkflowOptions.newBuilder()
                .setWorkflowId("child-workflow-id")
                .build());

        String result = child.process("input");
        return "Child result: " + result;
    }
}
```

## Continue-As-New

Use when workflow history grows large:

```java
public class LongRunningWorkflowImpl implements LongRunningWorkflow {
    @Override
    public void run(WorkflowState state) {
        for (int i = 0; i < 100; i++) {
            // Do work...
            state.incrementCounter();
        }

        // Check if we should continue-as-new
        if (Workflow.getInfo().isContinueAsNewSuggested()) {
            Workflow.continueAsNew(state);
        }
    }
}
```

## Timers

```java
public class MyWorkflowImpl implements MyWorkflow {
    @Override
    public void run() {
        // Durable sleep - survives crashes
        Workflow.sleep(Duration.ofHours(24));

        // Wait for condition with timeout
        boolean approved = Workflow.await(
            Duration.ofHours(1),
            () -> this.approved
        );

        if (!approved) {
            // Handle timeout
        }
    }
}
```

## Async Execution

```java
import io.temporal.workflow.Async;
import io.temporal.workflow.Promise;

public class MyWorkflowImpl implements MyWorkflow {
    @Override
    public void run() {
        // Start multiple activities concurrently
        Promise<String> result1 = Async.function(activities::activity1);
        Promise<String> result2 = Async.function(activities::activity2);
        Promise<String> result3 = Async.function(activities::activity3);

        // Wait for all to complete
        String r1 = result1.get();
        String r2 = result2.get();
        String r3 = result3.get();

        // Or wait for any
        Promise<String> first = Promise.anyOf(result1, result2, result3);
    }
}
```
