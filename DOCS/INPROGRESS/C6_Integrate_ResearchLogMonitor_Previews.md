# C6 — Integrate ResearchLogMonitor Audit Results into SwiftUI Previews

## 🎯 Objective

Ensure SwiftUI previews for the research log diagnostics surface execute `ResearchLogMonitor.audit` against the curated VR-006 fixtures so schema drift and missing assets are caught during design-time preview rendering.

## 🧩 Context

- Execution workplan task **C6** calls for wiring `ResearchLogMonitor` outputs into SwiftUI previews so VR-006 auditing remains visible to UI contributors without running the full app. It depends on the completed validation rules (Task B5) and the detail/hex UI foundation (Task C3).
- `ResearchLogPreviewProvider` already exposes helpers that drive ready/missing/schema mismatch states for deterministic fixtures, while `ResearchLogAuditPreview` renders the diagnostics UI including accessibility identifiers for automation.
- Previous VR-006 efforts (Tasks 14–17) established the shared research log schema, audit utilities, and automation
  coverage. This task extends that pipeline into ongoing preview workflows so future schema updates and fixture
  refreshes surface actionable warnings immediately.

## ✅ Success Criteria

- SwiftUI preview definitions instantiate `ResearchLogAuditPreview` snapshots for the ready, missing fixture, and schema mismatch cases using `ResearchLogPreviewProvider`, ensuring previews render audit metadata without runtime errors.
- Preview rendering surfaces diagnostics text for schema mismatch and missing fixture scenarios that mirrors `ResearchLogMonitor` expectations, keeping VR-006 schema drift visible in design tools.
- Tests cover the preview provider fixtures and accessibility identifiers so the audit previews remain synchronized with
  VR-006 schema and NestedA11yIDs contracts.
- Documentation (DocC tutorials or developer guides) references the preview audit capability so contributors know how to
  validate VR-006 fixtures locally.

## 🔧 Implementation Notes

- Confirm preview fixture bundles (`VR006PreviewLog*.json`) live alongside the SwiftUI preview target and remain synchronized with `ResearchLogSchema.fieldNames`; update generator scripts if schema fields change.
- Extend or validate `ResearchLogPreviewProvider` and `ResearchLogAuditPreview` to emit consistent diagnostics strings and accessibility identifiers for automation tests and DocC snapshots.
- Augment `ResearchLogPreviewProviderTests` and `ResearchLogAccessibilityIdentifierTests` to assert the ready/missing/schema mismatch flows remain stable when previews load audit snapshots.
- Update DocC or README snippets that introduce VR-006 research logging so they highlight the new preview audit entry
  point for contributors.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived VR-006 context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
