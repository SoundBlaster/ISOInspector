# Summary of Work

## Completed Tasks

- **G6 — Export JSON Actions:** Added document-wide and selection-scoped JSON export controls across the toolbar, command menu, and outline context menu while wiring them to the shared exporter pipeline in `DocumentSessionController`.【F:Sources/ISOInspectorApp/AppShellView.swift†L5-L116】【F:Sources/ISOInspectorApp/ISOInspectorApp.swift†L1-L71】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L1-L460】【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L1-L720】

## Implementation Notes

- DocumentSessionController now orchestrates JSON exports through FilesystemAccessKit with contextual filenames and
  status alerts surfaced back to the UI.【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L1-L720】
- UI affordances remain in sync via shared selection state so toolbar and context menu availability mirror command
  menus.【F:Sources/ISOInspectorApp/AppShellView.swift†L5-L116】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L1-L460】
- Added unit coverage validating exporter output and selection gating logic for the new
  flows.【F:Tests/ISOInspectorAppTests/DocumentSessionControllerTests.swift†L1-L560】
- Extended regression tests assert failure messaging and diagnostics when the selected node
  disappears or the save dialog fails, preventing silent export regressions.【F:Tests/ISOInspectorAppTests/DocumentSessionControllerTests.swift†L454-L520】

## Tests

- `swift test --target ISOInspectorAppTests`
