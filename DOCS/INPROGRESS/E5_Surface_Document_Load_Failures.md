# E5 Surface Document Load Failures

## 🎯 Objective

Implement the app shell error banner so unreadable documents immediately surface user-friendly failure messaging instead
of silently failing.

## 🧩 Context

- Task E5 in the execution workplan calls for a SwiftUI error banner that appears when the app cannot open a document,
  with automated coverage for the failure path.
- The app shell state controller currently carries a TODO placeholder for surfacing document load failures pending UI
  design finalization, signalling the implementation gap this task must close.

## ✅ Success Criteria

- Attempting to open an invalid or inaccessible file in the app shell presents the designed error banner with actionable
  text.
- UI tests cover the error presentation path and assert the banner clears when the user dismisses or retries
  successfully.
- Error events are logged or traced in a way that aligns with existing diagnostics expectations for document handling.

## 🔧 Implementation Notes

- Extend the document session controller to publish failure state that the SwiftUI shell can observe, replacing the
  existing TODO placeholder.
- Coordinate banner styling and copy with any existing design tokens or guidelines referenced in the workplan.
- Add regression coverage in XCTest UI or view model tests to ensure the banner persists until acknowledged and does not
  regress future success flows.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
