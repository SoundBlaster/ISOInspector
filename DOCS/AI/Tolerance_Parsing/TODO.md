# Corrupted Media Tolerance — TODO & Workplan

## Overview

This workplan decomposes the **Corrupted Media Tolerance** feature into execution-ready phases aligned with the PRD (`CorruptedMediaTolerancePRD.md`). The goal is to transform ISOInspector from a strict parser that halts on structural errors into a resilient forensic tool that continues parsing while explicitly flagging corruption.

**Related PRD:** [`CorruptedMediaTolerancePRD.md`](./CorruptedMediaTolerancePRD.md)

**Dependencies:**
- Builds on existing validation rules (VR-001 to VR-006, VR-014, VR-015)
- Extends `BoxParser`, `ParseTreeNode`, and UI layers
- Leverages validation configuration infrastructure from Task B7

**Sprint Timeline:** 6 sprints (Prototype → Alpha → Beta → GA → Post-Launch)

---

## Phase T1 — Core Parsing Resiliency

Transform the parsing pipeline to support lenient mode while preserving strict mode behavior.

| Task ID | Description | Priority | Effort | Dependencies | Acceptance Criteria |
|---------|-------------|----------|--------|--------------|---------------------|
| T1.1 | Define `ParseIssue` model with severity (error/warning/info), byte offsets, reason codes, and affected node references. | High | 1d | None | `ParseIssue` struct defined; unit tests cover initialization and serialization. |
| T1.2 | Extend `ParseTreeNode` with `issues: [ParseIssue]` array and `status` enum (valid/partial/corrupt/skipped). | High | 1d | T1.1 | ✅ Complete — nodes now carry tolerant parsing metadata and exports include the new fields. See `DOCS/TASK_ARCHIVE/165_T1_2_Extend_ParseTreeNode_Status_and_Issues/Summary_of_Work.md`. |
| T1.3 | Create `ParsePipeline.Options` with `abortOnStructuralError`, `maxCorruptionEvents`, `payloadValidationLevel` toggles. | High | 1d | None | ✅ Complete — Options type introduced with strict/tolerant presets; CLI defaults to strict while app uses tolerant caps. See `DOCS/TASK_ARCHIVE/166_T1_3_ParsePipeline_Options/Summary_of_Work.md`. |
| T1.4 | Refactor `BoxHeaderDecoder` to return `Result<BoxHeader, BoxHeaderDecodingError>` instead of throwing. | High | 2d | T1.1, T1.2 | ✅ Complete — decoder now returns `Result` values; see `DOCS/TASK_ARCHIVE/167_T1_4_BoxHeaderDecoder_Result_API/Summary_of_Work.md`. |
| T1.5 | Update container iteration logic to catch decoder errors, attach issues to node, and skip to next sibling using parent boundary. | High | 2d | T1.4 | ✅ Complete — tolerant mode records decoder failures as `ParseIssue` entries and resumes traversal without regressing strict parsing. |
| T1.6 | Implement binary reader guards: clamp reads to parent boundaries, record `truncatedPayload` issue when size exceeds available bytes. | High | 2d | T1.1 | ✅ Complete — Streaming walker now clamps child traversal to parent bounds and emits `payload.truncated` issues (see `DOCS/TASK_ARCHIVE/170_T1_6_Implement_Binary_Reader_Guards/Summary_of_Work.md`). |
| T1.7 | Add progress and depth guards in lenient mode to prevent infinite loops even with malformed sizes. | High | 1d | T1.6 | ✅ Complete — guard specification published in `DOCS/AI/Tolerance_Parsing/Traversal_Guard_Requirements.md`; implementation tasks tracked in `DOCS/TASK_ARCHIVE/171_T1_7_Finalize_Traversal_Guard_Requirements/next_tasks.md`. |

> **Completed (2025-10-24):** Traversal guard implementation for `StreamingBoxWalker` landed with forward-progress, depth, zero-length, cursor-regression, and issue-budget enforcement. See `DOCS/INPROGRESS/Summary_of_Work.md` for implementation notes and verification coverage.

**Verification:**
- Unit tests for `ParseIssue` and updated node model
- Integration tests with corrupt fixtures (truncated, oversized, overlapping boxes)
- Performance regression tests ensure lenient mode overhead ≤ 20% on healthy files

---

## Phase T2 — Corruption Recording & Aggregation

Persist and aggregate corruption events for UI/CLI/export consumption.

| Task ID | Description | Priority | Effort | Dependencies | Acceptance Criteria |
|---------|-------------|----------|--------|--------------|---------------------|
| T2.1 | Create `ParseIssueStore` to aggregate issues keyed by node identifier and byte ranges. | High | 1.5d | T1.1 | Store accepts issues during streaming parse; exposes query APIs (by severity, by node, by range). |
| T2.2 | Emit parse events with severity, offsets, and reason codes; integrate with existing streaming event system. | High | 1.5d | T2.1, existing `ParsePipeline` | Events flow to Combine bridge; `ParseTreeStore` observes and updates UI state. |
| T2.3 | Add severity metrics aggregation (count per severity, deepest affected depth) for summary views. | Medium | 1d | T2.1 | Store computes real-time metrics; accessible via property/computed fields. |
| T2.4 | Extend validation rules (VR-001 to VR-015) to produce `ParseIssue` objects instead of throwing when in lenient mode. | High | 2d | T1.1, T1.3 | Validation rules check pipeline options; generate issues for lenient, throw for strict. |

**Verification:**
- Tests verify issue store accumulates events during streaming parse
- CLI smoke tests confirm metrics appear in summary output
- Validate no regressions in strict mode behavior

---

## Phase T3 — UI Representation of Corruption

Extend SwiftUI views to surface corruption badges, placeholders, and diagnostic details.

| Task ID | Description | Priority | Effort | Dependencies | Acceptance Criteria |
|---------|-------------|----------|--------|--------------|---------------------|
| T3.1 | Replace blocking load-failure banner with non-modal warning ribbon showing corruption counts. | High | 1.5d | T2.1 | Document loads with warnings visible; banner dismissible; tapping opens "Integrity" tab. |
| T3.2 | Add corruption badges (warning triangle icon) to tree view nodes; tooltip shows issue summary. | High | 1.5d | T1.2, T2.1 | Nodes with issues display badge; VoiceOver announces corruption state. |
| T3.3 | Extend details pane with "Corruption" section: error code, byte offsets, affected range, suggested actions. | High | 2d | T2.1 | Selecting corrupt node shows detailed diagnostics; fields copyable. |
| T3.4 | Implement placeholder nodes for missing/required children: expected fourcc, attach issues, link to hex viewer. | Medium | 2d | T1.2 | Missing `stbl` child renders placeholder with "expected but absent" message. |
| T3.5 | Add contextual status labels (Invalid, Empty, Corrupted, Partial, Trimmed) to tree view and detail inspector. | Medium | 1d | T1.2 | Labels reflect node status; color-coded for severity (error=red, warning=yellow, info=blue). |
| T3.6 | Create "Integrity" summary tab aggregating all issues, sortable by severity, with export to text/JSON. | Medium | 2d | T2.1, T2.3 | Tab lists all issues; filter/sort controls work; export actions present in Share menu. |
| T3.7 | Add tree view filters to show/hide corrupt nodes; keyboard shortcuts to jump between issues. | Low | 1d | T3.2 | Filter toggle in toolbar; Cmd+Shift+E jumps to next issue. |

**Verification:**
- SwiftUI previews render corrupt fixtures with badges and placeholders
- Accessibility audit confirms VoiceOver labels and focus order
- UI automation tests verify filter and navigation behaviors

---

## Phase T4 — Diagnostics Export

Enable exportable corruption reports for external analysis.

| Task ID | Description | Priority | Effort | Dependencies | Acceptance Criteria |
|---------|-------------|----------|--------|--------------|---------------------|
| T4.1 | Extend JSON export schema to include `issues` array per node with severity, offsets, reason codes. | High | 1.5d | T1.1, T1.2 | JSON export contains corruption events; schema versioned. |
| T4.2 | Add plaintext export format for issue summary (file metadata + issue list). | Medium | 1d | T2.1 | Text export lists issues in human-readable format; suitable for logs/reports. |
| T4.3 | Include file metadata (size, hash, analysis timestamp) in all exports. | Medium | 0.5d | Existing export infrastructure | Exports include SHA-256 hash, file size, ISO timestamp. |
| T4.4 | Ensure exports omit raw binary snippets to minimize security/privacy exposure. | High | 0.5d | T4.1, T4.2 | Only byte ranges and issue codes exported; no payload bytes. |

**Verification:**
- Golden-file tests for corrupt fixture exports
- Validate JSON schema with external validator
- Privacy audit confirms no sensitive payloads in exports

---

## Phase T5 — Testing & Fixtures

Build comprehensive test coverage for tolerant parsing.

| Task ID | Description | Priority | Effort | Dependencies | Acceptance Criteria |
|---------|-------------|----------|--------|--------------|---------------------|
| T5.1 | Create corrupt fixture corpus: truncated boxes, overlapping boxes, invalid sample tables, broken chunk offsets. | High | 2d | None | At least 10 distinct corruption patterns covered; fixtures stored in `Fixtures/Corrupt/`. |
| T5.2 | Add regression tests verifying continued traversal and warning generation for each corrupt pattern. | High | 2d | T5.1 | Tests assert partial tree rendered; specific issues recorded. |
| T5.3 | Add UI rendering smoke tests for corrupt nodes (badges, placeholders, detail sections). | Medium | 1.5d | T3.1-T3.7, T5.1 | UI tests confirm visual corruption indicators present. |
| T5.4 | Performance benchmark: ensure lenient mode ≤ 1.2× strict mode on 1 GB reference file. | High | 1d | T5.1, existing benchmarks | Benchmark passes; results archived. |
| T5.5 | Crash-free session test: fuzz 100 synthetic corrupt files; target 99.9% completion without crashes. | High | 1.5d | T5.1 | Fuzzing harness completes; crash rate logged. |

**Verification:**
- All tests pass in CI
- Coverage report shows ≥90% coverage for lenient parsing paths
- Performance regression alerts configured

---

## Phase T6 — CLI & Ecosystem Parity

Ensure CLI and SDK surface tolerant parsing equivalently to the GUI.

| Task ID | Description | Priority | Effort | Dependencies | Acceptance Criteria |
|---------|-------------|----------|--------|--------------|---------------------|
| T6.1 | Add `--tolerant` flag to CLI; defaults to lenient for interactive, strict for CI/scripting contexts. | High | 1d | T1.3 | CLI accepts flag; help text documents behavior. |
| T6.2 | Extend CLI output to show corruption summary (counts by severity). | Medium | 1d | T2.3 | CLI prints summary table after parse completion. |
| T6.3 | Ensure SDK consumers can opt into tolerant parsing via `ISOInspectorKit.ParseOptions`. | Medium | 1d | T1.3 | SDK docs include tolerant parsing example; API is public. |
| T6.4 | Update CLI manual and SDK guides with tolerant mode usage and diagnostics interpretation. | Low | 1d | T6.1-T6.3 | Documentation updated; examples provided. |

**Verification:**
- CLI smoke tests with corrupt fixtures
- SDK integration test exercises tolerant mode
- Documentation review confirms clarity

---

## Phase T7 — Rollout & Iteration (per PRD Rollout Plan)

Staged release with feedback loops.

| Sprint | Focus | Tasks | Exit Criteria |
|--------|-------|-------|---------------|
| Sprint 1-2 | **Prototype** | T1.1-T1.7, T2.1-T2.4, T5.1 | Lenient pipeline parses corrupt fixtures behind feature flag; metrics collected. |
| Sprint 3 | **Alpha** | T3.1-T3.7, T4.1-T4.4, T5.2-T5.3 | Internal build with UI corruption signals; QC stakeholder feedback gathered. |
| Sprint 4-5 | **Beta** | T6.1-T6.4, T5.4-T5.5 | External beta testers use toggle in preferences; logs monitored for regressions. |
| Sprint 6 | **GA** | Documentation finalization, default lenient mode, strict mode in advanced prefs | Public release; crash-free sessions ≥99.9%; performance ≤1.2×; user satisfaction ≥4/5. |
| Post-Launch | **Telemetry & Refinement** | Gather opt-in telemetry on corruption event frequency; refine heuristics and diagnostics catalog. | Quarterly review of telemetry; issue catalog updated. |

---

## Open Questions (from PRD)

Track resolutions as work progresses:

1. **Batching large corruption clusters:** How to summarize thousands of broken samples without hiding detail?
   - *Resolution:* TBD in Sprint 3 based on QC feedback.

2. **Placeholder creation heuristics:** When to auto-create vs. group missing siblings?
   - *Resolution:* TBD in Sprint 2 prototyping.

3. **Localization research:** Validate issue labels with Russian- and English-speaking teams.
   - *Resolution:* Defer to Sprint 5 beta feedback.

4. **Telemetry safeguards:** Ensure offset ranges don't leak sensitive metadata.
   - *Resolution:* Audit in T4.4; confirm no payload bytes exported.

---

## Cross-References

- **Main PRD:** [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../ISOViewer/ISOInspector_PRD_TODO.md)
- **Validation Infrastructure:** Task B7 ([`DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/`](../../TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/))
- **Existing Validation Rules:**
  - E1: [`DOCS/TASK_ARCHIVE/159_E1_Enforce_Parent_Containment_and_Non_Overlap/`](../../TASK_ARCHIVE/159_E1_Enforce_Parent_Containment_and_Non_Overlap/)
  - E2: [`DOCS/TASK_ARCHIVE/163_E2_Detect_Progress_Loops/`](../../TASK_ARCHIVE/163_E2_Detect_Progress_Loops/)
- **Export Infrastructure:** Task B6 ([`DOCS/TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/`](../../TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/))
- **UI State Management:** Task G7 ([`DOCS/TASK_ARCHIVE/154_G7_State_Management_ViewModels/`](../../TASK_ARCHIVE/154_G7_State_Management_ViewModels/))

---

## Notes

- **Incremental Delivery:** Each phase delivers independently testable artifacts; feature flag guards experimental paths.
- **Backward Compatibility:** Strict mode remains default for CLI; lenient mode is opt-in until GA.
- **Performance Budget:** Lenient mode overhead must stay ≤20% on healthy files; gate GA on benchmark pass.
- **Documentation Sync:** Update main PRD TODO checklist (`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`) to reference Tolerance Parsing phases.
