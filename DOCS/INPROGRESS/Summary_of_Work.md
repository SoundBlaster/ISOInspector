# Summary of Work — 2025-10-25

## Completed Tasks

- **T2.4 — Validation Rule Dual-Mode Support**: Updated the live parse pipeline so validation rules VR-001…VR-015 generate `ParseIssue` diagnostics when tolerant parsing is enabled while preserving strict-mode behavior.

## Implementation Highlights

- Convert validation diagnostics into `ParseIssue` records inside `ParsePipeline`, recording them in `ParseIssueStore` and surfacing the issues on streamed events. (`Sources/ISOInspectorKit/ISO/ParsePipeline.swift`)
- Extended `ParsePipelineLiveTests` to cover tolerant mode behavior, ensuring parse issues and the shared issue store capture VR-003 warnings alongside existing structural diagnostics. (`Tests/ISOInspectorKitTests/ParsePipelineLiveTests.swift`)
- Updated tolerance parsing status documents and next-task trackers to reflect completion of T2.4 and point collaborators to these results.

## Verification

- `swift test --filter ParsePipelineLiveTests/testTolerantModeEmitsParseIssuesForValidationWarnings`
- `swift test`

## Follow-Up

- **T2.3** (Parse issue metrics aggregation) remains pending design handoff per the tolerance parsing TODO.
