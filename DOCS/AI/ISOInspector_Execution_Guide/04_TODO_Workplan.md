# ISOInspector Execution Workplan

The following plan decomposes delivery into dependency-aware phases. Each task includes priority, estimated effort (in ideal engineer days), required tools, dependencies, and acceptance criteria.

## Phase A — Foundations & Infrastructure
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| A1 | Initialize SwiftPM workspace with core, UI, CLI targets and shared test utilities. | High | 1 | None | SwiftPM, Xcode | Repository builds successfully; targets link with placeholder implementations. |
| A2 | Configure CI pipeline (GitHub Actions or similar) for build, test, lint. | High | 1.5 | A1 | GitHub Actions, swiftlint | CI runs on pull requests; failing tests block merge. |
| A3 | Set up DocC catalog and documentation publishing workflow. | Medium | 1 | A1 | DocC, SwiftPM | `docc` build succeeds; docs published artifact accessible. |

## Phase B — Core Parsing Engine
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| B1 | Implement chunked file reader with configurable buffer size and tests. | High | 1.5 | A1 | Swift, XCTest | Reader streams 1 MB chunks; tests cover EOF, seek, and error paths. (Completed ✅) |
| B2 | Build box header decoder supporting 32-bit, 64-bit, and `uuid` boxes. | High | 2 | B1 | Swift, XCTest | Unit tests for standard and extended headers; handles malformed sizes gracefully. (Completed ✅) |
| B3 | Implement streaming parse pipeline with event emission and context stack. | High | 3 | B2 | Swift Concurrency, XCTest | Parsing sample files emits ordered events with correct offsets. (Completed ✅) |
| B4 | Integrate MP4RA metadata catalog and fallback for unknown boxes. | High | 2 | B3 | Swift, JSON parsing | Catalog loads from bundled JSON; unknown types logged for research. |
| B5 | Implement validation rules VR-001 to VR-006 with test coverage. | High | 2 | B3 | XCTest | Malformed fixtures trigger expected validation outcomes. (Completed ✅ — VR-006 research logging now persists unknown boxes to a shared research log for CLI/UI analysis.) |
| B6 | Add JSON and binary export modules with regression tests. | Medium | 1.5 | B3 | Swift Codable | Exported files re-import successfully; CLI smoke tests pass. |

## Phase C — User Interface Package
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| C1 | Create Combine bridge and state stores for parse events. | High | 1.5 | B3 | Combine, SwiftUI | Store receives events and updates snapshot without race conditions. (Completed ✅ — Combine-backed session bridge fan-outs parse events to SwiftUI `@MainActor` tree store with validation aggregation.) |
| C2 | Implement tree view with virtualization, search, and filters. | High | 2.5 | C1 | SwiftUI | UI renders >10k nodes smoothly; search reduces nodes instantly. |
| C3 | Build detail pane with metadata, validation list, and hex viewer. | High | 3 | C1 | SwiftUI | Selecting node shows metadata; hex viewer displays payload windows. |
| C4 | Add annotation and bookmark management with persistence hooks. | Medium | 2 | C1 | CoreData/JSON | Notes persist across app relaunch; tests validate storage schema. |
| C5 | Implement accessibility features (VoiceOver labels, keyboard navigation). | Medium | 1.5 | C2, C3 | Accessibility Inspector | Accessibility audit passes; UI tests confirm focus order. |

## Phase D — CLI Interface
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| D1 | Scaffold CLI using `swift-argument-parser` with base command. | Medium | 1 | B3 | Swift ArgumentParser | `isoinspector --help` displays subcommands. |
| D2 | Implement `inspect` and `validate` commands with streaming output. | High | 2 | D1 | Swift, XCTest | Commands process sample files; exit codes match specification. |
| D3 | Add `export-json` and `export-report` commands with file output. | Medium | 1.5 | D2, B6 | Swift | Generated files validated via schema tests. |
| D4 | Create batch mode processing with aggregated summary + CSV export. | Medium | 1.5 | D2 | Swift, CSV writer | CLI handles multiple files; CSV contains expected rows and metrics. |

## Phase E — Application Shell
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| E1 | Build SwiftUI app shell with document browser and recent files list. | Medium | 2 | C1 | SwiftUI, UniformTypeIdentifiers | Users can open local files; recents persist. |
| E2 | Integrate parser event pipeline with UI components in app context. | High | 2 | E1, C2, C3 | SwiftUI | Opening file updates tree and detail views in real time. |
| E3 | Implement session persistence (open files, annotations, layout). | Medium | 2 | E2, C4 | CoreData/JSON | Relaunch restores previous workspace state. |
| E4 | Prepare app distribution configuration (bundle ID, entitlements, notarization). | Medium | 1.5 | E2 | Xcode, Notarytool | App builds and notarizes successfully; entitlements validated. |

## Phase F — Quality Assurance & Documentation
| Task ID | Description | Priority | Effort (days) | Dependencies | Tools | Acceptance Criteria |
|---------|-------------|----------|---------------|--------------|-------|---------------------|
| F1 | Develop automated test fixtures, including malformed MP4 samples. | High | 2 | B2 | Python (fixture generation), Swift | Fixtures stored with metadata; tests cover each failure mode. |
| F2 | Configure performance benchmarks for large files. | Medium | 1.5 | B3 | XCTest Metrics | Benchmark thresholds recorded; CI fails when regressions occur. |
| F3 | Author developer onboarding guide and API reference. | Medium | 2 | A3, B6, C3 | DocC, Markdown | Guides published; includes setup, architecture, and extension instructions. |
| F4 | Produce user manual covering CLI and App workflows. | Medium | 1.5 | D3, E2 | Markdown | Manual includes screenshots, command examples, troubleshooting. |
| F5 | Finalize release checklist and go-live runbook. | Medium | 1 | E4, F2 | Markdown | Checklist covers QA sign-off, documentation updates, release packaging. |

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
