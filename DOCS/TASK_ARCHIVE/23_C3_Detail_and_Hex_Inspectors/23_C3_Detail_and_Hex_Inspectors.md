# C3 — Detail and Hex Inspectors

## 🎯 Objective

Implement the detail pane stack that renders metadata, validation issues, and hex slices for the selected box using the
existing Combine bridge snapshots.

## 🧩 Context

- Fulfills FR-UI-002 for a metadata-rich detail pane with synchronized hex viewer and validation

  status.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L13-L18】

- Builds on the Combine session bridge delivered in C1 to keep UI.Detail components fed with streaming parse

  events.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L12-L25】

- Continues Phase C focus on UI components after tree virtualization work, aligning with Execution Workplan priority for

  C3.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L22-L29】

## ✅ Success Criteria

- Selecting a node produces a metadata detail view populated from `ParseTreeSnapshot` descriptors, including MP4RA-backed field labels.
- Validation issues associated with the node render in a dedicated section with severity badges and copy-to-clipboard

  support.

- Hex inspector shows a bounded payload window (configurable size) that stays synchronized with selection changes and

  shares snapshot timestamps for latency diagnostics.

- Detail + hex panes update within 200 ms of incoming events during live parsing, matching tree updates.

## 🔧 Implementation Notes

- Reuse Combine snapshot models from C1/C2 and extend them with convenience accessors for metadata fields and payload

  slices.

- Coordinate with planned hex slice provider work (Phase F1/F3) by defining protocols now and backing with simple file

  range requests until dedicated caching lands.【F:DOCS/AI/ISOInspector_PRD_TODO.md†L187-L204】

- Preserve separation between presentation (SwiftUI views) and derived state (view models) to ease snapshot testing and

  previews.

- Ensure preview/sample data leverage recorded snapshots to avoid divergence from live streaming behavior.
- Watch for accessibility requirements (labels, dynamic type) to keep future C5 work unblocked.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Any relevant archived context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
