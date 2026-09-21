# Ask Runtime Foundation

## What we're building

Make `ask-runtime` a dependable, independently consumable execution kernel for
the Ask ecosystem: adapter authors get one documented contract, one reusable
conformance suite, and a repository that can be tested and released on its
own.

## How this works (the rules of engagement)

- Every behavior change is test-first and must leave the full affected suite
  green.
- Use the 37signals gem conventions, explicit Git staging, and one focused
  commit per repository.
- Keep existing Ask, MCP, sandbox, and agent APIs backward compatible.
- This is a living document: update it when implementation discoveries change
  the scope.

## Design decisions (made so far)

- `Ask::Runtime::ToolExecutor` is the stable adapter contract:
  `execute(tool_call, context: nil) -> Ask::Runtime::ToolResult`.
- Runtime lifecycle events travel through `ExecutionContext#event_sink` and
  use immutable `ToolStarted`, `ToolCompleted`, `ToolFailed`,
  `ToolCancelled`, and `ToolTimedOut` snapshots.
- Existing executors remain the owners of their legacy APIs. Runtime adapters
  are additive bridges, not replacements.
- The runtime gem owns the portable conformance helper; adapter repositories
  run it against their real executor and retain focused backend tests.

## Phases with task lists

| Phase | Tasks |
| --- | --- |
| Contract | - [x] Add the reusable executor conformance helper — validate normalization, cancellation, events, terminal state, and correlation. |
| Adapters | - [x] Run the helper against agent, MCP, and sandbox executors — fix any semantic drift without breaking legacy APIs. |
| Repository | - [x] Add CI, setup, and release workflows — make `ask-runtime` independently testable and publishable. |
| Documentation | - [x] Document the adapter contract and conformance helper — give third-party Ruby authors a copyable path. |
| Verification | - [x] Run all affected suites and commit each repository’s complete slice. |

## Definition of done

1. A Ruby author implements `execute(tool_call, context:)` for a new backend.
2. They include the runtime conformance helper and receive clear failures for
   missing normalization, cancellation, or lifecycle behavior.
3. The agent, MCP, and sandbox adapters all pass the same contract checks.
4. A clean checkout of `ask-runtime` runs its tests on supported Ruby versions
   and can build/release the gem using documented repository workflows.
