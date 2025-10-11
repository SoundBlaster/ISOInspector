# C5 — Accessibility Enhancements

## 🎯 Objective

Ensure the SwiftUI interface meets the accessibility requirements by providing VoiceOver-friendly labels, Dynamic Type
adaptability, and full keyboard navigation across the tree, detail, and hex views.

## 🧩 Context

- Execution workplan task **C5** targets VoiceOver labels and keyboard navigation for ISOInspectorUI, dependent on the

  completed tree and detail views from C2/C3.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L22-L31】

- Non-functional requirement **NFR-USAB-001** mandates VoiceOver and Dynamic Type support across the

  UI.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L21-L43】

- The technical spec calls for automated accessibility testing alongside UI snapshot coverage, underscoring the need for

  testable accessibility traits.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L86-L104】

- Accessibility research gap **R3** outlines guidelines and best practices from Apple references that should inform

  control labeling and focus order.【F:DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md†L5-L14】

## ✅ Success Criteria

- VoiceOver announces meaningful descriptions for tree rows, detail fields, validation badges, and hex viewer sections,

  with rotor navigation enabling box-to-box traversal.

- Dynamic Type scaling preserves layout readability for all primary views without truncating metadata or controls.
- Keyboard navigation allows selecting tree nodes, switching panes, and activating toolbar actions without a pointing

  device; focus order follows logical reading sequence.

- Automated accessibility checks (XCTest + Accessibility Inspector) run in CI to verify labels and focus behaviors, with

  documentation capturing the test plan.

## 🔧 Implementation Notes

- Audit existing SwiftUI views to ensure `accessibilityLabel`, `accessibilityValue`, and `accessibilityHint` are populated using MP4RA metadata where available.
- Introduce focus management using `@FocusState`/`FocusScope` to coordinate tree selection and detail pane editing from keyboard input.
- Apply `dynamicTypeSize` modifiers and test with large content sizes, adjusting layout priorities or wrapping behavior as needed.
- Extend UI test targets with accessibility assertions, and integrate Accessibility Inspector runs or snapshots into the

  existing CI workflow.

- Document any remaining blockers or research follow-ups in `DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md` if tooling gaps persist.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
