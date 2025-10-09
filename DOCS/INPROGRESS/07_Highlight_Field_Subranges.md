# #7 Highlight Field Subranges and Selection Sync

## 🎯 Objective

Implement synchronized highlighting between parsed field annotations and the hex viewer so that selecting a metadata
field focuses the corresponding byte range and vice versa.

## 🧩 Context

- Fulfills the remaining portion of FR-UI-002 for the detail pane hex viewer in the product requirements.
  【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L13-L19】
- Extends follow-up item "#7 Highlight field subranges" noted after completing task 23_C3 Detail and Hex Inspectors.
  【F:DOCS/TASK_ARCHIVE/23_C3_Detail_and_Hex_Inspectors/Summary_of_Work.md†L5-L16】
- Depends on Phase C detail/annotation milestones in the execution workplan and the backlog item for field-to-hex
  mapping that will supply payload annotation metadata.
  【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L22-L33】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L67-L75】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L182-L186】

## ✅ Success Criteria

- Detail view metadata fields expose selectable annotations describing byte ranges for each structure component.
- Selecting a metadata field highlights the associated subrange inside the hex viewer and scrolls it into view when
  needed.
- Clicking or dragging inside the hex viewer updates the active field selection and annotation state.
- Unit/UI tests cover annotation-to-hex synchronization for at least one representative box (e.g., `ftyp`, `mvhd`).

## 🔧 Implementation Notes

- Introduce a payload annotation provider capable of mapping parsed field descriptors to byte offsets within `HexSlice` windows.
- Wire annotation updates through `ParseTreeDetailViewModel` so SwiftUI views remain responsive as slices stream in.
- Coordinate with any outstanding tasks for generating annotation metadata within ISOInspectorCore; block execution
  until those providers ship.
- Ensure accessibility (VoiceOver) communicates highlighted ranges when focus changes between metadata and hex views.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
