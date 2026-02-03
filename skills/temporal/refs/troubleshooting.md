# Temporal Troubleshooting Reference

## Common Errors and Fixes

### NonDeterministicError / NonDeterminismError

**Symptom:** Workflow fails with "nondeterminism" or "history mismatch" error during replay.

**Cause:** Workflow code changed in a way that produces different commands on replay.

**Common triggers:**
- Changed Activity order or added/removed Activities
- Changed Timer durations
- Used non-deterministic operations (random, time, I/O)
- Changed conditional logic affecting command order

**Fix:**
1. **Use Versioning/Patching API:**
   ```python
   # Python
   if workflow.patched("my-change-id"):
       await new_activity()
   else:
       await old_activity()
   ```

2. **Or use Worker Versioning** to pin workflows to specific code versions

3. **For existing broken workflows:**
   - Reset the workflow to before the problematic event
   - Or terminate and restart with a new workflow ID

**Prevention:**
- Always use patching when modifying workflow logic
- Run replay tests as part of CI/CD
- Never deploy workflow changes during high-traffic periods

---

### WorkflowTaskFailed (repeating)

**Symptom:** Workflow stuck, WorkflowTaskFailed events keep appearing in history.

**Cause:** Bug in Workflow code causing panic/exception during processing.

**Diagnosis:**
1. Check Worker logs for stack traces
2. Look at the `failure` field in WorkflowTaskFailed event
3. Check for recent code deployments

**Common causes:**
- Nil/null pointer dereference
- Unhandled exception in Signal/Query handler
- Serialization error (activity result can't be deserialized)

**Fix:**
1. Fix the code bug
2. Deploy the fix to Workers
3. Workflow will automatically recover on next task

---

### Activity stuck / not progressing

**Symptom:** Activity started but never completes, no retries happening.

**Possible causes:**

1. **Worker not running for Task Queue:**
   - Check Worker logs
   - Verify Task Queue name matches
   - Verify Activity is registered on Worker

2. **Activity blocked on external system:**
   - Check external system status
   - If heartbeating, check heartbeat timeout

3. **Long-running Activity without heartbeat:**
   - Won't fail until StartToCloseTimeout
   - Add heartbeats for early detection

**Diagnosis:**
```bash
# Check pending activities
temporal workflow describe -w <workflow-id>

# Check task queue
temporal task-queue describe -tq <task-queue>
```

**Fix:**
- Start/restart Worker with correct registrations
- Add heartbeats to long-running activities
- Set appropriate timeouts

---

### Workflow stuck waiting for Signal

**Symptom:** Workflow waiting indefinitely, expected Signal never arrives.

**Possible causes:**
1. Signal never sent (client bug)
2. Wrong workflow ID
3. Signal sent to terminated workflow
4. Workflow ID reuse — signal sent to old execution

**Diagnosis:**
```bash
# Check workflow history for signals
temporal workflow show -w <workflow-id>

# List recent executions with same ID
temporal workflow list -q 'WorkflowId="<workflow-id>"'
```

**Fix:**
- Verify Signal is being sent correctly
- Check workflow ID in client code
- Consider Signal-with-Start to avoid race conditions

---

### Activity retrying forever

**Symptom:** Activity keeps retrying, never succeeds or gives up.

**Cause:**
- MaximumAttempts not set (unlimited by default)
- ScheduleToCloseTimeout not set
- Transient error that's actually permanent

**Fix:**
1. Set MaximumAttempts:
   ```go
   RetryPolicy: &temporal.RetryPolicy{
       MaximumAttempts: 5,
   }
   ```

2. Set ScheduleToCloseTimeout as backstop:
   ```go
   ScheduleToCloseTimeout: time.Hour,
   ```

3. For permanent errors, throw non-retryable error:
   ```python
   raise ApplicationError("Invalid input", non_retryable=True)
   ```

---

### Cancellation not received by Activity

**Symptom:** Workflow cancelled but Activity keeps running.

**Cause:** Activity not heartbeating.

**Why:** Cancellation is delivered via heartbeat response.

**Fix:**
```python
@activity.defn
async def my_long_activity():
    while processing:
        activity.heartbeat()  # Checks for cancellation
        if activity.is_cancelled():
            # Clean up
            raise CancelledError()
```

Set HeartbeatTimeout:
```python
start_to_close_timeout=timedelta(hours=2),
heartbeat_timeout=timedelta(seconds=30),
```

---

### BlobSizeLimitError

**Symptom:** Error about payload or blob size exceeding limit.

**Limits:**
- Single payload: 2 MB
- gRPC message: 4 MB
- Event History transaction: 4 MB

**Common causes:**
- Large Activity input/output
- Large Signal/Query/Update payloads
- Accumulated state in long-running workflow

**Fix:**
1. Pass references instead of data:
   ```python
   # Instead of passing file contents
   await activity(file_contents)  # Bad

   # Pass a reference
   await activity(s3_url)  # Good
   ```

2. Use external storage for large data

3. For accumulated state, use Continue-As-New periodically

---

### Deadline Exceeded Error

**Symptom:** "Context: deadline exceeded" error from Client or Worker.

**Possible causes:**

1. **Network issues:**
   - High latency between Worker and Temporal Service
   - Connection drops

2. **Temporal Service overloaded:**
   - Check Temporal Service metrics
   - Check for resource contention

3. **Client timeout too short:**
   - Increase RPC timeout

4. **Query timeout:**
   - Complex query taking too long
   - Workflow history too large

**Fix:**
- Check network connectivity
- Increase client timeouts
- For queries: simplify or use shorter history

---

### Failed reaching server / Connection error

**Symptom:** "Failed reaching server: last connection error" on startup.

**Possible causes:**
1. Temporal Service not running
2. Wrong address/port
3. TLS certificate issues
4. Network/firewall blocking

**Diagnosis:**
```bash
# Test connectivity
temporal workflow list  # If this works, Worker should too

# Check TLS certs
openssl s_client -connect <host>:7233
```

**Fix:**
- Verify Temporal Service is running
- Check connection address
- Verify TLS certificates haven't expired
- Check firewall rules

---

### Event History growing too large

**Symptom:** Workflow slowing down, warnings about history size.

**Cause:** Long-running workflow accumulating events without Continue-As-New.

**Warning threshold:** ~10,000 events
**Hard limit:** 50,000 events (configurable)

**Fix:**
```python
@workflow.defn
class LongRunningWorkflow:
    @workflow.run
    async def run(self, state):
        while not done:
            # Do work...

            # Check if should continue-as-new
            if workflow.info().is_continue_as_new_suggested():
                workflow.continue_as_new(state)
```

**Prevention:**
- Use Continue-As-New for loops/polling
- Keep Activity payloads small
- Don't use workflows for high-frequency event streaming

---

## Diagnostic Commands

### Check Workflow Status
```bash
temporal workflow describe -w <workflow-id>
```

### View Workflow History
```bash
temporal workflow show -w <workflow-id>
```

### Check Pending Activities
```bash
temporal workflow show -w <workflow-id> --fields long
```

### Check Task Queue
```bash
temporal task-queue describe -tq <task-queue>
```

### List Workflows by Status
```bash
# Running workflows
temporal workflow list -q 'ExecutionStatus="Running"'

# Failed in last hour
temporal workflow list -q 'ExecutionStatus="Failed" AND CloseTime > "2024-01-01T00:00:00Z"'
```

### Reset Workflow
```bash
# Reset to before specific event
temporal workflow reset -w <workflow-id> --event-id <event-id>

# Reset to last successful workflow task
temporal workflow reset -w <workflow-id> --type LastWorkflowTask
```

---

## Debugging Checklist

When a workflow isn't behaving as expected:

1. **Check Worker logs** — Most errors appear here first

2. **Check Event History** — `temporal workflow show -w <id>`
   - Look for failed events
   - Check Activity inputs/outputs
   - Verify Signal delivery

3. **Check Task Queue** — `temporal task-queue describe -tq <queue>`
   - Verify Workers are polling
   - Check for backlog

4. **Check Workflow code**
   - Recent changes?
   - Non-deterministic operations?
   - Missing error handling?

5. **Check Activity code**
   - External system availability?
   - Timeout settings appropriate?
   - Heartbeating for long operations?

6. **Check Client code**
   - Correct workflow/activity types?
   - Correct Task Queue?
   - Appropriate timeouts?
