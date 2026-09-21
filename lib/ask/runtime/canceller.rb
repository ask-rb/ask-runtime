# frozen_string_literal: true

module Ask
  module Runtime
    # Cooperative cancellation token for tool execution.
    #
    # A {Canceller} starts in an uncancelled state and can be cancelled at any
    # time. Tools receive the canceller via {ExecutionContext} and may check
    # +cancelled?+ periodically during long-running work to abort early.
    #
    #   canceller = Ask::Runtime::Canceller.new
    #   canceller.on_cancel { puts "cancelled!" }
    #   canceller.cancel
    #   canceller.cancelled? # => true
    #
    class Canceller
      def initialize
        @cancelled = false
        @mutex = Mutex.new
        @callbacks = []
      end

      # @return [Boolean] true if +cancel+ has been called
      def cancelled?
        @mutex.synchronize { @cancelled }
      end

      # Request cooperative cancellation. Fires registered callbacks exactly once.
      #
      # Callbacks are never invoked while the internal mutex is held: the
      # callback list is snapshotted under the lock and each callback is
      # invoked after the lock is released.
      #
      # @return [self]
      def cancel
        callbacks_to_run = @mutex.synchronize do
          return self if @cancelled

          @cancelled = true
          snapshot = @callbacks.dup
          @callbacks.clear
          snapshot
        end
        callbacks_to_run.each(&:call)
        self
      end

      # Register a callback to be invoked when cancellation is requested.
      # If already cancelled, the callback fires immediately (outside the
      # internal mutex) to preserve immediate already-cancelled semantics
      # while never invoking user code under the lock.
      #
      # @yield [] block to run on cancellation
      # @return [self]
      def on_cancel(&block)
        raise ArgumentError, "block required" unless block

        immediate = @mutex.synchronize do
          if @cancelled
            block
          else
            @callbacks << block
            nil
          end
        end
        immediate&.call
        self
      end

      def inspect
        "#<Ask::Runtime::Canceller cancelled=#{cancelled?}>"
      end
    end
  end
end
