# Summary of Work — 2025-10-25

## Completed Tasks
- **T3.1 — Tolerant Parsing Warning Ribbon**
  - Published tolerant parsing metrics from `ParseTreeStore` and reset them with document lifecycle events so SwiftUI overlays can react without polling.
  - Introduced the `CorruptionWarningRibbon` component with persisted dismissal state, accessible copy, and hooks into `DocumentSessionController.focusIntegrityDiagnostics()`.
  - Updated `AppShellView` to layer the ribbon above the navigation split view, animate presentation, and reset the dismissal flag when no issues remain.
  - Added Combine-driven unit coverage in `ParseTreeStoreTests` plus host-based validation in `AppShellViewErrorBannerTests` for the new overlay text.

## Verification
- `swift test`

## Follow-Up
- Future Integrity tab navigation can reuse `DocumentSessionController.focusIntegrityDiagnostics()` once the diagnostics surface ships.
