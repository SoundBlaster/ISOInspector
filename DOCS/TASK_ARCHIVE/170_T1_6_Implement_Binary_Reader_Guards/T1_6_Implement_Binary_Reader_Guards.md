# T1.6 — Implement Binary Reader Guards

## 🎯 Objective
Ensure the streaming reader clamps all reads to the current parent range and records `truncatedPayload` issues so tolerant parsing can continue without overrunning corrupted payloads.

## 🧩 Context
- Phase T1 of the tolerance initiative transitions the parser into a lenient mode that records corruption instead of aborting; Task T1.6 specifically introduces binary reader guards to enforce parent boundaries and emit truncation diagnostics.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L29-L38】
- The PRD backlog tracks T1.6 as the remaining core resiliency deliverable following the decoder-result refactors, underscoring its importance for resilient parsing workflows.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L260-L268】

## ✅ Success Criteria
- Reader never seeks or reads beyond a node’s declared parent range while tolerant parsing is enabled.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L29-L38】
- `ParseIssue` entries with a `truncatedPayload` (or equivalent) code are emitted whenever payload bytes run short, capturing the offending byte range for downstream consumers.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L29-L38】
- Strict mode behaviour remains unchanged: the reader still throws on overflow while tolerant mode records issues and continues traversal.【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L60-L82】

## 🔧 Implementation Notes
- Update `StreamingBoxWalker` (and any helper readers) to track `currentOffset`/`parentRange.upperBound`, clamping skips to the parent end when decoder failures occur in tolerant mode.【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L60-L82】
- Emit `ParseIssue` payloads using the existing construction pattern that records severity, byte ranges, and reason codes when a box declares more bytes than remain.【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L153-L171】
- Extend regression coverage with corrupt fixtures to verify the tolerant pipeline resumes parsing after truncation while strict mode still fails early (coordinate with future T5 fixture work as needed).【F:DOCS/AI/Tolerance_Parsing/TODO.md†L29-L38】

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/Tolerance_Parsing`](../AI/Tolerance_Parsing)
