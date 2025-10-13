# E3 — Session Persistence Implementation

## 🎯 Objective

Enable ISOInspector to restore the previous workspace on launch by persisting open documents, annotation/bookmark state,
and window layouts using the CoreData-backed store introduced for annotations.

## 🧩 Context

- Phase E of the execution workplan schedules Task E3 after the app shell and parser integration so that restored state
  can hydrate the existing SwiftUI experience.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L63-L88】
- Task 34 in the archive documented the CoreData migration plan required before expanding the persistence schema to
  include session
  metadata.【F:DOCS/TASK_ARCHIVE/34_E3_CoreData_Migration_Planning/34_E3_CoreData_Migration_Planning.md†L1-L69】
- The root TODO backlog tracks item #11 for session persistence, ensuring user workspaces survive relaunches alongside
  annotation data.【F:todo.md†L8-L18】

## ✅ Success Criteria

- Launching the app after a clean quit restores the previously open files, selected nodes, window positions, and any
  unsaved annotation edits without data loss.
- Automatic CoreData migration upgrades existing annotation/bookmark stores to the new schema without requiring manual
  recovery steps.
- Linux/CLI builds continue to operate with a JSON fallback when CoreData is unavailable while keeping schema metadata
  in sync.
- New tests verify migration, workspace restoration, and fallback behaviors across macOS and non-CoreData environments.

## 🔧 Implementation Notes

- Extend the CoreData model per the migration blueprint: add `Workspace`, `Session`, `SessionFile`, `WindowLayout`, and related entities while keeping lightweight migration paths enabled.【F:DOCS/TASK_ARCHIVE/34_E3_CoreData_Migration_Planning/34_E3_CoreData_Migration_Planning.md†L46-L118】
- Update `CoreDataAnnotationBookmarkStore` to surface session APIs that coordinate with existing annotation operations and maintain thread-safety on the background context.【F:Sources/ISOInspectorApp/Annotations/CoreDataAnnotationBookmarkStore.swift†L17-L209】
- Persist parse snapshots or reference external artifacts judiciously to avoid bloating the CoreData store, following
  the open questions captured during
  planning.【F:DOCS/TASK_ARCHIVE/34_E3_CoreData_Migration_Planning/34_E3_CoreData_Migration_Planning.md†L120-L167】
- Refresh DocC articles and the app manual so onboarding material describes workspace restoration workflows once the
  feature
  stabilizes.【F:DOCS/TASK_ARCHIVE/34_E3_CoreData_Migration_Planning/34_E3_CoreData_Migration_Planning.md†L118-L144】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
