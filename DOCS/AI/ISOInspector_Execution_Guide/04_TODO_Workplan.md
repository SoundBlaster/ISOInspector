# ISOInspector Execution Workplan

The following plan decomposes delivery into dependency-aware phases. Each task includes priority, estimated effort (in ideal engineer days), required tools, dependencies, and acceptance criteria.

## Phase A — Foundations & Infrastructure
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| A1 | Initialize SwiftPM workspace with core, UI, CLI targets and shared test utilities. | High | 1 | None | SwiftPM, Xcode | Repository builds successfully; targets link with placeholder implementations. |
| A2 | Configure CI pipeline (GitHub Actions or similar) for build, test, lint. | High | 1.5 | A1 | GitHub Actions, swiftlint | CI runs on pull requests; failing tests block merge. (Completed ✅ — archived in `DOCS/ARCHIVE/01_A2_Configure_CI_Pipeline/`.) |
| A3 | Set up DocC catalog and documentation publishing workflow. | Medium | 1 | A1 | DocC, SwiftPM | `docc` build succeeds; docs published artifact accessible. (Completed ✅ — generates archives via `scripts/generate_documentation.sh`, DocC catalogs live under `Sources/*/*.docc`, tutorials expanded in `DOCS/TASK_ARCHIVE/35_A3_DocC_Tutorial_Expansion/`, and CI publishing now delivered by the TODO #12-backed `docc-archives` job.) |
| A6 | Enforce SwiftFormat-based formatting locally and in CI. | Medium | 0.5 | A2 | swift-format, GitHub Actions | `.pre-commit-config.yaml` runs `swift format --in-place` on staged Swift files; CI step executes `swift format --mode lint` and fails on diff. Documentation updated in `README.md` tooling section. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/226_A6_Enforce_SwiftFormat_Formatting/`.) |
| A7 | Reinstate SwiftLint complexity thresholds across targets. | Medium | 0.75 | A2 | SwiftLint | `.swiftlint.yml` restores `cyclomatic_complexity`, `function_body_length`, `nesting`, and `type_body_length` with agreed limits; pre-commit runs `swiftlint lint --strict`; CI publishes analyzer report artifact. *(Completed ✅ — see `DOCS/INPROGRESS/Summary_of_Work.md`.)* |
| A8 | Gate test coverage using `coverage_analysis.py`. | Medium | 1 | A2 | Python, SwiftPM | `coverage_analysis.py --threshold 0.67` executes in pre-push and GitHub Actions after `swift test --enable-code-coverage`; pushes blocked and workflow fails when ratio drops. Coverage report archived under `Documentation/Quality/` per run. *(Completed ✅ — enforced via pre-push gate and CI `coverage-gate` job with artifacts stored under `Documentation/Quality/`.)* |
| A9 | Automate strict concurrency checks for core and tests. | High | 1 | A2 | SwiftPM, GitHub Actions | Pre-push hook and CI workflow run `swift build --strict-concurrency=complete` and `swift test --strict-concurrency=complete`; logs show zero warnings. Results linked to `PRD_SwiftStrictConcurrency_Store.md` rollout checklist. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/225_A9_Swift6_Concurrency_Cleanup/`; includes post-A9 Swift 6 migration cleanup that removed redundant StrictConcurrency flags and aligned CI to Swift 6.0/Xcode 16.2.) |
| A10 | Add Swift duplication detection to CI. | Medium | 1 | A2 | GitHub Actions, Node, `jscpd` | `.github/workflows/swift-duplication.yml` runs `scripts/run_swift_duplication_check.sh` (wrapper for `npx jscpd@3.5.10`) on Swift sources for every PR/push. Workflow fails when duplicated lines exceed 1% or any block >45 lines repeats; artifact uploads console report. Plan + scope: `DOCS/AI/github-workflows/02_swift_duplication_guard/prd.md`. |
| A11 | Enable local CI execution on macOS. | Medium | 1.5 | A2 | Bash, Docker (optional) | Scripts in `scripts/local-ci/` replicate GitHub Actions workflows locally, supporting lint, build, test, and coverage jobs. Native and Docker execution modes available. Documentation in `scripts/local-ci/README.md` covers setup, usage, and troubleshooting. *(Completed ✅ — Phase 1 delivered in `DOCS/AI/github-workflows/04_local_ci_macos/`; see `Summary.md` for deliverables and coverage matrix.)* |

> **Current focus:** _BUG #001 Design System Color Token Migration_ archived to `DOCS/TASK_ARCHIVE/227_Bug001_Design_System_Color_Token_Migration/` (2025-11-16). ISOInspectorApp continues to use hardcoded `.accentColor` and manual opacity values in 6 view files instead of FoundationUI design tokens. Blocking FoundationUI Phase 5.2 completion. See archive for full analysis and blockers. Next candidate task in automation track: A10 (duplication detection), following completion of A7 (SwiftLint complexity) and A8 (coverage gate). Refer to `DOCS/INPROGRESS/next_tasks.md` and `DOCS/INPROGRESS/blocked.md` for day-to-day queue and active blockers.
>
> **Bug resolved (2025-11-25):** Bug #235 — Smoke tests blocked by Sendable violations in `WindowSessionController` under strict concurrency. Fixed via sendable annotations + document loading refactor; see `DOCS/INPROGRESS/235_Sendable_SmokeTest_Build_Failure.md` for details and test evidence.
>
> **Completed (2025-11-27):** Task **A11 — Local CI Execution on macOS** delivered comprehensive scripts for running GitHub Actions workflows locally. Phase 1 (core scripts) covers linting, builds, and tests with native and Docker execution modes. See `DOCS/AI/github-workflows/04_local_ci_macos/Summary.md` for full deliverables, `scripts/local-ci/README.md` for user guide, and `.local-ci-config.example` for configuration template.
>
> **Completed (2025-10-26):** _Snapshot & CLI Fixture Maintenance_ refreshed JSON export baselines and CLI expectations with the new issue metrics fields. Coordination details are archived in `DOCS/TASK_ARCHIVE/178_Snapshot_and_CLI_Fixture_Maintenance/`.
>
> **Status:** _Blocked_ — benchmark harness implementation is archived and awaiting macOS hardware to execute random slice metrics, UI automation coverage, and Combine-backed UI benchmarks documented in the archived `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/next_tasks.md`.
>
> **Completed (2025-10-24):** Task **T1.3 — ParsePipeline Options** added strict/tolerant presets with shared defaults. Integration notes captured in `DOCS/TASK_ARCHIVE/166_T1_3_ParsePipeline_Options/Summary_of_Work.md`.
>
> **Completed (2025-10-24):** Task **T1.4 — Refactor BoxHeaderDecoder to Result-based API** is archived in `DOCS/TASK_ARCHIVE/167_T1_4_BoxHeaderDecoder_Result_API/`, enabling tolerant parsing flows to record malformed header diagnostics without aborting sibling traversal.
>
> **Completed (2025-10-24):** Task **T1.5 — Propagate Decoder Failures Through Tolerant Parsing** is archived in `DOCS/TASK_ARCHIVE/169_T1_5_Propagate_Decoder_Failures_Through_Tolerant_Parsing/`, documenting how decoder failures now surface as `ParseIssue` records without halting tolerant traversal.
>
> **Completed (2025-10-25):** Task **T1.6 — Implement Binary Reader Guards** is archived in `DOCS/TASK_ARCHIVE/170_T1_6_Implement_Binary_Reader_Guards/`, documenting the traversal guard clamps and tolerant parsing regression coverage captured in `Summary_of_Work.md`.
>
> **Completed (2025-10-26):** Task **T1.7 — Finalize Traversal Guard Requirements** is archived in `DOCS/TASK_ARCHIVE/171_T1_7_Finalize_Traversal_Guard_Requirements/`, with the guard specification published at `DOCS/AI/Tolerance_Parsing/Traversal_Guard_Requirements.md`.
>
> **Completed (2025-10-24):** Task **T1.8 — Traversal Guard Implementation** is archived in `DOCS/TASK_ARCHIVE/173_T1_8_Traversal_Guard_Implementation/`, detailing guard enforcement in `StreamingBoxWalker`, option preset updates, and verification coverage documented in `Summary_of_Work.md`.
>
> **Completed (2025-10-26):** Task **T2.1 — ParseIssueStore Aggregation** is archived in `DOCS/TASK_ARCHIVE/175_Summary_of_Work_2025-10-26_ParseIssueStore_Aggregation/`, summarizing the shared store implementation, pipeline wiring, and verification runs that closed the tolerant parsing aggregation milestone.
>
> **Completed (2025-10-27):** Task **T2.3 — Aggregate Parse Issue Metrics for UI and CLI Ribbons** is archived in `DOCS/TASK_ARCHIVE/184_T2_3_Aggregate_Parse_Issue_Metrics_for_UI_and_CLI_Ribbons/`, delivering per-severity counters and depth analytics for tolerant parsing ribbons and CLI summaries. Coordinate with design deliverables before wiring UI badges.
> - ✅ Shared metrics now publish `countsBySeverity`, `totalCount`, and `deepestAffectedDepth` snapshots via `ParseIssueStore.metricsSnapshot()` and the CLI-ready `makeIssueSummary()` helper. See `Sources/ISOInspectorKit/Stores/ParseIssueStore.swift`.
> - 📝 Summary of verification runs and follow-up notes captured in `DOCS/TASK_ARCHIVE/184_T2_3_Aggregate_Parse_Issue_Metrics_for_UI_and_CLI_Ribbons/Summary_of_Work.md`.
>
> **Completed (2025-11-07):** Task **T6.2 — CLI Corruption Summary Output** is archived in `DOCS/TASK_ARCHIVE/208_T6_2_CLI_Corruption_Summary_Output/`, shipping tolerant-mode corruption summaries in `isoinspect inspect` along with refreshed DocC examples and CLI scaffold tests that cover strict vs. tolerant flows.
> - ✅ CLI output now prints severity counts and deepest affected depth when tolerant parsing records issues, while strict-mode behavior remains unchanged.
> - 🧪 Snapshot-style CLI tests validate strict success, tolerant without issues, and tolerant with mixed severities to guard formatting.
>
> **Completed (2025-11-03):** Task **T5.2 — Regression Tests for Tolerant Traversal** is archived in `DOCS/TASK_ARCHIVE/203_T5_2_Regression_Tests_for_Tolerant_Traversal/`, capturing the manifest-driven XCTest suite, strict/tolerant guard assertions, and Swift 6.0.3 execution log.
>
> **Follow-up queued (2025-11-04):** Task **T5.4 — Performance Benchmark: Lenient vs. Strict Parsing** is archived in `DOCS/TASK_ARCHIVE/206_T5_4_Performance_Benchmark_macOS_Run/205_T5_4_Performance_Benchmark.md`. The macOS 1 GiB verification run remains pending; execution steps now tracked in `DOCS/INPROGRESS/blocked.md` (active blockers) alongside the existing Linux metrics log, with historical day-to-day notes stored at `DOCS/TASK_ARCHIVE/207_Summary_of_Work_2025-11-04_macOS_Benchmark_Block/`.
>
> **Completed (2025-11-10):** Task **T5.5 — Tolerant Parsing Fuzzing Harness** delivered automated fuzzing with 100+ synthetically corrupted payloads and 99.9% crash-free completion rate assertion. Implementation captured in `DOCS/TASK_ARCHIVE/209_T5_5_Tolerant_Parsing_Fuzzing_Harness/Summary_of_Work_T5.5.md`.
> - ✅ `TolerantParsingFuzzTests` generates deterministic mutations (header truncation, overlapping ranges, bogus sizes) via seeded RNG
> - ✅ Reproduction artifacts automatically captured under `Documentation/CorruptedFixtures/FuzzArtifacts/` for failed cases
> - ✅ Test suite validates crash-free completion rate ≥99.9% across 100+ iterations with aggregate statistics
> - 🧪 `LargeFileBenchmarkTests` now exercises lenient versus strict parsing with enforced runtime (+20%) and RSS (+50 MiB) ceilings via `PerformanceBenchmarkConfiguration`.
> - 📈 Latest Linux results (32 MiB fixture) recorded in `Documentation/Performance/2025-11-04-lenient-vs-strict-benchmark.log` show ≤1.049× overhead; rerun on macOS hardware with `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824` to close out the gate.
>
> **Completed (2025-10-27):** Task **T4.1 — Extend JSON Export Schema for Issues** is archived in `DOCS/TASK_ARCHIVE/192_T4_1_Extend_JSON_Export_Schema_for_Issues/`, capturing the schema version bump, tolerant issue payload, and refreshed documentation notes.
>
> **Completed (2025-10-27):** Task **T4.4 — Ensure Exports Omit Raw Binary Snippets** hardened tolerant parsing exports so JSON and plaintext reports only publish metadata (severity, codes, byte ranges) while omitting binary payloads. Verification recorded in `DOCS/TASK_ARCHIVE/195_T4_4_Sanitize_Issue_Exports/195_T4_4_Sanitize_Issue_Exports.md` and enforced by new redaction tests in `Tests/ISOInspectorKitTests/ParseExportTests.swift`.
>
> **Completed (2025-10-28):** Task **T3.6 — Integrity Summary Tab** shipped the dedicated diagnostics surface. Notes now live in `DOCS/TASK_ARCHIVE/196_T3_6_Integrity_Summary_Tab/`, and the follow-up polish checklist is tracked via the refreshed `DOCS/INPROGRESS/T3_6_Integrity_Summary_Tab.md` stub.
>
> **Completed (2025-10-23):** Task **E2 — Detect Zero/Negative Progress Loops** is now archived in `DOCS/TASK_ARCHIVE/163_E2_Detect_Progress_Loops/`.
>
> **Archived (D5):** _`mfra/tfra/mfro` random access tables deliverable now lives in `DOCS/TASK_ARCHIVE/140_D5_mfra_tfra_mfro_Random_Access/`. Planning notes remain in `D5_mfra_tfra_mfro_Random_Access.md` with implementation details summarized in `Summary_of_Work.md`. Random access index integration shipped across ISOInspectorKit, CLI, and JSON exports; real-world codec fixture licensing follow-ups stay blocked in the archived `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/next_tasks.md` and the active `DOCS/INPROGRESS/blocked.md`._
>
> **Recently archived:** Validator & CLI polish documentation captured in `DOCS/TASK_ARCHIVE/139_Validator_and_CLI_Polish/` alongside the fragment fixture coverage deliverable stored in `DOCS/TASK_ARCHIVE/138_Fragment_Fixture_Coverage/`. Task D3 — `traf/tfhd/tfdt/trun` fragment run parsing and validation scaffolding — remains documented in `DOCS/TASK_ARCHIVE/137_D3_traf_tfhd_tfdt_trun_Parsing/Summary_of_Work.md`, with historical planning notes retained in `DOCS/TASK_ARCHIVE/136_Summary_of_Work_2025-10-21_tfhd_Track_Fragment_Header/D3_traf_tfhd_tfdt_trun_Parsing.md`.

> **Research initiative:** Task R3 cataloged VoiceOver, Dynamic Type, and keyboard guidance so future UI tasks stay aligned with accessibility requirements. Follow <doc:AccessibilityGuidelines> and the archived summary in `DOCS/TASK_ARCHIVE/91_R3_Accessibility_Guidelines/Summary_of_Work.md` when planning new UI stories.
>
> **Completed research:** Task **R5 — Export Schema Standardization** compared Bento4, ffprobe, and ISOInspector exports to propose a canonical schema plus compatibility adapters. Findings and follow-up verification notes now live in `DOCS/TASK_ARCHIVE/151_R5_Export_Schema_Standardization/R5_Export_Schema_Standardization.md` with the corresponding summary captured in `DOCS/TASK_ARCHIVE/151_R5_Export_Schema_Standardization/Summary_of_Work.md`.
>
> **Completed:** _Export Schema Verification Harness_ extends `JSONExportSnapshotTests` and adds CLI coverage for the R5 compatibility aliases plus format summary block. Summary archived in `DOCS/TASK_ARCHIVE/152_F6_Export_Schema_Verification_Harness/Summary_of_Work.md`.

> **Completed research:** Task R4 — Large File Performance Benchmarks. Benchmark charter, fixture manifests, and instrumentation guidance live in `DOCS/TASK_ARCHIVE/93_R4_Large_File_Performance_Benchmarks/R4_Large_File_Performance_Benchmarks.md`; macOS execution remains blocked pending hardware runners noted in the archived `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/next_tasks.md` and the active `DOCS/INPROGRESS/blocked.md`.

> **Completed research:** Task R7 — CLI distribution strategy is archived in `DOCS/TASK_ARCHIVE/161_R7_CLI_Distribution_Strategy/`, delivering notarized macOS, Homebrew tap, and Linux packaging guidance plus an automation helper script.

## Phase B — Core Parsing Engine
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| B1 | Implement chunked file reader with configurable buffer size and tests. | High | 1.5 | A1 | Swift, XCTest | Reader streams 1 MB chunks; tests cover EOF, seek, and error paths. (Completed ✅) |
| B2 | Build box header decoder supporting 32-bit, 64-bit, and `uuid` boxes. | High | 2 | B1 | Swift, XCTest | Unit tests for standard and extended headers; handles malformed sizes gracefully. (Completed ✅) |
| B3 | Implement streaming parse pipeline with event emission and context stack. | High | 3 | B2 | Swift Concurrency, XCTest | Parsing sample files emits ordered events with correct offsets. (Completed ✅) |
| B4 | Integrate MP4RA metadata catalog and fallback for unknown boxes. | High | 2 | B3 | Swift, JSON parsing | Catalog loads from bundled JSON; unknown types logged for research. (Completed ✅ — see `DOCS/TASK_ARCHIVE/25_B4_C2_Category_Filtering/`.) |
| B5 | Implement validation rules VR-001 to VR-006 with test coverage. | High | 2 | B3 | XCTest | Malformed fixtures trigger expected validation outcomes. (Completed ✅ — VR-006 research logging now persists unknown boxes to a shared research log for CLI/UI analysis.) |
| B6 | Add JSON and binary export modules with regression tests. | Medium | 1.5 | B3 | Swift Codable | Exported files re-import successfully; CLI smoke tests pass. |
| B7 | Introduce validation configuration layer with per-rule toggles and preset registry. | Medium | 1.5 | B5 | Swift, XCTest | `ValidationConfiguration`/`ValidationPreset` types serialize settings, load bundled preset manifests, persist user-authored presets under Application Support, annotate exports with `skipped` disabled rules, and default to all rules enabled per `13_Validation_Rule_Toggle_Presets_PRD.md`. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/`.) |

> **Completed:** Task **B2+ — AsyncSequence Event Stream Integration** now lives in `DOCS/TASK_ARCHIVE/176_B2_Plus_AsyncSequence_Event_Stream/`, documenting the live `ParsePipeline` event stream for CLI and SwiftUI consumers.

> **Completed:** Task **B7 — Validation Configuration Layer** now lives in `DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/`, establishing presets and per-rule toggles. CLI wiring (D7) shipped via `DOCS/TASK_ARCHIVE/148_D7_Validation_Preset_CLI_Wiring/Summary_of_Work.md`, and the UI settings flow (C19) is archived in `DOCS/TASK_ARCHIVE/147_Summary_of_Work_2025-10-22_Validation_Preset_UI_Settings_Integration/Summary_of_Work.md`.
>
> **Completed (2025-10-23):** Validation follow-up **E1 — Enforce Parent Containment and Non-Overlap** now enforces child containment and sibling spacing; see `DOCS/TASK_ARCHIVE/159_E1_Enforce_Parent_Containment_and_Non_Overlap/Summary_of_Work.md` for validation updates and regression notes.

> **Completed:** Backlog follow-up **B2 — Define BoxNode Aggregate** now lives in `DOCS/TASK_ARCHIVE/158_B2_Define_BoxNode/`, documenting the canonical tree aggregate shared by ISOInspectorKit, CLI, and export flows.
>
> **Completed:** Advisory validation **E3 — Warn on Unusual Top-Level Ordering** now emits guidance when `ftyp`/`moov` sequences deviate from expectations while respecting streaming layouts; implementation recap in `DOCS/TASK_ARCHIVE/142_E3_Warn_on_Unusual_Top_Level_Ordering/Summary_of_Work.md`.

> **Completed (2025-10-20):** Backlog item **B6 — Box Parser Registry** finalized parser registration infrastructure with a placeholder payload fallback for unknown boxes. See `DOCS/TASK_ARCHIVE/132_B6_Box_Parser_Registry/Summary_of_Work.md` for implementation notes and the archived follow-up checklist in `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/next_tasks.md` (current day-to-day blockers reside in `DOCS/INPROGRESS/blocked.md`).

> **Completed (2025-10-18):** Task B5 – Introduce a `FullBoxReader` helper for `(version, flags)` decoding so downstream parsers share a common entry point. Implementation details recorded in `DOCS/TASK_ARCHIVE/81_Summary_of_Work_2025-10-18_FullBoxReader_and_AppIcon/B5_FullBoxReader.md` and `DOCS/TASK_ARCHIVE/81_Summary_of_Work_2025-10-18_FullBoxReader_and_AppIcon/Summary_of_Work.md`.
>
> **Completed (2025-10-19):** Task C6 — Implement the `stsd` sample description parser to enumerate media sample entries. See `DOCS/TASK_ARCHIVE/97_C6_stsd_Sample_Description_Parser/` for the archived PRD outline, summary, and verification notes.

> **Completed (2025-10-20):** Fragment parser backlog Task **D2 — `moof/mfhd` sequence number decoding** wrapped with sequence numbers flowing through the parse pipeline, JSON export, and CLI formatting. See `DOCS/TASK_ARCHIVE/135_Summary_of_Work_2025-10-20_moof_mfhd_Sequence_Number/` for the summary and follow-up notes; D3 fragment run scaffolding remains next.

## Phase C — User Interface Package
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| C1 | Create Combine bridge and state stores for parse events. | High | 1.5 | B3 | Combine, SwiftUI | Store receives events and updates snapshot without race conditions. (Completed ✅ — Combine-backed session bridge fan-outs parse events to SwiftUI `@MainActor` tree store with validation aggregation.) |
| C2 | Implement tree view with virtualization, search, and filters. | High | 2.5 | C1 | SwiftUI | UI renders >10k nodes smoothly; search reduces nodes instantly. (Completed ✅ — captured across `DOCS/TASK_ARCHIVE/19_C2_Tree_View_Virtualization/` through `22_C2_Extend_Outline_Filters/`.) |
| C3 | Build detail pane with metadata, validation list, and hex viewer. | High | 3 | C1 | SwiftUI | Selecting node shows metadata; hex viewer displays payload windows. (Completed ✅ — documented in `DOCS/TASK_ARCHIVE/23_C3_Detail_and_Hex_Inspectors/` and `24_C3_Highlight_Field_Subranges/`.) |
| C4 | Add annotation and bookmark management with persistence hooks. | Medium | 2 | C1 | CoreData/JSON | Notes persist across app relaunch; tests validate storage schema. (Completed ✅ — CoreData-backed store archived in `DOCS/TASK_ARCHIVE/33_C4_CoreData_Annotation_Persistence/`.) |
| C5 | Implement accessibility features (VoiceOver labels, keyboard navigation). | Medium | 1.5 | C2, C3 | Accessibility Inspector | Accessibility audit passes; UI tests confirm focus order. (Completed ✅ — VoiceOver labels derive from metadata, keyboard focus is shared across tree/detail/hex panes, and accessibility formatters are covered by new XCTest cases.) |
| C6 | Integrate ResearchLogMonitor audit results into SwiftUI previews that display VR-006 research log entries. | Medium | 1 | C3, B5 | SwiftUI Previews, DocC | Previews render VR-006 entries with audit context; mismatched schema cases surface actionable errors. **(Completed — see `DOCS/TASK_ARCHIVE/C6_Integrate_ResearchLogMonitor_Previews/Summary_of_Work.md`.)** |
| C7 | Connect persisted bookmark diff entities to resolved bookmark records once reconciliation rules are finalized. | Medium | 0.5 | C4 | CoreData, Swift | Bookmark diff persistence reconciles with bookmark entities; unit tests cover add/update/remove flows. **(Completed ✅ — see `DOCS/TASK_ARCHIVE/77_C7_Connect_Bookmark_Diffs_to_Resolved_Bookmarks/Summary_of_Work.md`.)** |
| C19 | Surface validation presets and per-rule toggles in the UI settings workflow. | Medium | 1.5 | B7, C3 | SwiftUI | Settings pane lists presets, rule toggles, respects global defaults from user preferences, persists per-workspace overrides, and includes a “Reset to Global” affordance per `13_Validation_Rule_Toggle_Presets_PRD.md`. **(Completed — see `DOCS/TASK_ARCHIVE/147_Summary_of_Work_2025-10-22_Validation_Preset_UI_Settings_Integration/Summary_of_Work.md` for delivery notes.)** |
| C21 | Build the floating user settings panel shell with platform-aware presentation. | Medium | 1 | C3, C19 | SwiftUI, FoundationUI | Keyboard shortcut summons an `NSPanel` (macOS) or modal sheet (iPad/iOS), the UI renders separate sections for permanent vs. session settings as defined in `14_User_Settings_Panel_PRD.md`, and accessibility (VoiceOver, keyboard focus) passes regression tests. |
| C22 | Wire permanent + session persistence flows plus reset affordances for the floating panel. | Medium | 1 | C21, B7, E3 | SwiftUI, CoreData/JSON | Permanent changes persist via `UserPreferencesStore`, session edits update `DocumentSessionController`, diagnostics emit failures, and the “Reset Global”/“Reset Session” actions behave as documented in `14_User_Settings_Panel_PRD.md`. |

> **Completed:** Task R3 – Accessibility guidelines now live in <doc:AccessibilityGuidelines>, with verification notes in `DOCS/TASK_ARCHIVE/91_R3_Accessibility_Guidelines/Summary_of_Work.md`.

> **Archived:** C6 follow-up extended the `stsd` sample description parser with codec-specific metadata extraction for `avcC`, `hvcC`, and `esds`, documented in `DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/C6_Extend_stsd_Codec_Metadata.md`.

> **Completed:** Task C16.4 — Future codec payload descriptors now ship typed parsers for Dolby Vision (`dvvC`), AV1 (`av1C`), VP9 (`vpcC`), Dolby AC-4 (`dac4`), and MPEG-H (`mhaC`). See `DOCS/TASK_ARCHIVE/131_C16_4_Future_Codec_Payload_Descriptors/Summary_of_Work.md` for implementation notes and the archived follow-up checklist in `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/next_tasks.md` (active blocker tracking lives in `DOCS/INPROGRESS/blocked.md`).

> **Completed:** Task C2 – Implemented the `mvhd` movie header parser exposing timescale, 32/64-bit durations, rate, volume, and transformation matrix fields. See `DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/C2_mvhd_Movie_Header_Parser.md` and `DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/Summary_of_Work.md` for implementation and verification details.

> **Completed:** Task C10 — Built the `stco/co64` chunk offset parser so chunk tables now surface normalized offsets for both 32-bit and 64-bit entries. Implementation details, verification notes, and updated fixtures are archived in `DOCS/TASK_ARCHIVE/114_C10_stco_co64_Chunk_Offset_Parser_Update/`.
>
> **Completed:** Task C12 — Delivered the `dinf/dref` data reference parser so entry metadata flows into the random-access validation stack alongside refreshed tests and JSON exports. See `DOCS/TASK_ARCHIVE/117_C12_dinf_dref_Data_Reference_Parser/Summary_of_Work.md` and `DOCS/TASK_ARCHIVE/117_C12_dinf_dref_Data_Reference_Parser/C12_dinf_dref_Data_Reference_Parser.md` for implementation notes.
>
> **Completed:** Validation rule #15 now correlates `stsc` chunk runs, `stsz/stz2` sample sizes, and the new `stco/co64` offsets. Implementation notes live in `DOCS/TASK_ARCHIVE/130_VR15_Sample_Table_Correlation/Validation_Rule_15_Sample_Table_Correlation.md`, with the delivery summary captured in `DOCS/TASK_ARCHIVE/130_VR15_Sample_Table_Correlation/Summary_of_Work.md`.
>
> **Completed:** Expanded metadata value decoding for additional data types so metadata exports stay aligned with MP4RA guidance. See `DOCS/TASK_ARCHIVE/128_C15_Metadata_Value_Decoding_Expansion/C15_Metadata_Value_Decoding_Expansion.md` for the implementation outline and dependency notes.
>
> **Completed:** Task C17 – `mdat` parser now records header offsets and payload length while skipping media bytes. Notes captured in `DOCS/TASK_ARCHIVE/126_C17_mdat_Box_Parser/Summary_of_Work.md` alongside parser and snapshot updates.
>
> **Completed:** Task C14b — Implemented the `elst` edit list parser in `BoxParserRegistry`, normalizing durations and media rates while streaming large lists. See `DOCS/TASK_ARCHIVE/121_C14b_Implement_elst_Parser/C14b_Implement_elst_Parser.md` for scope, implementation notes, and verification details.
> **Completed:** Task C14d — Refreshed edit list fixtures, JSON exports, and snapshot baselines covering empty, single-offset, multi-segment, and rate-adjusted scenarios. Notes archived in `DOCS/TASK_ARCHIVE/123_C14d_Refresh_Edit_List_Fixtures/` alongside the consolidated summary in `DOCS/TASK_ARCHIVE/124_Summary_of_Work_2025-10-20/`.
> **Completed:** Task C15 metadata coverage now ships via `DOCS/TASK_ARCHIVE/125_C15_Metadata_Box_Coverage/`, covering parser registration, environment propagation, and JSON export updates while queuing Validation Rule #15 for follow-up in the refreshed checklist.
> **Completed:** Task C14c — VR-014 edit list validation is archived in `DOCS/TASK_ARCHIVE/122_C14c_Edit_List_Duration_Validation/`, covering duration reconciliation diagnostics and deferred streaming checks.
>

> **Completed (2025-10-19):** Task C3 – Implemented the `tkhd` track header parser covering flag-dependent field layouts, duration handling, and presentation dimensions. See `DOCS/TASK_ARCHIVE/111_C3_tkhd_Track_Header_Parser/Summary_of_Work.md` for implementation notes and verification details.
>
> **Completed:** Task C13 – `smhd`/`vmhd` media header fields now surface balance, graphics mode, and opcolor details through `BoxParserRegistry` (see `DOCS/TASK_ARCHIVE/118_C13_Surface_smhd_vmhd_Media_Header_Fields/Summary_of_Work.md`).

> **Completed:** Task C8 — Implemented the `stsc` sample-to-chunk parser so sample table metadata flows into UI/CLI surfaces. See `DOCS/TASK_ARCHIVE/109_C8_stsc_Sample_To_Chunk_Parser/Summary_of_Work.md` for implementation notes and follow-ups.

## Phase D — CLI Interface
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| D1 | Scaffold CLI using `swift-argument-parser` with base command. | Medium | 1 | B3 | Swift ArgumentParser | `isoinspector --help` displays subcommands. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/41_D1_Scaffold_CLI_Base_Command/` and now unblocks Task D2 streaming commands.) |
| D2 | Implement `inspect` and `validate` commands with streaming output. | High | 2 | D1 | Swift, XCTest | Commands process sample files; exit codes match specification. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/42_D2_Streaming_CLI_Commands/Summary_of_Work.md`. Global logging and telemetry toggles now delivered via `DOCS/TASK_ARCHIVE/49_CLI_Global_Logging_and_Telemetry_Toggles/49_CLI_Global_Logging_and_Telemetry_Toggles.md`.) |
| D3 | Add `export-json` and `export-report` commands with file output. | Medium | 1.5 | D2, B6 | Swift | Generated files validated via schema tests. (Completed ✅ — documented in `DOCS/TASK_ARCHIVE/29_D3_CLI_Export_Commands/` with CLI tests covering round-trips.) |
| D4 | Create batch mode processing with aggregated summary + CSV export. | Medium | 1.5 | D2 | Swift, CSV writer | CLI handles multiple files; CSV contains expected rows and metrics. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/51_D4_CLI_Batch_Mode/` with CSV summary generation and regression coverage.) |
| D6 | Recognize `senc/saio/saiz` sample encryption placeholders and record their offsets and lengths for downstream reporting. | Medium | 1 | D3 | Swift, XCTest | Fragment parses capture stub metadata for these boxes; CLI/UI surface presence without decrypting content. *(Completed ✅ — final regression notes archived in `DOCS/TASK_ARCHIVE/150_Summary_of_Work_2025-10-22_Sample_Encryption_Metadata/Summary_of_Work.md` with earlier planning retained under `DOCS/TASK_ARCHIVE/141_Summary_of_Work_2025-10-21_Sample_Encryption/`.)* |
| D7 | Expose validation presets and per-rule enable/disable flags on the CLI. | Medium | 1 | B7, D2 | Swift ArgumentParser | `--preset` and rule toggle flags configure `ValidationConfiguration`, alias flags (e.g., `--structural-only`) map to curated presets, and help text lists available presets per `13_Validation_Rule_Toggle_Presets_PRD.md`. *(Completed — see `DOCS/TASK_ARCHIVE/148_D7_Validation_Preset_CLI_Wiring/Summary_of_Work.md` and planning notes in `DOCS/TASK_ARCHIVE/148_D7_Validation_Preset_CLI_Wiring/D7_Validation_Preset_CLI_Wiring.md`.)* |

> **Completed (2025-10-22):** Validation follow-up **E5 — Basic `stbl` Coherence Checks** reconciles cross-table counts across `stts/ctts/stsc/stsz/stz2/stco`, with implementation recap captured in `DOCS/TASK_ARCHIVE/144_E5_Basic_stbl_Coherence_Checks/Summary_of_Work.md`.

> **Completed:** Task **E4 — Verify avcC/hvcC Invariants** delivered codec validation checks across ISOInspectorKit, CLI messaging, and JSON exports. See `DOCS/TASK_ARCHIVE/143_E4_Verify_avcC_hvcC_Invariants/Summary_of_Work.md` for the validator roll-out, regression coverage, and follow-up notes.
> **Completed:** **Codec Validation Coverage Expansion** extended ParsePipeline smoke tests plus CLI/JSON snapshots so VR-018 codec diagnostics surface consistently. Implementation is archived in `DOCS/TASK_ARCHIVE/149_Codec_Validation_Coverage_Expansion/Summary_of_Work.md`.

## Phase E — Application Shell
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| E1 | Build SwiftUI app shell with document browser and recent files list. | Medium | 2 | C1 | SwiftUI, UniformTypeIdentifiers | Users can open local files; recents persist. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/43_E1_Build_SwiftUI_App_Shell/Summary_of_Work.md`.) |
| E2 | Integrate parser event pipeline with UI components in app context. | High | 2 | E1, C2, C3 | SwiftUI | Opening file updates tree and detail views in real time. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/45_E2_Integrate_Parser_Event_Pipeline/` with default selection bridging verified by updated UI view model tests. Follow-up macOS SwiftUI automation coverage ✅ via `ParseTreeStreamingSelectionAutomationTests` documented in `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`; hardware execution run remains **Blocked** pending macOS runner — see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/51_ParseTreeStreamingSelectionAutomation_macOS_Run.md`, the archived `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/next_tasks.md`, and the active `DOCS/INPROGRESS/blocked.md`.) |
| E3 | Implement session persistence (open files, annotations, layout). | Medium | 2 | E2, C4 | CoreData/JSON | Relaunch restores previous workspace state. (Completed ✅ — implementation archived in `DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/` with CoreData and JSON fallback coverage.) |
| E4 | Prepare app distribution configuration (bundle ID, entitlements, notarization). | Medium | 1.5 | E2 | Xcode, Notarytool | App builds and notarizes successfully; entitlements validated. *(Completed ✅ — see `DOCS/TASK_ARCHIVE/55_E4_Prepare_App_Distribution_Configuration/Summary_of_Work.md`.)* |
| E4a | Evaluate Apple Events automation requirement for notarized builds. | Medium | 0.5 | E4 | Xcode, Notarytool, AppleScript | Determine whether Apple Events automation is required, adjust entitlements/notarization tooling, and document the decision. *(Completed ✅ — see `DOCS/TASK_ARCHIVE/57_Distribution_Apple_Events_Notarization_Assessment/57_Distribution_Apple_Events_Notarization_Assessment.md` and summary in `DOCS/TASK_ARCHIVE/79_Readme_Feature_Matrix_and_Distribution_Follow_Up/79_Distribution_Apple_Events_Follow_Up.md`.)* |
| E5 | Surface document load failures in the app shell UI with the forthcoming error banner design. | Medium | 0.5 | E1 | SwiftUI | Opening an unreadable file shows the designed error banner; automated tests cover failure presentation. (Completed ✅ — see `DOCS/TASK_ARCHIVE/66_E5_Surface_Document_Load_Failures/Summary_of_Work.md`.) |
| E6 | Emit diagnostics for recents and session persistence failures once the logging pipeline is available. | Medium | 0.5 | E3 | Swift Logging | Persistence errors write structured diagnostics and surface in QA tools; regression tests assert logging hooks. *(In Progress — see `DOCS/INPROGRESS/E6_Emit_Persistence_Diagnostics.md`.)* |

## Phase F — Quality Assurance & Documentation
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| F1 | Develop automated test fixtures, including malformed MP4 samples. | High | 2 | B2 | Python (fixture generation), Swift | Fixtures stored with metadata; tests cover each failure mode. (Completed ✅ — catalog growth and generation scripts archived in `DOCS/TASK_ARCHIVE/27_F1_Expand_Fixture_Catalog/`.) |
| F2 | Configure performance benchmarks for large files. | Medium | 1.5 | B3 | XCTest Metrics | Benchmark thresholds recorded; CI fails when regressions occur. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md`. Follow-up benchmark execution remains **Blocked** pending macOS hardware — see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md`, the archived `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/next_tasks.md`, and the active `DOCS/INPROGRESS/blocked.md`.) |
| F3 | Author developer onboarding guide and API reference. *(Completed ✅ — see `Docs/Guides/DeveloperOnboarding.md` and archived task notes under `DOCS/TASK_ARCHIVE/53_F3_Developer_Onboarding_Guide/`.)* | Medium | 2 | A3, B6, C3 | DocC, Markdown | Guides published; includes setup, architecture, and extension instructions. |
| F4 | Produce user manual covering CLI and App workflows. | Medium | 1.5 | D3, E2 | Markdown | Manual published under `Documentation/ISOInspector.docc/Manuals/` with CLI/App walkthroughs and troubleshooting notes. (Completed ✅ — see `Documentation/ISOInspector.docc/Manuals/App.md`, `Documentation/ISOInspector.docc/Manuals/CLI.md`, and the archived task notes in `DOCS/TASK_ARCHIVE/58_F4_User_Manual/`.) |
| F5 | Finalize release checklist and go-live runbook. | Medium | 1 | E4, F2 | Markdown | Checklist covers QA sign-off, documentation updates, release packaging. (Completed ✅ — see `Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md` and archive notes in `DOCS/TASK_ARCHIVE/59_F5_Finalize_Release_Checklist_and_Go_Live_Runbook/`.) |
| F6 | Automate DocC publishing via CI artifacts. | Medium | 1 | A3 | GitHub Actions, DocC | DocC archives uploaded on CI and accessible as artifacts. (Completed ✅ — delivered by the `docc-archives` GitHub Actions job tracked under TODO #12.) |
| F7 | Enforce DocC build health and public API documentation coverage. | Medium | 0.75 | A3, F3 | DocC, SwiftLint | `.swiftlint.yml` enables `missing_docs` for public symbols; pre-commit gate runs DocC tutorial build plus rule-only lint; CI workflow `docc convert` completes without warnings and fails the build otherwise. Updated suppression guide lives in `Documentation/ISOInspector.docc/Guides/DocumentationStyle.md`. |

> **Completed:** _PDD:45m Manifest-driven fixture acquisition for `generate_fixtures.py`, bringing checksum validation and license mirroring into the scripted workflow. Summary captured in `DOCS/TASK_ARCHIVE/100_Summary_of_Work_2025-10-19_ftyp_Follow_Up/Summary_of_Work.md`._

## Phase G — Secure Filesystem Access
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| G1 | Implement FilesystemAccessKit core API (`openFile`, `saveFile`, `createBookmark`, `resolveBookmarkData`) with platform adapters. | High | 2 | E2 | Swift Concurrency, App Sandbox docs | **Completed ✅** — Unit tests cover bookmark creation/resolution; macOS and iOS builds compile with the new module. Archived in `DOCS/TASK_ARCHIVE/69_G1_FilesystemAccessKit_Core_API/`. Follow-up integration threads now reside in the archived `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/next_tasks.md`, with active blockers tracked via `DOCS/INPROGRESS/blocked.md`. |
| G2 | Persist bookmarks and integrate with recents/session restoration in app targets. | High | 1.5 | G1, E3 | CoreData/JSON, SwiftUI | **Completed ✅** — App restores previously authorized files on launch; stale bookmarks prompt re-authorization flows. Archived in `DOCS/TASK_ARCHIVE/71_G2_Persist_FilesystemAccessKit_Bookmarks/`. |
| G3 | Expose CLI flags and sandbox profile guidance for headless access. | Medium | 1 | G1 | Swift ArgumentParser, sandbox profiles | **Completed ✅** — CLI documentation now details the `--open`/`--authorize` automation path, sample sandbox profiles, and notarization steps. See `Documentation/ISOInspector.docc/Guides/CLISandboxProfileGuide.md` and the archived task notes in `DOCS/TASK_ARCHIVE/72_G3_Expose_CLI_Sandbox_Profile_Guidance/`. |
| G4 | Implement zero-trust logging and audit trail for file access events. | Medium | 1 | G1 | Swift Logging | Access logs omit absolute paths, include hashed identifiers, and pass diagnostics tests. *(Completed — see `DOCS/TASK_ARCHIVE/74_G4_Zero_Trust_Logging/Summary_of_Work.md` and `DOCS/TASK_ARCHIVE/74_G4_Zero_Trust_Logging/G4_Zero_Trust_Logging.md`.)* |
| G5 | Provide UIDocumentPicker integration for iOS/iPadOS platform adapters. | Medium | 1 | G1 | UIKit, Swift Concurrency | FilesystemAccessKit presents `UIDocumentPickerViewController`, returns security-scoped URLs, and ships regression coverage without regressing macOS adapters. **(Completed — FilesystemAccess.live selects the UIKit presenter by default on iOS/iPadOS.)** |

> **Completed:** Task **G8 — Accessibility & Keyboard Shortcuts** unified hardware focus commands and VoiceOver-friendly navigation across macOS and iPadOS. Notes and summary are archived in `DOCS/TASK_ARCHIVE/155_G8_Accessibility_and_Keyboard_Shortcuts/`, and the follow-up VoiceOver verification pass now lives in the permanent blocker log at `DOCS/TASK_ARCHIVE/BLOCKED/2025-10-27_VoiceOver_Regression_Pass.md`.

> **Completed (2025-10-27):** Task **G6 — Export JSON Actions** shipped SwiftUI export controls, shared exporter wiring, and diagnostics-backed error handling. See `DOCS/TASK_ARCHIVE/179_Summary_of_Work_2025-10-27_G6_Export_JSON_Actions/Summary_of_Work.md` for the latest verification notes.

> **Completed:** Task **G7 — State Management View Models** formalized DocumentVM/NodeVM/HexVM orchestration for the SwiftUI outline, detail, and export flows; see `DOCS/TASK_ARCHIVE/154_G7_State_Management_ViewModels/Summary_of_Work.md` for the archived implementation notes.

> **Completed:** Task G2 – Persist FilesystemAccessKit bookmarks alongside recents/session storage while maintaining sandbox compliance. Notes archived in `DOCS/TASK_ARCHIVE/71_G2_Persist_FilesystemAccessKit_Bookmarks/`; remaining sandbox, benchmark, and automation follow-ups continue in the archived `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/next_tasks.md` while active blockers live in `DOCS/INPROGRESS/blocked.md`.

> **Completed:** Task **J2 — Persist Security-Scoped Bookmarks** realigned the bookmark ledger with the refreshed session controller, added stale bookmark remediation, and expanded diagnostics coverage. Notes and verification are archived in `DOCS/TASK_ARCHIVE/157_J2_Persist_Security_Scoped_Bookmarks/`, with ongoing follow-ups tracked via the archived `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/next_tasks.md` and the active `DOCS/INPROGRESS/blocked.md`.

## Phase H — Fixtures & Tests
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| H1 | Expand fixture corpus with fragmented, DASH, malformed, and large-sample assets. | High | 2 | B2 | Python, Swift | *(Completed ✅ — see `DOCS/TASK_ARCHIVE/27_F1_Expand_Fixture_Catalog/` for manifest-driven fixture coverage.)* |
| H2 | Author unit tests covering header parsing, container boundary enforcement, and targeted box field extraction. | High | 1.5 | B3 | XCTest | Structural regression tests assert header math, parent/child containment, and representative box decoders. **(Completed — see `DOCS/TASK_ARCHIVE/94_H2_Unit_Tests/Summary_of_Work.md`.)** |
| H3 | Capture snapshot tests for JSON export on representative fixtures. | Medium | 1 | B6 | XCTest | **Completed ✅** — Snapshot baselines cover baseline, streaming init, and DASH fixtures; see `Tests/ISOInspectorKitTests/JSONExportSnapshotTests.swift` and `DOCS/TASK_ARCHIVE/98_H3_JSON_Export_Snapshot_Tests/Summary_of_Work.md` for update workflow. |
| H4 | Execute performance tests to validate parse time and memory targets on large fixtures. | Medium | 1.5 | B3 | XCTest Metrics | Benchmarks document latency/memory ceilings and fail CI on regressions. *(Completed — see `DOCS/TASK_ARCHIVE/107_H4_Performance_Benchmark_Validation/Summary_of_Work.md`.)* |

## Phase I — Packaging & Release
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| I1 | SwiftPM product definitions (library + app). | Medium | 0.5 | A1 | SwiftPM | **Completed ✅** — Library and application products ship from `Package.swift`; see `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` for archived notes. |
| I2 | App entitlements for file access; sandbox configuration. | Medium | 1 | E4 | Xcode, Notarytool | **Completed ✅** — Distribution entitlements validated via `scripts/notarize_app.sh` and captured under `Distribution/Entitlements/`. |
| I2a | Evaluate Apple Events automation requirement for notarized builds. | Medium | 0.5 | I2 | Xcode, AppleScript | **Completed ✅** — Assessment archived in `DOCS/TASK_ARCHIVE/57_Distribution_Apple_Events_Notarization_Assessment/57_Distribution_Apple_Events_Notarization_Assessment.md`. |
| I3 | App theming (icon, light/dark). | Medium | 1 | E4 | Xcode Asset Catalogs | App icon set and accent colors match branding across light/dark appearances. **(Completed — manual `AppIcon.icon` asset now ships with the project; generator workflow retired per `DOCS/AI/ISOInspector_Execution_Guide/12_AppIcon_Asset_Update_Summary.md`, and CI is pinned to Xcode 16.0 to compile the asset.)** |
| I4 | README with feature matrix, supported boxes, screenshots. | Medium | 0.5 | I1, F4 | Markdown, DocC captures | README documents core features, platform support, and embeds up-to-date screenshots. *(Completed — README now includes feature matrix, platform coverage, and concept capture; see `DOCS/TASK_ARCHIVE/79_Readme_Feature_Matrix_and_Distribution_Follow_Up/Summary_of_Work.md`.)* |
| I5 | v0.1.0 Release notes; distribution packaging checklist. | Medium | 1 | I3, I4 | Markdown, Notarytool | **Completed ✅** — Release notes captured in `Distribution/ReleaseNotes/v0.1.0.md`; archival summary lives in `DOCS/TASK_ARCHIVE/82_I5_v0_1_0_Release_Notes/`. |

> **Completed:** Task I5 – Drafted v0.1.0 release notes and validated distribution packaging inputs. See `Distribution/ReleaseNotes/v0.1.0.md` and the archive folder `DOCS/TASK_ARCHIVE/82_I5_v0_1_0_Release_Notes/` for outputs; macOS-only verification remains tracked via the archived `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/next_tasks.md` and the active `DOCS/INPROGRESS/blocked.md`.

> **Completed:** Task **T1.2 — Extend ParseTreeNode with Issues and Status Fields** wrapped tolerant parsing metadata through `ParseTreeNode`, builder pipelines, and JSON exports. See `DOCS/TASK_ARCHIVE/165_T1_2_Extend_ParseTreeNode_Status_and_Issues/` for the archived PRD and summary, plus `DOCS/AI/Tolerance_Parsing/TODO.md` for remaining phase follow-ups.
>
> **Completed:** Task **T1.4 — Refactor BoxHeaderDecoder to Result-based API** now lives in `DOCS/TASK_ARCHIVE/167_T1_4_BoxHeaderDecoder_Result_API/`, providing tolerant parsing flows with recoverable header diagnostics and updated call sites/tests.
>
> **Completed:** Task **T1.5 — Propagate Decoder Failures Through Tolerant Parsing** now emits structured `ParseIssue` records for decoder failures and resumes tolerant traversal without aborting strict mode. See `DOCS/TASK_ARCHIVE/169_T1_5_Propagate_Decoder_Failures_Through_Tolerant_Parsing/Summary_of_Work.md` for verification details and updated test coverage notes.

> **Completed (2025-10-28):** Task **T3.3 — Integrity Detail Pane** delivered the corruption diagnostics section in the inspector. Review outcomes in `DOCS/TASK_ARCHIVE/188_T3_3_Integrity_Detail_Pane/Summary_of_Work.md` alongside the tolerance parsing roadmap in `DOCS/AI/Tolerance_Parsing/TODO.md`.
>
> **Completed (2025-10-26):** Task **T3.4 — Placeholder Nodes for Missing Children** now surfaces expected-but-absent structures with synthetic nodes so Integrity diagnostics can deep-link into the tree. See `DOCS/TASK_ARCHIVE/190_T3_4_Placeholder_Nodes_for_Missing_Children/Summary_of_Work.md` for the delivery recap and follow-on notes.

> **Completed (2025-10-28):** Task **T3.5 — Contextual Status Labels** shipped synchronized tolerant parsing badges across the outline and detail inspector. Delivery recap lives in `DOCS/TASK_ARCHIVE/191_T3_5_Contextual_Status_Labels/` alongside the archived work summary.

## Parallelization Notes
- Phase A must complete before downstream phases begin.
- Within Phase B, tasks B1–B3 and B4–B6 follow sequential order; B4 can start once B3 has event emission stubs.
- Phase C tasks C2 and C3 can run in parallel after C1. C4 depends on annotation store definitions from C3.
- C21 should follow C19 so it can reuse the existing settings view models, while C22 cannot start until E3's session persistence APIs are stable (the shared `DocumentSessionController` hooks gate that work).
- Phase D tasks proceed sequentially due to CLI command dependencies.
- Phase E tasks E2 and E3 depend on UI components from Phase C.
- Documentation and QA tasks in Phase F can overlap once dependent features stabilize.

## Progress Tracking Metrics
- Burn-down of remaining ideal days per phase.
- Automated test coverage percentage per module.
- Performance benchmark results (latency, memory, throughput).
- Count of unresolved research tasks from `05_Research_Gaps.md`.
