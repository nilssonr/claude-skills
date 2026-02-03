# PHP SDK Determinism Reference

## Determinism Constraints

Workflow code must be deterministic. Every time a Workflow state is restored, its code is re-executed from the beginning. Side effects (Activity invocations) are ignored during replay.

**Forbidden in Workflow code:**
- Mutable global variables
- Non-seeded random or UUID calls
- I/O operations (network, disk, stdio)
- Blocking SPL functions (`fopen`, `PDO`, etc.)
- Direct configuration access
- `sleep()` function

**Required SDK alternatives:**

| Instead of | Use |
|------------|-----|
| `time()` / `date()` | `Workflow::now()` |
| `sleep()` | `yield Workflow::timer()` |
| Random/UUID | Activities for non-deterministic operations |
| Config access | Pass as Workflow argument or use Activity |

## Workflow Definition

Workflows are classes implementing interfaces annotated with `#[WorkflowInterface]`:

```php
use Temporal\Workflow\WorkflowInterface;
use Temporal\Workflow\WorkflowMethod;
use Temporal\Workflow\ReturnType;

#[WorkflowInterface]
interface OrderWorkflow
{
    #[WorkflowMethod]
    #[ReturnType('string')]
    public function processOrder(OrderInput $input);
}

// Parameter class
class OrderInput
{
    public function __construct(
        public string $orderId,
        public int $quantity
    ) {}
}

// Implementation
class OrderWorkflowImpl implements OrderWorkflow
{
    public function processOrder(OrderInput $input): \Generator
    {
        // Workflow logic here
        $result = yield $this->activities->process($input->orderId);
        return "Processed: " . $result;
    }
}
```

**Note:** Workflow methods return `Generator` due to PHP's yield mechanism. Use `#[ReturnType()]` to specify the actual return type.

## Activity Definition

```php
use Temporal\Activity\ActivityInterface;
use Temporal\Activity\ActivityMethod;

#[ActivityInterface]
interface OrderActivities
{
    // Activities CAN do I/O, network calls, etc.
    #[ActivityMethod]
    public function processItem(string $itemId): string;

    #[ActivityMethod(name: "send_notification")]
    public function sendNotification(NotificationInput $input): void;
}

// Implementation
class OrderActivitiesImpl implements OrderActivities
{
    public function processItem(string $itemId): string
    {
        // Network call, DB access, etc. is fine here
        return "Processed: " . $itemId;
    }

    public function sendNotification(NotificationInput $input): void
    {
        // Send email, SMS, etc.
    }
}
```

## Execute Activity

```php
use Temporal\Activity\ActivityOptions;
use Temporal\Common\RetryOptions;

class OrderWorkflowImpl implements OrderWorkflow
{
    private $activities;

    public function __construct()
    {
        $this->activities = Workflow::newActivityStub(
            OrderActivities::class,
            ActivityOptions::new()
                ->withStartToCloseTimeout(CarbonInterval::minutes(5))
                // For long-running activities:
                // ->withHeartbeatTimeout(CarbonInterval::seconds(30))
                ->withRetryOptions(
                    RetryOptions::new()
                        ->withInitialInterval(CarbonInterval::second())
                        ->withBackoffCoefficient(2.0)
                        ->withMaximumInterval(CarbonInterval::seconds(30))
                        ->withMaximumAttempts(5)
                )
        );
    }

    public function processOrder(OrderInput $input): \Generator
    {
        // yield is required for activity calls
        $result = yield $this->activities->processItem($input->orderId);
        return $result;
    }
}
```

## Signals

```php
use Temporal\Workflow\SignalMethod;

#[WorkflowInterface]
interface ApprovalWorkflow
{
    #[WorkflowMethod]
    #[ReturnType('string')]
    public function run();

    #[SignalMethod]
    public function approve(string $approverName): void;
}

class ApprovalWorkflowImpl implements ApprovalWorkflow
{
    private bool $approved = false;
    private string $approverName = '';

    public function run(): \Generator
    {
        // Wait for approval signal
        yield Workflow::await(fn() => $this->approved);
        return "Approved by " . $this->approverName;
    }

    public function approve(string $approverName): void
    {
        // Signal handlers mutate state
        $this->approved = true;
        $this->approverName = $approverName;
    }
}
```

## Queries

```php
use Temporal\Workflow\QueryMethod;

#[WorkflowInterface]
interface MyWorkflow
{
    #[WorkflowMethod]
    public function run();

    #[QueryMethod]
    public function getStatus(): string;

    #[QueryMethod(name: "detailed_status")]
    public function getDetailedStatus(): StatusInfo;
}

class MyWorkflowImpl implements MyWorkflow
{
    private string $status = 'starting';

    public function run(): \Generator
    {
        $this->status = 'running';
        yield Workflow::timer(CarbonInterval::hour());
        $this->status = 'completed';
    }

    public function getStatus(): string
    {
        // Query handlers must NOT mutate state
        return $this->status;
    }

    public function getDetailedStatus(): StatusInfo
    {
        return new StatusInfo($this->status, Workflow::now());
    }
}
```

## Updates

```php
use Temporal\Workflow\UpdateMethod;
use Temporal\Workflow\UpdateValidatorMethod;

#[WorkflowInterface]
interface MyWorkflow
{
    #[WorkflowMethod]
    #[ReturnType('string')]
    public function run();

    #[UpdateMethod]
    public function setLanguage(string $language): string;

    #[UpdateValidatorMethod(forUpdate: "setLanguage")]
    public function validateSetLanguage(string $language): void;
}

class MyWorkflowImpl implements MyWorkflow
{
    private string $language = 'en';
    private array $supported = ['en', 'es', 'fr'];

    public function run(): \Generator
    {
        yield Workflow::await(fn() => $this->language === 'done');
        return "Final: " . $this->language;
    }

    public function validateSetLanguage(string $language): void
    {
        // Validator - reject before writing to history
        if (!in_array($language, $this->supported)) {
            throw new \InvalidArgumentException("Unsupported: " . $language);
        }
    }

    public function setLanguage(string $language): string
    {
        // Update handler - can mutate state and return value
        $previous = $this->language;
        $this->language = $language;
        return $previous;
    }
}
```

## Versioning with getVersion

```php
class MyWorkflowImpl implements MyWorkflow
{
    public function run(): \Generator
    {
        $version = yield Workflow::getVersion(
            'my-change-id',
            Workflow::DEFAULT_VERSION,
            1
        );

        if ($version === Workflow::DEFAULT_VERSION) {
            // Old code path
            yield $this->activities->oldActivity();
        } else {
            // New code path (version === 1)
            yield $this->activities->newActivity();
        }
    }
}
```

## Error Handling

```php
use Temporal\Exception\Failure\ActivityFailure;
use Temporal\Exception\Failure\ApplicationFailure;
use Temporal\Exception\Failure\TimeoutFailure;
use Temporal\Exception\Failure\CanceledFailure;

class MyWorkflowImpl implements MyWorkflow
{
    public function run(): \Generator
    {
        try {
            return yield $this->activities->processItem('item-1');
        } catch (ActivityFailure $e) {
            $cause = $e->getPrevious();

            if ($cause instanceof ApplicationFailure) {
                return "Activity failed: " . $cause->getOriginalMessage();
            }

            if ($cause instanceof TimeoutFailure) {
                return "Activity timed out: " . $cause->getTimeoutType();
            }

            if ($cause instanceof CanceledFailure) {
                return "Activity was cancelled";
            }

            throw $e;
        }
    }
}
```

## Worker Setup

```php
use Temporal\WorkerFactory;

$factory = WorkerFactory::create();

$worker = $factory->newWorker('my-task-queue');

// Register workflows
$worker->registerWorkflowTypes(OrderWorkflowImpl::class);

// Register activities
$worker->registerActivity(OrderActivitiesImpl::class);

$factory->run();
```

## Child Workflows

```php
use Temporal\Workflow\ChildWorkflowOptions;

class ParentWorkflowImpl implements ParentWorkflow
{
    public function run(): \Generator
    {
        $child = Workflow::newChildWorkflowStub(
            ChildWorkflow::class,
            ChildWorkflowOptions::new()
                ->withWorkflowId('child-workflow-id')
        );

        $result = yield $child->process('input');
        return "Child result: " . $result;
    }
}
```

## Continue-As-New

Use when workflow history grows large:

```php
use Temporal\Workflow\ContinueAsNewOptions;

class LongRunningWorkflowImpl implements LongRunningWorkflow
{
    public function run(WorkflowState $state): \Generator
    {
        for ($i = 0; $i < 100; $i++) {
            // Do work...
            $state->incrementCounter();
        }

        // Continue as new with updated state
        return Workflow::continueAsNew(
            'LongRunningWorkflow',
            [$state]
        );
    }
}
```

## Timers

```php
use Carbon\CarbonInterval;

class MyWorkflowImpl implements MyWorkflow
{
    private bool $approved = false;

    public function run(): \Generator
    {
        // Durable timer - survives crashes
        yield Workflow::timer(CarbonInterval::hours(24));

        // Wait for condition with timeout
        $wasApproved = yield Workflow::awaitWithTimeout(
            CarbonInterval::hour(),
            fn() => $this->approved
        );

        if (!$wasApproved) {
            return "Timed out waiting for approval";
        }

        return "Approved!";
    }
}
```

## Async Execution

```php
use Temporal\Promise;

class MyWorkflowImpl implements MyWorkflow
{
    public function run(): \Generator
    {
        // Start multiple activities concurrently (don't yield yet)
        $promise1 = $this->activities->activity1();
        $promise2 = $this->activities->activity2();
        $promise3 = $this->activities->activity3();

        // Wait for all to complete
        [$r1, $r2, $r3] = yield Promise::all([$promise1, $promise2, $promise3]);

        // Or wait for any
        $first = yield Promise::any([$promise1, $promise2, $promise3]);

        return $r1 . $r2 . $r3;
    }
}
```
