# E3 — CoreData Migration Planning for Session Persistence

## 🎯 Objective

Evaluate the current annotation/bookmark CoreData model and design a forward-compatible migration plan that will allow
the upcoming session persistence work (Task E3) to introduce additional entities (open files, window layouts, workspace
metadata) without data loss or schema churn.

## 🧩 Context

- Phase E of the execution workplan schedules Task **E3** to implement session persistence after the app shell and

  parser integration are complete, using CoreData or JSON storage to restore the previous workspace state on relaunch.
  【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L35-L45】

- The recently archived C4 CoreData implementation established entities for annotations and bookmarks and highlighted

  the need to plan migrations alongside E3 before more features rely on the store.

【F:DOCS/TASK_ARCHIVE/33_C4_CoreData_Annotation_Persistence/C4_CoreData_Annotation_Persistence.md†L1-L41】【F:DOCS/TASK_ARCHIVE/33_C4_CoreData_Annotation_Persistence/2025-10-10-coredata-annotation-bookmark-store.md†L1-L24】

- Product requirement **FR-UI-003** mandates that annotations and bookmarks persist between launches, so schema changes

  must preserve existing user data while accommodating future session-level records.
  【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L7-L18】

## ✅ Success Criteria

- Document a proposed CoreData model extension covering session metadata (recent files, window layouts, parse session

  snapshots) and its relationships to existing annotation/bookmark entities.

- Provide a migration strategy outlining lightweight versioning, automated migration steps, and fallback behavior when

  CoreData is unavailable (e.g., Linux CLI builds).

- Identify required updates to tests, DocC catalogs, and manuals to reflect the new persistence scope once migrations

  land in Task E3.

- List open questions or dependencies (e.g., concurrency constraints, shared stores across platforms) that must be

  resolved before implementation begins.

## 🔧 Implementation Notes

- Audit the current programmatic CoreData stack to confirm model versioning hooks (`NSPersistentStoreDescription`, migration options) are in place for adding new entities and relationships.
- Outline phased migration steps (lightweight vs. manual mapping) and assess whether intermediate JSON export/import

  tooling is necessary for backward compatibility.

- Coordinate with app architecture plans for session restoration (document browser, multi-window scenes) so the schema

  accounts for per-scene state and cross-device portability.

- Capture potential impacts on existing annotation/bookmark APIs to minimize UI refactoring when session records are

  introduced.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
