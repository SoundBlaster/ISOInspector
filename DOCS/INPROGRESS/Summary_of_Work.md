# Summary of Work — 2025-12-12

## Completed Tasks
- **Bug #234 – Remove Recent File from Sidebar**: Added context menu and iOS swipe actions for per-entry removal, exposed `removeRecent(_:)` in the controller, and ensured MRU persistence updates when entries are deleted.

## Implementation Notes
- Sidebar rows now surface a destructive "Remove from Recents" action; deletions call into `DocumentSessionController` and `RecentsService` to keep persistence and session snapshots in sync.
- Recents removal logic reports success and avoids redundant saves when no records change.

## Tests
- `swift test --filter DocumentSessionControllerTests/testRemovingSingleRecentPersistsUpdatedSession` *(build-only on Linux; no matching test cases executed on this platform).* 

## Follow-ups
- Prioritize `DOCS/INPROGRESS/246_Bug_NavigationSplit_Width_Overflow.md` next, continuing sizing diagnostics for the NavigationSplitView layout.
