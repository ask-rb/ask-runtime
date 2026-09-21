# frozen_string_literal: true

require_relative "test_helper"

class ToolExecutorTest < Minitest::Test
  include TestHelpers

  def test_execute_raises_not_implemented
    executor = Object.new
    executor.extend(Ask::Runtime::ToolExecutor)
    call = build_tool_call
    assert_raises(NotImplementedError) { executor.execute(call) }
  end

  def test_concrete_executor_includes_module
    executor = Class.new do
      include Ask::Runtime::ToolExecutor

      def execute(tool_call, context: nil)
        Ask::Runtime::ToolResult.success(data: "handled #{tool_call.tool_name}")
      end

      def supported_tools
        %w[search read]
      end
    end.new

    call = build_tool_call(tool_name: "search")
    result = executor.execute(call)
    assert result.success?
    assert_equal "handled search", result.output
  end

  def test_handles_predicate
    executor = Class.new do
      include Ask::Runtime::ToolExecutor

      def execute(tool_call, context: nil); end

      def supported_tools
        %w[search read]
      end
    end.new

    assert executor.handles?("search")
    assert executor.handles?(:read)
    refute executor.handles?("write")
  end

  def test_handles_without_supported_tools
    executor = Class.new do
      include Ask::Runtime::ToolExecutor

      def execute(tool_call, context: nil); end
    end.new

    refute executor.handles?("anything")
  end

  def test_duck_type_without_include
    executor = Class.new do
      def execute(tool_call, context: nil)
        Ask::Runtime::ToolResult.success(data: "ok")
      end
    end.new

    call = build_tool_call
    result = executor.execute(call, context: build_context)
    assert result.success?
  end
end
