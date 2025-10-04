
# ISOInspectorCore PRD — Async Streaming Parser

## Objective
Implement streaming-capable, concurrent-safe parser for ISO BMFF structures (MP4/MOV).

## Functional Requirements
- Parse boxes recursively with streaming (AsyncThrowingStream<BoxEvent>).
- Support validation, export (JSON), and hex slices.
- Handle 32/64-bit sizes, uuid, and malformed inputs gracefully.

## Non-Functional
- Performance ≥10MB/s, <100MB memory.
- Deterministic, Sendable-safe.

## TODO Breakdown
| Phase | Task | Priority | Effort |
|-------|------|-----------|--------|
| IO | RandomAccessReader abstractions | High | 2d |
| Parser | Async parser core | High | 4d |
| Validation | Integrity rules | High | 2d |
| Export | JSON exporter | Medium | 1d |
| Hex | Hex slice provider | Medium | 1d |
| Tests | Fixtures & fuzz tests | High | 3d |
