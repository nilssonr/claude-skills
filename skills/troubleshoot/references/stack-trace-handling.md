# Stack Trace Handling

Triage priority when a stack trace or error log is provided.

## Triage Steps

1. Read the last frame (or outermost exception) for the immediate error
2. Find the first frame that points to in-repo source (skip framework/library frames)
3. Open that file at the reported line; read surrounding context
4. Search for related call sites using Grep
5. Produce a triage summary (format below)

## Language-Specific Patterns

### Go
- `goroutine N [status]:` header followed by `package.Function(args)` and `file.go:line +offset`
- Panic traces: look for `panic:` line, then first non-runtime frame
- Multiple goroutines: check for deadlock patterns (all goroutines blocked)

### Java / Kotlin
- `Exception in thread "name" fully.qualified.Exception: message`
- `Caused by:` chains -- the deepest cause is usually the root
- `at package.Class.method(File.java:line)` frames
- Spring: skip proxy/AOP frames, find the actual handler

### Python
- `Traceback (most recent call last):` -- last frame is where it failed
- `File "path", line N, in function_name` frames
- Chained exceptions: `During handling of the above exception, another exception occurred:`

### TypeScript / Node.js
- `Error: message` followed by `at Function (file:line:col)` frames
- Async traces: look for `at async` or `at processTicksAndRejections` boundaries
- Webpack/bundler: source maps may offset line numbers -- check for `.map` files

### C# / .NET
- `System.Exception: message` with `at Namespace.Class.Method() in File:line N`
- Inner exceptions: `---> System.Exception:` -- follow the chain inward
- async/await: look past `--- End of stack trace from previous location ---`

### Rust
- `thread 'name' panicked at 'message', file:line:col`
- Backtrace frames: ` N: function_name at file:line`
- `RUST_BACKTRACE=1` may be needed for full traces

## Structured Log Fields

When errors come as JSON or structured logs, check these common fields:

| Field names | What they contain |
|---|---|
| `stackTrace`, `StackTrace`, `stack_trace` | Full stack trace string |
| `exception`, `error`, `err` | Exception type or message |
| `message`, `msg`, `detail` | Human-readable description |
| `Failures`, `Warnings`, `errors` | Arrays of nested error objects |
| `traceId`, `trace_id`, `correlationId` | Distributed tracing identifiers |
| `statusCode`, `status`, `code` | HTTP or application error codes |

## Triage Summary Format

After parsing, produce:

```
TRIAGE:
  Error: [exception type]: [message]
  Location: [file]:[line] in [function]
  Suspected cause: [one sentence]
  Confidence: high | medium | low
  Next step: [specific action]
```

If the stack trace lacks file paths or line numbers, ask for symbols or a fuller trace before proceeding.
