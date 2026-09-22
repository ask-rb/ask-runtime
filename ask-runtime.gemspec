require_relative "lib/ask/runtime/version"

Gem::Specification.new do |spec|
  spec.name = "ask-runtime"
  spec.version = Ask::Runtime::VERSION
  spec.authors = ["Kaka Ruto"]
  spec.email = ["kaka@myrrlabs.com"]

  spec.summary = "Tool-call execution kernel for the ask-rb ecosystem."
  spec.description = "Provides the foundational value objects and adapter contracts for tool-call execution in ask-rb: ToolCall, ToolResult, ExecutionContext, and the ToolExecutor adapter interface."

  spec.homepage = "https://github.com/ask-rb/ask-runtime"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "ask-core", ">= 0.12.1"

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "mocha", "~> 3.1"
  spec.add_development_dependency "rake", "~> 13.0"
end
