# CoreData annotation persistence upgrade — micro PRD

## Intent

Replace the JSON-based annotation/bookmark storage spike with the CoreData schema decided in R6 so the app can persist
notes across sessions.

## Scope

- Kit: None
- CLI: None
- App: `CoreDataAnnotationBookmarkStore`, `AnnotationBookmarkStoreTests`, DocC & manual notes for persistence

## Integration contract

- Public Kit API added/changed: None
- Call sites updated: Storage tests switched to instantiate the CoreData store (guarded by `canImport(CoreData)` for Linux CI).
- Backward compat: Records persist in SQLite; JSON spike is removed. Stub fallback throws `.featureUnsupported` on platforms without CoreData.
- Tests: `Tests/ISOInspectorAppTests/AnnotationBookmarkStoreTests.swift`

## Next puzzles

- [ ] Surface annotation/bookmark editing UI that uses the new store and updates view models live.
- [ ] Evaluate CoreData schema migrations once session persistence (E3) introduces additional entities.

## Notes

Build: `swift test`
