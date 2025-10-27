# T4.4 — Sanitize Tolerant Parsing Issue Exports

## 🎯 Objective
Guarantee that every tolerant-parsing export format (JSON, plaintext, and future variants) omits raw binary payloads while still conveying enough metadata for debugging so shared reports are safe to distribute.

## 🧩 Context
- Phase T4 of the tolerance roadmap focuses on diagnostics exports. Tasks T4.1 and T4.2 already extended the JSON schema and shipped the plaintext issue summary. This follow-up closes the privacy audit requirement described in the tolerance workplan by ensuring no exporter emits raw hexdumps or payload slices. 【F:DOCS/AI/Tolerance_Parsing/TODO.md†L132-L176】
- Current exporters live in `Sources/ISOInspectorKit/Export/` (e.g., `ParseEventCapturePayload.swift` and `PlaintextIssueSummaryExporter.swift`). They collect byte ranges for issues, and any lingering helpers may still capture payload fragments from earlier prototypes.
- The Master PRD emphasises privacy-conscious exports: diagnostics must remain safe for sharing outside the originating environment. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L112-L176】

## ✅ Success Criteria
- JSON and plaintext issue exports contain only metadata (counts, severities, byte ranges, identifiers) and never embed raw byte arrays, hexdumps, or base64 payloads.
- Automated tests (unit or snapshot) assert that exporters redact payload data when issues include cached byte buffers.
- Documentation for tolerant parsing exports explicitly states that binary content is excluded and references the sanitisation guarantee.

## 🔧 Implementation Notes
- Audit `ParseEventCapturePayload` and related DTOs to ensure `ParseIssuePayload` ignores any binary attachments, and enforce this by stripping or rejecting such fields during encoding.
- Update `PlaintextIssueSummaryExporter` (and any CLI bridge formatting) to elide payload previews while still including offset ranges and diagnostic codes.
- Extend exporter-focused tests in `Tests/ISOInspectorKitTests` to cover issues that previously included `Data` payloads, confirming sanitised output.
- Update DocC or README sections covering exports to mention the privacy guardrails once code changes land.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Relevant archives in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
