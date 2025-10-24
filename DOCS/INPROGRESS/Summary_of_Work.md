# Summary of Work — T2.1 ParseIssueStore Aggregation

## Completed Tasks
- Implemented `ParseIssueStore` aggregate with recording, query helpers, and metrics publishing for tolerant parsing events. (See `Sources/ISOInspectorKit/Stores/ParseIssueStore.swift`.)
- Threaded `ParseIssueStore` through `ParsePipeline`, CLI environment, and `ParseTreeStore` so tolerant parsing issues propagate to downstream consumers. (See `Sources/ISOInspectorKit/ISO/ParsePipeline.swift`, `Sources/ISOInspectorCLI/CLI.swift`, and `Sources/ISOInspectorApp/State/ParseTreeStore.swift`.)
- Added unit coverage for store behavior via `ParseIssueStoreTests` and ran the full workspace test suite.

## Follow-ups
- Surface ParseIssueStore metrics in SwiftUI ribbons once tolerant parsing UI specs are finalized. (Tracked via @todo in `ParseTreeStore.swift` and `todo.md`.)

## Verification
- `swift test --filter ParseIssueStoreTests`
- `swift test`
