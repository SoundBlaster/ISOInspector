# Task B1 — Chunked File Reader

## Objective
Build the foundational streaming file reader used by ISOInspectorKit so that large ISO BMFF assets can be parsed without loading entire files into memory, satisfying the PRD requirements for random-access buffered IO.

## Scope
- Implement a `RandomAccessReader`-compatible component that exposes buffered sequential reads with configurable chunk size (default 1 MiB) while supporting seeking to arbitrary offsets.
- Provide safe handling for end-of-file, partial reads, and IO errors with explicit error types.
- Integrate with Swift concurrency primitives when helpful (e.g., AsyncSequence wrappers) but keep synchronous API available for parser pipeline.
- Add unit tests covering standard reads, seeking, EOF handling, and simulated IO failures using fixtures or in-memory stubs.

## Dependencies
- ✅ A1 — SwiftPM workspace scaffolding is in place, enabling new ISOInspectorKit modules and tests.

## Acceptance Criteria
- Reader streams 1 MiB chunks (configurable) without excessive memory allocations.
- Tests cover EOF, seek, and error paths per Execution Workplan.
- API aligns with PRD Section 2.1 (File IO) requiring random-access reads and accurate file length.

## Risks & Mitigations
- **Large file access on limited memory** → ensure buffered reads reuse storage and do not retain entire file contents.
- **Platform differences (macOS/iOS vs Linux)** → abstract file handles so Linux-based CI can exercise logic; provide conditional compilation where necessary.

## Immediate Next Steps
 - [x] Define `RandomAccessReader` protocol covering length and offset-based read semantics derived from PRD File IO requirements.
 - [x] Implement concrete reader backed by `FileHandle` with chunked buffer reuse, caching, and bounds checking.
 - [x] Write XCTest cases for sequential and spanning chunk reads, seeking, EOF partial chunk, and injected read errors.
 - [x] Wire reader into package manifest/tests and document the API for future parser integration.

## Completion Notes (2025-10-04)
- Added `RandomAccessReader` protocol and `ChunkedFileReader` implementation with configurable chunk size defaulting to 1 MiB.
- Reader caches chunk-aligned buffers, validates requested ranges, and surfaces IO errors with contextual error cases.
- Test suite covers sequential reads, multi-chunk spans, seeks, EOF handling, out-of-bounds requests, and injected IO failures.
- Work aligns with Execution Guide Task B1 acceptance criteria; ready to unblock downstream parser tasks (B2+).
