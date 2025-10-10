# ISOInspector App Manual (Draft)

The ISOInspector SwiftUI application will provide interactive MP4/QuickTime inspection per the product requirements. This draft ties future work to tasks C1–C5 and E1–E4 of the execution workplan.

## Current State
- SwiftUI entry point renders the parse tree explorer with detail pane, live payload
  annotations, and CoreData-backed notes/bookmark controls.
- Linux-compatible fallback prints the same welcome summary for developers without SwiftUI.
- Annotation and bookmark persistence runs through
  `CoreDataAnnotationBookmarkStore`. The detail pane now exposes bookmarking,
  note creation/editing, and deletion for the selected box; outline rows
  display bookmark toggles that sync instantly with the store.

## Planned Features
1. Document browser and recent files list (E1).
2. Streaming tree and detail panes (C1–C3).
3. Annotation and bookmark persistence (C4) — live in-app editing is now
   available; future work covers synchronization with additional sessions.
4. Accessibility compliance and keyboard navigation (C5).
5. Distribution readiness including entitlements and notarization (E4).

Update this manual with screenshots, workflows, and troubleshooting notes as features land.
