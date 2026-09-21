# frozen_string_literal: true

require_relative "runtime/version"
require_relative "runtime/tool_call"
require_relative "runtime/tool_result"
require_relative "runtime/execution_context"
require_relative "runtime/event_sink"
require_relative "runtime/events"
require_relative "runtime/tool_executor"

module Ask
  # The runtime execution kernel for ask-rb tool calls.
  #
  # Provides value objects (ToolCall, ToolResult, ExecutionContext) and
  # the ToolExecutor adapter contract for pluggable tool execution.
  #
  # This gem does not depend on any LLM provider code. It defines the
  # stable public kernel that higher-level gems build on.
  module Runtime
  end
end
