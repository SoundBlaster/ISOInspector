# Task Archive Summary

## 01_A2_Configure_CI_Pipeline
- **Original file:** `DOCS/INPROGRESS/A2_Configure_CI_Pipeline.md`
- **Archived location:** `DOCS/ARCHIVE/01_A2_Configure_CI_Pipeline/A2_Configure_CI_Pipeline.md`
- **Purpose:** Establish an automated GitHub Actions workflow that builds and tests the ISOInspector Swift package on every pull request, preventing regressions before merge.
- **Scope highlights:** Create the CI workflow, configure status checks, and prepare for future linting or static analysis enhancements while leaving release automation and DocC publishing out of scope.
- **Key next steps:** Scaffold `.github/workflows/ci.yml`, set up Swift tooling on CI runners, cache builds, and ensure `swift build` plus `swift test` run automatically with clear failure logs.

## 03_B2_Plus_Streaming_Interface_Evaluation
- **Archived files:** `B2_Plus_Streaming_Interface_Evaluation.md`, `B3_Streaming_Parse_Pipeline.md`, `F1_Test_Fixtures.md`, `Summary_of_Work.md`, and the prior `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/03_B2_Plus_Streaming_Interface_Evaluation/`
- **Purpose:** Capture the investigation and documentation around introducing an asynchronous `ParsePipeline`, follow-on parser implementation notes, and fixture planning to support streaming validation.
- **Key outcomes:** Established the `ParsePipeline` event model, recorded parser integration guidance, and documented fixture needs while rolling follow-up implementation into Puzzle #1.

## 04_B3_ParsePipeline_Live_Streaming
- **Archived files:** `B3_ParsePipeline_Live_Streaming.md`, `Summary_of_Work.md`, and the in-progress `next_tasks.md` checklist.
- **Archived location:** `DOCS/TASK_ARCHIVE/04_B3_ParsePipeline_Live_Streaming/`
- **Highlights:** Documents completion of the streaming `ParsePipeline.live()` implementation, including validation of nested box traversal, offset accounting, and regression coverage through targeted unit tests.
- **Next steps carried forward:** Continue Puzzle #1 by connecting the live pipeline to the production streaming walker so concrete parsing logic runs end-to-end.

## 05_B3_Puzzle1_ParsePipeline_Live_Integration
- **Archived files:** `05_B3_Puzzle1_ParsePipeline_Live_Integration.md`, `Summary_of_Work.md`, and the completed `next_tasks.md` checklist.
- **Archived location:** `DOCS/TASK_ARCHIVE/05_B3_Puzzle1_ParsePipeline_Live_Integration/`
- **Highlights:** Captures the implementation details for wiring `ParsePipeline.live()` to the production `StreamingBoxWalker`, including validation of nested traversal, cancellation propagation, and concrete streaming integration tests.
- **Next steps carried forward:** Follow Puzzle #1 with Task B4 by integrating the MP4RA metadata catalog and related downstream parser work; these items now live in `DOCS/INPROGRESS/next_tasks.md`.

## 06_B4_MP4RA_Metadata_Integration
- **Archived files:** `B4_MP4RA_Metadata_Integration.md`, `Summary_of_Work.md`, and the prior `next_tasks.md` checklist captured during Task B4.
- **Archived location:** `DOCS/TASK_ARCHIVE/06_B4_MP4RA_Metadata_Integration/`
- **Highlights:** Records integration of the MP4RA-backed `BoxCatalog` into the streaming pipeline, inclusion of the bundled metadata fixture, and expanded diagnostics plus coverage for standard and UUID-based boxes.
- **Next steps carried forward:** ✅ Automation for refreshing `MP4RABoxes.json` now ships via R1 (`DOCS/INPROGRESS/07_R1_MP4RA_Catalog_Refresh.md`). Continue extending downstream validation/reporting that consumes enriched metadata and outline the parser follow-ups enabled by real-time streaming events.

## 07_R1_MP4RA_Catalog_Refresh
- **Archived files:** `07_R1_MP4RA_Catalog_Refresh.md`, `Summary_of_Work.md`, and the `next_tasks.md` checklist captured during Task R1.
- **Archived location:** `DOCS/TASK_ARCHIVE/07_R1_MP4RA_Catalog_Refresh/`
- **Highlights:** Documents automation for regenerating `MP4RABoxes.json`, the supporting CLI plumbing, and the refreshed metadata assets that keep the catalog aligned with the upstream registry.
- **Next steps carried forward:** Extend downstream validation/reporting to consume the enriched MP4RA metadata and outline additional parser follow-ups enabled by the live streaming pipeline.

## 08_Metadata_Driven_Validation_and_Reporting
- **Archived files:** `08_Metadata_Driven_Validation_and_Reporting.md`, `Summary_of_Work.md`, and the carried-forward `next_tasks.md` checklist.
- **Archived location:** `DOCS/TASK_ARCHIVE/08_Metadata_Driven_Validation_and_Reporting/`
- **Highlights:** Documents extension of the MP4RA metadata-aware validation layer, integration of the `EventConsoleFormatter`, and reporting updates that expose catalog-backed context for each streaming parse event.
- **Next steps carried forward:** Capture downstream parser follow-ups unlocked by streaming events and wire the console formatter into the forthcoming `inspect` CLI command.

## 09_B4_Metadata_Follow_Up_Planning
- **Archived files:** `09_B4_Metadata_Follow_Up_Planning.md`, `Summary_of_Work.md`, and the in-progress `next_tasks.md` checklist.
- **Archived location:** `DOCS/TASK_ARCHIVE/09_B4_Metadata_Follow_Up_Planning/`
- **Highlights:** Captures the downstream planning for catalog-enabled metadata coverage, including prioritized validation tasks,
  fixture strategies, and consumer integration notes building on the streaming parse pipeline.
- **Next steps carried forward:** Kick off VR-006 research logging alongside the CLI/UI metadata consumption work now that VR-003 catalog warnings are live.

## 10_B5_VR003_Metadata_Comparison_Rule
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/10_B5_VR003_Metadata_Comparison_Rule/`.
- **Highlights:** Captures completion of the VR-003 metadata comparison rule, including CLI and validation pipeline warning flows aligned with catalog data and expanded coverage for truncated or undersized payloads.
- **Next steps carried forward:** Launch VR-006 research logging to complement the new warnings and continue the VR-001 through VR-005 implementation threads outlined in `todo.md`.

## 11_B5_VR003_Metadata_Validation
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/11_B5_VR003_Metadata_Validation/`.
- **Highlights:** Documents verification of VR-003 metadata comparison behavior via focused unit coverage and live parse integration tests ensuring catalog-aligned boxes remain warning-free.
- **Next steps carried forward:** Execute VR-006 research logging in tandem with CLI/UI metadata consumers and continue driving VR-001, VR-002, VR-004, and VR-005 feature work per the active backlog.

## 12_B5_VR001_VR002_Structural_Validation
- **Archived files:** `12_B5_VR001_VR002_Structural_Validation.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/12_B5_VR001_VR002_Structural_Validation/`.
- **Highlights:** Captures completion of VR-001 and VR-002 structural validation, including streaming safeguards for impossible box sizes, boundary drift detection, and expanded regression coverage in `BoxValidatorTests`.
- **Next steps carried forward:** Continue VR-006 research logging efforts and drive VR-001, VR-002, VR-004, and VR-005 feature work tracked under `todo.md #3`.

## 13_B5_VR004_VR005_Ordering_Validation
- **Archived files:** `13_B5_VR004_VR005_Ordering_Validation.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/13_B5_VR004_VR005_Ordering_Validation/`.
- **Highlights:** Documents the ordering safeguards for VR-004 and VR-005, including validator state tracking for `ftyp` precedence, streaming-aware exceptions for fragmented layouts, and refreshed unit plus integration coverage.
- **Next steps carried forward:** Execute VR-006 research logging alongside CLI and UI metadata consumers so the new ordering signals feed downstream analysis per `todo.md #3`.

## 14_B5_VR006_Research_Logging
- **Archived files:** `14_B5_VR006_Research_Logging.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/14_B5_VR006_Research_Logging/`.
- **Highlights:** Documents delivery of persistent VR-006 research logging shared by CLI and UI consumers, including configurable log handling and expanded streaming pipeline coverage.
- **Next steps carried forward:** Monitor research log schema usage as UI components mature so downstream CLI/UI metadata consumers surface consistent insights per `todo.md #3`.

## 15_Monitor_VR006_Research_Log_Adoption
- **Archived files:** `15_Monitor_VR006_Research_Log_Adoption.md`, `Summary_of_Work.md`, `VR006_Monitoring_Checklist.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/15_Monitor_VR006_Research_Log_Adoption/`.
- **Highlights:** Captures the VR-006 monitoring audit work, including the shared schema banner, CLI audit helper, and the monitoring checklist detailing integration checkpoints.
- **Next steps carried forward:** Completed via SwiftUI preview integration and UI smoke telemetry coverage (todo.md #4 & #5).

## 16_Integrate_ResearchLogMonitor_SwiftUI_Previews
- **Archived files:** `04_Integrate_ResearchLogMonitor_SwiftUI_Previews.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/16_Integrate_ResearchLogMonitor_SwiftUI_Previews/`.
- **Highlights:** Captures integration of `ResearchLogMonitor.audit(logURL:)` with SwiftUI previews, including deterministic VR-006 fixtures, preview diagnostics views, and regression coverage that keeps UI bindings aligned with the CLI audit helper.
- **Next steps carried forward:** ✅ Completed by UI smoke telemetry coverage ensuring CLI and SwiftUI consumers surface VR-006 research log diagnostics (todo.md #5).

## 17_Extend_VR006_Telemetry_UI_Smoke_Tests
- **Archived files:** `17_Extend_VR006_Telemetry_UI_Smoke_Tests.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/17_Extend_VR006_Telemetry_UI_Smoke_Tests/`.
- **Highlights:** Captures the telemetry smoke test suite that exercises `ResearchLogTelemetryProbe` and `ResearchLogTelemetrySnapshot` across CLI and SwiftUI entry points, including success, missing log, empty log, and schema mismatch scenarios driven by the ParsePipeline.
- **Next steps carried forward:** None — VR-006 telemetry instrumentation is now fully covered by automated smoke tests and documentation.

## 18_C1_Combine_Bridge_and_State_Stores
- **Archived files:** `18_C1_Combine_Bridge_and_State_Stores.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/18_C1_Combine_Bridge_and_State_Stores/`.
- **Highlights:** Documents the Combine-based bridge that fans out `ParseEvent` streams and the `@MainActor` parse tree store that aggregates validation issues for SwiftUI consumers, along with coverage capturing bridge fan-out, aggregation, and failure propagation.
- **Next steps carried forward:** Focus next on C2 tree view rendering and C3 detail/hex stores that subscribe to the shared Combine bridge.

## 19_C2_Tree_View_Virtualization
- **Archived files:** `19_C2_Tree_View_Virtualization.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/19_C2_Tree_View_Virtualization/`.
- **Highlights:** Captures the initial SwiftUI outline explorer powered by the new `ParseTreeStore`, including severity filtering, search, and preview data seeding for virtualization experiments.
- **Next steps carried forward:** Continue wiring the explorer to live parse sessions and begin planning C3 detail and hex inspectors driven by the Combine bridge.

## 20_C2_Tree_View_Virtualization_Follow_Up
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/20_C2_Tree_View_Virtualization_Follow_Up/`.
- **Highlights:** Documents closure of the virtualization spike, verification via `swift test`, and outlines follow-ups for connecting the explorer to real imports plus expanding filter coverage.
- **Next steps carried forward:** Draft C3 detail/hex stores, integrate streaming snapshots from user-selected MP4s, and extend outline filters to surface catalog-driven categories per `@todo #6`.

## 21_C2_Integrate_Outline_Explorer_With_Streaming
- **Archived files:** `C2_Integrate_Outline_Explorer_With_Streaming.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/21_C2_Integrate_Outline_Explorer_With_Streaming/`.
- **Highlights:** Captures the streaming-bound outline explorer that consumes live `ParseTreeStore` snapshots, introduces latency instrumentation via `Logger` signposts, and removes preview-only sample data wiring.
- **Next steps carried forward:** Draft C3 detail and hex inspectors on the Combine bridge and expand outline filters to surface box categories plus streaming metadata (`@todo #6`).

## 22_C2_Extend_Outline_Filters
- **Archived files:** `C2_Extend_Outline_Filters.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/22_C2_Extend_Outline_Filters/`.
- **Highlights:** Documents the addition of reusable box classification helpers and streaming metadata toggles that extend the outline explorer filters while keeping severity filtering and virtualization performance intact.
- **Next steps carried forward:** Draft task C3 detail and hex inspectors that subscribe to the Combine bridge for payload slices and metadata panes.

## 23_C3_Detail_and_Hex_Inspectors
- **Archived files:** `23_C3_Detail_and_Hex_Inspectors.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/23_C3_Detail_and_Hex_Inspectors/`.
- **Highlights:** Documents the SwiftUI detail and hex inspectors bound to `ParseTreeSnapshot` updates, including metadata panes, validation issue listings, and synchronized hex slices powered by asynchronous providers.
- **Next steps carried forward:** #7 Highlight field subranges and sync selections once payload annotations are available so detail panes and hex viewers stay aligned.

## 24_C3_Highlight_Field_Subranges
- **Archived files:** `07_Highlight_Field_Subranges.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/24_C3_Highlight_Field_Subranges/`.
- **Highlights:** Captures the SwiftUI detail pane updates that surface selectable annotations, synchronized hex highlighting, and the random-access payload annotation provider backing the new interaction model.
- **Next steps carried forward:** None — the follow-up checklist has been cleared, so future backlog selection can proceed from `todo.md` and the execution workplan.

## 25_B4_C2_Category_Filtering
- **Archived files:** `2025-10-09-mp4ra-category-integration.md`, `B4_Integrate_MP4RA_Metadata_Catalog.md`, `C2_Tree_View_Virtualization.md`, `Summary_of_Work.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/25_B4_C2_Category_Filtering/`.
- **Highlights:** Documents the MP4RA catalog enrichment that adds category metadata to streaming parse events alongside the SwiftUI outline explorer updates that surface category chips and streaming toggles without regressing virtualization performance.
- **Next steps carried forward:** None — all noted follow-ups were resolved, so backlog selection can resume from `todo.md` and the execution workplan.

## 26_F1_Fixtures_and_B4_MP4RA
- **Archived files:** `B4_Integrate_MP4RA_Metadata_Catalog.md`, `F1_Develop_Automated_Test_Fixtures.md`, `Summary_of_Work.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/26_F1_Fixtures_and_B4_MP4RA/`.
- **Highlights:** Captures the MP4RA catalog integration plan alongside the automated fixture corpus roadmap, including streamed metadata enrichment goals and the newly added regression fixtures and tests outlined in the work summary.
- **Next steps carried forward:** Expand the fixture catalog with fragmented, DASH, and malformed assets plus validation expectations (`@todo #8`), now tracked in `DOCS/INPROGRESS/next_tasks.md`.

## 27_F1_Expand_Fixture_Catalog
- **Archived files:** `27_F1_Expand_Fixture_Catalog.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/27_F1_Expand_Fixture_Catalog/`.
- **Highlights:** Captures the expanded fixture catalog documentation, regression notes, and verification summary covering fragmented MP4, DASH, large payload, and malformed sample scenarios.
- **Next steps carried forward:** None — the refreshed `DOCS/INPROGRESS/next_tasks.md` notes that no follow-up items are currently queued.

## 33_C4_CoreData_Annotation_Persistence
- **Archived files:** `2025-10-10-coredata-annotation-bookmark-store.md`, `C4_CoreData_Annotation_Persistence.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/33_C4_CoreData_Annotation_Persistence/`.
- **Highlights:** Documents the CoreData-backed annotation and bookmark store, updated DocC/manual guidance, and SwiftUI integration that keeps notes and bookmarks in sync with the persistence layer.
- **Next steps carried forward:** DocC tutorial coverage now lives in `DOCS/TASK_ARCHIVE/35_A3_DocC_Tutorial_Expansion/`; DocC publishing is handled by the CI `docc-archives` job, leaving Task E3 CoreData migration work as the remaining focus.

## 28_B6_JSON_and_Binary_Export_Modules
- **Archived files:** `28_B6_JSON_and_Binary_Export_Modules.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/`.
- **Highlights:** Captures introduction of the reusable parse tree builder plus JSON and binary exporters in ISOInspectorKit and the accompanying CLI smoke coverage for the new APIs.
- **Next steps carried forward:** Resolved by `29_D3_CLI_Export_Commands`.

## 29_D3_CLI_Export_Commands
- **Archived files:** `29_D3_CLI_Export_Commands.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/29_D3_CLI_Export_Commands/`.
- **Highlights:** Documents the implementation of CLI `export-json` and `export-capture` commands, including option parsing, output validation, and integration with ISOInspectorKit exporters plus new CLI regression tests.
- **Next steps carried forward:** None — future CLI work continues with D4 batch processing.

## 30_Summary_of_Work_2025-10-10
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/30_Summary_of_Work_2025-10-10/`.
- **Highlights:** Summarizes the October 10, 2025 work session wrapping CLI export command delivery, verification details, and notes on awaiting new assignments.
- **Next steps carried forward:** None — current planning awaits assignment of D4 CLI batch mode tasks.

## 31_A3_DocC_Catalog_Setup
- **Archived files:** `31_A3_DocC_Catalog_Setup.md`, `Summary_of_Work.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/31_A3_DocC_Catalog_Setup/`.
- **Highlights:** Captures the DocC catalog scaffolding for ISOInspectorKit, CLI, and App targets alongside the automation scripts and Swift-DocC dependency wiring that enable repeatable documentation builds.
- **Next steps carried forward:** DocC tutorial expansion is now archived in `DOCS/TASK_ARCHIVE/35_A3_DocC_Tutorial_Expansion/`; DocC publishing is active via the CI `docc-archives` job, so no additional follow-up remains from this task.

## 32_C4_Annotation_Bookmark_Store
- **Archived files:** `2025-10-10-annotation-bookmark-store.md`, `C4_Annotation_and_Bookmark_Management.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/32_C4_Annotation_Bookmark_Store/`.
- **Highlights:** Captures the file-backed annotation and bookmark persistence spike, accompanying management notes, and the work summary covering regression tests and the CoreData migration follow-up.
- **Next steps carried forward:** The CoreData-backed store landed in `DOCS/TASK_ARCHIVE/33_C4_CoreData_Annotation_Persistence/`, DocC tutorial expansion followed in `DOCS/TASK_ARCHIVE/35_A3_DocC_Tutorial_Expansion/`, and DocC publishing now runs automatically through the CI `docc-archives` job.

## 34_E3_CoreData_Migration_Planning
- **Archived files:** `34_E3_CoreData_Migration_Planning.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/34_E3_CoreData_Migration_Planning/`.
- **Highlights:** Documents the CoreData migration strategy for session persistence, including schema evolution paths, lightweight migration safeguards, and testing plus tooling implications for Task E3.
- **Next steps carried forward:** Implement Task E3 with versioned model loading, migration coverage, and updated DocC articles describing session restoration workflows.

## 35_A3_DocC_Tutorial_Expansion
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/35_A3_DocC_Tutorial_Expansion/`.
- **Highlights:** Records the DocC tutorial updates for both CLI and app catalogs, including new screenshots, cross-linked workflows, and verification of documentation builds.
- **Next steps carried forward:** DocC publishing now executes in CI through the `docc-archives` job; the outstanding checklist item has been closed in `DOCS/INPROGRESS/next_tasks.md`.

## 36_A3_DocC_Publishing_CI
- **Archived files:** `12_Add_DocC_Publishing_to_CI.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/36_A3_DocC_Publishing_CI/`.
- **Highlights:** Documents automation for publishing DocC archives via the `docc-archives` GitHub Actions job, including updated planning notes and validation that CI artifact uploads fail when documentation output is missing.
- **Next steps carried forward:** None — DocC catalog enhancements remain tracked in prior archive entries, and no additional CI follow-up was noted in `next_tasks.md`.

## 37_C5_Accessibility_Features
- **Archived files:** `37_C5_Accessibility_Features.md`, `Summary_of_Work.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/37_C5_Accessibility_Features/`.
- **Highlights:** Captures the accessibility rollout covering shared VoiceOver descriptors, keyboard focus management across outline/detail/hex panes, Dynamic Type validation, and extended XCTest coverage for the new behaviors.
- **Next steps carried forward:** None — the summary recorded no follow-ups, so future planning resumes from the main backlog.

## 38_NestedA11yIDs_Integration
- **Archived files:** `2025-10-11-nested-a11y-integration.md`, `B6_BoxParserRegistry.md`, `Summary_of_Work.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/38_NestedA11yIDs_Integration/`.
- **Highlights:** Captures integration of NestedA11yIDs across the ISOInspector App parse tree explorer, linked documentation updates, and B6 Box Parser Registry planning notes gathered during the October 11, 2025 work session.
- **Next steps carried forward:** `DOCS/INPROGRESS/next_tasks.md` now tracks applying NestedA11yIDs identifiers to research log previews and annotation note controls, aligned with `todo.md` items #13 and #14 before resuming B6 exporter work.

## 39_Apply_NestedA11yIDs_Research_Log_Preview
- **Archived files:** `13_Apply_NestedA11yIDs_Research_Log_Preview.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/39_Apply_NestedA11yIDs_Research_Log_Preview/`.
- **Highlights:** Captures the completion of NestedA11yIDs adoption for the research log preview, documenting identifier coverage across preview metadata, diagnostic rows, and supporting QA automation references.
- **Next steps carried forward:** `DOCS/INPROGRESS/next_tasks.md` now tracks the remaining annotation editor control coverage aligned with `todo.md` item #14.

## 40_14_Add_NestedA11yIDs_Annotation_Note_Controls
- **Archived files:** `14_Add_NestedA11yIDs_Annotation_Note_Controls.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/40_14_Add_NestedA11yIDs_Annotation_Note_Controls/`.
- **Highlights:** Documents completion of NestedA11yIDs coverage for annotation note edit, save, cancel, and delete controls, aligning identifier constants, guides, and verification notes for QA automation.
- **Next steps carried forward:** None — the follow-up checklist is cleared, so future backlog selection can resume from the primary planning documents.
