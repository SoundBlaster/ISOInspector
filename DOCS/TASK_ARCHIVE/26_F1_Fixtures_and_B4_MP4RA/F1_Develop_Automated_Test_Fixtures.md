# F1 — Develop Automated Test Fixtures

## 🎯 Objective

Build a comprehensive, automated fixture corpus that exercises nominal and malformed MP4/QuickTime structures so
validation and export behaviors can be regression-tested confidently.

## 🧩 Context

- Execution workplan task **F1** prioritizes delivering curated MP4 samples (standard, fragmented, metadata-heavy,

  malformed) once core parsing work is stable, ensuring high-priority QA coverage now that earlier phases are complete.

- The detailed PRD backlog highlights a dedicated fixtures and tests phase covering corpus curation, unit coverage, and

  snapshot validation, reinforcing the need for representative assets before deeper verification expands.

## ✅ Success Criteria

- Fixture set includes baseline MP4, MOV, fragmented fMP4, DASH segments, oversized `mdat`, and deliberately malformed files with clear metadata describing scenarios and expected validation outcomes.
- Automated scripts generate or ingest fixtures reproducibly and place them in version-controlled locations consumable

  by Swift tests and CLI smoke runs.

- Regression tests reference the new fixtures to cover box parsing, validation rules, and JSON export flows without

  manual setup.

- Documentation explains how to refresh or extend the fixture library and how each sample maps to validation coverage

  gaps.

## 🔧 Implementation Notes

- Leverage lightweight Python or Swift utilities to synthesize malformed headers, truncated payloads, and large-data

  placeholders while keeping repository size manageable.

- Store fixtures with sidecar JSON/YAML metadata (description, provenance, expected warnings) to aid automated

  assertions and research-log integrations.

- Integrate fixture loading helpers into existing test targets so future rules or UI flows can reuse the corpus without

  duplicating IO setup.

- Consider CI storage constraints; compress or programmatically generate large artifacts on demand when full binaries

  would bloat the repository.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
