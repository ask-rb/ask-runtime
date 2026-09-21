# frozen_string_literal: true

module Ask
  module Runtime
    # Simple event sink contract for tool execution lifecycle notifications.
    #
    # Adapters and executors may emit events through the sink so that
    # higher-level systems (logging, observability, UI) can observe execution
    # without coupling to specific implementations.
    #
    # This is the base contract. Subclass and override +emit+ for concrete
    # behavior, or use a lambda/proc as a minimal sink.
    #
    #   sink = Ask::Runtime::EventSink.new
    #   sink.on(:tool_execution_start) { |event| puts event }
    #   sink.emit(:tool_execution_start, name: "search", id: "tc_1")
    #
    class EventSink
      # A sink that discards all events. Use when no observation is needed
      # but the executor requires a non-nil sink.
      #
      #   sink = Ask::Runtime::EventSink.null
      #   sink.emit(:anything)  # no-op, no allocation, no output
      #
      class NullSink
        def on(_event_type, &_block)
          self
        end

        def emit(_event_type, **_payload)
          self
        end

        def listening?(_event_type)
          false
        end

        def inspect
          "#<Ask::Runtime::EventSink::NullSink>"
        end
      end

      # Return a NullSink that discards all events.
      #
      # @return [NullSink]
      def self.null
        NullSink.new
      end

      def initialize
        @listeners = Hash.new { |h, k| h[k] = [] }
        @mutex = Mutex.new
      end

      # Register a listener for a specific event type.
      #
      # @param event_type [Symbol] the event name (e.g. +:tool_execution_start+)
      # @yield [payload] block to invoke when the event fires
      # @return [self]
      def on(event_type, &block)
        raise ArgumentError, "block required" unless block

        @mutex.synchronize { @listeners[event_type] << block }
        self
      end

      # Emit an event, notifying all registered listeners for that type.
      #
      # Listeners are never invoked while the internal mutex is held: the
      # listener list is snapshotted under the lock and each listener is
      # invoked after the lock is released.
      #
      # @param event_type [Symbol] the event name
      # @param payload [Hash] arbitrary event data
      # @return [self]
      def emit(event_type, **payload)
        listeners_to_run = @mutex.synchronize do
          @listeners[event_type].dup
        end
        listeners_to_run.each { |cb| cb.call(payload) }
        self
      end

      # @return [Boolean] true if any listeners are registered for +event_type+
      def listening?(event_type)
        @mutex.synchronize { @listeners[event_type].any? }
      end

      def inspect
        "#<Ask::Runtime::EventSink listeners=#{@mutex.synchronize { @listeners.keys }}>"
      end
    end
  end
end
