# 04 Integrate ResearchLogMonitor with SwiftUI Previews

## 🎯 Objective

Create SwiftUI preview scaffolding that runs `ResearchLogMonitor.audit(logURL:)` against representative VR-006 research log samples so UI components can validate schema alignment before binding live parse events.

## 🧩 Context

- Backlog item `todo.md #4` tracks the SwiftUI preview integration work.
  - Source: 【F:todo.md†L11-L12】
- The active next-task list calls for wiring the audit helper into SwiftUI previews so VR-006 bindings stay aligned.
  - Source: 【F:DOCS/INPROGRESS/next_tasks.md†L1-L5】
- VR-006 monitoring checklist keeps SwiftUI preview integration as the remaining pre-UI milestone.
  - Source: 【F:DOCS/TASK_ARCHIVE/15_Monitor_VR006_Research_Log_Adoption/VR006_Monitoring_Checklist.md†L5-L28】
- The audit helper and CLI schema banner already ship together, so previews must match the shared schema metadata.
  - Source: 【F:DOCS/TASK_ARCHIVE/15_Monitor_VR006_Research_Log_Adoption/VR006_Monitoring_Checklist.md†L5-L28】
- `ResearchLogMonitor.swift` exposes the schema metadata and audit logic, including TODO markers for this integration, so previews must exercise it without diverging from the shared schema definition.
  - Source: 【F:Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift†L3-L85】
- Upcoming SwiftUI surfaces will bind parse output and validation issues per the product backlog, requiring consistent
  research log metadata when analysts review unknown boxes.
  - Sources:
    【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L110-L140】【F:DOCS/TASK_ARCHIVE/15_Monitor_VR006_Research_Log_Adoption/15_Monitor_VR006_Research_Log_Adoption.md†L1-L58】

## ✅ Success Criteria

- SwiftUI previews load a deterministic VR-006 research log fixture, invoke `ResearchLogMonitor.audit`, and render the results (schema version, field names, entry counts) without runtime errors.
- Preview failure cases (missing file, schema mismatch) surface developer-facing diagnostics that mirror CLI
  expectations, preventing silent drift between surfaces.
- Documentation and inline preview guidance point to the shared schema source so UI engineers can update fixtures
  alongside schema changes.
- Tests or preview assertions prevent regressions by ensuring the audit call stays wired into the preview pipeline
  during future UI work.

## 🔧 Implementation Notes

- Reuse existing CLI fixtures or craft a minimal JSON sample under app resources to exercise the audit helper, matching
  the VR-006 schema fields and version.
  - Sources:
    【F:DOCS/TASK_ARCHIVE/15_Monitor_VR006_Research_Log_Adoption/VR006_Monitoring_Checklist.md†L30-L38】【F:Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift†L3-L85】
- Provide preview-only adapters (e.g., `PreviewResearchLogProvider`) that locate or synthesize the log file, allowing multiple UI previews to share the same audit result while remaining deterministic.
- Capture guidance in code comments or developer docs referencing the monitoring checklist so future work on telemetry
  (next-task follow-up) knows where to hook in once UI smoke tests exist.
  - Source: 【F:DOCS/TASK_ARCHIVE/15_Monitor_VR006_Research_Log_Adoption/VR006_Monitoring_Checklist.md†L22-L28】
- Coordinate with upcoming UI state stores and parse pipelines described in the PRD to ensure the preview scaffolding
  aligns with planned view models and validation issue bindings.
  - Source: 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L110-L140】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/INPROGRESS/next_tasks.md`](./next_tasks.md)
- [`todo.md`](../../todo.md)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
