# H2 – Unit Tests for Core Parsing Guarantees

## 🎯 Objective

Establish deterministic XCTest coverage for ISOInspectorKit parsing primitives so header math, container boundaries, and
critical box field decoders remain stable across future refactors.

## 🧩 Context

- Reinforces Phase B engine deliverables documented in the execution workplan and the Master PRD reliability
  requirements.
- Builds on the fixture catalog from Task H1 to validate structural expectations for representative MP4/MOV assets.
- Complements existing streaming integration tests by isolating low-level regressions before they reach UI or CLI
  surfaces.

## ✅ Success Criteria

- Tests in `Tests/ISOInspectorKitTests` fail when header size arithmetic or parent/child range validation regresses.
- Box-specific unit tests confirm decoded field values for key structures (`ftyp`, `mvhd`, `tkhd`, sample tables, codec configs).
- Regression suite runs quickly enough for CI gating (<30s incremental) using lightweight fixtures.
- Documentation updated where necessary to reflect new test coverage expectations.

## 🔧 Implementation Notes

- Focus on `ISOInspectorKit` modules: `BoxHeader`, `BoxNode`, `FullBoxReader`, and targeted parsers under `Sources/ISOInspectorKit/Parsers`.
- Leverage existing fixtures in `Tests/ISOInspectorKitTests/Fixtures` plus synthetic minimal boxes generated inline for edge cases.
- Incorporate failure-case fixtures from the manifest workflow to assert error pathways without relying on
  macOS-specific tooling.
- Consider using helper builders (e.g., `TestFileHandle`) to simulate truncated payloads or overlapping ranges.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
