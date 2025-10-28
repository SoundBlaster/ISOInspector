# T3.6 — Integrity Summary Tab — Post-Launch Follow-Ups

> Historical planning notes and the implementation summary were archived in `DOCS/TASK_ARCHIVE/196_T3_6_Integrity_Summary_Tab/T3_6_Integrity_Summary_Tab.md` and `DOCS/TASK_ARCHIVE/196_T3_6_Integrity_Summary_Tab/T3_6_Summary_of_Work.md`.

## 🎯 Objective

Triage the polish items that landed during the Integrity tab release so the table interactions, sorting refinements, and exporter hooks stay aligned with ribbon metrics and DocumentSession navigation.

## 🔄 Outstanding Refinements

- **Sorting polish (`#T36-001`, `#T36-002`):** finalize offset/node sorting behavior so deterministic ordering matches CLI exports on large fixture sets.
- **Navigation cue review (`#T36-003`):** confirm that focusing an issue row restores the Explorer tab selection reliably after recent state store refactors.
- **Metrics health check:** spot-audit ribbon versus tab counts after tolerance parsing fixture regenerations to ensure regressions surface quickly.

## ✅ Verification Targets

- Re-run `swift test --filter IntegritySummaryViewTests` once the sorting refinements ship to validate the updated ordering expectations.
- Extend UI automation coverage to confirm severity filtering keeps outline badges synchronized.
- Capture before/after exports for corrupt fixtures (`Tests/Fixtures/Corrupt/*`) to guarantee plaintext/JSON summaries still match the table counts.

## 📌 Next Actions

1. Audit the `@todo` markers in `Sources/ISOInspectorApp/Integrity/IntegritySummaryView.swift` and `IntegritySummaryViewModel.swift`, translating each into discrete follow-up tasks for the backlog.
2. Coordinate with design to confirm the final filter/button layout before freezing automation screenshots.
3. Draft acceptance criteria for T3.7 (issue navigation filters) based on the backlog guidance in `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`.
