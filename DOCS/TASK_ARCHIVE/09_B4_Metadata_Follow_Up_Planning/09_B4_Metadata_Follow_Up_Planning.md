# B4 Follow-Up Planning — Catalog Integration Coverage

## 🎯 Objective

Outline the concrete follow-up tasks unlocked by the MP4RA catalog integration so the parser, validators, and downstream
consumers gain full metadata-aware coverage and fallbacks.

## 🧩 Context

- Task B4 in the execution workplan prioritizes integrating the MP4RA metadata catalog once streaming parse events are
  in place, and highlights the need for graceful handling of unknown
  boxes.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L20】
- The technical specification describes how `ParsePipeline` should consult `BoxCatalog` to enrich events and enable validation/reporting layers to surface descriptive metadata.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L12-L33】
- The PRD backlog calls for metadata-driven validation and reporting so CLI/UI surfaces human-readable context and
  captures mismatches against MP4RA
  definitions.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L59-L67】【F:DOCS/AI/ISOInspector_PRD_TODO.md†L61-L85】

## ✅ Success Criteria

- Produce a prioritized checklist of downstream B4 follow-up tasks (tests, fallbacks, consumer updates) with
  dependencies and expected artifacts.
- Identify required fixtures and catalog scenarios (standard, UUID, unknown types) and document how they will be
  exercised in automation.
- Specify how validation and reporting layers (CLI/UI/export) should consume catalog metadata, including acceptance
  signals for graceful degradation when descriptors are missing.
- Capture any open risks or external research needed before implementation begins.

## 🔧 Implementation Notes

- Leverage existing `ParsePipeline.live()` event coverage to define integration test hooks for metadata assertions and fallback logging.
- Coordinate with validation rule backlog (VR-003, VR-006) so catalog mismatches and unknown box tracking align with
  success criteria.
- Call out tooling or data needs (e.g., fixture MP4 files with custom UUID boxes) and whether new scripts must be added to `scripts/`.
- Ensure proposed follow-ups map cleanly to workplan phases (e.g., B4 extensions before B5 validation or D2 CLI wiring)
  to maintain dependency order.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L36】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)

## 📋 Prioritized Follow-Up Backlog

| Priority | Task | Dependencies | Expected Artifacts |
|----------|------|--------------|--------------------|
| 1 | Extend `StreamingBoxWalker` integration tests to assert catalog lookups for standard and UUID boxes, including logging expectations for unknown identifiers.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L27-L33】 | `ParsePipeline.live()` fixture harness; bundled MP4RA catalog. | New integration test covering `ParsePipeline.live()` event metadata; log snapshot or assertion utilities verifying single logging per unknown type. |
| 2 | Implement VR-003 metadata comparison rule to enforce MP4RA-defined version and flag constraints, emitting warnings when payload headers diverge.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L59-L65】 | VR-003 spec; metadata-enriched events from Task 1. | Unit and integration tests in `BoxValidatorTests` validating mismatched version/flags; documentation updates describing VR-003 behavior. |
| 3 | Capture VR-006 research entries by persisting unknown box types with offsets into a research log, ensuring deduplication across runs.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L64-L67】【F:DOCS/TASK_ARCHIVE/07_R1_MP4RA_Catalog_Refresh/Summary_of_Work.md†L9-L17】 | Task 1 logging utilities; research backlog process from R1. | New persistence helper and test ensuring unknown boxes append to research log; CLI flag docs for enabling/disabling logging. |
| 4 | Wire catalog metadata into CLI `inspect` streaming output with graceful fallback when descriptors are missing.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L23-L33】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L32-L36】 | EventConsoleFormatter; CLI pipeline skeleton. | Updated console formatter tests showing name/summary usage and placeholder text for unknown descriptors; CLI acceptance test capturing sample output. |
| 5 | Provide metadata-aware adapters for future UI tree/detail panes, including placeholder descriptors when catalog entries are absent.【F:DOCS/AI/ISOInspector_PRD_TODO.md†L67-L113】 | Combine stores planned in Phase C; metadata-enriched events. | Interface contract document plus view model unit tests verifying fallback descriptors. |
| 6 | Introduce regression fixtures that mix known, UUID, and custom boxes to cover fallback behaviors and ensure catalog refresh automation stays effective.【F:DOCS/AI/ISOInspector_PRD_TODO.md†L83-L85】【F:DOCS/TASK_ARCHIVE/07_R1_MP4RA_Catalog_Refresh/Summary_of_Work.md†L9-L26】 | Task 1 harness; scripts for fixture generation. | New media samples under `Tests/media/` with README describing provenance; automation script updates in `scripts/`. |

## 🧪 Fixture & Scenario Coverage

- **Standard boxes (`ftyp`, `moov`, `trak`)** — reuse existing small MP4 fixture to validate metadata names and VR-003 version checks once rule implementation lands.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L59-L65】
- **UUID boxes** — craft targeted fixture with at least one cataloged UUID entry and one custom GUID to validate
  descriptor lookups and fallback logging; store generation instructions alongside
  fixture.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L27-L33】
- **Unknown fourcc** — extend fuzz or synthetic fixture generation to insert unsupported types, confirming VR-006
  logging and CLI fallback strings remain readable.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L64-L67】
- **Malformed metadata** — create fixture toggles (e.g., incorrect version bits) to drive VR-003 warnings without
  breaking structural parsing, ensuring validator surfaces actionable
  messages.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L59-L65】

## 🧰 Consumer Integration & Acceptance Signals

- **Validation pipeline** — `BoxValidator` should annotate events with VR-003 warnings when catalog expectations fail and continue emitting VR-006 info-level issues for unknown types; success is measured by `swift test` suites covering both rules and consistent attachment to `ParseEvent.validationIssues`.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L32-L84】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L59-L67】
- **CLI reporting** — `EventConsoleFormatter` and the upcoming `inspect` command must display catalog names/summaries when available, falling back to raw fourcc/UUID when metadata is missing; acceptance tests should snapshot CLI output for mixed-known/unknown fixtures.【F:Tests/ISOInspectorCLITests/EventConsoleFormatterTests.swift†L1-L42】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L32-L36】
- **Exporters/UI** — document expected adapters that map descriptors into JSON export metadata and UI view models, ensuring placeholders (`"Unknown box (uuid ...)"`) appear when descriptors are absent so downstream consumers do not crash.【F:DOCS/AI/ISOInspector_PRD_TODO.md†L67-L113】

## ⚠️ Risks & Research Items

- **Catalog drift** — Upstream MP4RA updates could invalidate cached descriptors; ensure automation from Task R1 remains
  part of regression pipeline and schedule periodic refresh
  checks.【F:DOCS/TASK_ARCHIVE/07_R1_MP4RA_Catalog_Refresh/Summary_of_Work.md†L9-L26】
- **Fixture licensing** — Custom UUID samples may require generating synthetic media; confirm redistribution rights
  before checking fixtures into the repository.
- **Performance impact** — Additional logging and validation must avoid regressing streaming throughput; monitor parse
  benchmarks once VR-003 and research logging are enabled.
- **Unknown descriptor UX** — Need guidance from product/design on how unknown boxes should appear in UI/CLI to avoid
  confusing operators; capture open question in design backlog.
