# frozen_string_literal: true

require_relative "events/tool_started"
require_relative "events/tool_completed"
require_relative "events/tool_failed"
require_relative "events/tool_cancelled"
require_relative "events/tool_timed_out"

module Ask
  module Runtime
    # Immutable event value objects for tool-call lifecycle notifications.
    #
    # Each event is a frozen +Data.define+ instance carrying a snapshot of
    # the ToolCall, ToolResult (when terminal), ExecutionContext, timestamp,
    # and duration (when terminal).
    #
    # Events are emitted through an +EventSink+ and can be observed by
    # listeners without coupling to the executor implementation.
    #
    # @see EventSink
    # @see ToolCall
    # @see ToolResult
    module Events
      # @!method tool_call
      #   @return [ToolCall] snapshot of the tool call at the time of the event

      # @!method execution_context
      #   @return [ExecutionContext] the execution context for this tool call

      # @!method timestamp
      #   @return [Time] wall-clock time when the event was created
    end
  end
end
