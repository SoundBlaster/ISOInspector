# Next Tasks

## 🔐 Filesystem Access Enablement

- [x] Prototype FilesystemAccessKit core APIs (`openFile`, `saveFile`, `createBookmark`, `resolveBookmarkData`) following `DOCS/AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md` and wire initial tests. **Completed — see [`G1_FilesystemAccessKit_Core_API.md`](./G1_FilesystemAccessKit_Core_API.md) and new unit tests in `Tests/ISOInspectorKitTests/FilesystemAccessTests.swift`.**
- [ ] Design bookmark persistence schema aligned with existing recents/session storage so Phase G (Workplan) can
  integrate without data loss.
- [ ] Draft CLI sandbox profile guidance covering `com.apple.security.files.user-selected.read-write` and automation workflows for headless usage.

## 🔭 Benchmark Validation

- [ ] Execute the random slice benchmark suite on macOS hardware once Combine support is available so we can compare mapped vs. chunked readers under identical workloads. **(Blocked — requires macOS runner with Combine; see `DOCS/TASK_ARCHIVE/64_A5_Random_Slice_Benchmarking/Summary_of_Work.md` and `DOCS/TASK_ARCHIVE/65_Summary_of_Work_2025-10-15_Benchmark/2025-10-15-random-slice-benchmark.md`.)**

## 🧪 Streaming UI Coverage

- [ ] Run `ParseTreeStreamingSelectionAutomationTests` on macOS hardware with XCTest UI support to validate the end-to-end SwiftUI automation flow introduced in `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`. **(Blocked — macOS UI testing entitlements unavailable in container; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/51_ParseTreeStreamingSelectionAutomation_macOS_Run.md`.)**

## 🔬 Combine UI Benchmark Follow-Up

- [ ] Execute the Combine-backed UI benchmark on macOS to capture latency metrics on a platform that ships Combine, keeping throughput parity with the CLI harness. **(Blocked — requires macOS runner with Xcode/Combine; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md`.)**
  - Latest container attempt (`2025-10-12`) confirmed XCTest skips the scenario on Linux because `Combine` is unavailable; macOS hardware run still required. See `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/Summary_of_Work.md` for details.

## 🛠️ Session Persistence Follow-Ups

- [x] Surface session persistence errors once diagnostics plumbing is available. **(Completed — see `DOCS/TASK_ARCHIVE/68_E6_Emit_Persistence_Diagnostics/Summary_of_Work.md`.)** See `DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/Summary_of_Work.md` and the closed `todo.md` entry “PDD:30m Surface session persistence failures in diagnostics once logging pipeline is available.”
- [ ] Reconcile CoreData session bookmark diffs with live bookmark entities when reconciliation rules are defined. See `DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/Summary_of_Work.md`.
- [x] Surface recents persistence errors once diagnostics plumbing is available. **(Completed — see `DOCS/TASK_ARCHIVE/68_E6_Emit_Persistence_Diagnostics/Summary_of_Work.md`.)** See the closed `todo.md` entry “PDD:30m Surface recents persistence failures in diagnostics once logging pipeline is available.”

## 📦 Distribution Follow-Up

- [ ] Track outcome of the notarized build Apple Events automation assessment alongside `todo.md` entry “PDD:30m Evaluate whether automation via Apple Events is required for notarized builds and extend entitlements safely.” Reference archival notes in `DOCS/TASK_ARCHIVE/57_Distribution_Apple_Events_Notarization_Assessment/56_Distribution_Apple_Events_Notarization_Assessment.md`.
