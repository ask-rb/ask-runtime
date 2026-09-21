# frozen_string_literal: true

require_relative "test_helper"

class ToolResultTest < Minitest::Test
  def test_success
    result = Ask::Runtime::ToolResult.success(data: { "count" => 42 })
    assert result.success?
    refute result.failure?
    refute result.cancelled?
    refute result.timeout?
    assert_equal({ "count" => 42 }, result.output)
    assert_nil result.error_message
  end

  def test_success_with_duration
    result = Ask::Runtime::ToolResult.success(data: "ok", duration: 0.5)
    assert result.success?
    assert_equal 0.5, result.duration
  end

  def test_success_with_metadata
    result = Ask::Runtime::ToolResult.success(data: "ok", metadata: { cached: true })
    assert result.success?
  end

  def test_failure
    result = Ask::Runtime::ToolResult.failure("file not found")
    assert result.failure?
    refute result.success?
    assert_equal "file not found", result.error_message
    assert_nil result.output
  end

  def test_failure_with_duration
    result = Ask::Runtime::ToolResult.failure("error", duration: 1.2)
    assert result.failure?
    assert_equal 1.2, result.duration
  end

  def test_cancelled
    result = Ask::Runtime::ToolResult.cancelled("user aborted")
    assert result.cancelled?
    refute result.success?
    refute result.failure?
    assert_equal "user aborted", result.error_message
  end

  def test_cancelled_default_reason
    result = Ask::Runtime::ToolResult.cancelled
    assert result.cancelled?
    assert_equal "Cancelled", result.error_message
  end

  def test_timeout
    result = Ask::Runtime::ToolResult.timeout("exceeded 30s limit")
    assert result.timeout?
    refute result.success?
    assert_equal "exceeded 30s limit", result.error_message
  end

  def test_timeout_default_message
    result = Ask::Runtime::ToolResult.timeout
    assert result.timeout?
    assert_equal "Execution timed out", result.error_message
  end

  def test_wraps_ask_result
    result = Ask::Runtime::ToolResult.success(data: "x")
    assert_kind_of Ask::Result, result.result
    assert result.result.ok?
  end

  def test_to_h
    result = Ask::Runtime::ToolResult.success(data: "hello", duration: 0.1)
    h = result.to_h
    assert_equal :success, h[:outcome]
    assert_equal "hello", h[:output]
    assert_equal 0.1, h[:duration]
    assert h.key?(:result)
  end

  def test_inspect_success
    result = Ask::Runtime::ToolResult.success(data: "test")
    assert_match(/success/, result.inspect)
    assert_match(/test/, result.inspect)
  end

  def test_inspect_failure
    result = Ask::Runtime::ToolResult.failure("bad")
    assert_match(/failure/, result.inspect)
    assert_match(/bad/, result.inspect)
  end

  def test_immutable
    result = Ask::Runtime::ToolResult.success(data: "x")
    assert result.frozen?
  end
end
