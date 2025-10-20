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

## 41_D1_Scaffold_CLI_Base_Command
- **Archived files:** `D1_Scaffold_CLI_Base_Command.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/41_D1_Scaffold_CLI_Base_Command/`.
- **Highlights:** Captures the new `isoinspector` root command built on `swift-argument-parser`, shared CLI context plumbing, and verification via `swift test` that the executable now dispatches placeholder `inspect`, `validate`, and `export` subcommands.
- **Next steps carried forward:** Implement the streaming `inspect`/`validate` commands, surface CLI logging and telemetry toggles, and route export flows through the new command infrastructure as tracked in `DOCS/INPROGRESS/next_tasks.md` and `todo.md` PDD items.

## 42_D2_Streaming_CLI_Commands
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/42_D2_Streaming_CLI_Commands/`.
- **Highlights:** Documents completion of the streaming `inspect` and `validate` CLI commands, including asynchronous environment wiring, streaming parse event logging, and validation aggregation validated via `swift test`.
- **Next steps carried forward:** Surface global logging and telemetry toggles for the CLI and route export operations through the shared streaming capture utilities, as tracked in `DOCS/INPROGRESS/next_tasks.md` and `todo.md` PDD items.

## 43_E1_Build_SwiftUI_App_Shell
- **Archived files:** `2025-10-12-app-shell.md`, `E1_Build_SwiftUI_App_Shell.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/43_E1_Build_SwiftUI_App_Shell/`.
- **Highlights:** Captures the SwiftUI navigation shell work including the new `AppShellView`, persisted `DocumentRecentsStore`,
  and `DocumentSessionController` coordination across streaming pipeline integrations, validated by `swift test`.
- **Next steps carried forward:** Continue CoreData session persistence wiring for Task E1 and pursue F2 performance benchmarking,
  with CLI logging/telemetry toggles and streaming export routing tracked in `DOCS/INPROGRESS/next_tasks.md`.

## 44_F2_Configure_Performance_Benchmarks
- **Archived files:** `44_F2_Configure_Performance_Benchmarks.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/`.
- **Highlights:** Documents the performance benchmark harnesses that tune payload sizes, iteration counts, and slack multipliers from the non-functional throughput targets, covering both CLI validation throughput and Combine-backed UI latency metrics.
- **Next steps carried forward:** Execute the Combine-backed UI benchmark on macOS to capture latency metrics and continue tracking CLI logging/telemetry toggles plus streaming export routing via the refreshed `DOCS/INPROGRESS/next_tasks.md` checklist. **(In Progress — see `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/47_Combine_UI_Benchmark_macOS.md`)**

## 45_E2_Integrate_Parser_Event_Pipeline
- **Archived files:** `2025-10-12-parser-selection-bridging.md`, `E2_Integrate_Parser_Event_Pipeline.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/45_E2_Integrate_Parser_Event_Pipeline/`.
- **Highlights:** Captures the SwiftUI integration work that wires the streaming parser bridge into the application shell, automatically selects the first parsed node, and refreshes the detail pane via updated view model identifiers with accompanying unit coverage.
- **Next steps carried forward:** Recreate UI automation for macOS streaming selection coverage plus the macOS Combine benchmark and CLI telemetry/export follow-ups now tracked in `DOCS/INPROGRESS/next_tasks.md` and `todo.md` PDD items.

## 46_D3_Route_Streaming_Export_Operations
- **Archived files:** `Route_Streaming_Export_Operations.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/46_D3_Route_Streaming_Export_Operations/`.
- **Highlights:** Captures routing the `isoinspector export` JSON and binary flows through the shared streaming capture utilities, aligning CLI behaviors with the modern pipeline and documenting verification via `swift test`.
- **Next steps carried forward:** Track macOS SwiftUI automation for streaming selection defaults, execute the Combine-backed UI benchmark on macOS, and surface global logging plus telemetry toggles for the CLI — all preserved in `DOCS/INPROGRESS/next_tasks.md` and `todo.md` PDD items. **(Benchmark In Progress — see `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/47_Combine_UI_Benchmark_macOS.md`)**

## 47_Combine_UI_Benchmark_macOS
- **Archived files:** `47_Combine_UI_Benchmark_macOS.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/`.
- **Highlights:** Captures the Combine-backed UI benchmark plan, Linux container skip logs, and macOS follow-up requirements for
  gathering latency, CPU, and memory metrics that align with the CLI performance baselines.
- **Next steps carried forward:** Re-run the benchmark on macOS hardware, archive the resulting measurements beside the CLI
  throughput baselines, and continue tracking UI automation plus CLI telemetry toggles in `DOCS/INPROGRESS/next_tasks.md` and
  related backlog entries.

## 48_macOS_SwiftUI_Automation_Streaming_Default_Selection
- **Archived files:** `48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/`.
- **Highlights:** Documents the macOS UI automation harness that hosts `ParseTreeExplorerView`, streams parse events, and asserts outline/detail panes stay synchronized around the default selection during live updates.
- **Next steps carried forward:** Run the new automation suite on macOS hardware with XCTest UI support and continue the macOS Combine benchmark measurements as tracked in `DOCS/INPROGRESS/next_tasks.md`.

## 49_CLI_Global_Logging_and_Telemetry_Toggles
- **Archived files:** `48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`, `49_CLI_Global_Logging_and_Telemetry_Toggles.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/49_CLI_Global_Logging_and_Telemetry_Toggles/`.
- **Highlights:** Captures delivery of the macOS SwiftUI automation suite that validates default selection during streaming updates alongside the CLI-wide logging and telemetry toggles, including dependency-injectable view wiring, command context plumbing, and supporting test coverage.
- **Next steps carried forward:** Execute the new automation run on macOS hardware with XCTest UI support and collect macOS Combine benchmark metrics, as outlined in `DOCS/INPROGRESS/next_tasks.md` and the related backlog trackers.

## 50_Summary_of_Work_2025-02-16
- **Archived files:** `50_Combine_UI_Benchmark_macOS_Run.md`, `51_ParseTreeStreamingSelectionAutomation_macOS_Run.md`, `Summary_of_Work.md`, `task_summary.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/`.
- **Highlights:** Preserves the February 16, 2025 checkpoint summarizing macOS-bound follow-ups for the Combine UI benchmark and SwiftUI automation runs, along with the latest task summary and blocked status documentation gathered while hardware access was unavailable in the Linux container.
- **Next steps carried forward:** Secure macOS hardware or CI capacity to execute the benchmark and automation suites, archive resulting metrics or `xcresult` bundles, and update backlog trackers — see the refreshed `DOCS/INPROGRESS/next_tasks.md` checklist for the active blockers.

## 51_D4_CLI_Batch_Mode
- **Archived files:** `51_D4_CLI_Batch_Mode.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/51_D4_CLI_Batch_Mode/`.
- **Highlights:** Captures delivery of the `isoinspect batch` workflow, including aggregated status tables, CSV summary export, and expanded regression coverage that verifies CI-friendly exit codes for multi-file validation runs.
- **Next steps carried forward:** Continue tracking macOS-only automation and benchmark follow-ups via `DOCS/INPROGRESS/next_tasks.md` and the related backlog entries until hardware access becomes available.

## 52_E3_Session_Persistence
- **Archived files:** `E3_Session_Persistence.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/`.
- **Highlights:** Chronicles delivering workspace session persistence across CoreData and JSON fallback stores, wiring restoration through the document session controller, and extending regression coverage for migrations, snapshot storage, and controller recovery flows.
- **Next steps carried forward:** Surface session persistence diagnostics and reconcile CoreData bookmark diffs when logging and reconciliation rules land, while macOS automation and benchmark runs remain tracked in `DOCS/INPROGRESS/next_tasks.md`.

## 53_F3_Developer_Onboarding_Guide
- **Archived files:** `F3_Developer_Onboarding_Guide.md`, `Summary_of_Work.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/53_F3_Developer_Onboarding_Guide/`.
- **Highlights:** Documents completion of the end-to-end developer onboarding guide and API reference refresh, covering setup, architecture walkthroughs, automation hooks, and cross-linking to DocC plus CLI resources.
- **Next steps carried forward:** Keep the onboarding guide synchronized with future API or DocC updates and link new tutorials or automation flows as they ship, as noted in the follow-up summary.

## 54_Summary_of_Work_2025-10-13
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/54_Summary_of_Work_2025-10-13/`.
- **Highlights:** Captures the October 13, 2025 work checkpoint summarizing completion of the F3 documentation task, including links to published guides and reminders about keeping onboarding materials current.
- **Next steps carried forward:** Continue tracking macOS-only automation, benchmarking, and session persistence diagnostics via the recreated `DOCS/INPROGRESS/next_tasks.md` checklist until required hardware and logging plumbing are available.

## 55_E4_Prepare_App_Distribution_Configuration
- **Archived files:** `2025-10-13-distribution-scaffolding.md`, `54_E4_Prepare_App_Distribution_Configuration.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/55_E4_Prepare_App_Distribution_Configuration/`.
- **Highlights:** Documents the shared distribution metadata manifest, Swift helper API, and XCTest coverage for versioned bundle identifiers plus the new platform entitlement sets and notarization helper script that enable dry-run submissions from CI. The Tuist configuration updates keep generated projects aligned with the source-controlled bundle IDs, versions, and entitlements.
- **Next steps carried forward:** Run the macOS-only streaming UI automation and Combine benchmark suites, surface session persistence diagnostics, and decide whether notarization requires Apple Events automation once macOS hardware and diagnostics plumbing are available; see the refreshed `DOCS/INPROGRESS/next_tasks.md` for tracking.

## 57_Distribution_Apple_Events_Notarization_Assessment
- **Archived files:** `56_Distribution_Apple_Events_Notarization_Assessment.md`, `57_Distribution_Apple_Events_Notarization_Assessment.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/57_Distribution_Apple_Events_Notarization_Assessment/`.
- **Highlights:** Captures the notarization entitlement audit confirming Apple Events automation is unnecessary for the current `notarytool` workflow while documenting how to extend entitlements if Finder or Archive Utility scripting becomes required.
- **Next steps carried forward:** Continue tracking macOS-only automation, benchmarking, and session persistence diagnostics via `DOCS/INPROGRESS/next_tasks.md`; revisit distribution entitlements if future tooling introduces Apple Events dependencies.

## 58_F4_User_Manual
- **Archived files:** `F4_User_Manual.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/58_F4_User_Manual/`.
- **Highlights:** Documents delivery of the ISOInspector user manuals for the SwiftUI app and CLI, covering onboarding flows, navigation, persistence behaviour, and automation-oriented command usage validated by Markdown linting.
- **Next steps carried forward:** Capture platform-specific screenshots and document diagnostics-driven persistence troubleshooting once logging signals surface, alongside macOS-only automation and benchmark runs tracked in `DOCS/INPROGRESS/next_tasks.md`.

## 60_Summary_of_Work_2025-10-13_Release_Runbook
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/60_Summary_of_Work_2025-10-13_Release_Runbook/`.
- **Highlights:** Captures the release readiness checklist finalization, go-live runbook publication, and supporting distribution metadata plus notarization tooling references that now live under `Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md`.
- **Next steps carried forward:** Hardware-dependent macOS UI automation runs, Combine-backed UI benchmark execution on macOS, session persistence diagnostics surfacing, and notarization Apple Events automation evaluation remain tracked in `DOCS/INPROGRESS/next_tasks.md` and `todo.md`.

## 61_A2_Implement_MappedReader
- **Archived files:** `A2_Implement_MappedReader.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/61_A2_Implement_MappedReader/`.
- **Highlights:** Records the delivery of a memory-mapped `RandomAccessReader` that wraps `Data(contentsOf:options:.mappedIfSafe)`, ensures safe slice extraction, and falls back gracefully when mapping is unavailable. Includes accompanying unit coverage for boundary enforcement and failure handling.
- **Next steps carried forward:** Revisit IO roadmap items A4–A5 to introduce explicit reader error types and benchmarking, and continue tracking macOS automation, benchmark runs, and persistence diagnostics in the refreshed `DOCS/INPROGRESS/next_tasks.md` checklist.

## 63_Summary_of_Work_2025-10-15
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/63_Summary_of_Work_2025-10-15/`.
- **Highlights:** Captures the October 15, 2025 checkpoint closing Task A4 with the unified `RandomAccessReaderError` taxonomy, aligned error reporting across mapped, chunked, and in-memory readers, and extended regression coverage for bounds, overflow, and IO propagation.
- **Next steps carried forward:** Recreated `DOCS/INPROGRESS/next_tasks.md` tracks IO roadmap Task A5 benchmarking work along with macOS-only automation, Combine UI benchmarking, session persistence diagnostics, and notarization follow-ups until required hardware and diagnostics plumbing land.

## 65_Summary_of_Work_2025-10-15_Benchmark
- **Archived files:** `2025-10-15-random-slice-benchmark.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/65_Summary_of_Work_2025-10-15_Benchmark/`.
- **Highlights:** Captures the October 15, 2025 benchmarking checkpoint consolidating the random slice harness design notes, throughput baselines for `MappedReader` vs. `ChunkedFileReader`, and the summary documenting Task A5 closure following the unified error taxonomy work.
- **Next steps carried forward:** Fresh `DOCS/INPROGRESS/next_tasks.md` tracks the macOS hardware runs required for random slice benchmarking, macOS UI automation, Combine-backed UI benchmarking, session persistence diagnostics, and notarization entitlement follow-ups until the needed platforms and diagnostics plumbing are available.

## 67_Summary_of_Work_2025-10-16
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/67_Summary_of_Work_2025-10-16/`.
- **Highlights:** Captures the October 16, 2025 checkpoint that wrapped Task E5 by surfacing document load failures in the SwiftUI app shell with banner-based retry and dismissal handling, plus validated the flow via updated controller publishing and UI coverage.
- **Next steps carried forward:** Hardware-dependent macOS benchmark and automation runs, diagnostics plumbing for session/recents persistence, and notarization Apple Events follow-ups remain tracked in the refreshed `DOCS/INPROGRESS/next_tasks.md` alongside the backlog in `todo.md`.

## 68_E6_Emit_Persistence_Diagnostics
- **Archived files:** `E6_Emit_Persistence_Diagnostics.md`, `Summary_of_Work.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/68_E6_Emit_Persistence_Diagnostics/`.
- **Highlights:** Documents completion of Task E6 by emitting diagnostics for recents and session persistence failures through the shared logging pipeline, introducing an injectable diagnostics protocol, and extending controller tests with stubs that assert error reporting.
- **Next steps carried forward:** Reconcile CoreData bookmark diffs with live session data and execute the macOS-only automation plus benchmarking work recorded in `DOCS/INPROGRESS/next_tasks.md`.

## 69_G1_FilesystemAccessKit_Core_API
- **Archived files:** `G1_FilesystemAccessKit_Core_API.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/69_G1_FilesystemAccessKit_Core_API/`.
- **Highlights:** Delivers the FilesystemAccessKit facade with async open/save/bookmark operations, macOS `NSOpenPanel`/`NSSavePanel` adapters, and unit tests covering bookmark lifecycle, stale access recovery, and diagnostics logging integrations.
- **Next steps carried forward:** Plan bookmark persistence integration (G2), CLI sandbox profile guidance (G3), and hardware-bound automation plus benchmarking work now tracked in the refreshed `DOCS/INPROGRESS/next_tasks.md` and Phase G workplan entries.

## 70_Bookmark_Persistence_Schema
- **Archived files:** `2025-10-16-bookmark-persistence-schema.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/70_Bookmark_Persistence_Schema/`.
- **Highlights:** Captures the shared `BookmarkPersistenceStore` design, schema notes, and verification details covering JSON/CoreData consumers plus the macOS CI workflow fix that pins Tuist CLI downloads to the latest release tag.
- **Next steps carried forward:** Wire the shared bookmark store into recents and session controllers (see `todo.md` PDD:45m) and continue tracking sandbox automation plus macOS benchmark follow-ups in `DOCS/INPROGRESS/next_tasks.md`.

## 71_G2_Persist_FilesystemAccessKit_Bookmarks
- **Archived files:** `G2_Persist_FilesystemAccessKit_Bookmarks.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/71_G2_Persist_FilesystemAccessKit_Bookmarks/`.
- **Highlights:** Captures the integration pass that wires `BookmarkPersistenceStore` through recents JSON storage and workspace session controllers, introduces dependency-injected bookmark management for UI flows, and documents verification via updated tests and `swift test --disable-sandbox`.
- **Next steps carried forward:** Renewed `DOCS/INPROGRESS/next_tasks.md` tracks sandbox profile guidance for the CLI along with macOS-dependent benchmark, UI automation, session reconciliation, and notarization follow-ups pending hardware and entitlement access.

## 72_G3_Expose_CLI_Sandbox_Profile_Guidance
- **Archived files:** `G3_Expose_CLI_Sandbox_Profile_Guidance.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/72_G3_Expose_CLI_Sandbox_Profile_Guidance/`.
- **Highlights:** Publishes the CLI sandbox automation runbook with sample `.sb` profiles, bookmark capture and authorization flows, troubleshooting tips, and verification steps that align with FilesystemAccessKit entitlements.
- **Next steps carried forward:** Continue Task G4 zero-trust logging work *(now in progress — see `DOCS/INPROGRESS/G4_Zero_Trust_Logging.md`)*, add automated coverage for the `--open`/`--authorize` flags, and bundle signed sandbox profiles with notarized distributions per the archived next-task checklist.

## 73_Sandbox_Profile_Guidance_Sprint
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/73_Sandbox_Profile_Guidance_Sprint/`.
- **Highlights:** Wraps the sandbox profile guidance sprint that finalized Task G3 documentation updates, refreshed the CLI manual, and recorded cross-references into the workplan and PRD backlog.
- **Next steps carried forward:** Renewed `DOCS/INPROGRESS/next_tasks.md` continues to track macOS hardware-dependent benchmarks and automation coverage, session bookmark reconciliation, and notarization Apple Events follow-up items until platform access is available.

## 74_G4_Zero_Trust_Logging
- **Archived files:** `G4_Zero_Trust_Logging.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/74_G4_Zero_Trust_Logging/`.
- **Highlights:** Captures completion of Task G4 zero-trust logging by recording hashed path identifiers, timestamped audit entries, and bounded rotation diagnostics across FilesystemAccessKit along with the supporting design narrative.
- **Next steps carried forward:** Follow-up CLI bookmark wiring for the audit trail remains on `todo.md`, while macOS benchmark and automation runs continue in the refreshed `DOCS/INPROGRESS/next_tasks.md` alongside other hardware-dependent work.

## 75_PDD1h_Provide_UIDocumentPicker_Integration
- **Archived files:** `PDD1h_Provide_UIDocumentPicker_Integration.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/75_PDD1h_Provide_UIDocumentPicker_Integration/`.
- **Highlights:** Documents delivery of the UIKit-backed `FilesystemDocumentPickerPresenter`, the platform-specific wiring inside `FilesystemAccess.live`, and the accompanying verification notes confirming Linux CI coverage via injectable presenters.
- **Next steps carried forward:** Hardware-dependent macOS benchmark, UI automation, session reconciliation, and notarization follow-ups remain tracked in the refreshed `DOCS/INPROGRESS/next_tasks.md` alongside the backlog entries in `todo.md` and the execution workplan.

## 76_VR006_Preview_Audit_Integration
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/76_VR006_Preview_Audit_Integration/`.
- **Highlights:** Records closure of the VR-006 preview audit workflow by verifying SwiftUI previews route through `ResearchLogMonitor.audit` and layering accessibility assertions for missing fixture and schema mismatch states.
- **Next steps carried forward:** Hardware-dependent benchmark, UI automation, and distribution follow-ups remain blocked and continue to live in `DOCS/INPROGRESS/next_tasks.md`.

## 77_C7_Connect_Bookmark_Diffs_to_Resolved_Bookmarks
- **Archived files:** `C7_Connect_Bookmark_Diffs_to_Resolved_Bookmarks.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/77_C7_Connect_Bookmark_Diffs_to_Resolved_Bookmarks/`.
- **Highlights:** Captures the session persistence updates that resolve CoreData bookmark diff entities to their corresponding `Bookmark` records, propagate identifiers through snapshot exports, and extend regression coverage for the reconciliation pipeline.
- **Next steps carried forward:** Renewed `DOCS/INPROGRESS/next_tasks.md` tracks the macOS hardware-dependent benchmark, UI automation, and notarization follow-ups that remain blocked pending Combine and entitlement support.

## 78_PDD_30m_Wire_CLI_Bookmark_Flows
- **Archived files:** `PDD_30m_Wire_CLI_Bookmark_Flows.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/78_PDD_30m_Wire_CLI_Bookmark_Flows/`.
- **Highlights:** Documents the CLI bookmark wiring that routes open/authorize flows through `FilesystemAccessAuditTrail`, adds telemetry-aware factory plumbing, and records verification of audit event emission when telemetry flags are enabled.
- **Next steps carried forward:** No new follow-ups introduced; macOS hardware-dependent benchmarks and automation remain tracked in `DOCS/INPROGRESS/next_tasks.md`.

## 79_Readme_Feature_Matrix_and_Distribution_Follow_Up
- **Archived files:** `79_Distribution_Apple_Events_Follow_Up.md`, `80_I4_README_Feature_Matrix_and_Screenshots.md`, `Summary_of_Work.md`, and the session `next_tasks.md` checklist.
- **Archived location:** `DOCS/TASK_ARCHIVE/79_Readme_Feature_Matrix_and_Distribution_Follow_Up/`.
- **Highlights:** Captures the notarized distribution Apple Events follow-up decision, the README feature matrix rollout with supporting assets, and the bookkeeping summary documenting the workplan/PRD updates.
- **Next steps carried forward:** Hardware-dependent macOS benchmarks and UI automation remain blocked and now live in the recreated `DOCS/INPROGRESS/next_tasks.md` checklist until dedicated hardware is available.

## 80_Summary_of_Work_2025-10-17_App_Theming
- **Archived files:** `I3_App_Theming.md`, `Summary_of_Work.md`, and the prior `next_tasks.md` checklist.
- **Archived location:** `DOCS/TASK_ARCHIVE/80_Summary_of_Work_2025-10-17_App_Theming/`.
- **Highlights:** Records delivery of the refreshed SwiftUI theming layer, including the WCAG-AA brand palette, app-wide tint modifier, and asset catalog wiring captured in the accompanying Summary of Work.
- **Next steps carried forward:** Production icon rasterization remains outstanding (`todo.md` PDD:45m) alongside the macOS hardware-dependent benchmark and automation runs documented in `DOCS/INPROGRESS/next_tasks.md`.

## 81_Summary_of_Work_2025-10-18_FullBoxReader_and_AppIcon
- **Archived files:** `B5_FullBoxReader.md`, `I3_App_Icon_Rasterization.md`, `Summary_of_Work.md`, and the `next_tasks.md` checklist.
- **Archived location:** `DOCS/TASK_ARCHIVE/81_Summary_of_Work_2025-10-18_FullBoxReader_and_AppIcon/`.
- **Highlights:** Captures introduction of the shared `FullBoxReader` helper plus parser refactors, alongside the production app icon rasterization workflow and verification notes consolidated in the Summary of Work.
- **Next steps carried forward:** macOS-only benchmark, UI automation, and Combine validation runs remain blocked pending hardware access and continue in the recreated `DOCS/INPROGRESS/next_tasks.md` checklist.

## 83_Summary_of_Work_2025-10-Release_Prep
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/83_Summary_of_Work_2025-10-Release_Prep/`.
- **Highlights:** Captures the October 2025 release prep wrap-up, including v0.1.0 release note publication, distribution checklist validation, and the associated QA evidence for the CLI build and test suites.
- **Next steps carried forward:** macOS-only release readiness verification, benchmark execution, UI automation, and Combine latency measurements remain blocked pending hardware access and continue in `DOCS/INPROGRESS/next_tasks.md`.

## 84_R2_Fixture_Acquisition
- **Archived files:** `R2_Fixture_Acquisition.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/`.
- **Highlights:** Captures the fixture acquisition research catalog, licensing guidance, storage sizing analysis, and workflow recommendations needed to unblock manifest-driven fixture downloads.
- **Next steps carried forward:** Recreated `DOCS/INPROGRESS/next_tasks.md` tracks the blocked macOS hardware validations and the follow-up fixture automation work outlined in the backlog.

## 85_PDD_45m_Wire_Generate_Fixtures_Manifest
- **Archived files:** `PDD_45m_Wire_Generate_Fixtures_Manifest.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/85_PDD_45m_Wire_Generate_Fixtures_Manifest/`.
- **Highlights:** Records completion of the manifest-driven fixture acquisition workflow, including checksum validation, license mirroring, and regression coverage for the updated `generate_fixtures.py` helper.
- **Next steps carried forward:** Author the fixture storage README outlining macOS runner mounts and Linux CI cache paths once infrastructure is available, keeping alignment with `todo.md` item `PDD:30m Produce fixture storage README`. **(Completed — documentation archived in `DOCS/TASK_ARCHIVE/86_PDD_30m_Fixture_Storage_README/` with follow-up summary in `DOCS/TASK_ARCHIVE/87_Summary_of_Work_2025-10-18_Storage_Workflow/`.)**

## 86_PDD_30m_Fixture_Storage_README
- **Archived files:** `PDD_30m_Fixture_Storage_README.md`, `Summary_of_Work.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/86_PDD_30m_Fixture_Storage_README/`.
- **Highlights:** Documents the macOS and Linux fixture storage quotas, mount paths, cache rotation process, and CI alignment guidance required to operationalize manifest-driven fixture downloads.
- **Next steps carried forward:** Exercise the storage workflow on macOS hardware to validate sparse bundle mounts and finalize CI automation once runners are available.

## 87_Summary_of_Work_2025-10-18_Storage_Workflow
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/87_Summary_of_Work_2025-10-18_Storage_Workflow/`.
- **Highlights:** Captures the storage workflow bookkeeping, linking the fixture storage README to the broader distribution plan and recording pending macOS validation work.
- **Next steps carried forward:** macOS-only release readiness, benchmark, automation, and Combine latency runs remain blocked pending hardware access and now persist in `DOCS/INPROGRESS/next_tasks.md`.

## 88_G6_Export_JSON_Actions
- **Archived files:** `G6_Export_JSON_Actions.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/88_G6_Export_JSON_Actions/`.
- **Highlights:** Documents delivery of document-wide and selection-scoped JSON export affordances across the app toolbar, command menu, and outline context menu, backed by the updated `DocumentSessionController` workflow with FilesystemAccess integration and comprehensive tests.
- **Next steps carried forward:** Select a new foreground puzzle; otherwise continue tracking release readiness, benchmarking, and UI automation follow-ups in `DOCS/INPROGRESS/next_tasks.md`.

## 89_Next_Tasks_Rollup
- **Archived files:** `.gitkeep`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/89_Next_Tasks_Rollup/`.
- **Highlights:** Preserves the standing backlog checklist while rotating `DOCS/INPROGRESS` for the next assignment cycle. Captures the unchanged release readiness, benchmarking, UI automation, and Combine follow-ups that remain blocked pending macOS hardware access.
- **Next steps carried forward:** Recreated `DOCS/INPROGRESS/next_tasks.md` with the same macOS-dependent follow-ups so future task selection can resume from the shared backlog.

## 90_Summary_of_Work_2025-10-19
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/90_Summary_of_Work_2025-10-19/`.
- **Highlights:** Captures the rollover that confirmed `todo.md #3` remains complete and preserves the standing macOS-dependent validation backlog for the next assignee.
- **Next steps carried forward:** Recreated `DOCS/INPROGRESS/next_tasks.md` continues to track the macOS release readiness, benchmarking, UI automation, and Combine latency follow-ups until hardware is available.

## 92_Summary_of_Work_2025-10-19_Accessibility_Guidelines
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/92_Summary_of_Work_2025-10-19_Accessibility_Guidelines/`.
- **Highlights:** Captures the October 19, 2025 accessibility guidelines checkpoint, linking the published DocC guide with NestedA11yIDs navigation updates and noting that the earlier R3 PRD has been archived for traceability.
- **Next steps carried forward:** Recreated `DOCS/INPROGRESS/next_tasks.md` continues to track the macOS-only release readiness, benchmarking, UI automation, and Combine latency runs that remain blocked pending hardware access.

## 93_R4_Large_File_Performance_Benchmarks
- **Archived files:** `R4_Large_File_Performance_Benchmarks.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/93_R4_Large_File_Performance_Benchmarks/`.
- **Highlights:** Captures the large-file benchmark charter detailing CLI and SwiftUI execution scenarios, fixture sourcing plan, instrumentation matrix, and mitigation strategy for hardware availability, storage pressure, and tooling drift risks.
- **Next steps carried forward:** Recreated `DOCS/INPROGRESS/next_tasks.md` tracks the macOS hardware-dependent benchmark execution, release readiness validation, UI automation, and Combine latency runs that remain blocked until runners come online.

## 94_H2_Unit_Tests
- **Archived files:** `H2_Unit_Tests.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/94_H2_Unit_Tests/`.
- **Highlights:** Captures hardening the header decoder and parser registry unit suites with oversized payload checks, UUID boundary coverage, and version 1 movie/track header assertions tied to width, height, and next track identifiers.
- **Next steps carried forward:** macOS-bound benchmarking, release readiness, and automation follow-ups remain blocked and now persist in the recreated `DOCS/INPROGRESS/next_tasks.md` checklist until dedicated runners come online.

## 95_C4_mdhd_Media_Header_Parser
- **Archived files:** `C4_mdhd_Media_Header_Parser.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/95_C4_mdhd_Media_Header_Parser/`.
- **Highlights:** Documents delivery of the `mdhd` media header parser, including version-aware timestamp decoding, duration/time-scale extraction, language code helpers, and test fixtures covering 32-bit, 64-bit, and short-payload regressions now wired through the default `BoxParserRegistry`.
- **Next steps carried forward:** Recreated `DOCS/INPROGRESS/next_tasks.md` targets the follow-on `hdlr` parser implementation while preserving the macOS-only benchmarking, release readiness, UI automation, and Combine latency follow-ups awaiting dedicated hardware.

## 96_C5_hdlr_Handler_Parser
- **Archived files:** `C5_hdlr_Handler_Parser.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/`.
- **Highlights:** Finalizes the handler (`hdlr`) box parser with handler type classification, UTF-8 name decoding, and streaming/CLI/UI integration tests that verify metadata propagation through exports and SwiftUI detail flows.
- **Next steps carried forward:** `DOCS/INPROGRESS/next_tasks.md` retains the handler categorization follow-up along with the macOS-bound benchmarking, release readiness, UI automation, and Combine latency work awaiting dedicated runners.

## 97_C6_stsd_Sample_Description_Parser
- **Archived files:** `C6_stsd_Sample_Description_Parser.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/97_C6_stsd_Sample_Description_Parser/`.
- **Highlights:** Adds a full-box parser that enumerates each `stsd` sample entry, records entry byte lengths, surfaces data reference indices, and extracts baseline visual/audio metadata for `avc1`, `hvc1`, and `mp4a` entries with targeted unit coverage.
- **Next steps carried forward:** Extend the parser with codec-specific descriptors (`avcC`, `hvcC`, encrypted variants) and resume the hardware-dependent benchmarking, release readiness, and UI automation runs tracked in `DOCS/INPROGRESS/next_tasks.md`.

## 98_H3_JSON_Export_Snapshot_Tests
- **Archived files:** `H3_JSON_Export_Snapshot_Tests.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/98_H3_JSON_Export_Snapshot_Tests/`.
- **Highlights:** Preserves the JSON export snapshot suite rollout, including pretty-printed baseline fixtures, regeneration workflow, and Swift test verification guidance for guarding tree format regressions.
- **Next steps carried forward:** Parser enhancements for codec-specific `stsd` metadata plus macOS-bound benchmarking, release readiness, UI automation, and Combine latency runs remain tracked in the recreated `DOCS/INPROGRESS/next_tasks.md` until hardware access is available.

## 99_C1_ftyp_Box_Parser
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/99_C1_ftyp_Box_Parser/`.
- **Highlights:** Captures delivery of the structured `ftyp` box payload parser, including brand metadata propagation through the streaming pipeline, updated JSON export snapshots, and broad regression coverage across parser registry and live pipeline tests.
- **Next steps carried forward:** Codec inference for `ftyp` brand data remains on the backlog and is tracked through the standing hardware-dependent checklist in `DOCS/INPROGRESS/next_tasks.md`.

## 100_Summary_of_Work_2025-10-19_ftyp_Follow_Up
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/100_Summary_of_Work_2025-10-19_ftyp_Follow_Up/`.
- **Highlights:** Rolls forward the October 19, 2025 work log confirming the `ftyp` parser integration, cross-linking parser coverage and verification commands, and documenting follow-up coordination with the codec backlog.
- **Next steps carried forward:** Recreated `DOCS/INPROGRESS/next_tasks.md` preserves the macOS-only benchmarking, release readiness, UI automation, Combine latency runs, and codec descriptor follow-ups awaiting dedicated hardware and future planning cycles.

## 102_C6_Extend_stsd_Codec_Metadata
- **Archived files:** `C6_Extend_stsd_Codec_Metadata.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/`.
- **Highlights:** Documents the codec-specific metadata extraction for `stsd` sample entries, including dedicated parsers for `avcC`, `hvcC`, `esds`, and Common Encryption protection boxes alongside refreshed unit tests.
- **Next steps carried forward:** Monitor upcoming codec payload additions (e.g., Dolby Vision descriptors) and extend `BoxParserRegistry` coverage when new fixtures land, tracked in `DOCS/INPROGRESS/next_tasks.md`.

## 103_C2_mvhd_Movie_Header_Parser
- **Archived files:** `C2_mvhd_Movie_Header_Parser.md`, `C6_Codec_Payload_Additions.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/`.
- **Highlights:** Captures delivery of the `mvhd` movie header parser with full transformation matrix decoding, JSON exporter updates, refreshed fixtures, and the codec payload planning roadmap spanning Dolby Vision, AV1, VP9, AC-4, and MPEG-H follow-ups.
- **Next steps carried forward:** Hardware-dependent benchmarking, release readiness, UI automation, Combine latency benchmarks, and codec descriptor implementation threads now persist in the recreated `DOCS/INPROGRESS/next_tasks.md` checklist awaiting macOS runners and future planning cycles.

## 108_Summary_of_Work_2025-10-19_Performance_Benchmark_Readout
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/108_Summary_of_Work_2025-10-19_Performance_Benchmark_Readout/`.
- **Highlights:** Captures the October 19, 2025 benchmark validation session that closed Task H4, including CLI and local run comparisons, release documentation updates, and links to the archived XCTest outputs.
- **Next steps carried forward:** The recreated `DOCS/INPROGRESS/next_tasks.md` keeps the macOS hardware-dependent benchmark, UI automation, release readiness, and Combine latency follow-ups until dedicated runners become available.

## 110_Summary_of_Work_2025-10-19_C9_C10_Planning
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/110_Summary_of_Work_2025-10-19_C9_C10_Planning/`.
- **Highlights:** Preserves the October 19 worklog capturing the completed `stsc` parser delivery, linked Swift test coverage, and coordination notes for the upcoming `stsz/stz2` and `stco/co64` parser efforts that depend on the new detail model.
- **Next steps carried forward:** The recreated `DOCS/INPROGRESS/next_tasks.md` now calls out the C9/C10 parser alignment alongside the standing macOS-bound benchmarking, release readiness, UI automation, and Combine latency runs awaiting dedicated hardware.

## 111_C3_tkhd_Track_Header_Parser
- **Archived files:** `C3_tkhd_Track_Header_Parser.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/111_C3_tkhd_Track_Header_Parser/`.
- **Highlights:** Captures completion of the `tkhd` track header parser with version-aware timeline decoding, flag-derived enablement states, fixed-point transformation matrices, and presentation dimension exports wired into the JSON/UI surfaces alongside refreshed fixture coverage.
- **Next steps carried forward:** The recreated `DOCS/INPROGRESS/next_tasks.md` now focuses on coordinating the upcoming C9 (`stsz/stz2`) and C10 (`stco/co64`) parser efforts plus the macOS-bound benchmarking, release readiness, UI automation, and Combine latency validations awaiting dedicated hardware.

## 112_C9_stsz_stz2_Sample_Size_Parser
- **Archived files:** `C9_stsz_stz2_Sample_Size_Parser.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/112_C9_stsz_stz2_Sample_Size_Parser/`.
- **Highlights:** Captures the dedicated `stsz`/`stz2` sample size parser implementation, JSON/export wiring, and Swift test coverage validating constant, variable, and malformed sample tables while documenting CLI/UI integration notes.
- **Next steps carried forward:** Recreated `DOCS/INPROGRESS/next_tasks.md` keeps the C10 chunk offset coordination plus the macOS-dependent benchmarking, release readiness, UI automation, and Combine latency follow-ups awaiting hardware support.

## 113_C10_stco_co64_Chunk_Offset_Parser
- **Archived files:** `C10_stco_co64_Chunk_Offset_Parser.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/113_C10_stco_co64_Chunk_Offset_Parser/`.
- **Highlights:** Documents delivery of the 32-bit `stco` and 64-bit `co64` chunk offset parsers, normalization into the shared sample table model, JSON/export integration, and linked Swift verification covering registry wiring and snapshot updates.
- **Next steps carried forward:** `DOCS/INPROGRESS/next_tasks.md` now centers on implementing validation rule #15 that correlates `stsc` chunk runs, `stsz/stz2` sample sizes, and the newly archived chunk offsets alongside the standing macOS hardware-dependent benchmarks, release readiness, UI automation, and Combine latency follow-ups.

## 114_C10_stco_co64_Chunk_Offset_Parser_Update
- **Archived files:** `C10_stco_co64_Chunk_Offset_Parser.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/114_C10_stco_co64_Chunk_Offset_Parser_Update/`.
- **Highlights:** Captures the refined chunk offset parser that now emits decimal and hexadecimal offsets for both `stco` (32-bit) and `co64` (64-bit) tables, refreshed JSON fixture baselines, and extended Swift tests validating truncated table handling.
- **Next steps carried forward:** Validation rule #15 to correlate `stsc` runs with `stsz/stz2` sample sizes remains active alongside macOS hardware-dependent benchmarking, release readiness, UI automation, and Combine latency validations — all tracked in the recreated `DOCS/INPROGRESS/next_tasks.md` checklist.

## 115_C11_stss_Sync_Sample_Table
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/115_C11_stss_Sync_Sample_Table/`.
- **Highlights:** Captures the sync sample table parser delivery, including CLI integration, fixture expansion, and refreshed JSON snapshots.
- **Next steps carried forward:** Align validation rule #15 with the updated random-access metadata so chunk offsets, sample sizes, and sync markers remain coherent.

## 116_Summary_of_Work_Parser_Focus
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/116_Summary_of_Work_Parser_Focus/`.
- **Highlights:** Aggregates parser progress notes through the C11 `stss` sync sample milestone, including cross-references to refreshed JSON exports and streaming validation coverage.
- **Next steps carried forward:** Prioritize remaining Phase C parser backlog (C12–C15) and VR-015 validation coherence checks to unblock end-to-end random access reporting.

## 117_C12_dinf_dref_Data_Reference_Parser
- **Archived files:** `C12_dinf_dref_Data_Reference_Parser.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/117_C12_dinf_dref_Data_Reference_Parser/`.
- **Highlights:** Captures completion of the `dinf/dref` data reference parser with dedicated registry wiring, refreshed JSON export snapshots, and Swift tests exercising URL/URN payload coverage, all summarized for downstream random-access validation work.
- **Next steps carried forward:** The recreated `DOCS/INPROGRESS/next_tasks.md` prioritizes the remaining Phase C parser backlog (C13–C15) and Validation Rule #15 coherence checks so media metadata stays aligned with chunk correlation logic.

## 118_C13_Surface_smhd_vmhd_Media_Header_Fields
- **Archived files:** `C13_Surface_smhd_vmhd_Media_Header_Fields.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/118_C13_Surface_smhd_vmhd_Media_Header_Fields/`.
- **Highlights:** Documents the delivery of dedicated `smhd` and `vmhd` media header parsers, JSON export updates, and validation coverage ensuring balance, graphics mode, and opcolor metadata flows through the registry and downstream consumers.
- **Next steps carried forward:** The new `DOCS/INPROGRESS/next_tasks.md` breaks down Phase C Task C14 (`edts/elst` edit lists) into actionable subtasks while keeping C15 metadata boxes and Validation Rule #15 queued for follow-up.

## 121_C14b_Implement_elst_Parser
- **Archived files:** `C14b_Implement_elst_Parser.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/121_C14b_Implement_elst_Parser/`.
- **Highlights:** Registers the streaming `elst` decoder that emits normalized edit list metadata, playback rates, and cumulative presentation offsets while threading `mvhd`/`mdhd` timescales into the live parse pipeline. Fixtures and tests cover both 32-bit and 64-bit edit entries so CLI exports and downstream consumers stay aligned.
- **Next steps carried forward:** The recreated `DOCS/INPROGRESS/next_tasks.md` now tracks Tasks C14c–C14d for validation and fixture updates, plus Task C15 metadata coverage and Validation Rule #15 chunk/sample correlation work.

## 122_C14c_Edit_List_Duration_Validation
- **Archived files:** `C14c_Edit_List_Duration_Validation.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/122_C14c_Edit_List_Duration_Validation/`.
- **Highlights:** Captures validation rule VR-014 that reconciles edit list presentation spans against `mvhd`, `tkhd`, and `mdhd` durations, surfaces unsupported playback rates, and defers diagnostics until referenced media headers are parsed so streaming order remains flexible.
- **Next steps carried forward:** Fresh fixtures (Task C14d), metadata box coverage (Task C15), and Validation Rule #15 chunk/sample correlation remain open in `DOCS/INPROGRESS/next_tasks.md` alongside existing backlog checkpoints.

## 124_Summary_of_Work_2025-10-20
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/124_Summary_of_Work_2025-10-20/`.
- **Highlights:** Summarizes completion of Task C14d fixture refresh with regenerated edit list JSON exports, snapshot baselines, and regression validation commands covering empty, offset, multi-segment, and rate-adjusted scenarios.
- **Next steps carried forward:** Task C15 metadata box coverage and Validation Rule #15 chunk/sample correlation remain tracked in the recreated `DOCS/INPROGRESS/next_tasks.md` checklist.

## 125_C15_Metadata_Box_Coverage
- **Archived files:** `C15_Metadata_Box_Coverage.md`, `Summary_of_Work.md`, `next_tasks.md`, `split_plan.yaml`.
- **Archived location:** `DOCS/TASK_ARCHIVE/125_C15_Metadata_Box_Coverage/`.
- **Highlights:** Captures delivery of baseline metadata box parsing, environment propagation, and JSON export updates for `udta/meta/keys/ilst`, including parser registry wiring notes and streaming walker validation results.
- **Next steps carried forward:** The refreshed `DOCS/INPROGRESS/next_tasks.md` now prioritizes extending metadata value decoding for new fixture types and implementing Validation Rule #15 chunk/sample correlation diagnostics.

## 126_C17_mdat_Box_Parser
- **Archived files:** `C17_mdat_Box_Parser.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/126_C17_mdat_Box_Parser/`.
- **Highlights:** Documents the streaming `mdat` parser that records header offsets and payload length, updates JSON export baselines, and refreshes regression coverage so large media payloads are skipped without loading bytes.
- **Next steps carried forward:** `DOCS/INPROGRESS/next_tasks.md` continues to track the metadata decoding expansion and Validation Rule #15 chunk/sample correlation diagnostics referenced across the backlog.

## 127_C18_free_skip_Pass_Through
- **Archived files:** `C18_free_skip_Pass_Through.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/127_C18_free_skip_Pass_Through/`.
- **Highlights:** Records the shared padding parser added to `BoxParserRegistry`, JSON export updates that surface padding metadata, and the verification notes covering unit plus live pipeline coverage for `free`/`skip` boxes.
- **Next steps carried forward:** Continue the metadata decoding expansion and Validation Rule #15 correlation work now tracked in `DOCS/INPROGRESS/next_tasks.md`.

## 128_C15_Metadata_Value_Decoding_Expansion
- **Archived files:** `C15_Metadata_Value_Decoding_Expansion.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/128_C15_Metadata_Value_Decoding_Expansion/`.
- **Highlights:** Documents the metadata value decoding enhancements that add boolean, floating-point, and binary payload renderers across the parse tree and JSON exporters, with fixtures validating CLI/app parity.
- **Next steps carried forward:** The recreated `DOCS/INPROGRESS/next_tasks.md` now tracks the remaining MP4RA metadata formats (GIF, TIFF, fixed-point) and Validation Rule #15 chunk/sample correlation diagnostics.

## 129_C15_Metadata_Value_Type_Expansion
- **Archived files:** `C15_Metadata_Value_Type_Expansion.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/129_C15_Metadata_Value_Type_Expansion/`.
- **Highlights:** Captures the follow-on metadata decoder expansion that adds GIF, TIFF, and signed fixed-point MP4RA value support across `BoxParserRegistry`, JSON exporters, and regression fixtures, keeping CLI and app outputs readable for the new data types.
- **Next steps carried forward:** Validation Rule #15 completion is now archived in `DOCS/TASK_ARCHIVE/130_VR15_Sample_Table_Correlation/`; no additional metadata follow-ups remain in the active tracker.

## 130_VR15_Sample_Table_Correlation
- **Archived files:** `Summary_of_Work.md`, `Validation_Rule_15_Sample_Table_Correlation.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/130_VR15_Sample_Table_Correlation/`.
- **Highlights:** Finalizes Validation Rule #15 by correlating `stsc` chunk runs, `stsz/stz2` sample sizes, and `stco/co64` offsets, adds regression coverage for aligned and mismatched sample tables, and documents the validator integration notes captured during delivery.
- **Next steps carried forward:** None — `DOCS/INPROGRESS/next_tasks.md` now records that no additional parser or validation follow-ups are queued.

## 131_C16_4_Future_Codec_Payload_Descriptors
- **Archived files:** `C16_4_Future_Codec_Payload_Descriptors.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/131_C16_4_Future_Codec_Payload_Descriptors/`.
- **Highlights:** Captures completion of the future codec descriptor rollout that adds typed parsers for Dolby Vision (`dvvC`), AV1 (`av1C`), VP9 (`vpcC`), Dolby AC-4 (`dac4`), and MPEG-H (`mhaC`) payloads, updates the sample entry registry, and extends fixture-backed tests to cover the new metadata surfaces.
- **Next steps carried forward:** `DOCS/INPROGRESS/next_tasks.md` now tracks acquisition of real-world fixtures for each codec so synthetic payloads can be replaced and snapshot baselines refreshed once licensing clears.

## 132_B6_Box_Parser_Registry
- **Archived files:** `B6_BoxParserRegistry.md`, `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/132_B6_Box_Parser_Registry/`.
- **Highlights:** Captures completion of the shared `BoxParserRegistry` fallback that emits placeholder payload metadata for unknown boxes, refreshes JSON export baselines to reflect the richer structure, and adds unit coverage ensuring the default parser delivers contextual byte ranges instead of `nil` payloads.
- **Next steps carried forward:** Acquire Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so snapshot baselines migrate from synthetic payloads; tracked in `DOCS/INPROGRESS/next_tasks.md` pending licensing clearance.

## 133_Summary_of_Work_2025-10-20_mvex_trex_Defaults
- **Archived files:** `Summary_of_Work.md`, `next_tasks.md`.
- **Archived location:** `DOCS/TASK_ARCHIVE/133_Summary_of_Work_2025-10-20_mvex_trex_Defaults/`.
- **Highlights:** Captures the 2025-10-20 summary that documents completion of Task D1, including the new `mvex` container plus `trex` defaults parsing, structured payload export updates, refreshed fragmented fixture snapshots, and the associated regression coverage.
- **Next steps carried forward:** `DOCS/INPROGRESS/next_tasks.md` now focuses on acquiring Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so synthetic payloads can be replaced once licensing is cleared.
