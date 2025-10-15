# A2 Implement MappedReader

## 🎯 Objective

Deliver a memory-mapped `RandomAccessReader` implementation that provides bounded, slice-based reads backed by `Data(contentsOf:options:.mappedIfSafe)` so large media files can be scanned efficiently without duplicating buffers.

## 🧩 Context

- Detailed TODO entry **A2** calls for a `MappedReader` using `Data(..., .mappedIfSafe)` with bounds-checked slicing so the IO layer offers both mapped and chunked backends.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L162-L170】
- The PRD functional requirements call for random-access reads by offset and length, preferring memory-mapped `Data` with a buffered fallback — the exact behaviour `MappedReader` must supply.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L40-L44】
- `ChunkedFileReader` currently satisfies `RandomAccessReader` via `FileHandle` buffers; a mapped peer keeps parity with the architectural expectations outlined in the execution workplan.【F:Sources/ISOInspectorKit/IO/ChunkedFileReader.swift†L5-L82】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L1-L28】

## ✅ Success Criteria

- `MappedReader` conforms to `RandomAccessReader`, exposing file `length` and `read(at:count:)` with defensive bounds checking and descriptive errors when requests exceed the available range.
- Reader initialisation validates the URL, captures the mapped `Data`, and releases resources deterministically when deallocated.
- Unit tests cover full-file reads, partial slices, zero-length requests, and out-of-bounds failures alongside parity checks with `ChunkedFileReader` fixtures.
- Documentation in the IO module explains when to prefer the mapped versus chunked reader and how they interoperate with

  parser components.

## 🔧 Implementation Notes

- Mirror the error surface already exposed by `RandomAccessReaderValueDecodingError` and extend as needed for IO-specific faults without introducing new dependencies.【F:Sources/ISOInspectorKit/IO/RandomAccessReader.swift†L5-L55】
- Consider platform differences: guard `mappedIfSafe` availability and provide graceful degradation (e.g., fallback to chunked reader) when mapping is unsupported.
- Ensure thread safety by treating the mapped `Data` as immutable and documenting concurrency expectations.
- Update factory closures (CLI, app) once implementation lands so callers can opt into mapped IO for large files when

  the environment allows it.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)

## ✅ Outcome

- Added `MappedReader` in `Sources/ISOInspectorKit/IO/MappedReader.swift`, providing bounds-checked random access backed by `Data(contentsOf:options:.mappedIfSafe)` with an eager-loading fallback for platforms that cannot memory-map the file.
- Extended the ISOInspectorKit test suite with `MappedReaderTests` to cover slice reads, zero-length requests, out-of-bounds protection, and missing file handling (`Tests/ISOInspectorKitTests/MappedReaderTests.swift`).
- Updated work tracking documents to mark Task A2 as complete and captured the delivery record in `DOCS/INPROGRESS/Summary_of_Work.md`.

## 🔬 Verification

- `swift test`
