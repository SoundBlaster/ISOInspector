# C14d — Refresh Edit List Fixtures and Exports

## 🎯 Objective

Ensure edit list diagnostics (VR-014) have comprehensive regression coverage by updating fixtures, JSON exports, and snapshot baselines for empty, single-offset, multi-segment, and rate-adjusted `elst` scenarios.

## 🧩 Context

- Extends the `edts/elst` parser delivered in Task C14b and the VR-014 validation wiring from Task C14c so documentation and regression assets match the new diagnostics.
- Supports Phase C milestone requirements called out in `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`, which escalated C14 tasks to P0+ priority for the upcoming release.
- Builds on fixture generation and snapshot workflows captured in `Tests/ISOInspectorKitTests/JSONExportSnapshotTests.swift` and the archived summaries for Tasks H1 and H3.

## ✅ Success Criteria

- Refresh fixture inputs (including empty list, single offset, multi-segment, and rate-adjusted cases) with regenerated
  JSON exports and snapshots reflecting VR-014 outputs.
- Update any failing snapshot or export assertions in `Tests/ISOInspectorKitTests` to align with the new fixtures without regressing unrelated parsers.
- Document test execution notes (e.g., `swift test`, targeted snapshot regenerations) within the eventual task summary.
- Confirm regression coverage by running the full SwiftPM test suite after fixture updates.

## 🔧 Implementation Notes

- Use the existing fixture generation utilities in `scripts/` and the guidance from `DOCS/TASK_ARCHIVE/27_F1_Expand_Fixture_Catalog/` to regenerate assets; ensure checksums and metadata stay in sync with `Tests/Fixtures/` manifests.
- Verify JSON exports via `Tests/ISOInspectorKitTests/JSONExportSnapshotTests.swift`, updating stored baselines under `Tests/__Snapshots__/` as needed.
- Re-run `swift test` and the snapshot regeneration workflow documented in `DOCS/TASK_ARCHIVE/98_H3_JSON_Export_Snapshot_Tests/` to ensure deterministic outputs.
- Coordinate with Validation Rule #15 planning notes to avoid conflicting fixture expectations for chunk/sample
  correlation follow-ups.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/121_C14b_Implement_elst_Parser/`](../TASK_ARCHIVE/121_C14b_Implement_elst_Parser/)
- [`DOCS/TASK_ARCHIVE/122_C14c_Edit_List_Duration_Validation/`](../TASK_ARCHIVE/122_C14c_Edit_List_Duration_Validation/)
