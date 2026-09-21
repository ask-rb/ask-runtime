# frozen_string_literal: true

require_relative "../tool_call"
require_relative "../execution_context"

module Ask
  module Runtime
    module Events
      # Immutable event emitted when a tool call begins execution.
      #
      # Carries a snapshot of the ToolCall (in :pending or :running state)
      # and the ExecutionContext for the execution. No ToolResult is present
      # since the tool has not yet completed.
      #
      #   event = ToolStarted.new(
      #     tool_call: call, execution_context: ctx, timestamp: Time.now
      #   )
      #   event.tool_call_id  #=> "tc_abc123"
      #   event.tool_name     #=> "search"
      #
      class ToolStarted
        attr_reader :tool_call, :execution_context, :timestamp

        def initialize(tool_call:, execution_context:, timestamp:)
          raise ArgumentError, "tool_call required" unless tool_call.is_a?(Ask::Runtime::ToolCall)
          raise ArgumentError, "execution_context required" unless execution_context.is_a?(Ask::Runtime::ExecutionContext)
          raise ArgumentError, "timestamp required" unless timestamp.is_a?(Time)

          @tool_call = tool_call
          @execution_context = execution_context
          @timestamp = timestamp
          freeze
        end

        def tool_call_id = @tool_call.id
        def tool_name = @tool_call.tool_name

        def to_h
          {
            tool_call: @tool_call,
            execution_context: @execution_context,
            timestamp: @timestamp,
            tool_call_id: tool_call_id,
            tool_name: tool_name
          }
        end

        def inspect
          "#<ToolStarted tool=#{tool_name.inspect} id=#{tool_call_id.inspect}>"
        end
      end
    end
  end
end
