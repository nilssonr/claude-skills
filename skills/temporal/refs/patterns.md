# Temporal Design Patterns

## Saga Pattern

Execute a sequence of Activities with compensating actions on failure.

**Use when:** You need to maintain consistency across multiple services/operations that don't support distributed transactions.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Activity A  │────▶│ Activity B  │────▶│ Activity C  │
│  (Reserve)  │     │  (Charge)   │     │  (Ship)     │
└─────────────┘     └─────────────┘     └─────────────┘
       │                  │                   │
       ▼                  ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Compensate  │◀────│ Compensate  │◀────│ Compensate  │
│  (Release)  │     │  (Refund)   │     │  (Cancel)   │
└─────────────┘     └─────────────┘     └─────────────┘
```

**Implementation:**

```python
# Python example
@workflow.defn
class OrderSagaWorkflow:
    @workflow.run
    async def run(self, order: Order) -> str:
        compensations = []

        try:
            # Step 1: Reserve inventory
            await workflow.execute_activity(
                reserve_inventory,
                order,
                start_to_close_timeout=timedelta(minutes=5)
            )
            compensations.append(("release_inventory", order))

            # Step 2: Charge payment
            await workflow.execute_activity(
                charge_payment,
                order,
                start_to_close_timeout=timedelta(minutes=5)
            )
            compensations.append(("refund_payment", order))

            # Step 3: Ship order
            await workflow.execute_activity(
                ship_order,
                order,
                start_to_close_timeout=timedelta(minutes=5)
            )

            return "Order completed"

        except Exception as e:
            # Compensate in reverse order
            for compensation_name, args in reversed(compensations):
                try:
                    await workflow.execute_activity(
                        compensation_name,
                        args,
                        start_to_close_timeout=timedelta(minutes=5)
                    )
                except Exception:
                    # Log but continue compensating
                    pass
            raise
```

**Key points:**
- Track compensations as you go
- Execute compensations in reverse order
- Handle compensation failures gracefully
- Consider idempotency for both forward and compensation operations

---

## Entity Workflow Pattern

A long-lived Workflow that accumulates state via Signals/Updates.

**Use when:** You need a stateful entity that receives events over time (user session, shopping cart, order lifecycle).

```
┌──────────────────────────────────────────────────────────┐
│                    Entity Workflow                        │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ State: { items: [], total: 0, status: "active" }    │ │
│  └─────────────────────────────────────────────────────┘ │
│                          ▲                               │
│    Signal: AddItem       │        Signal: Checkout       │
│    Signal: RemoveItem    │        Query: GetCart         │
│    Update: ApplyCoupon   │        Update: SetQuantity    │
└──────────────────────────────────────────────────────────┘
```

**Implementation:**

```typescript
// TypeScript example
import * as wf from '@temporalio/workflow';

interface CartItem { productId: string; quantity: number; price: number; }
interface CartState { items: CartItem[]; total: number; checkedOut: boolean; }

export const addItem = wf.defineSignal<[CartItem]>('addItem');
export const removeItem = wf.defineSignal<[string]>('removeItem');
export const getCart = wf.defineQuery<CartState>('getCart');
export const checkout = wf.defineSignal('checkout');

export async function shoppingCartWorkflow(userId: string): Promise<CartState> {
  const state: CartState = { items: [], total: 0, checkedOut: false };

  wf.setHandler(addItem, (item) => {
    state.items.push(item);
    state.total += item.price * item.quantity;
  });

  wf.setHandler(removeItem, (productId) => {
    const idx = state.items.findIndex(i => i.productId === productId);
    if (idx >= 0) {
      state.total -= state.items[idx].price * state.items[idx].quantity;
      state.items.splice(idx, 1);
    }
  });

  wf.setHandler(getCart, () => state);

  wf.setHandler(checkout, () => { state.checkedOut = true; });

  // Wait for checkout or timeout after 24 hours
  const completed = await wf.condition(() => state.checkedOut, '24h');

  if (!completed) {
    // Cart abandoned - could trigger reminder
  }

  // Use Continue-As-New periodically for long-lived entities
  if (wf.workflowInfo().continueAsNewSuggested) {
    await wf.continueAsNew<typeof shoppingCartWorkflow>(userId);
  }

  return state;
}
```

**Key points:**
- Use Signals for fire-and-forget state changes
- Use Updates when you need a return value or validation
- Use Queries for read-only state access
- Implement Continue-As-New to prevent unbounded history growth
- Consider workflow timeouts for entity lifecycle

---

## Human-in-the-Loop Pattern

Workflow waits for human action via Signal, with optional reminders/escalation.

**Use when:** A process requires human approval, review, or input.

```
┌─────────────────────────────────────────────────────────────┐
│                    Approval Workflow                         │
│                                                              │
│  ┌──────────┐     ┌──────────────┐     ┌──────────────────┐ │
│  │ Request  │────▶│ Wait for     │────▶│ Process          │ │
│  │ Created  │     │ Approval     │     │ Approval         │ │
│  └──────────┘     └──────────────┘     └──────────────────┘ │
│                         │                                    │
│                    ┌────┴────┐                               │
│                    │ Timer   │                               │
│                    │ (1 day) │                               │
│                    └────┬────┘                               │
│                         │                                    │
│                    ┌────▼────┐                               │
│                    │ Remind  │                               │
│                    │ or      │                               │
│                    │Escalate │                               │
│                    └─────────┘                               │
└─────────────────────────────────────────────────────────────┘
```

**Implementation:**

```go
// Go example
func ApprovalWorkflow(ctx workflow.Context, request ApprovalRequest) (string, error) {
    logger := workflow.GetLogger(ctx)

    var approval ApprovalDecision
    approvalCh := workflow.GetSignalChannel(ctx, "approval")

    // Send initial notification
    ao := workflow.ActivityOptions{StartToCloseTimeout: time.Minute}
    ctx = workflow.WithActivityOptions(ctx, ao)
    workflow.ExecuteActivity(ctx, NotifyApprover, request).Get(ctx, nil)

    reminderCount := 0
    maxReminders := 3

    for {
        selector := workflow.NewSelector(ctx)

        // Wait for approval signal
        selector.AddReceive(approvalCh, func(c workflow.ReceiveChannel, more bool) {
            c.Receive(ctx, &approval)
        })

        // Set reminder timer (1 day)
        timer := workflow.NewTimer(ctx, 24*time.Hour)
        selector.AddFuture(timer, func(f workflow.Future) {
            reminderCount++
            if reminderCount < maxReminders {
                workflow.ExecuteActivity(ctx, SendReminder, request, reminderCount)
            } else {
                workflow.ExecuteActivity(ctx, EscalateRequest, request)
            }
        })

        selector.Select(ctx)

        // Check if we received approval
        if approval.Decision != "" {
            break
        }
    }

    if approval.Decision == "approved" {
        return "Request approved by " + approval.Approver, nil
    }
    return "Request rejected: " + approval.Reason, nil
}
```

**Key points:**
- Use durable Timers for reminders (survive crashes)
- Implement escalation after multiple reminders
- Consider timeout for auto-rejection/escalation
- Track approval chain for audit

---

## Fan-Out/Fan-In Pattern

Execute multiple Activities or Child Workflows in parallel, then aggregate results.

**Use when:** You need to process multiple items concurrently and combine results.

```
                    ┌─────────────┐
                    │   Workflow  │
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │ Activity 1 │  │ Activity 2 │  │ Activity 3 │
    └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
          │               │               │
          └───────────────┼───────────────┘
                          │
                          ▼
                   ┌────────────┐
                   │  Aggregate │
                   │  Results   │
                   └────────────┘
```

**Implementation:**

```java
// Java example
public class BatchProcessingWorkflowImpl implements BatchProcessingWorkflow {
    private final ProcessingActivities activities = Workflow.newActivityStub(
        ProcessingActivities.class,
        ActivityOptions.newBuilder()
            .setStartToCloseTimeout(Duration.ofMinutes(5))
            .build());

    @Override
    public BatchResult processBatch(List<Item> items) {
        // Fan out: start all activities concurrently
        List<Promise<ItemResult>> promises = new ArrayList<>();
        for (Item item : items) {
            promises.add(Async.function(activities::processItem, item));
        }

        // Fan in: wait for all to complete and aggregate
        List<ItemResult> results = new ArrayList<>();
        List<String> errors = new ArrayList<>();

        for (int i = 0; i < promises.size(); i++) {
            try {
                results.add(promises.get(i).get());
            } catch (Exception e) {
                errors.add("Item " + i + ": " + e.getMessage());
            }
        }

        return new BatchResult(results, errors);
    }
}
```

**Key points:**
- Use SDK-specific async primitives (`Promise`, `Future`, `asyncio.gather`)
- Handle partial failures gracefully
- Consider rate limiting for large fan-outs
- Use Child Workflows for complex sub-processes

---

## Polling Pattern

Activity polls an external system until a condition is met.

**Use when:** You need to wait for an external system to reach a certain state.

```
┌────────────────────────────────────────────────────┐
│                 Polling Activity                    │
│                                                     │
│   ┌─────────┐      ┌─────────┐      ┌─────────┐   │
│   │  Poll   │─────▶│  Check  │─────▶│ Return  │   │
│   │ System  │      │ Result  │      │ Result  │   │
│   └─────────┘      └────┬────┘      └─────────┘   │
│        ▲                │                          │
│        │           Not Ready                       │
│        │                │                          │
│        │           ┌────▼────┐                     │
│        └───────────│  Wait   │                     │
│                    │ (backoff)│                     │
│                    └─────────┘                     │
└────────────────────────────────────────────────────┘
```

**Implementation:**

```python
# Python example
@activity.defn
async def poll_for_completion(job_id: str) -> JobResult:
    backoff = 1  # Start with 1 second
    max_backoff = 60  # Cap at 60 seconds

    while True:
        # Heartbeat to show we're alive
        activity.heartbeat(f"Polling job {job_id}")

        # Check external system
        result = await check_job_status(job_id)

        if result.status == "completed":
            return result
        elif result.status == "failed":
            raise ApplicationError(f"Job failed: {result.error}")

        # Not ready, wait with exponential backoff
        await asyncio.sleep(backoff)
        backoff = min(backoff * 2, max_backoff)

# In workflow
@workflow.defn
class JobWorkflow:
    @workflow.run
    async def run(self, job_request: JobRequest) -> JobResult:
        # Submit job
        job_id = await workflow.execute_activity(
            submit_job,
            job_request,
            start_to_close_timeout=timedelta(minutes=5)
        )

        # Poll for completion (long timeout, with heartbeats)
        result = await workflow.execute_activity(
            poll_for_completion,
            job_id,
            start_to_close_timeout=timedelta(hours=2),
            heartbeat_timeout=timedelta(minutes=1)
        )

        return result
```

**Key points:**
- Always heartbeat in long-running polling activities
- Use exponential backoff to avoid overwhelming the external system
- Set appropriate timeouts (ScheduleToClose for total time, Heartbeat for liveness)
- Consider circuit breaker for repeated failures

---

## Continue-As-New Pattern

Periodically reset Workflow history to prevent unbounded growth.

**Use when:** Long-running or looping Workflows that would accumulate large Event History.

```
┌────────────────────────────────────────────────────────────┐
│ Workflow Run 1           Continue-As-New                   │
│ ┌──────────────────┐    ┌─────────────────────────────────┐│
│ │ Events: 1-1000   │───▶│ Workflow Run 2                  ││
│ │ State: {...}     │    │ Events: 1-1000                  ││
│ └──────────────────┘    │ State: {...} (carried over)     ││
│                         └─────────────────────────────────┘│
└────────────────────────────────────────────────────────────┘
```

**Implementation:**

```go
// Go example
func ProcessingWorkflow(ctx workflow.Context, state ProcessingState) error {
    logger := workflow.GetLogger(ctx)

    for {
        // Process next batch
        var result BatchResult
        err := workflow.ExecuteActivity(ctx, ProcessBatch, state.NextBatchId).Get(ctx, &result)
        if err != nil {
            return err
        }

        state.ProcessedCount += result.Count
        state.NextBatchId = result.NextBatchId

        // Check if done
        if result.IsComplete {
            return nil
        }

        // Check if we should continue-as-new
        if workflow.GetInfo(ctx).GetContinueAsNewSuggested() {
            logger.Info("Continuing as new", "processedCount", state.ProcessedCount)
            return workflow.NewContinueAsNewError(ctx, ProcessingWorkflow, state)
        }
    }
}
```

**Key points:**
- Check `ContinueAsNewSuggested` flag periodically
- Carry forward only essential state
- Drain Signal channels before continuing (signals are lost otherwise)
- Wait for all handlers to finish: `Workflow.await(Workflow::allHandlersFinished)`

---

## Rate Limiting Pattern

Control the rate of Activity executions to avoid overwhelming external systems.

**Implementation approaches:**

1. **Semaphore in Workflow** (SDK-specific):
   ```typescript
   // TypeScript - limit concurrent activities
   const semaphore = new wf.Semaphore(5); // Max 5 concurrent

   for (const item of items) {
     await semaphore.acquire();
     wf.executeActivity(processItem, item)
       .finally(() => semaphore.release());
   }
   ```

2. **Worker-level rate limiting** (configure in Worker options)

3. **Activity-level rate limiting** (implement in Activity code)

**Key points:**
- Prefer Worker-level rate limiting when possible
- Use Workflow-level semaphores for fine-grained control
- Consider external rate limiting services for distributed scenarios
