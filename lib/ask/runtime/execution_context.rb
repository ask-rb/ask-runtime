# frozen_string_literal: true

require_relative "canceller"
require_relative "event_sink"

module Ask
  module Runtime
    # Immutable context for tool execution.
    #
    # ExecutionContext bundles everything a tool executor needs beyond the
    # ToolCall itself: session/turn correlation, caller identity, workspace,
    # capabilities, cancellation support, event emission, artifact storage,
    # and arbitrary metadata.
    #
    # All attributes are set at construction time and frozen.
    #
    #   ctx = Ask::Runtime::ExecutionContext.new(
    #     session_id: "s_001",
    #     turn: 3,
    #     caller_id: "agent_main",
    #     workspace: "/tmp/work",
    #     capabilities: [:file_read, :file_write]
    #   )
    #
    class ExecutionContext
      # @return [String, nil] session identifier
      attr_reader :session_id

      # @return [Integer, nil] current turn number
      attr_reader :turn

      # @return [String, nil] caller identifier
      attr_reader :caller_id

      # @return [String, nil] workspace root directory
      attr_reader :workspace

      # @return [Array<Symbol>] capability symbols this execution may use
      attr_reader :capabilities

      # @return [Canceller] cooperative cancellation token
      attr_reader :canceller

      # @return [EventSink] event emitter for lifecycle notifications
      attr_reader :event_sink

      # @return [Hash] artifact store (tool_name => artifact data)
      attr_reader :artifact_store

      # @return [Hash] arbitrary metadata
      attr_reader :metadata

      # @return [Time] when this context was created
      attr_reader :created_at

      def initialize(session_id: nil, turn: nil, caller_id: nil,
                     workspace: nil, capabilities: [],
                     canceller: nil, event_sink: nil,
                     artifact_store: nil, metadata: {},
                     created_at: Time.now)
        @session_id = session_id
        @turn = turn
        @caller_id = caller_id
        @workspace = workspace
        @capabilities = Array(capabilities).freeze
        @canceller = canceller || Canceller.new
        @event_sink = event_sink || EventSink.new
        @artifact_store = artifact_store ? artifact_store.dup.freeze : {}.freeze
        @metadata = metadata.dup.freeze
        @created_at = created_at
        freeze
      end

      # @return [Boolean] whether this context is correlated to a session
      def session?
        !@session_id.nil?
      end

      # @return [Boolean] whether a specific capability is available
      def has_capability?(cap)
        @capabilities.include?(cap)
      end

      # @return [Boolean] whether the execution has been cancelled
      def cancelled?
        @canceller.cancelled?
      end

      # Return a new ExecutionContext with the given attributes replaced.
      #
      # @param attrs [Hash] attributes to override
      # @return [ExecutionContext] a new frozen instance
      def with(**attrs)
        self.class.new(**to_h.merge(attrs))
      end

      # @return [Hash] serializable representation
      def to_h
        {
          session_id: @session_id,
          turn: @turn,
          caller_id: @caller_id,
          workspace: @workspace,
          capabilities: @capabilities,
          canceller: @canceller,
          event_sink: @event_sink,
          artifact_store: @artifact_store,
          metadata: @metadata,
          created_at: @created_at
        }
      end

      def inspect
        "#<Ask::Runtime::ExecutionContext session=#{@session_id.inspect} turn=#{@turn.inspect} caller=#{@caller_id.inspect}>"
      end
    end
  end
end
