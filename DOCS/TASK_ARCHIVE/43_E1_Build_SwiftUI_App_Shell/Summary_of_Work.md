# Summary of Work

## Completed tasks

- **E1 — Build SwiftUI App Shell**
  - Added a `DocumentSessionController` that coordinates `ParseTreeStore`, annotation sessions, and a persisted `DocumentRecentsStore` with security-scoped bookmarks.
  - Replaced the previous single-screen `ContentView` with `AppShellView`, providing a navigation split interface with onboarding, recents management, and file import handling for MP4/QuickTime sources.
  - Persist recents to `Application Support/DocumentRecents` and hydrate them on launch, including bookmark refresh for stale entries.

## Tests and validation

- `swift test`

## Documentation

- Added micro PRD note: [`2025-10-12-app-shell.md`](./2025-10-12-app-shell.md).

## Follow-up puzzles

- Surface document load failures in the app shell UI once design for error banners lands. (PDD:30m)
- Surface recents persistence failures in diagnostics once logging pipeline is available. (PDD:30m)
- Implement session persistence (Task E3) once CoreData workspace restoration plan is ready. (#11)
