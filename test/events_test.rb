# frozen_string_literal: true

require_relative "test_helper"

class EventStartedTest < Minitest::Test
  include TestHelpers

  def test_tool_started_immutability
    call = build_tool_call
    ctx = build_context
    ts = Time.now
    event = Ask::Runtime::Events::ToolStarted.new(tool_call: call, execution_context: ctx, timestamp: ts)

    assert_equal call, event.tool_call
    assert_equal ctx, event.execution_context
    assert_equal ts, event.timestamp
    assert_equal "search", event.tool_name
    assert_equal call.id, event.tool_call_id
  end

  def test_tool_started_raises_without_tool_call
    ctx = build_context
    assert_raises(ArgumentError) do
      Ask::Runtime::Events::ToolStarted.new(tool_call: nil, execution_context: ctx, timestamp: Time.now)
    end
  end

  def test_tool_started_raises_without_execution_context
    call = build_tool_call
    assert_raises(ArgumentError) do
      Ask::Runtime::Events::ToolStarted.new(tool_call: call, execution_context: nil, timestamp: Time.now)
    end
  end

  def test_tool_started_raises_without_timestamp
    call = build_tool_call
    ctx = build_context
    assert_raises(ArgumentError) do
      Ask::Runtime::Events::ToolStarted.new(tool_call: call, execution_context: ctx, timestamp: nil)
    end
  end

  def test_tool_started_is_frozen
    event = Ask::Runtime::Events::ToolStarted.new(
      tool_call: build_tool_call, execution_context: build_context, timestamp: Time.now
    )
    assert event.frozen?
  end

  def test_tool_started_to_h
    call = build_tool_call
    ctx = build_context
    ts = Time.now
    event = Ask::Runtime::Events::ToolStarted.new(tool_call: call, execution_context: ctx, timestamp: ts)

    h = event.to_h
    assert_equal call, h[:tool_call]
    assert_equal ctx, h[:execution_context]
    assert_equal ts, h[:timestamp]
    assert_equal "search", h[:tool_name]
  end

  def test_tool_started_inspect
    event = Ask::Runtime::Events::ToolStarted.new(
      tool_call: build_tool_call, execution_context: build_context, timestamp: Time.now
    )
    assert_match(/ToolStarted/, event.inspect)
    assert_match(/search/, event.inspect)
  end
end

class EventCompletedTest < Minitest::Test
  include TestHelpers

  def test_tool_completed_fields
    call = build_tool_call
    ctx = build_context
    result = Ask::Runtime::ToolResult.success(data: "done")
    ts = Time.now
    event = Ask::Runtime::Events::ToolCompleted.new(
      tool_call: call, tool_result: result, execution_context: ctx, timestamp: ts, duration: 1.5
    )

    assert_equal call, event.tool_call
    assert_equal result, event.tool_result
    assert_equal ctx, event.execution_context
    assert_equal ts, event.timestamp
    assert_equal 1.5, event.duration
    assert event.success?
  end

  def test_tool_completed_raises_without_tool_result
    call = build_tool_call
    ctx = build_context
    assert_raises(ArgumentError) do
      Ask::Runtime::Events::ToolCompleted.new(
        tool_call: call, tool_result: nil, execution_context: ctx, timestamp: Time.now, duration: 1.0
      )
    end
  end

  def test_tool_completed_is_frozen
    event = Ask::Runtime::Events::ToolCompleted.new(
      tool_call: build_tool_call, tool_result: Ask::Runtime::ToolResult.success,
      execution_context: build_context, timestamp: Time.now, duration: 0.1
    )
    assert event.frozen?
  end
end

class EventFailedTest < Minitest::Test
  include TestHelpers

  def test_tool_failed_fields
    call = build_tool_call
    ctx = build_context
    result = Ask::Runtime::ToolResult.failure("not found")
    ts = Time.now
    event = Ask::Runtime::Events::ToolFailed.new(
      tool_call: call, tool_result: result, execution_context: ctx, timestamp: ts, duration: 0.3
    )

    assert_equal call, event.tool_call
    assert_equal result, event.tool_result
    assert_equal ctx, event.execution_context
    assert event.failed?
    assert_equal "not found", event.error
    assert_equal 0.3, event.duration
  end

  def test_tool_failed_is_frozen
    event = Ask::Runtime::Events::ToolFailed.new(
      tool_call: build_tool_call, tool_result: Ask::Runtime::ToolResult.failure("err"),
      execution_context: build_context, timestamp: Time.now, duration: 0.0
    )
    assert event.frozen?
  end
end

class EventCancelledTest < Minitest::Test
  include TestHelpers

  def test_tool_cancelled_fields
    call = build_tool_call
    ctx = build_context
    result = Ask::Runtime::ToolResult.cancelled("aborted")
    ts = Time.now
    event = Ask::Runtime::Events::ToolCancelled.new(
      tool_call: call, tool_result: result, execution_context: ctx, timestamp: ts, duration: 0.8
    )

    assert_equal call, event.tool_call
    assert_equal result, event.tool_result
    assert event.cancelled?
    assert_equal "aborted", event.reason
    assert_equal 0.8, event.duration
  end

  def test_tool_cancelled_is_frozen
    event = Ask::Runtime::Events::ToolCancelled.new(
      tool_call: build_tool_call, tool_result: Ask::Runtime::ToolResult.cancelled,
      execution_context: build_context, timestamp: Time.now, duration: nil
    )
    assert event.frozen?
  end
end

class EventTimedOutTest < Minitest::Test
  include TestHelpers

  def test_tool_timed_out_fields
    call = build_tool_call
    ctx = build_context
    result = Ask::Runtime::ToolResult.timeout("exceeded 30s")
    ts = Time.now
    event = Ask::Runtime::Events::ToolTimedOut.new(
      tool_call: call, tool_result: result, execution_context: ctx, timestamp: ts, duration: 30.0
    )

    assert_equal call, event.tool_call
    assert_equal result, event.tool_result
    assert event.timed_out?
    assert_equal 30.0, event.duration
  end

  def test_tool_timed_out_is_frozen
    event = Ask::Runtime::Events::ToolTimedOut.new(
      tool_call: build_tool_call, tool_result: Ask::Runtime::ToolResult.timeout,
      execution_context: build_context, timestamp: Time.now, duration: nil
    )
    assert event.frozen?
  end
end

class NullSinkTest < Minitest::Test
  def test_null_sink_emitting_does_not_raise
    sink = Ask::Runtime::EventSink.null
    sink.emit(:anything, key: "value")
  end

  def test_null_sink_on_does_not_raise
    sink = Ask::Runtime::EventSink.null
    sink.on(:anything) { raise "should not be called" }
  end

  def test_null_sink_listening_returns_false
    sink = Ask::Runtime::EventSink.null
    refute sink.listening?(:anything)
  end

  def test_null_sink_returns_self
    sink = Ask::Runtime::EventSink.null
    assert_same sink, sink.on(:ev) { }
    assert_same sink, sink.emit(:ev)
  end

  def test_null_sink_inspect
    sink = Ask::Runtime::EventSink.null
    assert_match(/NullSink/, sink.inspect)
  end

  def test_null_sink_is_not_the_same_as_regular_sink
    sink = Ask::Runtime::EventSink.new
    refute sink.is_a?(Ask::Runtime::EventSink::NullSink)
  end
end

class EventOrderingTest < Minitest::Test
  def test_events_emit_in_order
    sink = Ask::Runtime::EventSink.new
    received = []

    sink.on(:tool_started) { |e| received << [:started, e[:id]] }
    sink.on(:tool_completed) { |e| received << [:completed, e[:id]] }

    sink.emit(:tool_started, id: "tc_1")
    sink.emit(:tool_completed, id: "tc_1")

    assert_equal [[:started, "tc_1"], [:completed, "tc_1"]], received
  end

  def test_parallel_emits_are_independent
    sink = Ask::Runtime::EventSink.new
    received = Queue.new
    mutex = Mutex.new

    sink.on(:ev) { |e| mutex.synchronize { received << e[:val] } }

    t1 = Thread.new { 10.times { |i| sink.emit(:ev, val: "a#{i}") } }
    t2 = Thread.new { 10.times { |i| sink.emit(:ev, val: "b#{i}") } }
    t1.join
    t2.join

    assert_equal 20, received.size
  end
end
