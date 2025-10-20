# C15 Metadata Value Decoding Expansion

## 🎯 Objective

Expand the metadata value decoding pipeline so additional `ilst` data types emitted by new fixtures render human-readable values across the CLI and app exports.

## 🧩 Context

- Builds on the completed C15 metadata parser rollout captured in `DOCS/TASK_ARCHIVE/125_C15_Metadata_Box_Coverage/`.
- Relies on the existing metadata registry defined in `BoxParserRegistry+Metadata.swift` and MP4RA catalog entries bundled under `Sources/ISOInspectorKit/Metadata/`.
- Supports roadmap priority updates in `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` that elevated Phase C coverage to P0+.

## ✅ Success Criteria

- Add decoding coverage for the next tranche of MP4RA-listed metadata value types (e.g., boolean, signed/unsigned numeric variants, `data` flavors) with verified fixtures.
- CLI JSON export and SwiftUI detail panes display normalized values for each newly supported type without falling back

  to hex dumps.

- Regression tests cover at least one fixture per new type, ensuring `decodeMetadataValue` continues to resolve UTF-8/UTF-16/integer types while exercising the new cases.

## 🔧 Implementation Notes

- Extend `decodeMetadataValue(type:data:)` within `BoxParserRegistry+Metadata.swift` to branch on additional four-byte type codes surfaced by MP4RA and recent fixture captures.
- Refresh the MP4RA catalog snapshot or add targeted overrides in `Sources/ISOInspectorKit/Metadata/` when the upstream registry introduces new identifiers required for decoding.
- Introduce fixture updates (or synthetic samples) that emit the new metadata values, then update JSON snapshot tests under `Tests/ISOInspectorKitTests` to confirm human-readable output.
- Coordinate with Validation Rule #15 planning to ensure metadata field expansions do not regress pending chunk table

  audits.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archives linked from `DOCS/TASK_ARCHIVE/125_C15_Metadata_Box_Coverage/`
