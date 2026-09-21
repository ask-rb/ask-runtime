# frozen_string_literal: true

require_relative "test_helper"
require "ask/runtime/testing"

class TestingExecutorContractTest < Minitest::Test
  include Ask::Runtime::Testing::ExecutorContract

  class ConformingExecutor
    include Ask::Runtime::ToolExecutor

    def execute(tool_call, context: nil)
      context ||= Ask::Runtime::ExecutionContext.new
      started = tool_call.with(state: :running, started_at: Time.now)
      context.event_sink.emit(
        :tool_started,
        event: Ask::Runtime::Events::ToolStarted.new(
          tool_call: started, execution_context: context, timestamp: Time.now
        )
      )

      result = case tool_call.input[:outcome]
      when :failure
        Ask::Runtime::ToolResult.failure("failed")
      when :cancelled
        Ask::Runtime::ToolResult.cancelled("cancelled")
      else
        Ask::Runtime::ToolResult.success(data: "ok")
      end
      duration = Time.now - started.started_at
      result = Ask::Runtime::ToolResult.new(
        result: result.result, outcome: result.outcome, duration: duration
      )
      state = result.success? ? :completed : result.cancelled? ? :cancelled : :failed
      finished = Time.now
      terminal = started.with(state: state, tool_result: result, finished_at: finished)
      event_class = state == :completed ? Ask::Runtime::Events::ToolCompleted :
        state == :cancelled ? Ask::Runtime::Events::ToolCancelled : Ask::Runtime::Events::ToolFailed
      context.event_sink.emit(
        "tool_#{state}".to_sym,
        event: event_class.new(
          tool_call: terminal, tool_result: result, execution_context: context,
          timestamp: finished, duration: finished - started.started_at
        )
      )
      result
    end
  end

  def test_contract_accepts_conforming_executor
    executor = ConformingExecutor.new
    context_factory = ->(event_sink:, canceller: nil) do
      Ask::Runtime::ExecutionContext.new(event_sink: event_sink, canceller: canceller)
    end

    assert_conforms_to_runtime_contract(
      executor,
      success_call: tool_call(outcome: :success),
      failure_call: tool_call(outcome: :failure),
      cancelled_call: tool_call(outcome: :cancelled),
      context_factory: context_factory
    )
  end

  private

  def tool_call(outcome:)
    Ask::Runtime::ToolCall.new(
      id: "tc_#{outcome}", tool_name: "contract", input: { outcome: outcome },
      session_id: "s_1", turn: 1
    )
  end
end
