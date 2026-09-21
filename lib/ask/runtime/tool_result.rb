# frozen_string_literal: true

require "ask"

module Ask
  module Runtime
    # Normalized result of tool execution.
    #
    # ToolResult wraps +Ask::Result+ and adds lifecycle-specific predicates
    # for cancelled and timed-out states that are not part of the core result
    # vocabulary but are natural outcomes of the runtime execution model.
    #
    # Factory methods produce canonical results:
    #
    #   Ask::Runtime::ToolResult.success(data: { "count" => 42 })
    #   Ask::Runtime::ToolResult.failure("file not found")
    #   Ask::Runtime::ToolResult.cancelled("user aborted")
    #   Ask::Runtime::ToolResult.timeout("exceeded 30s limit")
    #
    class ToolResult
      # @return [Ask::Result] the underlying core result
      attr_reader :result

      # @return [Symbol] normalized outcome (:success, :failure, :cancelled, :timeout)
      attr_reader :outcome

      # @return [Float, nil] execution duration in seconds
      attr_reader :duration

      def initialize(result:, outcome:, duration: nil)
        @result = result
        @outcome = outcome
        @duration = duration
        freeze
      end

      class << self
        # Create a successful tool result.
        #
        # @param data [Object] the tool's output payload
        # @param duration [Float, nil] execution time in seconds
        # @param metadata [Hash] additional metadata
        # @return [ToolResult]
        def success(data: nil, duration: nil, metadata: {})
          result = Ask::Result.ok(data: data, metadata: metadata)
          new(result: result, outcome: :success, duration: duration)
        end

        # Create a failed tool result.
        #
        # @param message [String] error description
        # @param duration [Float, nil] execution time in seconds
        # @param metadata [Hash] additional metadata
        # @return [ToolResult]
        def failure(message, duration: nil, metadata: {})
          result = Ask::Result.error(message: message, metadata: metadata)
          new(result: result, outcome: :failure, duration: duration)
        end

        # Create a cancelled tool result (cooperative cancellation).
        #
        # @param reason [String] why execution was cancelled
        # @param duration [Float, nil] execution time before cancellation
        # @return [ToolResult]
        def cancelled(reason = "Cancelled", duration: nil)
          result = Ask::Result.failure(reason)
          new(result: result, outcome: :cancelled, duration: duration)
        end

        # Create a timed-out tool result.
        #
        # @param message [String] timeout description
        # @param duration [Float, nil] elapsed time before timeout
        # @return [ToolResult]
        def timeout(message = "Execution timed out", duration: nil)
          result = Ask::Result.failure(message)
          new(result: result, outcome: :timeout, duration: duration)
        end
      end

      # @!group Predicates

      # @return [Boolean]
      def success? = @outcome == :success

      # @return [Boolean]
      def failure? = @outcome == :failure

      # @return [Boolean]
      def cancelled? = @outcome == :cancelled

      # @return [Boolean]
      def timeout? = @outcome == :timeout

      # @!endgroup

      # @return [Object, nil] the output data when successful
      def output = @result.output

      # @return [Object, nil] the error message or object
      def error_message = @result.error_message

      # @return [Hash] serializable representation
      def to_h
        {
          outcome: @outcome,
          output: output,
          error: error_message,
          duration: @duration,
          result: @result.to_h
        }
      end

      def inspect
        if success?
          "#<Ask::Runtime::ToolResult outcome=success output=#{output.inspect}>"
        else
          "#<Ask::Runtime::ToolResult outcome=#{@outcome.inspect} error=#{error_message.inspect}>"
        end
      end
    end
  end
end
