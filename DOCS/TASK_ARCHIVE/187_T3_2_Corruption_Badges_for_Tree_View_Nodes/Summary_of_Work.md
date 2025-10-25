# Summary of Work — 2025-10-25

## Completed Tasks
- **T3.2 Corruption Badges for Tree View Nodes**
  - Propagated `ParseIssue` data into `ParseTreeStore` snapshots so outline rows receive per-node corruption context. (`Sources/ISOInspectorApp/State/ParseTreeStore.swift`)
  - Extended `ParseTreeOutlineRow` with a `CorruptionSummary` model and updated the SwiftUI list to render accessible badges with tooltip and VoiceOver support. (`Sources/ISOInspectorApp/Tree/ParseTreeOutlineRow.swift`, `Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift`)
  - Updated outline filters and accessibility helpers to factor in tolerant parsing issues while keeping previews representative. (`Sources/ISOInspectorApp/Tree/ParseTreeOutlineFilter.swift`, `Sources/ISOInspectorApp/Accessibility/AccessibilitySupport.swift`, `Sources/ISOInspectorApp/Tree/ParseTreePreviewData.swift`)
  - Verification: `swift test` (Linux toolchain – Combine-dependent UI tests skipped as expected).【7e1add†L1-L188】

## Follow-ups
- [ ] Continue with T3.3 integrity detail pane per tolerance parsing roadmap (`DOCS/AI/Tolerance_Parsing/TODO.md`).
