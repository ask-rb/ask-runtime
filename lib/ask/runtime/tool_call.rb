# frozen_string_literal: true

require "securerandom"
require_relative "canceller"
require_relative "event_sink"

module Ask
  module Runtime
    # Immutable value object representing a single tool-call request.
    #
    # A ToolCall is created by the LLM (or a caller) to invoke a named tool
    # with structured input. It carries identity, correlation data, and
    # lifecycle state that progresses through:
    #
    #   :pending → :running → :completed | :failed | :cancelled | :timed_out
    #
    # ToolCall instances are frozen after initialization.
    #
    #   call = Ask::Runtime::ToolCall.new(
    #     id: "tc_abc",
    #     tool_name: "search",
    #     input: { query: "ruby" },
    #     session_id: "s_001",
    #     turn: 2
    #   )
    #   call.pending? # => true
    #
    class ToolCall
      STATES = %i[pending running completed failed cancelled timed_out].freeze

      # @return [String] unique identifier for this tool call
      attr_reader :id

      # @return [String] name of the tool to execute
      attr_reader :tool_name

      # @return [Hash] the tool's input parameters
      attr_reader :input

      # @return [String, nil] session identifier for correlation
      attr_reader :session_id

      # @return [Integer, nil] turn number within the session
      attr_reader :turn

      # @return [Symbol] lifecycle state (:pending, :running, :completed,
      #   :cancelled, :timed_out)
      attr_reader :state

      # @return [String, nil] caller identifier (e.g. agent name or user id)
      attr_reader :caller_id

      # @return [String, nil] error message when state is :failed
      attr_reader :error

      # @return [ToolResult, nil] the normalized execution result, set on
      #   terminal states (:completed, :failed, :cancelled, :timed_out)
      attr_reader :tool_result

      # @return [Hash] arbitrary metadata
      attr_reader :metadata

      # @return [Time] when this tool call was created
      attr_reader :created_at

      # @return [Time, nil] when execution started
      attr_reader :started_at

      # @return [Time, nil] when execution finished
      attr_reader :finished_at

      def initialize(id: nil, tool_name:, input: {}, session_id: nil,
                     turn: nil, state: :pending, caller_id: nil,
                     error: nil, tool_result: nil,
                     metadata: {}, created_at: Time.now, started_at: nil,
                     finished_at: nil)
        @id = id || "tc_#{SecureRandom.hex(8)}"
        @tool_name = tool_name.to_s
        @input = input.dup.freeze
        @session_id = session_id
        @turn = turn
        @state = validate_state!(state)
        @caller_id = caller_id
        @error = error
        @tool_result = tool_result
        @metadata = metadata.dup.freeze
        @created_at = created_at
        @started_at = started_at
        @finished_at = finished_at
        freeze
      end

      # @!group State Predicates

      # @return [Boolean]
      def pending? = @state == :pending

      # @return [Boolean]
      def running? = @state == :running

      # @return [Boolean]
      def completed? = @state == :completed

      # @return [Boolean]
      def failed? = @state == :failed

      # @return [Boolean]
      def cancelled? = @state == :cancelled

      # @return [Boolean]
      def timed_out? = @state == :timed_out

      # @!endgroup

      # Return a new ToolCall with the given attributes replaced.
      #
      # @param attrs [Hash] attributes to override
      # @return [ToolCall] a new frozen instance
      def with(**attrs)
        self.class.new(**to_h.merge(attrs))
      end

      # @return [Hash] representation suitable for Ruby serialization.
      #   Note: +created_at+, +started_at+, and +finished_at+ are +Time+
      #   objects and are NOT directly JSON-serializable.  Callers must
      #   convert them (e.g. +.iso8601+) before encoding to JSON.
      def to_h
        {
          id: @id,
          tool_name: @tool_name,
          input: @input,
          session_id: @session_id,
          turn: @turn,
          state: @state,
          caller_id: @caller_id,
          error: @error,
          tool_result: @tool_result&.to_h,
          metadata: @metadata,
          created_at: @created_at,
          started_at: @started_at,
          finished_at: @finished_at
        }
      end

      def inspect
        "#<Ask::Runtime::ToolCall id=#{@id.inspect} tool=#{@tool_name.inspect} state=#{@state.inspect}>"
      end

      def ==(other)
        other.is_a?(self.class) && @id == other.id
      end
      alias eql? ==

      def hash
        @id.hash
      end

      private

      def validate_state!(state)
        return state if STATES.include?(state)

        raise ArgumentError, "Invalid state #{state.inspect}. Valid: #{STATES.join(', ')}"
      end
    end
  end
end
