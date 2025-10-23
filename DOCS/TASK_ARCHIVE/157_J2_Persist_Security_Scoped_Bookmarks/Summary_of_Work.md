# Summary of Work — 2025-10-23

## Completed tasks
- **J2 — Persist Security-Scoped Bookmarks**: Updated `FilesystemAccess.resolveBookmarkData` to annotate audit events with persisted bookmark identifiers and ensure failures still redact paths while retaining ledger context.【F:Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccess.swift†L60-L109】 Document session restoration now passes bookmark identifiers into FilesystemAccessKit, refreshes stale records with new data, and removes failed ledger entries so recents stay accurate across launches.【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L566-L683】
- **Documentation refresh**: Extended the app manual with bookmark recovery behavior and expanded the CLI sandbox guide with ledger-aware audit logging so operators can correlate `bookmark_id` output with stored credentials.【F:Documentation/ISOInspector.docc/Manuals/App.md†L28-L33】【F:Documentation/ISOInspector.docc/Guides/CLISandboxProfileGuide.md†L73-L90】

## Verification
- `swift test --disable-sandbox`

## Follow-ups
- None. The bookmark ledger now restores valid entries automatically and surfaces stale failures via hashed audit logs.
