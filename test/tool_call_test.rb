# frozen_string_literal: true

require_relative "test_helper"

class ToolCallTest < Minitest::Test
  include TestHelpers

  def test_creates_with_defaults
    call = build_tool_call
    assert_kind_of Ask::Runtime::ToolCall, call
    assert call.id.start_with?("tc_")
    assert_equal "search", call.tool_name
    assert_equal({ query: "test" }, call.input)
    assert_equal "s_001", call.session_id
    assert_equal 1, call.turn
    assert call.pending?
    assert_nil call.caller_id
    assert_kind_of Time, call.created_at
  end

  def test_generates_unique_ids
    c1 = build_tool_call
    c2 = build_tool_call
    refute_equal c1.id, c2.id
  end

  def test_accepts_explicit_id
    call = build_tool_call(id: "tc_explicit")
    assert_equal "tc_explicit", call.id
  end

  def test_default_state_is_pending
    call = build_tool_call
    assert call.pending?
    refute call.running?
    refute call.completed?
    refute call.cancelled?
    refute call.timed_out?
  end

  def test_coerces_tool_name_to_string
    call = build_tool_call(tool_name: :my_tool)
    assert_equal "my_tool", call.tool_name
  end

  def test_freezes_input
    call = build_tool_call(input: { a: 1 })
    assert call.input.frozen?
  end

  def test_freezes_metadata
    call = build_tool_call(metadata: { key: "val" })
    assert call.metadata.frozen?
  end

  def test_immutable_after_creation
    call = build_tool_call
    assert call.frozen?
  end

  def test_valid_states
    %i[pending running completed failed cancelled timed_out].each do |state|
      call = build_tool_call(state: state)
      assert_equal state, call.state
    end
  end

  def test_invalid_state_raises
    assert_raises(ArgumentError) { build_tool_call(state: :invalid) }
  end

  def test_with_returns_new_instance
    original = build_tool_call(state: :pending)
    updated = original.with(state: :running)

    assert updated.running?
    assert original.pending?
    refute_equal original.object_id, updated.object_id
  end

  def test_with_preserves_id
    original = build_tool_call(id: "tc_keep")
    updated = original.with(state: :running)
    assert_equal "tc_keep", updated.id
  end

  def test_equality_by_id
    a = build_tool_call(id: "tc_same")
    b = build_tool_call(id: "tc_same")
    assert_equal a, b
  end

  def test_inequality_by_id
    a = build_tool_call(id: "tc_1")
    b = build_tool_call(id: "tc_2")
    refute_equal a, b
  end

  def test_to_h
    call = build_tool_call(id: "tc_h")
    h = call.to_h
    assert_equal "tc_h", h[:id]
    assert_equal "search", h[:tool_name]
    assert_equal :pending, h[:state]
  end

  def test_inspect
    call = build_tool_call(id: "tc_123")
    assert_match(/tc_123/, call.inspect)
    assert_match(/search/, call.inspect)
  end

  def test_turn_can_be_nil
    call = build_tool_call(turn: nil)
    assert_nil call.turn
  end

  def test_caller_id
    call = build_tool_call(caller_id: "user_42")
    assert_equal "user_42", call.caller_id
  end

  def test_metadata
    call = build_tool_call(metadata: { priority: :high })
    assert_equal({ priority: :high }, call.metadata)
  end

  # --- Lifecycle: failed state ---

  def test_default_state_refutes_failed
    call = build_tool_call
    refute call.failed?
  end

  def test_failed_state_predicate
    call = build_tool_call(state: :failed)
    assert call.failed?
    refute call.completed?
    refute call.cancelled?
    refute call.timed_out?
  end

  def test_failed_state_with_error
    call = build_tool_call(state: :failed, error: "connection refused")
    assert_equal "connection refused", call.error
  end

  # --- Lifecycle: error field ---

  def test_error_nil_by_default
    call = build_tool_call
    assert_nil call.error
  end

  def test_error_set_on_failed
    call = build_tool_call(state: :failed, error: "boom")
    assert_equal "boom", call.error
  end

  # --- Lifecycle: tool_result field ---

  def test_tool_result_nil_by_default
    call = build_tool_call
    assert_nil call.tool_result
  end

  def test_tool_result_on_completed
    result = Ask::Runtime::ToolResult.success(data: "ok")
    call = build_tool_call(state: :completed, tool_result: result)
    assert_equal result, call.tool_result
    assert call.tool_result.success?
  end

  def test_tool_result_on_failed
    result = Ask::Runtime::ToolResult.failure("bad input")
    call = build_tool_call(state: :failed, tool_result: result)
    assert_equal result, call.tool_result
    assert call.tool_result.failure?
  end

  def test_tool_result_on_cancelled
    result = Ask::Runtime::ToolResult.cancelled("user abort")
    call = build_tool_call(state: :cancelled, tool_result: result)
    assert_equal result, call.tool_result
    assert call.tool_result.cancelled?
  end

  def test_tool_result_on_timed_out
    result = Ask::Runtime::ToolResult.timeout("30s exceeded")
    call = build_tool_call(state: :timed_out, tool_result: result)
    assert_equal result, call.tool_result
    assert call.tool_result.timeout?
  end

  # --- Lifecycle: state transitions via with ---

  def test_pending_to_running
    call = build_tool_call(state: :pending)
    running = call.with(state: :running, started_at: Time.now)
    assert running.running?
    assert call.pending?
  end

  def test_running_to_completed
    call = build_tool_call(state: :running)
    result = Ask::Runtime::ToolResult.success(data: 42)
    completed = call.with(state: :completed, tool_result: result, finished_at: Time.now)
    assert completed.completed?
    assert_equal 42, completed.tool_result.output
  end

  def test_running_to_failed
    call = build_tool_call(state: :running)
    result = Ask::Runtime::ToolResult.failure("error")
    failed = call.with(state: :failed, error: "error", tool_result: result, finished_at: Time.now)
    assert failed.failed?
    assert_equal "error", failed.error
  end

  def test_running_to_cancelled
    call = build_tool_call(state: :running)
    result = Ask::Runtime::ToolResult.cancelled("user abort")
    cancelled = call.with(state: :cancelled, tool_result: result, finished_at: Time.now)
    assert cancelled.cancelled?
  end

  def test_running_to_timed_out
    call = build_tool_call(state: :running)
    result = Ask::Runtime::ToolResult.timeout("30s exceeded")
    timed = call.with(state: :timed_out, tool_result: result, finished_at: Time.now)
    assert timed.timed_out?
  end

  # --- to_h includes new fields ---

  def test_to_h_includes_error_and_tool_result
    result = Ask::Runtime::ToolResult.success(data: "x")
    call = build_tool_call(id: "tc_new", state: :completed, error: nil, tool_result: result)
    h = call.to_h
    assert_equal :completed, h[:state]
    assert_nil h[:error]
    assert_equal({ outcome: :success, output: "x", error: nil, duration: nil, result: result.result.to_h }, h[:tool_result])
  end

  def test_to_h_includes_failed_error
    call = build_tool_call(id: "tc_fail", state: :failed, error: "boom")
    h = call.to_h
    assert_equal "boom", h[:error]
    assert_equal :failed, h[:state]
  end

  def test_to_h_tool_result_nil_when_not_set
    call = build_tool_call
    h = call.to_h
    assert_nil h[:tool_result]
  end
end
