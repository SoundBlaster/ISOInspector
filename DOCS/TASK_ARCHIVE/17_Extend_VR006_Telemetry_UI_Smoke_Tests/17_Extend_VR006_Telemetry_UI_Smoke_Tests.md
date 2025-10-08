# Extend VR-006 Telemetry Coverage in UI Smoke Tests

## 🎯 Objective

Bring VR-006 research log telemetry into the UI smoke test suite so automated runs surface missing or malformed
research log entries for both CLI and SwiftUI consumers, satisfying `todo.md #5`.

## 🧩 Context

- `todo.md` still tracks backlog item `#5` to emit telemetry during UI smoke tests for VR-006 research log coverage.

  Aligning with that TODO closes the remaining monitoring gap. 【F:todo.md†L11-L12】

- `DOCS/INPROGRESS/next_tasks.md` carries forward the directive to extend telemetry once UI smoke tests exist so

  CLI and UI surfaces stay in sync. 【F:DOCS/INPROGRESS/next_tasks.md†L1-L5】

- `ResearchLogMonitor` now enforces schema expectations and documents TODOs for SwiftUI previews and smoke test

  telemetry, providing the API surface this task must exercise.
【F:Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift†L1-L43】

- The VR-006 monitoring checklist highlights telemetry dashboards during UI smoke tests as the outstanding

  milestone after preview integration.
【F:DOCS/TASK_ARCHIVE/15_Monitor_VR006_Research_Log_Adoption/VR006_Monitoring_Checklist.md†L1-L18】

- SwiftUI previews already audit fixtures via `ResearchLogPreviewProvider`, meaning smoke tests can reuse the same

  audit helpers and diagnostics pipeline. 【F:Sources/ISOInspectorKit/Support/ResearchLogPreviewProvider.swift†L1-L78】

## ✅ Success Criteria

- UI smoke tests execute at least one end-to-end parse scenario that writes VR-006 research log entries and emits

  telemetry events or assertions when entries are missing, empty, or schema-incompatible.

- CLI telemetry hooks (e.g., log writers or diagnostics) are exercised in the same smoke suite so both surfaces

  emit consistent VR-006 coverage data.

- Test failures clearly identify whether the research log was absent, empty, or schema drifted, mirroring

  `ResearchLogMonitor.Error.schemaMismatch` messaging.

- Documentation or inline comments link the smoke test telemetry to `todo.md #5` and the VR-006 monitoring

  checklist so future contributors maintain the instrumentation.

## 🔧 Implementation Notes

- Reuse `ResearchLogPreviewProvider` snapshots to seed deterministic fixtures and compare telemetry output against

  the shared schema expectations baked into `ResearchLogSchema`. 【F:Sources/ISOInspectorKit/Support/ResearchLogPreviewProvider.swift†L20-L78】

- Decide whether telemetry should be surfaced via `DiagnosticsLogger`, `os_signpost`, or explicit XCTest

  assertions, ensuring the smoke tests fail fast when VR-006 events are missing.

- Ensure the smoke tests cover both CLI (`isoinspect inspect`) and SwiftUI pathways, potentially by sharing a

  helper that inspects the persisted research log and emits telemetry counts.

- Update or create developer documentation so engineers know how to interpret the telemetry output locally and in

  CI dashboards when VR-006 coverage regresses.

---

## ✅ Completion Notes (2025-10-08)

- Added `ResearchLogTelemetryProbe` and `ResearchLogTelemetrySnapshot` to translate audits into CLI/SwiftUI smoke telemetry diagnostics.
- Implemented `ResearchLogTelemetrySmokeTests` covering missing, empty, schema mismatch, and healthy VR-006 scenarios via `ParsePipeline.live`, satisfying `todo.md #5`.
- Updated `todo.md` and archived monitoring summaries to reflect completed UI telemetry coverage.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
