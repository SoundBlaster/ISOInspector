# Summary of Work — 2025-10-16

## Completed tasks

- Designed the bookmark persistence schema and created `BookmarkPersistenceStore` so recents/session snapshots can reference canonical security-scoped bookmarks. See `DOCS/INPROGRESS/2025-10-16-bookmark-persistence-schema.md` for design notes.
- Updated the macOS CI workflow to pin Tuist installation to the newest CLI release, avoiding 404 errors when
  server-only tags are published.

## Implementation notes

- Added `BookmarkPersistenceStore` with versioned JSON format and resolution tracking.
- Extended `DocumentRecent`, `WorkspaceSessionFileSnapshot`, and CoreData session persistence to carry bookmark identifiers without breaking existing JSON/CoreData data.
- Introduced `BookmarkPersistenceStoreTests` and refreshed recents/session persistence tests to exercise the new schema.

## Verification

- `swift test`
- GitHub macOS workflow now resolves Tuist CLI tags instead of server releases.

## Follow-ups

- Wire `BookmarkPersistenceStore` into recents and session controllers so bookmark identifiers persist from the shared store (`@todo` PDD:45m).
