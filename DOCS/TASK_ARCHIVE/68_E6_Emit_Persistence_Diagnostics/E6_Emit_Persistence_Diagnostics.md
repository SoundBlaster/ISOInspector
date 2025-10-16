# E6 — Emit Persistence Diagnostics

## 🎯 Objective

Instrument the session and recents persistence flows so failures are surfaced through the shared diagnostics logging
pipeline, enabling QA tooling to detect issues when CoreData writes or bookmark serialization fail.

## 🧩 Context

- Phase E of the execution workplan calls for wiring diagnostics for session/recents persistence now that the logging
  pipeline exists, with the task tracked as E6. 【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L45-L54】
- Session persistence foundations are in place, and their follow-up explicitly requests exposing failures once
  diagnostics plumbing is available. 【F:DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/Summary_of_Work.md†L1-L26】
- The root TODO list tracks recents and session diagnostics work items as in progress, providing stakeholder visibility
  for this initiative. 【F:todo.md†L20-L28】

## ✅ Success Criteria

- Persistence failures encountered in `DocumentSessionController.persistRecents()` and `persistSession()` emit errors through `DiagnosticsLogger`, including enough metadata (file URL, session identifier) to triage issues. 【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L201-L317】【F:Sources/ISOInspectorKit/Support/Diagnostics.swift†L1-L38】
- QA automation (unit or integration tests) exercises simulated recents/session write failures and asserts that
  diagnostics entries are produced without crashing the app shell.
- User-facing behavior remains unchanged when persistence succeeds: recents and session state still save/restore via
  existing CoreData and JSON stores. 【F:DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/Summary_of_Work.md†L1-L18】

## 🔧 Implementation Notes

- Replace the existing `@todo` markers in `DocumentSessionController` with concrete logging, ensuring we reuse the shared diagnostics subsystem rather than ad-hoc `print` calls. 【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L217-L317】
- Consider capturing relevant contextual metadata (workspace/session IDs, failing file URLs) in the logged message so
  telemetry dashboards and CLI/app smoke tests can surface actionable alerts.
- Extend test coverage in `ISOInspectorAppTests` to inject failing `RecentsStore` / `WorkspaceSessionStore` collaborators and validate diagnostics emission without persisting partial state.
- Ensure any new diagnostics helpers remain cross-platform (macOS/iOS/iPadOS) and compile without `os.log` availability, following the existing `DiagnosticsLogger` conditional compilation pattern. 【F:Sources/ISOInspectorKit/Support/Diagnostics.swift†L1-L38】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/52_E3_Session_Persistence`](../TASK_ARCHIVE/52_E3_Session_Persistence)
