# Summary of Current Work — 2025-10-25

## Completed
- **T3.1 — Tolerant Parsing Warning Ribbon** (archived in `DOCS/TASK_ARCHIVE/185_T3_1_Tolerant_Parsing_Warning_Ribbon/`)
  - Bound `ParseTreeStore` to the tolerant parsing issue metrics stream and reset counters during lifecycle events.
  - Added the `CorruptionWarningRibbon` SwiftUI component with persisted dismissal state and accessibility copy.
  - Updated `AppShellView` and `DocumentSessionController` to present the ribbon, animate transitions, and focus the first affected node when tapped.
  - Expanded test coverage with new Combine and host-based UI assertions for ribbon presentation.

## Verification
- `swift test`

## Follow-Ups
- Await Integrity tab implementation to hook into `DocumentSessionController.focusIntegrityDiagnostics()` for richer navigation.
