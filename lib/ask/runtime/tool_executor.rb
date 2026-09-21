# frozen_string_literal: true

module Ask
  module Runtime
    # Adapter contract for tool execution backends.
    #
    # ToolExecutor is the duck-type interface that concrete adapters must
    # implement. It does not depend on any LLM or provider code — adapters
    # bridge between the runtime kernel and specific tool implementations.
    #
    # A minimal adapter:
    #
    #   class MyExecutor
    #     include Ask::Runtime::ToolExecutor
    #
    #     def execute(tool_call, context: nil)
    #       # run the tool, return Ask::Runtime::ToolResult
    #     end
    #   end
    #
    # Or implement the interface directly without including the module:
    #
    #   class MyExecutor
    #     def execute(tool_call, context: nil)
    #       # ...
    #     end
    #   end
    #
    module ToolExecutor
      # Execute a tool call within the given context.
      #
      # @param tool_call [ToolCall] the tool-call request to execute
      # @param context [ExecutionContext, nil] optional execution context
      # @return [ToolResult] the normalized execution result
      # @raise [NotImplementedError] if not overridden
      def execute(tool_call, context: nil)
        raise NotImplementedError,
          "#{self.class} must implement #execute(tool_call, context:)"
      end

      # Check whether this executor can handle a given tool name.
      #
      # @param tool_name [String, Symbol] the tool name to check
      # @return [Boolean] whether this executor handles the tool
      def handles?(tool_name)
        respond_to?(:supported_tools) &&
          supported_tools.include?(tool_name.to_s)
      end
    end
  end
end
