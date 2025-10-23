# Summary of Work

## Completed Tasks
- **G7 — State Management View Models**
  - Added `DocumentViewModel` to orchestrate `ParseTreeStore`, track validation badge counts, and surface export availability for the outline/detail flows.【F:Sources/ISOInspectorApp/State/DocumentViewModel.swift†L7-L101】
  - Introduced `NodeSelectionViewModel` and `HexViewModel` to keep selection, annotations, and hex highlights synchronized as the streaming parser mutates the tree.【F:Sources/ISOInspectorApp/State/NodeSelectionViewModel.swift†L1-L59】【F:Sources/ISOInspectorApp/State/HexViewModel.swift†L1-L43】
  - Updated the SwiftUI explorer, app shell, and session controller to depend on the shared document view model so export affordances and toolbar actions stay in sync.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L1-L123】【F:Sources/ISOInspectorApp/AppShellView.swift†L1-L99】【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L34-L101】

## Verification
- `swift test`【6db102†L1-L115】

## Follow-ups
- None; monitor remaining tasks in `DOCS/INPROGRESS/next_tasks.md`.
