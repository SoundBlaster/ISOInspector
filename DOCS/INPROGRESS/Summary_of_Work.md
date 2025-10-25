# Summary of Work — 2025-10-25

## Completed Tasks
- **T2.2 — Emit Parse Events with Severity Metadata**
  - `ParsePipeline.live()` now streams `ParseIssue` severity, offsets, and reason codes with every matching event, ensuring tolerant parsing consumers receive corruption diagnostics immediately.
  - `ISOInspectorCommand.filteredEvent` preserves streamed `ParseIssue` collections so CLI formatting retains tolerant metadata even when validation rules are filtered.
  - Added regression coverage via `ParsePipelineLiveTests.testLivePipelineStreamsParseIssueMetadata` and `ISOInspectorCommandTests.testFilteredEventPreservesParseIssueMetadata`.

## Verification
- `swift test --filter testLivePipelineStreamsParseIssueMetadata`
- `swift test --filter testFilteredEventPreservesParseIssueMetadata`

## Follow-Ups
- Proceed to T2.3 to aggregate per-severity metrics from `ParseIssueStore` for UI ribbons and CLI summaries once design handoff completes.
