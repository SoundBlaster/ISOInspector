# Summary of Work — 2025-10-09

## Completed

- Unblocked ParseTree preview data by exposing `BoxHeader`'s memberwise initializer so SwiftUI previews compile in ISOInspectorApp. 【F:Sources/ISOInspectorKit/ISO/BoxHeader.swift†L1-L24】
- Added coverage ensuring preview sample snapshots build valid headers from outside the Kit module.
  【F:Tests/ISOInspectorAppTests/ParseTreePreviewDataTests.swift†L1-L13】

## Notes

- Highlight field subrange syncing (#7) still pending; existing `@todo` marker remains in `ParseTreeDetailView`. 【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L143-L168】
- All tests run with `swift test`. 【aed472†L1-L91】
