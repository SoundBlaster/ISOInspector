# C2 — Tree View Virtualization & Search

## 🎯 Objective

Deliver the SwiftUI outline view for parsed ISO BMFF boxes using the `ParseTreeStore` snapshots so users can explore files through a responsive hierarchy with search and filtering.

## 🧩 Context

- Follows the completed C1 Combine bridge/state stores work; next priority item in Phase C UI track. [Execution workplan
  — task C2](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md).
- Align with ISOInspectorUI PRD requirements for tree/details/hex components and live updates. [ISOInspectorUI
  PRD](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspectorUI_PRD.md).
- Overall product scope defined in the master PRD covering the UI surface. [Master
  PRD](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md).

## ✅ Success Criteria

- Outline renders >10k nodes smoothly while expanding/collapsing and reacting to incoming snapshots. [Execution workplan
  — acceptance criteria](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md).
- Search input filters the tree immediately, highlighting matches and collapsing irrelevant branches per UX expectations
  from the UI PRD. [ISOInspectorUI PRD](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspectorUI_PRD.md).
- Filter toggles allow focusing on validation warnings/errors, box categories, and streaming metadata in line with
  backlog notes. [ISOInspector_PRD_TODO backlog](../AI/ISOViewer/ISOInspector_PRD_TODO.md).
- Works across macOS/iPadOS form factors with SwiftUI best practices, ready for integration in Phase E. [Master
  PRD](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md).

## 🔧 Implementation Notes

- Consume `ParseTreeStore` Combine snapshots (produced by C1) and virtualize rendering to avoid performance cliffs when large payloads arrive.
- Define view models for nodes, selection state, and filtering categories so C3 detail/hex panes can subscribe later.
- Ensure search/filter logic can be reused by CLI/export features and that unknown box warnings from VR-006 remain
  visible.
- Validate with SwiftUI previews or snapshots using representative large-tree fixtures; coordinate with future
  accessibility task C5.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
