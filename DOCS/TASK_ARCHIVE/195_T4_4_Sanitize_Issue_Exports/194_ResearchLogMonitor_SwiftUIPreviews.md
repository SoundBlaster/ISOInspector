# Integrate ResearchLogMonitor Audit with SwiftUI Previews (2025-10-27 Refresh)

> Earlier investigation notes are archived in `DOCS/TASK_ARCHIVE/194_T4_2_Plaintext_Issue_Export_Closeout/194_ResearchLogMonitor_SwiftUIPreviews.md`.

## 🎯 Objective
Ensure SwiftUI preview scenarios that render VR-006 research log data execute `ResearchLogMonitor.audit` so schema drift, missing fixtures, and empty payloads are surfaced during design-time validation.

## 📌 Immediate Focus
- Thread `ResearchLogPreviewProvider` snapshots through preview compositions so diagnostics appear alongside sample payloads.
- Back previews with canonical VR-006 fixtures plus mismatch/missing variants for regression visibility.
- Document the refresh process for preview fixtures when schema fields change to keep designers unblocked.

## 🔗 References
- [`todo.md`](../../todo.md)
- [`Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift`](../../Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift)
- [`Sources/ISOInspectorKit/Support/ResearchLogPreviewProvider.swift`](../../Sources/ISOInspectorKit/Support/ResearchLogPreviewProvider.swift)
