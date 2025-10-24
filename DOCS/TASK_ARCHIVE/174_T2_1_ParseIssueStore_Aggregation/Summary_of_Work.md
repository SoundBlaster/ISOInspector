# Summary of Work — T2.1 ParseIssueStore Aggregation

## Completed Tasks
- Delivered the shared `ParseIssueStore` aggregate that records tolerant parsing issues, supports node/byte range queries, and publishes real-time metrics for downstream observers.
- Threaded `ParseIssueStore` through `ParsePipeline`, the CLI environment, and `ParseTreeStore` so tolerant parsing runs reuse a single store instance and surface metrics consistently across app and CLI clients.
- Added focused unit coverage for the store plus refreshed streaming walker tests for depth-aware issue callbacks.

## Implementation Highlights
- Introduced `ParseIssueStore` with `@Published` issue collections, node/range queries, metrics tracking, and main-thread coordination for safe reuse across Combine and CLI workflows.
- Updated `StreamingBoxWalker` to supply depth values when emitting issues, enabling the store to calculate deepest affected depth without re-traversal.
- Ensured `ParsePipeline.Context` propagates an optional `ParseIssueStore`, resetting it before runs and recording issues as they stream in.
- Exposed the store through `ISOInspectorCLIEnvironment` and `ParseTreeStore`, allowing CLI commands and SwiftUI state to access shared metrics without additional wiring.

## Verification
- `swift test --filter ParseIssueStoreTests`
- `swift test`

## Follow-ups
- Surface tolerant parsing issue metrics inside SwiftUI ribbons once the design spec is finalized (`@todo PDD:45m` in `ParseTreeStore.swift`, mirrored in `todo.md`).
