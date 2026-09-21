# frozen_string_literal: true

require_relative "test_helper"

class CancellerTest < Minitest::Test
  def test_starts_uncancelled
    c = Ask::Runtime::Canceller.new
    refute c.cancelled?
  end

  def test_cancel_sets_state
    c = Ask::Runtime::Canceller.new
    c.cancel
    assert c.cancelled?
  end

  def test_cancel_is_idempotent
    c = Ask::Runtime::Canceller.new
    c.cancel
    c.cancel
    assert c.cancelled?
  end

  def test_on_cancel_fires_callback
    c = Ask::Runtime::Canceller.new
    fired = false
    c.on_cancel { fired = true }
    c.cancel
    assert fired
  end

  def test_on_cancel_fires_immediately_if_already_cancelled
    c = Ask::Runtime::Canceller.new
    c.cancel
    fired = false
    c.on_cancel { fired = true }
    assert fired
  end

  def test_on_cancel_requires_block
    c = Ask::Runtime::Canceller.new
    assert_raises(ArgumentError) { c.on_cancel }
  end

  def test_inspect
    c = Ask::Runtime::Canceller.new
    assert_match(/cancelled=false/, c.inspect)
    c.cancel
    assert_match(/cancelled=true/, c.inspect)
  end

  def test_callbacks_not_invoked_while_mutex_held
    c = Ask::Runtime::Canceller.new
    mutex_ref = c.instance_variable_get(:@mutex)
    lock_held = nil

    c.on_cancel { lock_held = mutex_ref.locked? }
    c.cancel

    refute lock_held, "mutex must not be held during callback invocation"
  end

  def test_reentrant_callback_registration_during_cancel
    c = Ask::Runtime::Canceller.new
    second_called = false
    first_called = false

    c.on_cancel do
      first_called = true
      c.on_cancel { second_called = true }
    end

    c.cancel
    assert first_called
    assert second_called
  end

  def test_reentrant_cancel_from_callback_does_not_deadlock
    c = Ask::Runtime::Canceller.new
    c.on_cancel { c.cancel }
    c.cancel
    assert c.cancelled?
  end

  def test_concurrent_cancel_and_on_cancel
    c = Ask::Runtime::Canceller.new
    results = Queue.new

    threads = 10.times.map do |i|
      Thread.new do
        c.on_cancel { results << i }
        nil
      end
    end

    c.cancel
    threads.each(&:join)

    assert results.size >= 1, "at least one callback should fire"
  end
end

class EventSinkTest < Minitest::Test
  def test_emit_calls_listener
    sink = Ask::Runtime::EventSink.new
    received = nil
    sink.on(:test) { |e| received = e }
    sink.emit(:test, value: 42)
    assert_equal({ value: 42 }, received)
  end

  def test_emit_with_multiple_listeners
    sink = Ask::Runtime::EventSink.new
    calls = []
    sink.on(:ev) { calls << "a" }
    sink.on(:ev) { calls << "b" }
    sink.emit(:ev)
    assert_equal %w[a b], calls
  end

  def test_emit_different_types
    sink = Ask::Runtime::EventSink.new
    a_received = nil
    b_received = nil
    sink.on(:a) { |e| a_received = e }
    sink.on(:b) { |e| b_received = e }
    sink.emit(:a, x: 1)
    sink.emit(:b, y: 2)
    assert_equal({ x: 1 }, a_received)
    assert_equal({ y: 2 }, b_received)
  end

  def test_listening
    sink = Ask::Runtime::EventSink.new
    refute sink.listening?(:ev)
    sink.on(:ev) { }
    assert sink.listening?(:ev)
  end

  def test_on_requires_block
    sink = Ask::Runtime::EventSink.new
    assert_raises(ArgumentError) { sink.on(:ev) }
  end

  def test_emit_without_listeners_does_not_raise
    sink = Ask::Runtime::EventSink.new
    sink.emit(:nonexistent, data: "ok")
  end

  def test_inspect
    sink = Ask::Runtime::EventSink.new
    assert_match(/EventSink/, sink.inspect)
  end

  def test_listeners_not_invoked_while_mutex_held
    sink = Ask::Runtime::EventSink.new
    mutex_ref = sink.instance_variable_get(:@mutex)

    lock_held = nil
    sink.on(:test) { lock_held = mutex_ref.locked? }
    sink.emit(:test)

    refute lock_held, "mutex must not be held during listener invocation"
  end

  def test_emit_snapshots_listeners
    sink = Ask::Runtime::EventSink.new
    call_order = []

    sink.on(:event) do
      call_order << :first
      sink.on(:event) { call_order << :added_during_emit }
    end

    sink.emit(:event)
    assert_equal [:first], call_order

    sink.emit(:event)
    assert_equal [:first, :first, :added_during_emit], call_order
  end

  def test_reentrant_emit_does_not_deadlock
    sink = Ask::Runtime::EventSink.new
    depth = 0
    max_depth = 0

    sink.on(:nested) do
      depth += 1
      max_depth = [max_depth, depth].max
      sink.emit(:nested) if depth < 3
      depth -= 1
    end

    sink.emit(:nested)
    assert_equal 3, max_depth
  end

  def test_listener_registration_during_emit_is_safe
    sink = Ask::Runtime::EventSink.new
    order = []

    sink.on(:step) do
      order << :a
      sink.on(:step) { order << :b }
    end

    sink.emit(:step)
    assert_equal [:a], order

    sink.emit(:step)
    assert_equal [:a, :a, :b], order
  end
end
