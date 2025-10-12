# 14_Add_NestedA11yIDs_Annotation_Note_Controls

## 🎯 Objective

Add NestedA11yIDs identifiers to the annotation note edit, save, cancel, and delete controls so QA automation can target
them deterministically across platforms.

## 🧩 Context

- Continues the NestedA11yIDs rollout captured in the archived task `39_Apply_NestedA11yIDs_Research_Log_Preview`, which noted annotation editors as the next follow-up.
- Aligns with `todo.md` item #14 and the in-progress checklist under `DOCS/INPROGRESS/next_tasks.md`.
- Builds on the accessibility identifier principles in `DOCS/RULES/09_AccessibilityIdentifiers.md` and the guidance in `Docs/Guides/NestedA11yIDsIntegration.md`.

## ✅ Success Criteria

- Annotation note toolbar buttons expose stable `.nestedAccessibilityIdentifier` values for edit, save, cancel, and delete actions.
- Identifier constants live alongside existing NestedA11yIDs definitions (e.g., in a dedicated `AnnotationAccessibilityID` namespace) with unit coverage similar to other accessibility identifier tests.
- Documentation in `Docs/Guides/NestedA11yIDsIntegration.md` lists the new identifiers for QA reference if additional usage notes are required.

## 🔧 Implementation Notes

- Update `AnnotationNoteRow` in `ParseTreeDetailView.swift` to wrap the control stack with `.nestedAccessibilityIdentifier(...)` assignments following the root hierarchy already used for detail panes.
- Ensure identifier naming follows the no-dot-per-segment rule and mirrors automation semantics (e.g., `annotationNotes.list.row.edit` rather than display labels).
- Consider adding focused SwiftUI preview or unit tests to assert the composed identifiers, using existing accessibility

  identifier test patterns as a reference.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived context under [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
