# B6 — Box Parser Registry

## 🎯 Objective
Establish a shared registry that routes MP4/QuickTime box headers to the correct parser implementation so downstream modules (streaming pipeline, CLI, and UI) consistently decode typed payloads.

## 🧩 Context
- Follows Phase B infrastructure tasks (`B1`–`B5`) from the execution workplan to leverage the chunked reader, header decoder, and streaming pipeline.
- Aligns with the Phase C parser backlog in `ISOInspector_PRD_TODO.md`, which elevates comprehensive box decoding as a P0 milestone dependency.
- Supports validation and export features outlined in the master PRD by ensuring every parsed node is created via a single source of truth.

## ✅ Success Criteria
- A `BoxParserRegistry` type maps fourcc and UUID identifiers to parser closures, with facilities to register defaults at startup.
- Container defaults recurse into child ranges while opaque leaves capture offset/length metadata without payload inflation.
- Unknown box types return a safe placeholder payload and emit research hooks defined in existing validation rules.
- Unit tests cover registry registration, unknown fallback behavior, and parser invocation for representative headers.

## 🔧 Implementation Notes
- Implement the registry under `Sources/ISOInspectorKit/ISO`, exposing a `shared` instance for app/CLI consumers.
- Seed registrations for all core Phase C parsers; leave extension points for codec-specific handlers documented in the backlog.
- Ensure the streaming pipeline requests the registry instance instead of constructing parsers manually to centralize behavior.
- Provide XCTest coverage in `Tests/ISOInspectorKitTests` verifying registration, unknown handling, and container passthrough logic.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Any relevant archived context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
