# frozen_string_literal: true

require_relative "test_helper"

class ExecutionContextTest < Minitest::Test
  include TestHelpers

  def test_creates_with_defaults
    ctx = Ask::Runtime::ExecutionContext.new
    assert_nil ctx.session_id
    assert_nil ctx.turn
    assert_nil ctx.caller_id
    assert_nil ctx.workspace
    assert_empty ctx.capabilities
    assert_kind_of Ask::Runtime::Canceller, ctx.canceller
    assert_kind_of Ask::Runtime::EventSink, ctx.event_sink
    assert_equal({}, ctx.artifact_store)
    assert_equal({}, ctx.metadata)
    assert_kind_of Time, ctx.created_at
  end

  def test_creates_with_values
    ctx = build_context(
      session_id: "s_99",
      turn: 5,
      caller_id: "agent_x",
      workspace: "/tmp/work",
      capabilities: [:read, :write]
    )
    assert_equal "s_99", ctx.session_id
    assert_equal 5, ctx.turn
    assert_equal "agent_x", ctx.caller_id
    assert_equal "/tmp/work", ctx.workspace
    assert_equal %i[read write], ctx.capabilities
  end

  def test_session_predicate
    ctx_with = build_context(session_id: "s_1")
    ctx_without = build_context(session_id: nil)
    assert ctx_with.session?
    refute ctx_without.session?
  end

  def test_has_capability
    ctx = build_context(capabilities: [:file_read, :file_write])
    assert ctx.has_capability?(:file_read)
    assert ctx.has_capability?(:file_write)
    refute ctx.has_capability?(:network)
  end

  def test_cancelled_delegates_to_canceller
    canceller = Ask::Runtime::Canceller.new
    ctx = build_context(canceller: canceller)
    refute ctx.cancelled?
    canceller.cancel
    assert ctx.cancelled?
  end

  def test_freezes_capabilities
    ctx = build_context(capabilities: [:a])
    assert ctx.capabilities.frozen?
  end

  def test_freezes_artifact_store
    ctx = build_context(artifact_store: { "tool" => "data" })
    assert ctx.artifact_store.frozen?
  end

  def test_freezes_metadata
    ctx = build_context(metadata: { key: "val" })
    assert ctx.metadata.frozen?
  end

  def test_immutable_after_creation
    ctx = build_context
    assert ctx.frozen?
  end

  def test_with_returns_new_instance
    original = build_context(session_id: "s_1")
    updated = original.with(session_id: "s_2")
    assert_equal "s_2", updated.session_id
    assert_equal "s_1", original.session_id
    refute_equal original.object_id, updated.object_id
  end

  def test_to_h
    ctx = build_context(session_id: "s_h", turn: 3)
    h = ctx.to_h
    assert_equal "s_h", h[:session_id]
    assert_equal 3, h[:turn]
  end

  def test_inspect
    ctx = build_context(session_id: "s_x", turn: 2, caller_id: "a")
    str = ctx.inspect
    assert_match(/s_x/, str)
    assert_match(/2/, str)
  end

  def test_default_canceller_is_independent
    ctx1 = build_context
    ctx2 = build_context
    ctx1.canceller.cancel
    refute ctx2.canceller.cancelled?
  end

  def test_default_event_sink_is_independent
    ctx1 = build_context
    ctx2 = build_context
    received = nil
    ctx1.event_sink.on(:test) { |e| received = e }
    ctx2.event_sink.emit(:test, value: 42)
    assert_nil received
  end
end
