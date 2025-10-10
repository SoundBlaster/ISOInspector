# F1 — Develop Automated Test Fixtures

## 🎯 Objective

Establish an automated corpus of MP4/QuickTime sample files (well-formed and malformed) so parser, validation, and
export suites can exercise every planned failure mode.

## 🧩 Context

- The execution workplan calls for a High-priority fixture effort that depends on the completed box parsing pipeline and
  decoder groundwork. 【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L47-L54】
- The PRD backlog outlines the specific formats and edge cases the corpus must cover, ensuring real-world coverage for
  streaming, metadata-heavy, and intentionally corrupted files. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L226-L230】

## ✅ Success Criteria

- Fixture set includes baseline MP4, MOV, fragmented MP4, DASH init/media, oversized `mdat`, and multiple malformed/truncated variations documented in the backlog. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L226-L229】
- Each fixture carries machine-readable metadata (e.g., description, expected validation outcome) consumed by automated
  tests. 【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L47-L54】
- Continuous integration can download or generate fixtures on demand without manual intervention, keeping `swift test` deterministic.

## 🔧 Implementation Notes

- Leverage existing parsing/validation infrastructure from phases B3–B5 when authoring fixture expectations to avoid
  duplicating logic. 【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L20-L37】
- Favor scripted generation for malformed variants to guarantee reproducibility and ease of extension; document
  generator parameters alongside the files. 【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L47-L54】
- Coordinate naming and storage layout with forthcoming export and documentation tasks so fixtures double as DocC and
  CLI examples. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L226-L229】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
