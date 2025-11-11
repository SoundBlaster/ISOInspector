# T5.3 — UI Corruption Smoke Tests

## 🎯 Objective
Develop automated UI smoke tests that verify corruption indicators (badges, placeholders, detail diagnostics) render correctly in the ISOInspector app when tolerant parsing detects issues.

## 🧩 Context
- Task **T5.3** from the Corrupted Media Tolerance workplan remains open while upstream UI integrations (T3.1–T3.7) and fixture generation (T5.1) are complete.
- Existing tolerant parsing UI features include warning ribbons, corruption badges, placeholder nodes, and the Integrity summary tab, all documented in `DOCS/TASK_ARCHIVE/185_T3_1_Tolerant_Parsing_Warning_Ribbon/` through `DOCS/TASK_ARCHIVE/196_T3_6_Integrity_Summary_Tab/` and `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/`.
- The corrupt fixture corpus (Task T5.1) provides deterministic samples under `Fixtures/Corrupted/` with manifests describing expected issue patterns.
- No FoundationUI deliverables are involved; this work targets the primary ISOInspector app test suite.

## ✅ Success Criteria
- UI automation tests load corrupt fixtures and assert the warning ribbon, corruption badges, and placeholder nodes appear with the correct accessibility labels.
- Integrity summary views expose the aggregate issue list for the loaded fixture and the tests validate representative rows.
- Tests confirm that selecting nodes reveals the Corruption detail section populated with offsets and reason codes sourced from `ParseIssueStore`.
- Test suite passes locally (`swift test`) and integrates into CI without flakiness, using fixtures or previews available in the repository.

## 🔧 Implementation Notes
- Reuse or extend existing UI automation infrastructure under `Tests/ISOInspectorUITests/` (e.g., `ParseTreeStreamingSelectionAutomationTests`) to open fixtures and interact with the Integrity tab.
- Reference manifest metadata from `Fixtures/Corrupted/manifest.json` (or equivalent) to drive expectations for badge counts and placeholder presence.
- Ensure automation waits for streaming parse completion; consider existing Combine publishers or view model states to synchronize assertions.
- Cover at least one case each for: corrupt node badge, missing-child placeholder, and aggregate Integrity list entry.
- Coordinate with tolerance parsing exports to reuse shared helper functions (`Tests/ISOInspectorKitTests/Helpers/FixtureLoading.swift`) if UI tests need to verify textual content.
- Update documentation (e.g., `DOCS/AI/Tolerance_Parsing/TODO.md`) after landing to mark T5.3 complete and archive this PRD.

## 🧠 Source References
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`DOCS/TASK_ARCHIVE/201_T5_1_Corrupt_Fixture_Corpus/`](../TASK_ARCHIVE/201_T5_1_Corrupt_Fixture_Corpus/)
- [`DOCS/TASK_ARCHIVE/188_T3_3_Integrity_Detail_Pane/`](../TASK_ARCHIVE/188_T3_3_Integrity_Detail_Pane/)
- [`DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/`](../TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/)
