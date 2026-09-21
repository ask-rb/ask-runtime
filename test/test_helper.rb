# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ask-runtime"

require "minitest/autorun"
require "mocha/minitest"

module TestHelpers
  def build_tool_call(**overrides)
    defaults = {
      tool_name: "search",
      input: { query: "test" },
      session_id: "s_001",
      turn: 1
    }
    Ask::Runtime::ToolCall.new(**defaults.merge(overrides))
  end

  def build_context(**overrides)
    defaults = {
      session_id: "s_001",
      turn: 1,
      caller_id: "test_agent"
    }
    Ask::Runtime::ExecutionContext.new(**defaults.merge(overrides))
  end
end
