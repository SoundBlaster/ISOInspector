# InterfaceOverview

ISOInspectorApp presents parsed MP4 data through a split-view layout:

- **Outline** — Shows the hierarchical box tree with filters for metadata,
  streaming, and category tags synchronized with ISOInspectorKit's metadata.
- **Details** — Displays parsed fields, validation messages, and research log
  annotations for the selected node.
- **Hex viewer** — Highlights byte ranges and allows copying offsets for deeper
  investigations.

The app reuses the same streaming pipeline as the CLI, ensuring validation and
export results stay consistent across experiences. SwiftUI previews and telemetry
hooks keep the research log surfaces aligned with VR-006 requirements described in
the execution guide.

## Annotation & Bookmark Persistence

- User-authored annotations and bookmark selections persist between launches via
  a CoreData-backed store (`CoreDataAnnotationBookmarkStore`). Records are keyed
  to the canonical file URL so multiple sessions on the same asset share notes.
- The persistence layer is synchronous and designed for SwiftUI previews and
  unit tests. It performs all writes on a private queue context and exposes
  plain `AnnotationRecord` / `BookmarkRecord` values for view models. The SwiftUI
  detail pane now surfaces bookmark toggles and a note editor backed by this
  store, keeping UI state synchronized with persisted records.

## Extending the app

- Add new filters or inspectors only after the necessary parsing support exists
  in ISOInspectorKit (see `Sources/ISOInspectorKit/ISOInspectorKit.docc`).
- Propagate CLI capabilities into the UI when they affect validation or export
  behavior to keep workflows consistent (see `Sources/ISOInspectorCLI/ISOInspectorCLI.docc`).
- Leave focused `@todo` notes for follow-up UI polish and reference them from the
  task summary in `DOCS/INPROGRESS`.
