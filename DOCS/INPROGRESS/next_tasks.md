# Next Tasks

## 🔐 Filesystem Access Enablement

- [ ] Draft CLI sandbox profile guidance covering `com.apple.security.files.user-selected.read-write` and automation workflows for headless usage. Reference the archived FilesystemAccessKit baseline in `DOCS/TASK_ARCHIVE/69_G1_FilesystemAccessKit_Core_API/` and the persistence summary in `DOCS/TASK_ARCHIVE/71_G2_Persist_FilesystemAccessKit_Bookmarks/Summary_of_Work.md`. **(In Progress — see `DOCS/INPROGRESS/G3_Expose_CLI_Sandbox_Profile_Guidance.md`.)**

## 🔭 Benchmark Validation

- [ ] Execute the random slice benchmark suite on macOS hardware once Combine support is available so we can compare mapped vs. chunked readers under identical workloads. **(Blocked — requires macOS runner with Combine; see `DOCS/TASK_ARCHIVE/64_A5_Random_Slice_Benchmarking/Summary_of_Work.md` and `DOCS/TASK_ARCHIVE/65_Summary_of_Work_2025-10-15_Benchmark/2025-10-15-random-slice-benchmark.md`.)**

## 🧪 Streaming UI Coverage

- [ ] Run `ParseTreeStreamingSelectionAutomationTests` on macOS hardware with XCTest UI support to validate the end-to-end SwiftUI automation flow introduced in `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`. **(Blocked — macOS UI testing entitlements unavailable in container; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/51_ParseTreeStreamingSelectionAutomation_macOS_Run.md`.)**

## 🔬 Combine UI Benchmark Follow-Up

- [ ] Execute the Combine-backed UI benchmark on macOS to capture latency metrics on a platform that ships Combine, keeping throughput parity with the CLI harness. **(Blocked — requires macOS runner with Xcode/Combine; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md`.)**
  - Latest container attempt (`2025-10-12`) confirmed XCTest skips the scenario on Linux because `Combine` is unavailable; macOS hardware run still required. See `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/Summary_of_Work.md` for details.

## 🛠️ Session Persistence Follow-Ups

- [ ] Reconcile CoreData session bookmark diffs with live bookmark entities when reconciliation rules are defined. See `DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/Summary_of_Work.md`.

## 📦 Distribution Follow-Up

- [ ] Track outcome of the notarized build Apple Events automation assessment alongside `todo.md` entry “PDD:30m Evaluate whether automation via Apple Events is required for notarized builds and extend entitlements safely.” Reference archival notes in `DOCS/TASK_ARCHIVE/57_Distribution_Apple_Events_Notarization_Assessment/56_Distribution_Apple_Events_Notarization_Assessment.md`.
