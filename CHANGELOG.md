# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - Unreleased

### Added

- `Ask::Runtime::ToolCall` — immutable value object for a tool-call request with identity, tool name, input, session/turn correlation, and lifecycle state.
- `Ask::Runtime::ToolResult` — normalized success/failure/cancelled/timeout result from tool execution, wrapping `Ask::Result`.
- `Ask::Runtime::ExecutionContext` — immutable context passed to tool execution: session, turn, caller, workspace, capabilities, cancellation, event sink, artifact store, and metadata.
- `Ask::Runtime::ToolExecutor` — adapter contract (interface) for pluggable tool execution backends.
- `Ask::Runtime::Canceller` — cooperative cancellation token with `cancelled?` / `cancel` / `on_cancel` callbacks.
- `Ask::Runtime::EventSink` — simple event emitter contract for execution lifecycle notifications.

### Documentation
- Added RuntimeAdapter integration section to README showing how to bridge EventSink events to ask-instrumentation.
- Added the reusable `Ask::Runtime::Testing::ExecutorContract` helper for adapter conformance tests.
- Added independent CI, setup, and release workflows for the runtime repository.
