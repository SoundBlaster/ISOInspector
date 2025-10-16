# G2 Persist FilesystemAccessKit Bookmarks

## 🎯 Objective

Deliver bookmark persistence that unifies security-scoped bookmark storage across recents and session controllers using the shared `BookmarkPersistenceStore`, so files reopen without re-authorization after relaunch.

## 🧩 Context

- Phase G in the execution workplan highlights G2 as the next FilesystemAccessKit milestone following the completed core API (G1) and session persistence (E3). See `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md` and `DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/Summary_of_Work.md`.
- The bookmark schema groundwork shipped in `DOCS/TASK_ARCHIVE/70_Bookmark_Persistence_Schema/2025-10-16-bookmark-persistence-schema.md` and introduces `BookmarkPersistenceStore` for CoreData/JSON consumers.
- Master PRD app requirements call for sandbox-compliant file reopening and persistence, while the CLI TODO backlog tracks the PDD item for wiring bookmark storage into existing controllers (`todo.md`).

## ✅ Success Criteria

- Recents and session persistence flows write and resolve bookmark identifiers exclusively through `BookmarkPersistenceStore`, covering both JSON and CoreData code paths.
- Existing persisted data without bookmark identifiers continues to decode, adopting the new identifiers once files are
  re-authorized.
- Unit tests updated in `DocumentRecentsStoreTests`, `WorkspaceSessionStoreTests`, and related controller tests validate bookmark survival across save/load and migration scenarios.
- Documentation in user-facing guides and CLI/app notes references the unified bookmark persistence behavior and
  re-authorization expectations.

## 🔧 Implementation Notes

- Dependencies satisfied: G1 core API shipped (`DOCS/TASK_ARCHIVE/69_G1_FilesystemAccessKit_Core_API/`) and E3 session persistence completed (`DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/Summary_of_Work.md`).
- Update CoreData models and JSON payload structs to store bookmark identifiers, ensuring migrations follow the existing
  lightweight migration strategy captured in the session persistence archive.
- Audit `BookmarkPersistenceStore` `@todo` markers for integration touchpoints, covering both the SwiftUI app controllers and CLI sandbox adapters planned for G3.
- Coordinate with forthcoming CLI sandbox guidance to avoid schema drift; any new fields should be versioned within the
  store to remain forward-compatible.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`todo.md`](../../todo.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
