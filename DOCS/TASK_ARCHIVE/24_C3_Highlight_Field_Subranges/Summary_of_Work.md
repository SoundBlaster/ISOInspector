# Summary of Work — 2025-10-09

## Completed

- Unblocked ParseTree preview data by exposing `BoxHeader`'s memberwise initializer so SwiftUI previews compile in ISOInspectorApp. 【F:Sources/ISOInspectorKit/ISO/BoxHeader.swift†L1-L24】
- Added coverage ensuring preview sample snapshots build valid headers from outside the Kit module.

  【F:Tests/ISOInspectorAppTests/ParseTreePreviewDataTests.swift†L1-L13】

- Introduced a random-access payload annotation provider that surfaces `ftyp` and `mvhd` field ranges for UI highlights with regression coverage. 【F:Sources/ISOInspectorApp/Detail/RandomAccessPayloadAnnotationProvider.swift†L1-L204】【F:Tests/ISOInspectorAppTests/RandomAccessPayloadAnnotationProviderTests.swift†L1-L98】
- Refreshed the detail pane to list selectable annotations and render a synchronized hex grid with interactive byte
  selection. 【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L1-L403】
- Expanded `ParseTreeDetailViewModel` to orchestrate annotation loading, selection state, and highlighted ranges shared with the hex viewer. 【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailViewModel.swift†L1-L163】

## Notes

- All tests run with `swift test`. 【9e8713†L1-L120】
