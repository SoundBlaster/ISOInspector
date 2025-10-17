# C7 — Connect Bookmark Diffs to Persisted Bookmarks

## 🎯 Objective

Reconcile CoreData session bookmark diff entities with the persisted bookmark records so the session store,
recents list, and annotation features stay in sync after Task E3's persistence foundations.

## 🧩 Context

- Execution workplan Task C7 highlights the need to link bookmark diff entities with their persisted counterparts.
- Task E3 delivered the CoreData schema and live persistence flows; this follow-up closes the remaining reconciliation

  gap.

- The `todo.md` PDD:1h item mirrors this work so planning views stay consistent.

## ✅ Success Criteria

- Bookmark diff reconciliation updates or removes CoreData records without duplication or orphaned entries.
- Automated tests cover add, update, and delete flows across CoreData and JSON-backed stores.
- Session restoration continues to present the latest bookmark state in UI and CLI surfaces without regressions.

## 🔧 Implementation Notes

- Review `CoreDataAnnotationBookmarkStore` and `AnnotationBookmarkSession` to confirm how diffs are generated and applied.
- Confirm FilesystemAccessKit bookmark identifiers remain valid after reconciliation merges.
- Extend `AnnotationBookmarkStoreTests`, `WorkspaceSessionStoreTests`, and `DocumentSessionControllerTests` to cover this path.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/Summary_of_Work.md`](../TASK_ARCHIVE/52_E3_Session_Persistence/Summary_of_Work.md)
