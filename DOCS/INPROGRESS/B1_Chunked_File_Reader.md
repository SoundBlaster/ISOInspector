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
1. Define `RandomAccessReader` protocol (if not already present) covering length, seek, and read semantics derived from PRD File IO requirements.
2. Implement concrete reader backed by `FileHandle` (fallback from PRD) with chunked buffer reuse and bounds checking.
3. Write XCTest cases for: sequential chunk reads, seeking backwards/forwards, EOF partial chunk, and injected read errors.
4. Wire reader into package manifest/tests and update documentation/comments as needed.
