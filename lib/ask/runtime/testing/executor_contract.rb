# frozen_string_literal: true

module Ask
  module Runtime
    module Testing
      # Minitest assertions for checking a ToolExecutor implementation.
      #
      # Include this module in an adapter test class and call
      # +assert_conforms_to_runtime_contract+ with representative calls:
      #
      #   include Ask::Runtime::Testing::ExecutorContract
      #
      #   assert_conforms_to_runtime_contract(
      #     executor,
      #     success_call: success_call,
      #     failure_call: failure_call,
      #     cancelled_call: cancelled_call,
      #     context_factory: ->(event_sink:) { build_context(event_sink:) }
      #   )
      #
      # The adapter remains responsible for backend-specific tests; this
      # helper checks the shared result, cancellation, event, and correlation
      # contract that every runtime executor must provide.
      module ExecutorContract
        def assert_conforms_to_runtime_contract(executor, success_call:, failure_call:,
                                                cancelled_call:, context_factory:)
          assert_respond_to executor, :execute

          success_sink = Ask::Runtime::EventSink.new
          success_events = []
          observe_events(success_sink, success_events)
          success_context = context_factory.call(event_sink: success_sink)
          success_result = executor.execute(success_call, context: success_context)

          assert_instance_of Ask::Runtime::ToolResult, success_result
          assert_predicate success_result, :success?
          refute_nil success_result.duration
          assert_operator success_result.duration, :>=, 0
          assert_equal %i[tool_started tool_completed], success_events.map(&:first)

          terminal_event = success_events.last.last
          assert_equal success_call.id, terminal_event.tool_call_id
          assert_equal success_call.session_id, terminal_event.tool_call.session_id
          assert_equal :completed, terminal_event.tool_call.state

          failure_sink = Ask::Runtime::EventSink.new
          failure_events = []
          observe_events(failure_sink, failure_events)
          failure_result = executor.execute(
            failure_call, context: context_factory.call(event_sink: failure_sink)
          )
          assert_instance_of Ask::Runtime::ToolResult, failure_result
          assert_predicate failure_result, :failure?
          assert_equal %i[tool_started tool_failed], failure_events.map(&:first)

          canceller = Ask::Runtime::Canceller.new
          canceller.cancel
          cancellation_sink = Ask::Runtime::EventSink.new
          cancellation_events = []
          observe_events(cancellation_sink, cancellation_events)
          cancellation_context = context_factory.call(event_sink: cancellation_sink, canceller: canceller)
          cancelled_result = executor.execute(
            cancelled_call,
            context: cancellation_context
          )
          assert_instance_of Ask::Runtime::ToolResult, cancelled_result
          assert_predicate cancelled_result, :cancelled?
          assert_equal %i[tool_started tool_cancelled], cancellation_events.map(&:first)
        end

        private

        def observe_events(sink, events)
          %i[tool_started tool_completed tool_failed tool_cancelled tool_timed_out].each do |type|
            sink.on(type) { |payload| events << [type, payload[:event]] }
          end
        end

      end
    end
  end
end
