# frozen_string_literal: true

require_relative "../tool_call"
require_relative "../tool_result"
require_relative "../execution_context"

module Ask
  module Runtime
    module Events
      # Immutable event emitted when a tool call exceeds its execution time
      # limit and is terminated.
      #
      # Carries the terminal ToolCall snapshot (state: :timed_out), the
      # ToolResult with outcome: :timeout, the ExecutionContext, a monotonic
      # timestamp, and the wall-clock duration in seconds.
      #
      #   event = ToolTimedOut.new(
      #     tool_call: finished_call, tool_result: result,
      #     execution_context: ctx, timestamp: Time.now, duration: 30.0
      #   )
      #   event.timed_out?  #=> true
      #   event.duration    #=> 30.0
      #
      class ToolTimedOut
        attr_reader :tool_call, :tool_result, :execution_context, :timestamp, :duration

        def initialize(tool_call:, tool_result:, execution_context:, timestamp:, duration:)
          raise ArgumentError, "tool_call required" unless tool_call.is_a?(Ask::Runtime::ToolCall)
          raise ArgumentError, "tool_result required" unless tool_result.is_a?(Ask::Runtime::ToolResult)
          raise ArgumentError, "execution_context required" unless execution_context.is_a?(Ask::Runtime::ExecutionContext)
          raise ArgumentError, "timestamp required" unless timestamp.is_a?(Time)

          @tool_call = tool_call
          @tool_result = tool_result
          @execution_context = execution_context
          @timestamp = timestamp
          @duration = duration
          freeze
        end

        def tool_call_id = @tool_call.id
        def tool_name = @tool_call.tool_name
        def timed_out? = @tool_result.timeout?

        def to_h
          {
            tool_call: @tool_call,
            tool_result: @tool_result,
            execution_context: @execution_context,
            timestamp: @timestamp,
            duration: @duration,
            tool_call_id: tool_call_id,
            tool_name: tool_name
          }
        end

        def inspect
          "#<ToolTimedOut tool=#{tool_name.inspect} id=#{tool_call_id.inspect} duration=#{@duration}>"
        end
      end
    end
  end
end
