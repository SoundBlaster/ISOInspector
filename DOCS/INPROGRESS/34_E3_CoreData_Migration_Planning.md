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

【F:DOCS/TASK_ARCHIVE/33_C4_CoreData_Annotation_Persistence/C4_CoreData_Annotation_Persistence.md†L1-L64】【F:DOCS/TASK_ARCHIVE/33_C4_CoreData_Annotation_Persistence/2025-10-10-coredata-annotation-bookmark-store.md†L1-L24】

- Product requirement **FR-UI-003** mandates that annotations and bookmarks persist between launches, so schema changes
  must preserve existing user data while accommodating future session-level records.

  【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L1-L43】

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

## 🔍 Current CoreData Stack Audit

- `CoreDataAnnotationBookmarkStore` builds its `NSPersistentContainer` programmatically with automatic lightweight migration enabled (`shouldMigrateStoreAutomatically`, `shouldInferMappingModelAutomatically`), so introducing new entities can piggyback on existing flags once model versioning is formalized.【F:Sources/ISOInspectorApp/Annotations/CoreDataAnnotationBookmarkStore.swift†L17-L87】
- The store currently defines three entities (`File`, `Annotation`, `Bookmark`) with relationships managed in code, simplifying forward migration because the schema is expressed in Swift rather than `.xcdatamodeld` assets.【F:Sources/ISOInspectorApp/Annotations/CoreDataAnnotationBookmarkStore.swift†L112-L209】
- `AnnotationBookmarkStoreTests` exercise create/update/delete flows and cross-file isolation, providing regression coverage that will need to expand for new entities and migration paths.【F:Tests/ISOInspectorAppTests/AnnotationBookmarkStoreTests.swift†L1-L78】
- Linux builds already compile against a stub that lacks CoreData functionality, so any migration must keep the graceful
  fallback by persisting annotations/bookmarks only when the framework
  exists.【F:Sources/ISOInspectorApp/Annotations/CoreDataAnnotationBookmarkStore.swift†L210-L399】

## 🧱 Proposed Model Extensions

| Entity | Purpose | Key Attributes | Relationships |
|--------|---------|----------------|---------------|
| `Workspace` | Single-row metadata describing the last-known app state (app version, migration marker, timestamp). | `id`, `appVersion`, `lastOpened`, `schemaVersion` | 1:many to `Session`; 1:1 to active `Session`. |
| `Session` | Represents one persisted workspace snapshot (open documents, focused windows, parse caches). | `id`, `createdAt`, `updatedAt`, `lastSceneIdentifier`, `isCurrent` | Many:many with `File` via `SessionFile`; 1:many to `WindowLayout`; optional link to serialized parse snapshots. |
| `SessionFile` | Join table connecting a session to canonical file entries with per-file UI state. | `id`, `orderIndex`, `lastSelectionNodeID`, `scrollOffset`, `isPinned` | Many:1 to `Session`; many:1 to `File`; 1:many to `SessionBookmarkDiff`. |
| `WindowLayout` | Captures per-scene SwiftUI window geometry and navigation stack for multi-window setups. | `id`, `sceneIdentifier`, `serializedLayout`, `isFloatingInspector` | Many:1 to `Session`. |
| `SessionBookmarkDiff` | Tracks transient bookmark changes per session for conflict resolution with live annotation data. | `id`, `bookmarkID`, `isRemoved`, `noteDelta` | Many:1 to `SessionFile`; optional link to `Bookmark`. |

- `File` remains the canonical entity for media URLs, avoiding duplication while letting `SessionFile` express ordering and per-session UI state.
- Future parse snapshots can be serialized as binary blobs or JSON inside `Session` or a dedicated `SessionSnapshot` entity once streaming persistence requirements stabilize; the schema above leaves room for that extension without touching annotations again.
- Multi-device syncing can layer on top of the `Workspace` metadata by storing a UUID that later feeds iCloud/CoreData CloudKit mirroring when prioritized.

## 🔄 Migration Strategy

1. **Introduce explicit model versions:** Wrap `makeModel()` in a `ModelVersion` enum so the current schema becomes `v1`. The migration build for Task E3 adds a `v2` method with new entities and updates the persistent container to load the latest version while exposing previous versions for mapping.【F:Sources/ISOInspectorApp/Annotations/CoreDataAnnotationBookmarkStore.swift†L17-L209】
1. **Leverage lightweight migration:** Because the new entities only add tables and relationships without altering
   existing columns, CoreData can infer the mapping as long as entity and relationship names remain stable. Automated
   migration stays enabled through the existing store description
   flags.【F:Sources/ISOInspectorApp/Annotations/CoreDataAnnotationBookmarkStore.swift†L30-L39】
1. **Seed workspace rows:** On first launch after migration, insert a default `Workspace` and mark the active session. This work should run inside a background context transaction alongside annotation/bookmark fetches to avoid blocking the UI.
1. **Fallback/export support:** When CoreData is unavailable (Linux builds) or migration fails, persist session metadata
   via the existing JSON exporter pattern used before the CoreData upgrade, writing a sidecar file next to the SQLite
   store so CLI workflows still have deterministic
   behavior.【F:DOCS/TASK_ARCHIVE/33_C4_CoreData_Annotation_Persistence/2025-10-10-coredata-annotation-bookmark-store.md†L1-L24】
1. **Manual recovery path:** Document a one-time export/import utility that converts pre-migration annotations to the new schema by reading `Annotation`/`Bookmark` rows and synthesizing default session records. This tool doubles as a debugging aid if automatic migration ever fails.

## 🧪 Test & Documentation Updates

- Extend `AnnotationBookmarkStoreTests` with fixtures that pre-populate a v1 store, run the migration path, and assert that annotations/bookmarks remain intact while new session tables receive default values.【F:Tests/ISOInspectorAppTests/AnnotationBookmarkStoreTests.swift†L1-L106】
- Add new XCTest coverage for session persistence APIs (e.g., `SessionStoreTests`) once Task E3 introduces them, ensuring order indices, layout payloads, and bookmark diffs round-trip correctly.
- Update DocC (`InterfaceOverview`) and the App manual to explain how workspace restoration now covers open files and window layouts in addition to annotations.【F:Sources/ISOInspectorApp/ISOInspectorApp.docc/Articles/InterfaceOverview.md†L20-L41】【F:Docs/Manuals/App.md†L7-L18】
- Capture new workflow steps in the developer README or onboarding docs so contributors understand the migration tooling
  and fallback paths.

## ❓ Open Questions & Dependencies

- **Concurrency model:** Should session writes occur on the same private queue context as annotations, or does Task E3 require an `NSPersistentContainer` with multiple child contexts to coordinate UI state updates? Clarify to prevent deadlocks during multi-window edits.【F:Sources/ISOInspectorApp/Annotations/CoreDataAnnotationBookmarkStore.swift†L40-L73】
- **Cross-platform storage directory:** Session persistence needs a shared directory accessible to both the app sandbox and future command-line utilities; confirm whether the existing `Application Support` path suffices or if a user-configurable location is required.【F:Sources/ISOInspectorApp/ISOInspectorApp.swift†L21-L45】
- **Parse snapshot format:** Decide whether parse results are stored as binary blobs inside CoreData or as external files referenced by `SessionFile`. The answer affects whether the migration remains lightweight or needs custom mapping for large payloads.
- **Cloud sync roadmap:** If CloudKit mirroring is planned, validate that new entities include stable primary keys and
  change tracking metadata before Task E3 cements the schema.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
