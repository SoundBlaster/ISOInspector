# ISOInspector Execution Workplan

The following plan decomposes delivery into dependency-aware phases. Each task includes priority, estimated effort (in ideal engineer days), required tools, dependencies, and acceptance criteria.

## Phase A — Foundations & Infrastructure
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| A1 | Initialize SwiftPM workspace with core, UI, CLI targets and shared test utilities. | High | 1 | None | SwiftPM, Xcode | Repository builds successfully; targets link with placeholder implementations. |
| A2 | Configure CI pipeline (GitHub Actions or similar) for build, test, lint. | High | 1.5 | A1 | GitHub Actions, swiftlint | CI runs on pull requests; failing tests block merge. (Completed ✅ — archived in `DOCS/ARCHIVE/01_A2_Configure_CI_Pipeline/`.) |
| A3 | Set up DocC catalog and documentation publishing workflow. | Medium | 1 | A1 | DocC, SwiftPM | `docc` build succeeds; docs published artifact accessible. (Completed ✅ — generates archives via `scripts/generate_documentation.sh`, DocC catalogs live under `Sources/*/*.docc`, tutorials expanded in `DOCS/TASK_ARCHIVE/35_A3_DocC_Tutorial_Expansion/`, and CI publishing now delivered by the TODO #12-backed `docc-archives` job.) |

> **Current focus:** _Hardware validation follow-ups for Task A5’s random slice benchmarking deliverable._ See `DOCS/TASK_ARCHIVE/65_Summary_of_Work_2025-10-15_Benchmark/Summary_of_Work.md` for the Task A5 wrap-up and refer to `DOCS/INPROGRESS/next_tasks.md` for hardware-dependent runs still outstanding.
>
> **Status:** _Blocked_ — benchmark harness implementation is archived and awaiting macOS hardware to execute random slice metrics, UI automation coverage, and Combine-backed UI benchmarks documented in the refreshed `DOCS/INPROGRESS/next_tasks.md`.

## Phase B — Core Parsing Engine
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| B1 | Implement chunked file reader with configurable buffer size and tests. | High | 1.5 | A1 | Swift, XCTest | Reader streams 1 MB chunks; tests cover EOF, seek, and error paths. (Completed ✅) |
| B2 | Build box header decoder supporting 32-bit, 64-bit, and `uuid` boxes. | High | 2 | B1 | Swift, XCTest | Unit tests for standard and extended headers; handles malformed sizes gracefully. (Completed ✅) |
| B3 | Implement streaming parse pipeline with event emission and context stack. | High | 3 | B2 | Swift Concurrency, XCTest | Parsing sample files emits ordered events with correct offsets. (Completed ✅) |
| B4 | Integrate MP4RA metadata catalog and fallback for unknown boxes. | High | 2 | B3 | Swift, JSON parsing | Catalog loads from bundled JSON; unknown types logged for research. (Completed ✅ — see `DOCS/TASK_ARCHIVE/25_B4_C2_Category_Filtering/`.) |
| B5 | Implement validation rules VR-001 to VR-006 with test coverage. | High | 2 | B3 | XCTest | Malformed fixtures trigger expected validation outcomes. (Completed ✅ — VR-006 research logging now persists unknown boxes to a shared research log for CLI/UI analysis.) |
| B6 | Add JSON and binary export modules with regression tests. | Medium | 1.5 | B3 | Swift Codable | Exported files re-import successfully; CLI smoke tests pass. |

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

## Phase D — CLI Interface
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| D1 | Scaffold CLI using `swift-argument-parser` with base command. | Medium | 1 | B3 | Swift ArgumentParser | `isoinspector --help` displays subcommands. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/41_D1_Scaffold_CLI_Base_Command/` and now unblocks Task D2 streaming commands.) |
| D2 | Implement `inspect` and `validate` commands with streaming output. | High | 2 | D1 | Swift, XCTest | Commands process sample files; exit codes match specification. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/42_D2_Streaming_CLI_Commands/Summary_of_Work.md`. Global logging and telemetry toggles now delivered via `DOCS/TASK_ARCHIVE/49_CLI_Global_Logging_and_Telemetry_Toggles/49_CLI_Global_Logging_and_Telemetry_Toggles.md`.) |
| D3 | Add `export-json` and `export-report` commands with file output. | Medium | 1.5 | D2, B6 | Swift | Generated files validated via schema tests. (Completed ✅ — documented in `DOCS/TASK_ARCHIVE/29_D3_CLI_Export_Commands/` with CLI tests covering round-trips.) |
| D4 | Create batch mode processing with aggregated summary + CSV export. | Medium | 1.5 | D2 | Swift, CSV writer | CLI handles multiple files; CSV contains expected rows and metrics. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/51_D4_CLI_Batch_Mode/` with CSV summary generation and regression coverage.) |

## Phase E — Application Shell
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| E1 | Build SwiftUI app shell with document browser and recent files list. | Medium | 2 | C1 | SwiftUI, UniformTypeIdentifiers | Users can open local files; recents persist. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/43_E1_Build_SwiftUI_App_Shell/Summary_of_Work.md`.) |
| E2 | Integrate parser event pipeline with UI components in app context. | High | 2 | E1, C2, C3 | SwiftUI | Opening file updates tree and detail views in real time. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/45_E2_Integrate_Parser_Event_Pipeline/` with default selection bridging verified by updated UI view model tests. Follow-up macOS SwiftUI automation coverage ✅ via `ParseTreeStreamingSelectionAutomationTests` documented in `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`; hardware execution run remains **Blocked** pending macOS runner — see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/51_ParseTreeStreamingSelectionAutomation_macOS_Run.md` and `DOCS/INPROGRESS/next_tasks.md`.) |
| E3 | Implement session persistence (open files, annotations, layout). | Medium | 2 | E2, C4 | CoreData/JSON | Relaunch restores previous workspace state. (Completed ✅ — implementation archived in `DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/` with CoreData and JSON fallback coverage.) |
| E4 | Prepare app distribution configuration (bundle ID, entitlements, notarization). | Medium | 1.5 | E2 | Xcode, Notarytool | App builds and notarizes successfully; entitlements validated. *(Completed ✅ — see `DOCS/TASK_ARCHIVE/55_E4_Prepare_App_Distribution_Configuration/Summary_of_Work.md`.)* |
| E4a | Evaluate Apple Events automation requirement for notarized builds. | Medium | 0.5 | E4 | Xcode, Notarytool, AppleScript | Determine whether Apple Events automation is required, adjust entitlements/notarization tooling, and document the decision. *(Completed ✅ — see `DOCS/TASK_ARCHIVE/57_Distribution_Apple_Events_Notarization_Assessment/57_Distribution_Apple_Events_Notarization_Assessment.md` and summary in `DOCS/TASK_ARCHIVE/79_Readme_Feature_Matrix_and_Distribution_Follow_Up/79_Distribution_Apple_Events_Follow_Up.md`.)* |
| E5 | Surface document load failures in the app shell UI with the forthcoming error banner design. | Medium | 0.5 | E1 | SwiftUI | Opening an unreadable file shows the designed error banner; automated tests cover failure presentation. (Completed ✅ — see `DOCS/TASK_ARCHIVE/66_E5_Surface_Document_Load_Failures/Summary_of_Work.md`.) |
| E6 | Emit diagnostics for recents and session persistence failures once the logging pipeline is available. | Medium | 0.5 | E3 | Swift Logging | Persistence errors write structured diagnostics and surface in QA tools; regression tests assert logging hooks. *(In Progress — see `DOCS/INPROGRESS/E6_Emit_Persistence_Diagnostics.md`.)* |

## Phase F — Quality Assurance & Documentation
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| F1 | Develop automated test fixtures, including malformed MP4 samples. | High | 2 | B2 | Python (fixture generation), Swift | Fixtures stored with metadata; tests cover each failure mode. (Completed ✅ — catalog growth and generation scripts archived in `DOCS/TASK_ARCHIVE/27_F1_Expand_Fixture_Catalog/`.) |
| F2 | Configure performance benchmarks for large files. | Medium | 1.5 | B3 | XCTest Metrics | Benchmark thresholds recorded; CI fails when regressions occur. (Completed ✅ — archived in `DOCS/TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md`. Follow-up benchmark execution remains **Blocked** pending macOS hardware — see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md` and `DOCS/INPROGRESS/next_tasks.md`.) |
| F3 | Author developer onboarding guide and API reference. *(Completed ✅ — see `Docs/Guides/DeveloperOnboarding.md` and archived task notes under `DOCS/TASK_ARCHIVE/53_F3_Developer_Onboarding_Guide/`.)* | Medium | 2 | A3, B6, C3 | DocC, Markdown | Guides published; includes setup, architecture, and extension instructions. |
| F4 | Produce user manual covering CLI and App workflows. | Medium | 1.5 | D3, E2 | Markdown | Manual published under `Documentation/ISOInspector.docc/Manuals/` with CLI/App walkthroughs and troubleshooting notes. (Completed ✅ — see `Documentation/ISOInspector.docc/Manuals/App.md`, `Documentation/ISOInspector.docc/Manuals/CLI.md`, and the archived task notes in `DOCS/TASK_ARCHIVE/58_F4_User_Manual/`.) |
| F5 | Finalize release checklist and go-live runbook. | Medium | 1 | E4, F2 | Markdown | Checklist covers QA sign-off, documentation updates, release packaging. (Completed ✅ — see `Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md` and archive notes in `DOCS/TASK_ARCHIVE/59_F5_Finalize_Release_Checklist_and_Go_Live_Runbook/`.) |
| F6 | Automate DocC publishing via CI artifacts. | Medium | 1 | A3 | GitHub Actions, DocC | DocC archives uploaded on CI and accessible as artifacts. (Completed ✅ — delivered by the `docc-archives` GitHub Actions job tracked under TODO #12.) |

## Phase G — Secure Filesystem Access
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| G1 | Implement FilesystemAccessKit core API (`openFile`, `saveFile`, `createBookmark`, `resolveBookmarkData`) with platform adapters. | High | 2 | E2 | Swift Concurrency, App Sandbox docs | **Completed ✅** — Unit tests cover bookmark creation/resolution; macOS and iOS builds compile with the new module. Archived in `DOCS/TASK_ARCHIVE/69_G1_FilesystemAccessKit_Core_API/`. Follow-up integration threads live in `DOCS/INPROGRESS/next_tasks.md`. |
| G2 | Persist bookmarks and integrate with recents/session restoration in app targets. | High | 1.5 | G1, E3 | CoreData/JSON, SwiftUI | **Completed ✅** — App restores previously authorized files on launch; stale bookmarks prompt re-authorization flows. Archived in `DOCS/TASK_ARCHIVE/71_G2_Persist_FilesystemAccessKit_Bookmarks/`. |
| G3 | Expose CLI flags and sandbox profile guidance for headless access. | Medium | 1 | G1 | Swift ArgumentParser, sandbox profiles | **Completed ✅** — CLI documentation now details the `--open`/`--authorize` automation path, sample sandbox profiles, and notarization steps. See `Documentation/ISOInspector.docc/Guides/CLISandboxProfileGuide.md` and the archived task notes in `DOCS/TASK_ARCHIVE/72_G3_Expose_CLI_Sandbox_Profile_Guidance/`. |
| G4 | Implement zero-trust logging and audit trail for file access events. | Medium | 1 | G1 | Swift Logging | Access logs omit absolute paths, include hashed identifiers, and pass diagnostics tests. *(Completed — see `DOCS/TASK_ARCHIVE/74_G4_Zero_Trust_Logging/Summary_of_Work.md` and `DOCS/TASK_ARCHIVE/74_G4_Zero_Trust_Logging/G4_Zero_Trust_Logging.md`.)* |
| G5 | Provide UIDocumentPicker integration for iOS/iPadOS platform adapters. | Medium | 1 | G1 | UIKit, Swift Concurrency | FilesystemAccessKit presents `UIDocumentPickerViewController`, returns security-scoped URLs, and ships regression coverage without regressing macOS adapters. **(Completed — FilesystemAccess.live selects the UIKit presenter by default on iOS/iPadOS.)** |

> **Completed:** Task G2 – Persist FilesystemAccessKit bookmarks alongside recents/session storage while maintaining sandbox compliance. Notes archived in `DOCS/TASK_ARCHIVE/71_G2_Persist_FilesystemAccessKit_Bookmarks/`; remaining sandbox, benchmark, and automation follow-ups continue in `DOCS/INPROGRESS/next_tasks.md`.

## Phase I — Packaging & Release
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| I1 | SwiftPM product definitions (library + app). | Medium | 0.5 | A1 | SwiftPM | **Completed ✅** — Library and application products ship from `Package.swift`; see `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` for archived notes. |
| I2 | App entitlements for file access; sandbox configuration. | Medium | 1 | E4 | Xcode, Notarytool | **Completed ✅** — Distribution entitlements validated via `scripts/notarize_app.sh` and captured under `Distribution/Entitlements/`. |
| I2a | Evaluate Apple Events automation requirement for notarized builds. | Medium | 0.5 | I2 | Xcode, AppleScript | **Completed ✅** — Assessment archived in `DOCS/TASK_ARCHIVE/57_Distribution_Apple_Events_Notarization_Assessment/57_Distribution_Apple_Events_Notarization_Assessment.md`. |
| I3 | App theming (icon, light/dark). | Medium | 1 | E4 | Xcode Asset Catalogs | App icon set and accent colors match branding across light/dark appearances. (Accent palette delivery archived in `DOCS/TASK_ARCHIVE/80_Summary_of_Work_2025-10-17_App_Theming/`; production icon rasterization remains open via `todo.md` PDD:45m.) |
| I4 | README with feature matrix, supported boxes, screenshots. | Medium | 0.5 | I1, F4 | Markdown, DocC captures | README documents core features, platform support, and embeds up-to-date screenshots. *(Completed — README now includes feature matrix, platform coverage, and concept capture; see `DOCS/TASK_ARCHIVE/79_Readme_Feature_Matrix_and_Distribution_Follow_Up/Summary_of_Work.md`.)* |
| I5 | v0.1.0 Release notes; distribution packaging checklist. | Medium | 1 | I3, I4 | Markdown, Notarytool | Publish release notes summarizing MVP scope; DMG/TestFlight artifacts validated. |

> **In Progress:** Task I3 – App theming (icon, light/dark) now awaits production icon raster assets after landing the accent palette. The working notes live in `DOCS/TASK_ARCHIVE/80_Summary_of_Work_2025-10-17_App_Theming/`; outstanding icon deliverables remain tracked via `todo.md` and `DOCS/INPROGRESS/next_tasks.md`.

## Parallelization Notes
- Phase A must complete before downstream phases begin.
- Within Phase B, tasks B1–B3 and B4–B6 follow sequential order; B4 can start once B3 has event emission stubs.
- Phase C tasks C2 and C3 can run in parallel after C1. C4 depends on annotation store definitions from C3.
- Phase D tasks proceed sequentially due to CLI command dependencies.
- Phase E tasks E2 and E3 depend on UI components from Phase C.
- Documentation and QA tasks in Phase F can overlap once dependent features stabilize.

## Progress Tracking Metrics
- Burn-down of remaining ideal days per phase.
- Automated test coverage percentage per module.
- Performance benchmark results (latency, memory, throughput).
- Count of unresolved research tasks from `05_Research_Gaps.md`.
