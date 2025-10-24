# Summary of Work — 2025-10-24

## Completed Tasks
- **T1.5 — Propagate Decoder Failures Through Tolerant Parsing**
  - Streaming walker now inspects `BoxHeaderDecoder` results with tolerant options, converts failures into `ParseIssue` records, and advances within parent boundaries instead of aborting.
  - `ParsePipeline.live` propagates tolerant options, tracks per-node issues, and emits them with parse events for tree builders and captures.
  - `ParseEvent`/`ParseTreeBuilder`/capture payload updated to carry parse issues end-to-end.
  - Added regression coverage for tolerant recovery plus parse tree aggregation.

## Verification
- `swift test` (passes; includes tolerant walker regression and full suite)

## Follow-ups
- Continue tolerant parsing roadmap by wiring issue presentation into downstream consumers (CLI/app summaries) once issue aggregation APIs land.
