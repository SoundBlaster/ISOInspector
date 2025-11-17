# Bug Report 234: Remove Recent File from Sidebar

## Objective
Document the missing affordance for deleting an entry from the Recent Files section in the sidebar so that the UX team can scope, implement, and verify the feature without touching code yet.

## Symptoms
- Users can open files which adds them to the Recent Files list in the sidebar.
- There is no context menu item or inline affordance to remove an accidental or obsolete entry.
- The list can therefore become cluttered and may expose sensitive filenames longer than necessary.

## Environment
- ISOInspector desktop build (macOS) per current main branch.
- Sidebar component (likely SwiftUI) that renders the “Recent Files” collection.

## Reproduction Steps
1. Launch ISOInspector.
2. Open multiple ISO/Box files so they appear under Recent Files in the sidebar.
3. Attempt to remove one of the entries via right-click, keyboard shortcut, or toolbar.

## Expected vs. Actual
- **Expected:** There is a way to remove or hide a selected recent file entry (context menu option, delete key, or dedicated button) without clearing the entire history.
- **Actual:** No removal interaction exists, so the entry persists until global history reset or cache purge.

## Open Questions
- Should removal also delete on-disk MRU cache or simply hide entry for current session?
- Do we need an undo or confirmation prompt?
- Are there analytics or telemetry implications when removing entries?

## Scope & Hypotheses
- Front of work: Sidebar UI state management (likely `RecentFilesView` and persistence layer storing recents).
- We likely need to add gesture handlers and update persistence store to support deletion of individual entries.
- Tests should cover MRU store updates and UI state refresh.

## Diagnostics Plan
1. Inspect the recent files persistence implementation (search for `RecentFileStore` or `RecentDocuments` in `Sources`).
2. Confirm whether deletions are supported by the data layer but simply not exposed in UI.
3. Add debug logging to ensure the deletion message is dispatched when the UI action fires (later during implementation).

## TDD Testing Plan
- Unit test for the MRU store verifying `remove(id:)` removes an entry and updates ordering.
- UI snapshot or SwiftUI unit test ensuring the context menu exposes a “Remove from Recent” action.
- Integration test verifying the sidebar refreshes without requiring app restart.

## PRD Update
- **Customer Impact:** Power users and security-conscious operators need control over MRU entries to avoid clutter and potential data exposure.
- **Acceptance Criteria:** From the sidebar, a user can remove a selected recent file using an accessible action; list updates immediately and persists across launches; no accidental removal of other entries.
- **Technical Approach:** Add a delete action in the sidebar row, wire it to the MRU store, persist change.

## Status
Planning complete; pending assignment for implementation according to BUG workflow instructions.
