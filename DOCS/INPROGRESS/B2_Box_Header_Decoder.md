# Task B2 — Box Header Decoder

## Objective
Develop the reusable header decoding layer for ISO BMFF boxes so downstream parsers can rely on consistent metadata (size, type, offsets, uuid) derived from buffered IO provided by `RandomAccessReader`.

## Scope
- Extend `RandomAccessReader` with big-endian helpers for 32-bit/64-bit integers and FourCC decoding required by ISO BMFF headers.
- Implement a header decoding API that reads 32-bit, 64-bit (largesize), and `uuid` variants while validating forward progress and parent bounds.
- Surface structured errors for malformed headers (e.g., zero size without context, overflow, truncated reads) aligned with PRD validation requirements.
- Provide unit tests covering standard, extended, and malformed headers using in-memory reader stubs or fixtures.

## Dependencies
- ✅ B1 — Chunked file reader and `RandomAccessReader` protocol available for buffered IO access.

## Acceptance Criteria
- Decoding supports size32, largesize64, and optional `uuid` fields with accurate header size computation.
- Handles `size == 0` semantics (extends to parent/end-of-file) without unsafe assumptions.
- Raises descriptive errors on truncated buffers, overflow, or invalid combinations while keeping parser state consistent.
- XCTest suite covers 32-bit, 64-bit, and uuid boxes plus malformed scenarios per Execution Workplan Task B2.

## Immediate Next Steps
1. Draft BE helper methods on `RandomAccessReader` (u16/u32/u64, FourCC) with tests verifying endian correctness.
2. Implement `BoxHeader` model capturing offsets, payload range, header size, and optional uuid.
3. Build `readBoxHeader(at:inParentRange:)` that uses helpers to parse and validate header variants and `size == 0` cases.
4. Add tests for nominal headers, large-size paths, uuid boxes, zero-size to parent end, and malformed inputs (short reads, overflow).
