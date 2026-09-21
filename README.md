# Ask::Runtime

Tool-call execution kernel for the [ask-rb](https://github.com/ask-rb) ecosystem.

## Installation

```ruby
gem "ask-runtime"
```

## Overview

Ask::Runtime provides the foundational value objects and adapter contracts for tool-call execution in ask-rb. It defines the stable public kernel that higher-level gems (ask-agent, ask-session) build on.

### Core Types

- **`ToolCall`** — immutable value object for a tool-call request: identity, tool name, input, session/turn correlation, and lifecycle state (`:pending`, `:running`, `:completed`, `:cancelled`, `:timed_out`).
- **`ToolResult`** — normalized execution result wrapping `Ask::Result` with `success?`, `failure?`, `cancelled?`, and `timeout?` predicates.
- **`ExecutionContext`** — immutable context for tool execution: optional session, turn, caller, workspace, capabilities, cancellation token, event sink, artifact store, and metadata.
- **`ToolExecutor`** — adapter contract (duck-type interface) for pluggable tool execution backends.

### Runtime Events

Immutable event value objects emitted through an `EventSink` during tool execution:

| Event | When | Key Fields |
|-------|------|------------|
| `ToolStarted` | Tool begins execution | `tool_call`, `execution_context`, `timestamp` |
| `ToolCompleted` | Tool finishes successfully | `tool_call`, `tool_result`, `execution_context`, `timestamp`, `duration` |
| `ToolFailed` | Tool errors | `tool_call`, `tool_result`, `execution_context`, `timestamp`, `duration` |
| `ToolCancelled` | Cooperative cancellation | `tool_call`, `tool_result`, `execution_context`, `timestamp`, `duration` |
| `ToolTimedOut` | Execution time exceeded | `tool_call`, `tool_result`, `execution_context`, `timestamp`, `duration` |

### EventSink

Thread-safe pub/sub emitter for lifecycle notifications:

```ruby
sink = Ask::Runtime::EventSink.new

# Listen for events
sink.on(:tool_started) { |payload| puts payload[:event].tool_name }
sink.on(:tool_completed) { |payload| puts payload[:event].duration }

# Emit events (typically done by executors)
sink.emit(:tool_started, event: Ask::Runtime::Events::ToolStarted.new(...))
```

#### NullSink

When no observation is needed, use a `NullSink` to avoid allocations and output:

```ruby
sink = Ask::Runtime::EventSink.null
sink.emit(:anything)  # no-op
```

## Example

```ruby
require "ask-runtime"

call = Ask::Runtime::ToolCall.new(
  id: "tc_abc123",
  tool_name: "search",
  input: { query: "ruby concurrency" },
  session_id: "s_001",
  turn: 3
)

result = Ask::Runtime::ToolResult.success(data: "results here")
context = Ask::Runtime::ExecutionContext.new(session_id: "s_001", turn: 3)

executor = MyToolExecutor.new
result = executor.execute(call, context: context)
```

### Observing Tool Execution

```ruby
sink = Ask::Runtime::EventSink.new

# Subscribe to terminal events
sink.on(:tool_completed) do |payload|
  event = payload[:event]
  puts "#{event.tool_name} completed in #{event.duration}s"
  puts "Result: #{event.tool_result.output}"
end

sink.on(:tool_failed) do |payload|
  event = payload[:event]
  puts "#{event.tool_name} failed: #{event.error}"
end

# Wire into an executor
context = Ask::Runtime::ExecutionContext.new(
  session_id: "s_001",
  turn: 1,
  event_sink: sink
)
```

### Integration with ask-instrumentation

If you use [ask-instrumentation](https://github.com/ask-rb/ask-instrumentation),
you can bridge runtime events to `ActiveSupport::Notifications`:

```ruby
require "ask/instrumentation"
require "ask/instrumentation/runtime_adapter"

sink = Ask::Instrumentation.install_runtime_sink

# All tool lifecycle events are now forwarded as Ask::Instrumentation events:
#   tool.started.ask, tool.completed.ask, tool.failed.ask,
#   tool.cancelled.ask, tool.timed_out.ask

context = Ask::Runtime::ExecutionContext.new(
  session_id: "s_001", turn: 1, event_sink: sink
)
```

See the [ask-instrumentation README](https://github.com/ask-rb/ask-instrumentation#runtime-adapter)
for the full payload schema and event mapping.

## Testing an executor

Adapter gems can reuse the runtime contract assertions instead of defining
their own compatibility checklist:

```ruby
require "ask/runtime/testing"

class MyExecutorTest < Minitest::Test
  include Ask::Runtime::Testing::ExecutorContract

  def test_executor_contract
    assert_conforms_to_runtime_contract(
      MyExecutor.new,
      success_call: build_success_call,
      failure_call: build_failure_call,
      cancelled_call: build_cancelled_call,
      context_factory: ->(event_sink:, canceller: nil) {
        Ask::Runtime::ExecutionContext.new(
          event_sink: event_sink, canceller: canceller
        )
      }
    )
  end
end
```

The helper checks the shared `ToolResult` shape, non-negative duration,
pre-execution cancellation, lifecycle event ordering, terminal state, and
call correlation. Backend-specific behavior should remain covered by the
adapter's own tests.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-feature`)
3. Commit your changes (`git commit -am 'Add feature'`)
4. Push to the branch (`git push origin my-feature`)
5. Create a Pull Request

## License

MIT License. See [LICENSE](LICENSE) for details.
