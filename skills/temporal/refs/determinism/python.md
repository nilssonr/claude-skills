# Python SDK Determinism Reference

## Determinism Constraints

Workflow code must be deterministic. This means NO:
- Threading
- Randomness
- External calls to processes
- Network I/O
- Global state mutation
- System date or time

Use these SDK APIs instead of standard Python equivalents:

| Instead of | Use |
|------------|-----|
| `time.time()` | `workflow.time()` |
| `asyncio.sleep()` | `workflow.sleep()` |
| `random.random()` | `workflow.random().random()` |
| `datetime.now()` | `workflow.now()` |
| `uuid.uuid4()` | `workflow.uuid4()` |

### Sandbox and Imports

The Python SDK uses a sandbox that restricts non-deterministic operations. For modules with deterministic calls (Activities, data classes, third-party libs):

```python
from temporalio import workflow

# Pass through modules that are deterministic
with workflow.unsafe.imports_passed_through():
    from your_activities import your_activity
    from your_dataobjects import YourParams
```

Or configure at Worker creation time using `with_passthrough_modules`.

## Workflow Definition

```python
from dataclasses import dataclass
from datetime import timedelta
from temporalio import workflow

with workflow.unsafe.imports_passed_through():
    from your_activities import your_activity

# Use dataclasses for parameters (allows adding fields later)
@dataclass
class YourWorkflowParams:
    param_x: str
    param_y: int

@dataclass
class YourWorkflowResult:
    result_x: str
    result_y: int

@workflow.defn(name="YourWorkflow")
class YourWorkflow:
    @workflow.run
    async def run(self, params: YourWorkflowParams) -> YourWorkflowResult:
        # Workflow logic here
        result = await workflow.execute_activity(
            your_activity,
            params,
            start_to_close_timeout=timedelta(seconds=10),
        )
        return YourWorkflowResult(result_x=result, result_y=42)
```

## Activity Definition

```python
from dataclasses import dataclass
from temporalio import activity

@dataclass
class YourActivityParams:
    input: str

@activity.defn(name="your_activity")
async def your_activity(params: YourActivityParams) -> str:
    # Activities CAN do I/O, network calls, etc.
    return f"processed: {params.input}"
```

### Sync vs Async Activities

```python
# Async activity (recommended for I/O-bound work)
@activity.defn
async def async_activity(param: str) -> str:
    async with aiohttp.ClientSession() as session:
        async with session.get(f"https://api.example.com/{param}") as resp:
            return await resp.text()

# Sync activity (for CPU-bound or blocking libraries)
# Must run on ThreadPoolExecutor or ProcessPoolExecutor
@activity.defn
def sync_activity(param: str) -> str:
    import requests
    return requests.get(f"https://api.example.com/{param}").text
```

## Execute Activity

```python
@workflow.defn
class YourWorkflow:
    @workflow.run
    async def run(self, params: YourWorkflowParams) -> YourWorkflowResult:
        # start_to_close_timeout is REQUIRED
        result = await workflow.execute_activity(
            your_activity,
            YourActivityParams(input="hello"),
            start_to_close_timeout=timedelta(seconds=30),
            # For long-running activities, add heartbeat:
            # heartbeat_timeout=timedelta(seconds=10),
        )
        return YourWorkflowResult(result_x=result, result_y=42)
```

## Signals

```python
@dataclass
class ApproveInput:
    approver_name: str

@workflow.defn
class YourWorkflow:
    def __init__(self) -> None:
        self.approved = False
        self.approver_name = ""

    @workflow.signal
    def approve(self, input: ApproveInput) -> None:
        # Signal handlers mutate state but cannot return a value
        self.approved = True
        self.approver_name = input.approver_name

    @workflow.run
    async def run(self) -> str:
        # Wait for approval signal
        await workflow.wait_condition(lambda: self.approved)
        return f"Approved by {self.approver_name}"
```

## Queries

```python
@workflow.defn
class YourWorkflow:
    def __init__(self) -> None:
        self.current_state = "initial"

    @workflow.query
    def get_state(self) -> str:
        # Query handlers must NOT mutate state
        # Use def, not async def
        return self.current_state

    @workflow.run
    async def run(self) -> str:
        self.current_state = "running"
        await workflow.sleep(timedelta(hours=1))
        self.current_state = "completed"
        return self.current_state
```

## Updates

```python
@dataclass
class SetLanguageInput:
    language: str

@workflow.defn
class YourWorkflow:
    def __init__(self) -> None:
        self.language = "en"
        self.supported = ["en", "es", "fr"]

    @workflow.update
    def set_language(self, input: SetLanguageInput) -> str:
        # Updates CAN mutate state and return a value
        previous = self.language
        self.language = input.language
        return previous

    @set_language.validator
    def validate_set_language(self, input: SetLanguageInput) -> None:
        # Validators reject updates before they're written to history
        if input.language not in self.supported:
            raise ValueError(f"Unsupported language: {input.language}")

    @workflow.run
    async def run(self) -> str:
        await workflow.wait_condition(lambda: self.language == "done")
        return f"Final language: {self.language}"
```

## Versioning with patched()

Use `patched()` to make backward-compatible changes to running workflows:

```python
@workflow.defn
class MyWorkflow:
    @workflow.run
    async def run(self) -> None:
        if workflow.patched("my-patch"):
            # New code path (workflows started after this change)
            self._result = await workflow.execute_activity(
                post_patch_activity,
                schedule_to_close_timeout=timedelta(minutes=5),
            )
        else:
            # Old code path (workflows started before this change)
            self._result = await workflow.execute_activity(
                pre_patch_activity,
                schedule_to_close_timeout=timedelta(minutes=5),
            )
```

### Deprecating Patches

After all old workflows complete:

```python
@workflow.defn
class MyWorkflow:
    @workflow.run
    async def run(self) -> None:
        # Mark the patch as deprecated
        workflow.deprecate_patch("my-patch")
        # Only new code remains
        self._result = await workflow.execute_activity(
            post_patch_activity,
            schedule_to_close_timeout=timedelta(minutes=5),
        )
```

## Error Handling

```python
from temporalio import workflow
from temporalio.exceptions import (
    ActivityError,
    ApplicationError,
    CancelledError,
    TimeoutError,
)

@workflow.defn
class YourWorkflow:
    @workflow.run
    async def run(self) -> str:
        try:
            result = await workflow.execute_activity(
                your_activity,
                start_to_close_timeout=timedelta(seconds=30),
            )
            return result
        except ActivityError as e:
            if isinstance(e.cause, ApplicationError):
                # Handle application-level error
                return f"Activity failed: {e.cause.message}"
            elif isinstance(e.cause, TimeoutError):
                # Handle timeout
                return f"Activity timed out: {e.cause.type}"
            elif isinstance(e.cause, CancelledError):
                # Handle cancellation
                return "Activity was cancelled"
            raise
```

## Worker Setup

```python
import asyncio
from temporalio.client import Client
from temporalio.worker import Worker

from your_workflows import YourWorkflow
from your_activities import your_activity

async def main():
    client = await Client.connect("localhost:7233")

    worker = Worker(
        client,
        task_queue="your-task-queue",
        workflows=[YourWorkflow],
        activities=[your_activity],
    )

    await worker.run()

if __name__ == "__main__":
    asyncio.run(main())
```

## Child Workflows

```python
@workflow.defn
class ParentWorkflow:
    @workflow.run
    async def run(self) -> str:
        result = await workflow.execute_child_workflow(
            ChildWorkflow.run,
            "child-input",
            id="child-workflow-id",
        )
        return f"Child result: {result}"

@workflow.defn
class ChildWorkflow:
    @workflow.run
    async def run(self, input: str) -> str:
        return f"processed: {input}"
```

## Continue-As-New

Use when workflow history grows large:

```python
from temporalio.workflow import ContinueAsNewError

@dataclass
class WorkflowState:
    counter: int
    data: list

@workflow.defn
class LongRunningWorkflow:
    @workflow.run
    async def run(self, state: WorkflowState) -> str:
        for _ in range(100):
            # Do work...
            state.counter += 1

        # Check if we should continue-as-new
        if workflow.info().is_continue_as_new_suggested():
            workflow.continue_as_new(state)

        return f"Completed with counter: {state.counter}"
```

## Timers

```python
@workflow.defn
class YourWorkflow:
    @workflow.run
    async def run(self) -> str:
        # Durable sleep - survives crashes
        await workflow.sleep(timedelta(hours=24))

        # Or wait for a condition with timeout
        try:
            await workflow.wait_condition(
                lambda: self.approved,
                timeout=timedelta(hours=1),
            )
        except asyncio.TimeoutError:
            return "Timed out waiting for approval"

        return "Completed"
```

## Async Signal/Update Handlers

Signal and Update handlers can be async, allowing Activities and Child Workflows:

```python
@workflow.defn
class YourWorkflow:
    def __init__(self) -> None:
        self.processing = False

    @workflow.signal
    async def process_data(self, data: str) -> None:
        self.processing = True
        # Can execute activities from signal handler
        await workflow.execute_activity(
            process_activity,
            data,
            start_to_close_timeout=timedelta(minutes=5),
        )
        self.processing = False

    @workflow.run
    async def run(self) -> str:
        # Wait for all handlers to complete before finishing
        await workflow.wait_condition(lambda: not self.processing)
        return "Done"
```

**Important:** Always wait for handlers to complete before using Continue-As-New or completing the workflow using `workflow.wait_condition(workflow.all_handlers_finished)`.
