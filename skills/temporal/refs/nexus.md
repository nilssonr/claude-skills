# Temporal Nexus Reference

## Overview

Nexus enables reliable communication between Temporal Applications across:
- Different Namespaces
- Different teams
- Different regions
- Different clouds

It provides well-defined microservice contracts that abstract underlying Temporal primitives.

## Core Concepts

### Nexus Endpoint

A reverse proxy that:
- Routes requests to a target Namespace and Task Queue
- Decouples callers from handlers
- Provides built-in access controls (in Temporal Cloud)

**Registry scope:**
- Temporal Cloud: Account-scoped
- Self-hosted: Cluster-scoped

### Nexus Service

A logical grouping of related Operations. Exposed from a Nexus Endpoint.

### Nexus Operation

A unit of work that can be:
- **Synchronous:** Completes immediately (like an RPC)
- **Asynchronous:** Starts a long-running process (backed by a Workflow)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Caller Namespace                             │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Caller Workflow                              │   │
│  │                                                           │   │
│  │  result = await executeNexusOperation(                   │   │
│  │      endpoint: "my-endpoint",                             │   │
│  │      service: "OrderService",                             │   │
│  │      operation: "CreateOrder"                             │   │
│  │  )                                                        │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Nexus RPC
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Nexus Endpoint                                │
│              (Routes to target Namespace)                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Handler Namespace                             │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   Nexus Worker                            │   │
│  │                                                           │   │
│  │  OrderService:                                            │   │
│  │    - CreateOrder (async) → starts OrderWorkflow          │   │
│  │    - GetOrderStatus (sync) → queries OrderWorkflow       │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Operation Lifecycle

### Synchronous Operations

Fast operations that complete within the Nexus RPC timeout.

```
Caller                    Nexus                    Handler
  │                         │                         │
  │── StartOperation ──────▶│                         │
  │                         │── Execute ─────────────▶│
  │                         │                         │── Run Code
  │                         │◀── Result ─────────────│
  │◀── Response ───────────│                         │
  │                         │                         │
```

**Use for:**
- Simple queries
- Lightweight computations
- Operations completing in < 10 seconds

### Asynchronous Operations

Long-running operations backed by Workflows.

```
Caller                    Nexus                    Handler
  │                         │                         │
  │── StartOperation ──────▶│                         │
  │                         │── Execute ─────────────▶│
  │                         │                         │── Start Workflow
  │                         │◀── OperationToken ─────│
  │◀── "Started" + Token ──│                         │
  │                         │                         │
  │      (Workflow runs for hours/days)              │
  │                         │                         │
  │── GetResult(Token) ────▶│── Check Status ───────▶│
  │◀── "Running" ──────────│◀── Status ─────────────│
  │                         │                         │
  │── GetResult(Token) ────▶│── Check Status ───────▶│
  │◀── Result ─────────────│◀── Completed + Result ─│
```

**Use for:**
- Multi-step processes
- Human-in-the-loop workflows
- Long-running computations

## Defining Nexus Services

### Go Example

```go
// Define the service interface
type OrderService struct{}

// Sync operation - executes arbitrary code
func (s *OrderService) GetOrderStatus(ctx context.Context, orderId string) (OrderStatus, error) {
    // Query a workflow or database
    return OrderStatus{Status: "processing"}, nil
}

// Async operation - starts a workflow
func (s *OrderService) CreateOrder(ctx context.Context, input CreateOrderInput) (nexus.OperationStartResult[OrderResult], error) {
    // Start a workflow and return the operation
    return nexus.NewAsyncOperationResult(
        nexus.WorkflowRunOperation[OrderResult](
            func(ctx workflow.Context, input CreateOrderInput) (OrderResult, error) {
                // This runs as a workflow
                return processOrder(ctx, input)
            },
        ),
    ), nil
}

// Register with worker
worker.RegisterNexusService(&OrderService{})
```

### TypeScript Example

```typescript
import { nexus } from '@temporalio/workflow';

// Define operations
const createOrder = nexus.defineOperation<CreateOrderInput, OrderResult>({
  name: 'CreateOrder',
  handler: async (input) => {
    // Async - starts a workflow
    return nexus.startWorkflow(orderWorkflow, {
      args: [input],
      workflowId: `order-${input.orderId}`,
    });
  },
});

const getOrderStatus = nexus.defineOperation<string, OrderStatus>({
  name: 'GetOrderStatus',
  handler: async (orderId) => {
    // Sync - queries a workflow
    const handle = nexus.getWorkflowHandle(`order-${orderId}`);
    return handle.query(getStatusQuery);
  },
});

// Export the service
export const orderService = nexus.defineService({
  name: 'OrderService',
  operations: [createOrder, getOrderStatus],
});
```

### Python Example

```python
from temporalio import nexus, workflow
from temporalio.nexus import WorkflowRunOperation

@nexus.service
class OrderService:
    @nexus.operation
    async def get_order_status(self, order_id: str) -> OrderStatus:
        # Sync operation - queries workflow
        handle = await nexus.get_workflow_handle(f"order-{order_id}")
        return await handle.query(GetStatusQuery)

    @nexus.operation
    async def create_order(self, input: CreateOrderInput) -> nexus.OperationResult[OrderResult]:
        # Async operation - starts workflow
        return await nexus.start_workflow(
            OrderWorkflow.run,
            input,
            id=f"order-{input.order_id}",
        )
```

## Calling Nexus Operations

### From Workflow Code

```go
// Go - calling a Nexus operation from a workflow
func CallerWorkflow(ctx workflow.Context, orderId string) error {
    // Create Nexus client
    nexusClient := workflow.NewNexusClient("my-endpoint", "OrderService")

    // Call sync operation
    var status OrderStatus
    err := nexusClient.ExecuteOperation(ctx, "GetOrderStatus", orderId, &status)
    if err != nil {
        return err
    }

    // Call async operation
    var result OrderResult
    err = nexusClient.ExecuteOperation(ctx, "CreateOrder", CreateOrderInput{
        OrderId: orderId,
    }, &result)
    if err != nil {
        return err
    }

    return nil
}
```

```typescript
// TypeScript - calling a Nexus operation from a workflow
import { nexus } from '@temporalio/workflow';

export async function callerWorkflow(orderId: string): Promise<void> {
  const client = nexus.createClient({
    endpoint: 'my-endpoint',
    service: 'OrderService',
  });

  // Call sync operation
  const status = await client.execute('GetOrderStatus', orderId);

  // Call async operation
  const result = await client.execute('CreateOrder', { orderId });
}
```

## Error Handling

### Handler-Side Errors

```go
// Return specific error types
func (s *OrderService) CreateOrder(ctx context.Context, input CreateOrderInput) error {
    if input.Amount <= 0 {
        // Client will receive this as a validation error
        return nexus.NewHandlerError(
            nexus.HandlerErrorTypeBadRequest,
            "Amount must be positive",
        )
    }

    // Internal errors
    if dbErr != nil {
        return nexus.NewHandlerError(
            nexus.HandlerErrorTypeInternal,
            "Database unavailable",
        )
    }

    return nil
}
```

### Caller-Side Error Handling

```go
err := nexusClient.ExecuteOperation(ctx, "CreateOrder", input, &result)
if err != nil {
    var handlerErr *nexus.HandlerError
    if errors.As(err, &handlerErr) {
        switch handlerErr.Type {
        case nexus.HandlerErrorTypeBadRequest:
            // Invalid input from caller
        case nexus.HandlerErrorTypeNotFound:
            // Resource not found
        case nexus.HandlerErrorTypeInternal:
            // Handler-side failure
        case nexus.HandlerErrorTypeUnavailable:
            // Temporary unavailability, can retry
        }
    }
}
```

## Multi-Level Calls

Nexus supports chained calls:

```
Workflow A
    └── Nexus Operation 1
            └── Workflow B
                    └── Nexus Operation 2
                            └── Workflow C
```

## Best Practices

### Service Design

1. **Define clear contracts** — Use typed inputs/outputs
2. **Prefer async for long operations** — Anything > 10 seconds
3. **Version your services** — Include version in service name if needed
4. **Document operations** — Describe expected behavior and errors

### Security

1. **Use built-in access controls** (Temporal Cloud)
2. **Implement authorization in handlers** (self-hosted)
3. **Validate all inputs**
4. **Don't expose internal details in errors**

### Reliability

1. **Make operations idempotent** — They may be retried
2. **Use appropriate timeouts** — Consider network latency
3. **Handle partial failures** — Async operations may start but caller may not get response
4. **Monitor operation metrics**

## Temporal Cloud vs Self-Hosted

| Feature | Temporal Cloud | Self-Hosted |
|---------|---------------|-------------|
| Endpoint Registry | Account-scoped | Cluster-scoped |
| Cross-region | Supported | Single cluster |
| Access Control | Built-in | Custom Authorizer |
| mTLS | Supported | Supported |
| API Keys | Supported | Not available |
