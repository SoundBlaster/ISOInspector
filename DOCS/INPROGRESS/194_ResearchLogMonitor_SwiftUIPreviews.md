# Integrate ResearchLogMonitor Audit with SwiftUI Previews — Next Iteration

> Historical discovery notes were archived in `DOCS/TASK_ARCHIVE/196_T3_6_Integrity_Summary_Tab/194_ResearchLogMonitor_SwiftUIPreviews.md` after the 2025-10-28 refresh.

## 🎯 Objective

Ensure SwiftUI preview scenarios that render VR-006 research log data execute `ResearchLogMonitor.audit` so schema drift, missing fixtures, and empty payloads surface during design-time validation.

## 📌 Immediate Focus

- Thread `ResearchLogPreviewProvider` snapshots through preview compositions so diagnostics appear alongside sample payloads.
- Back previews with canonical VR-006 fixtures plus mismatch/missing variants for regression visibility.
- Document the refresh process for preview fixtures when schema fields change to keep designers unblocked.

## 🔍 Open Questions

- What lightweight dependency injection point lets previews call `ResearchLogMonitor.audit` without leaking app-only singletons?
- Can previews surface audit failures using the existing `FoundationUI` banner styles, or is a dedicated preview overlay required?

## 🔗 References

- [`todo.md`](../../todo.md)
- [`Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift`](../../Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift)
- [`Sources/ISOInspectorKit/Support/ResearchLogPreviewProvider.swift`](../../Sources/ISOInspectorKit/Support/ResearchLogPreviewProvider.swift)
- Archived spike notes in `DOCS/TASK_ARCHIVE/16_Integrate_ResearchLogMonitor_SwiftUI_Previews/`
