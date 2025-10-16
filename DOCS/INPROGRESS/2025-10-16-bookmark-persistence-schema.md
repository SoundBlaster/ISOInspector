# Bookmark persistence schema — micro PRD

## Intent

Design a shared bookmark persistence schema so recents and workspace sessions can reference a single security-scoped
bookmark record.

## Scope

- Kit: `BookmarkPersistenceStore` with versioned JSON format and resolution metadata.
- CLI: No direct changes yet; future integrations will load bookmark identifiers when wiring sandbox profiles.
- App: `DocumentRecent`/`WorkspaceSessionFileSnapshot` updated to track bookmark identifiers and CoreData session persistence mirrors the new field.

## Integration contract

- Public Kit API added/changed: `BookmarkPersistenceStore` and nested `BookmarkPersistenceStore.Record` (new file `Sources/ISOInspectorKit/FilesystemAccess/BookmarkPersistenceStore.swift`).
- Call sites updated: `DocumentSessionController`, CoreData session persistence, recents/session tests.
- Backward compat: Existing JSON/CoreData payloads decode with default `nil` bookmark identifiers; new schema is additive.
- Tests: `BookmarkPersistenceStoreTests` (Kit), updated recents/session persistence tests (`DocumentRecentsStoreTests`, `WorkspaceSessionStoreTests`, `AnnotationBookmarkStoreTests`, `DocumentSessionControllerTests`).

## Next puzzles

- [ ] PDD:45m Wire BookmarkPersistenceStore into recents and session controllers so bookmark identifiers persist from a single source. See inline `@todo` in `BookmarkPersistenceStore` and update CLI/App wiring accordingly.

## Notes

Build: `swift test`

Bookmark persistence records now capture canonical file URLs, resolution state, and timestamps. Recents/session
snapshots carry bookmark identifiers so future phases can drop raw bookmark blobs once the store is wired into load/save
flows.
