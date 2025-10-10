# Annotation bookmark store scaffold — micro PRD

## Intent

Persist user-authored annotations and bookmarks between runs using a lightweight JSON store to unblock C4 groundwork.

## Scope

- Kit: None
- CLI: None
- App: `FileBackedAnnotationBookmarkStore`, `AnnotationRecord`, `BookmarkRecord`, `AnnotationBookmarkSession`

## Integration contract

- Public Kit API added/changed: None
- Call sites updated: Pending — detail view models and SwiftUI components still reference providers only.
- Backward compat: Additive scaffolding, not yet wired into UI flows.
- Tests: `Tests/ISOInspectorAppTests/AnnotationBookmarkStoreTests.swift`

## Next puzzles

- [ ] #10 Replace JSON persistence with the selected CoreData schema once R6 finalizes annotation storage requirements.

## Notes

Build: `swift build && swift test`
