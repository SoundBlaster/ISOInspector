# Integrate ResearchLogMonitor Audit with SwiftUI Previews

## 🎯 Objective
Ensure SwiftUI preview scenarios that render VR-006 research log data execute `ResearchLogMonitor.audit` so schema drift, missing fixtures, and empty payloads are surfaced during design-time validation.

## 🧩 Context
- `ResearchLogMonitor.audit` currently audits VR-006 research logs for schema conformance but is not yet wired into the preview-facing data flow. TODO marker `#4` in `Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift` calls out the integration gap.
- `ResearchLogPreviewProvider` synthesizes deterministic snapshots for previews and already depends on `ResearchLogMonitor.audit` for fixture validation; the UI layer still needs to consume these snapshots and surface diagnostics in preview compositions.
- `todo.md` item `#4` tracks this follow-up so previews highlight VR-006 telemetry issues alongside live app surfaces.

## ✅ Success Criteria
- SwiftUI previews that display VR-006 research log information load diagnostics from `ResearchLogPreviewProvider` and present ready/missing/schema-mismatch states without runtime failures.
- Preview bundles include the canonical `VR006PreviewLog` fixture plus representative missing and mismatch variants so schema drift is caught.
- Inline documentation (DocC or preview annotations) instructs contributors how to refresh fixtures when schema fields change.

## 🔧 Implementation Notes
- Extend preview compositions in the relevant UI modules to bind against `ResearchLogPreviewProvider` snapshots and render status messaging.
- Add lightweight unit or snapshot coverage (if feasible) to guarantee previews continue invoking the audit helper when fixtures change.
- Coordinate with telemetry probes (`ResearchLogTelemetryProbe`) to keep shared messaging aligned between previews, CLI diagnostics, and smoke tests.

## 🧠 Source References
- [`todo.md`](../../todo.md)
- [`Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift`](../../Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift)
- [`Sources/ISOInspectorKit/Support/ResearchLogPreviewProvider.swift`](../../Sources/ISOInspectorKit/Support/ResearchLogPreviewProvider.swift)
