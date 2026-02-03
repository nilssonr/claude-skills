# Ruby SDK Determinism Reference

## Determinism Constraints

Workflow code must be deterministic. The SDK includes a call tracer that raises exceptions for illegal calls.

**Forbidden in Workflow code:**
- I/O operations (network, disk, stdio)
- External mutable state access
- Threading
- System clock (`Time.now`, `Date.today`)
- Random calls (`rand`, `SecureRandom`)
- Non-deterministic operations

Use SDK-provided alternatives:
- `Temporalio::Workflow.now` for current time
- `Temporalio::Workflow.random` for random numbers
- `Temporalio::Workflow.sleep` for delays
- Activities for any I/O operations

## Workflow Definition

Workflows are classes extending `Temporalio::Workflow::Definition`:

```ruby
class OrderWorkflow < Temporalio::Workflow::Definition
  # Optional: customize the workflow name
  # workflow_name :CustomOrderWorkflow

  def execute(input)
    # input is typically a Hash for flexibility
    order_id = input[:order_id]
    quantity = input[:quantity]

    # Workflow logic here
    result = Temporalio::Workflow.execute_activity(
      ProcessOrderActivity,
      { order_id: order_id },
      start_to_close_timeout: 300  # 5 minutes in seconds
    )

    "Processed: #{result}"
  end
end
```

**Note:** Use a single Hash parameter to allow adding fields without breaking the signature.

## Activity Definition

Activities are classes extending `Temporalio::Activity::Definition`:

```ruby
class ProcessOrderActivity < Temporalio::Activity::Definition
  # Optional: customize the activity name
  # activity_name :custom_process_order

  def execute(input)
    # Activities CAN do I/O, network calls, etc.
    order_id = input[:order_id]

    # Network call, DB access, etc. is fine here
    result = external_api_call(order_id)

    "Processed: #{result}"
  end

  private

  def external_api_call(order_id)
    # HTTP requests, database queries, file I/O all allowed
    order_id
  end
end
```

### Activity with Heartbeat

```ruby
class LongRunningActivity < Temporalio::Activity::Definition
  def execute(input)
    file_path = input[:file_path]

    1000.times do |i|
      # Report progress and check for cancellation
      Temporalio::Activity::Context.current.heartbeat("Processing chunk #{i}")

      # Check if cancelled
      raise Temporalio::Error::CanceledError if Temporalio::Activity::Context.current.cancellation.canceled?

      process_chunk(file_path, i)
    end

    'Completed'
  end
end
```

## Execute Activity

```ruby
class OrderWorkflow < Temporalio::Workflow::Definition
  def execute(input)
    # Basic activity execution
    result = Temporalio::Workflow.execute_activity(
      ProcessOrderActivity,
      { order_id: input[:order_id] },
      start_to_close_timeout: 300,
      # For long-running activities:
      # heartbeat_timeout: 30,
      retry_policy: Temporalio::RetryPolicy.new(
        initial_interval: 1,
        backoff_coefficient: 2.0,
        maximum_interval: 30,
        maximum_attempts: 5
      )
    )

    result
  end
end
```

## Signals

```ruby
class ApprovalWorkflow < Temporalio::Workflow::Definition
  def initialize
    super
    @approved = false
    @approver_name = ''
  end

  # Signal handler
  workflow_signal def approve(input)
    # Signal handlers mutate state but cannot return a value
    @approved = true
    @approver_name = input[:approver_name]
  end

  def execute
    # Wait for approval signal
    Temporalio::Workflow.wait_condition { @approved }

    "Approved by #{@approver_name}"
  end
end
```

## Queries

```ruby
class MyWorkflow < Temporalio::Workflow::Definition
  def initialize
    super
    @status = 'starting'
  end

  # Query handler - must NOT mutate state
  workflow_query def get_status
    @status
  end

  # Query with input
  workflow_query def get_detailed_status(verbose: false)
    verbose ? "Status: #{@status} (detailed)" : @status
  end

  def execute
    @status = 'running'
    Temporalio::Workflow.sleep(3600)  # 1 hour
    @status = 'completed'
  end
end
```

## Updates

```ruby
class MyWorkflow < Temporalio::Workflow::Definition
  SUPPORTED_LANGUAGES = %w[en es fr].freeze

  def initialize
    super
    @language = 'en'
  end

  # Update validator - reject before writing to history
  workflow_update_validator :set_language do |language|
    raise ArgumentError, "Unsupported: #{language}" unless SUPPORTED_LANGUAGES.include?(language)
  end

  # Update handler - can mutate state and return value
  workflow_update def set_language(language)
    previous = @language
    @language = language
    previous
  end

  def execute
    Temporalio::Workflow.wait_condition { @language == 'done' }
    "Final: #{@language}"
  end
end
```

## Versioning with patched

```ruby
class MyWorkflow < Temporalio::Workflow::Definition
  def execute
    if Temporalio::Workflow.patched?('my-change-id')
      # New code path
      Temporalio::Workflow.execute_activity(
        NewActivity,
        {},
        start_to_close_timeout: 300
      )
    else
      # Old code path
      Temporalio::Workflow.execute_activity(
        OldActivity,
        {},
        start_to_close_timeout: 300
      )
    end
  end
end
```

### Deprecating Patches

After all old workflows complete:

```ruby
class MyWorkflow < Temporalio::Workflow::Definition
  def execute
    Temporalio::Workflow.deprecate_patch('my-change-id')
    # Only new code remains
    Temporalio::Workflow.execute_activity(
      NewActivity,
      {},
      start_to_close_timeout: 300
    )
  end
end
```

## Error Handling

```ruby
class MyWorkflow < Temporalio::Workflow::Definition
  def execute
    begin
      Temporalio::Workflow.execute_activity(
        ProcessActivity,
        { item: 'item-1' },
        start_to_close_timeout: 300
      )
    rescue Temporalio::Error::ActivityError => e
      case e.cause
      when Temporalio::Error::ApplicationError
        "Activity failed: #{e.cause.message}"
      when Temporalio::Error::TimeoutError
        "Activity timed out: #{e.cause.timeout_type}"
      when Temporalio::Error::CanceledError
        'Activity was cancelled'
      else
        raise
      end
    end
  end
end
```

### Throwing Non-Retryable Errors from Activities

```ruby
class ValidateActivity < Temporalio::Activity::Definition
  def execute(input)
    if input.nil? || input.empty?
      # This error will NOT be retried
      raise Temporalio::Error::ApplicationError.new(
        'Input cannot be empty',
        type: 'ValidationError',
        non_retryable: true
      )
    end
  end
end
```

## Worker Setup

```ruby
require 'temporalio'

client = Temporalio::Client.connect('localhost:7233')

worker = Temporalio::Worker.new(
  client: client,
  task_queue: 'my-task-queue',
  workflows: [OrderWorkflow, ApprovalWorkflow],
  activities: [ProcessOrderActivity, ValidateActivity]
)

worker.run
```

## Child Workflows

```ruby
class ParentWorkflow < Temporalio::Workflow::Definition
  def execute
    result = Temporalio::Workflow.execute_child_workflow(
      ChildWorkflow,
      'input',
      id: 'child-workflow-id'
    )

    "Child result: #{result}"
  end
end

class ChildWorkflow < Temporalio::Workflow::Definition
  def execute(input)
    "Processed: #{input}"
  end
end
```

## Continue-As-New

Use when workflow history grows large:

```ruby
class LongRunningWorkflow < Temporalio::Workflow::Definition
  def execute(state)
    100.times do
      # Do work...
      state[:counter] += 1
    end

    # Check if we should continue-as-new
    if Temporalio::Workflow.info.continue_as_new_suggested
      Temporalio::Workflow.continue_as_new(state)
    end

    "Completed with counter: #{state[:counter]}"
  end
end
```

## Timers and Conditions

```ruby
class MyWorkflow < Temporalio::Workflow::Definition
  def initialize
    super
    @approved = false
  end

  def execute
    # Durable sleep - survives crashes
    Temporalio::Workflow.sleep(86_400)  # 24 hours

    # Wait for condition with timeout
    was_approved = Temporalio::Workflow.wait_condition(timeout: 3600) { @approved }

    unless was_approved
      return 'Timed out waiting for approval'
    end

    'Approved!'
  end
end
```

## Concurrent Execution with Futures

```ruby
class MyWorkflow < Temporalio::Workflow::Definition
  def execute
    # Start multiple activities concurrently
    futures = [
      Temporalio::Workflow::Future.new { execute_activity1 },
      Temporalio::Workflow::Future.new { execute_activity2 },
      Temporalio::Workflow::Future.new { execute_activity3 }
    ]

    # Wait for all to complete
    results = futures.map(&:result)

    results.join(', ')
  end

  private

  def execute_activity1
    Temporalio::Workflow.execute_activity(
      Activity1,
      {},
      start_to_close_timeout: 300
    )
  end

  # Similar for activity2 and activity3...
end
```

## Cancellation

```ruby
class CancellableWorkflow < Temporalio::Workflow::Definition
  def execute
    begin
      Temporalio::Workflow.sleep(3600)  # 1 hour
      'Completed normally'
    rescue Temporalio::Error::CanceledError
      # Perform cleanup
      Temporalio::Workflow.execute_activity(
        CleanupActivity,
        {},
        start_to_close_timeout: 60
      )
      'Cancelled and cleaned up'
    end
  end
end
```
