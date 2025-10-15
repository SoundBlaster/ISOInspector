# Next Tasks

## 🧪 Streaming UI Coverage

- [ ] Run `ParseTreeStreamingSelectionAutomationTests` on macOS hardware with XCTest UI support to validate the end-to-end SwiftUI automation flow introduced in `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`. **(Blocked — macOS UI testing entitlements unavailable in container; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/51_ParseTreeStreamingSelectionAutomation_macOS_Run.md`)**

## 🔬 Benchmark Follow-Up

- [ ] Execute the Combine-backed UI benchmark on macOS to capture latency metrics on a platform that ships Combine, keeping throughput parity with the CLI harness. **(Blocked — requires macOS runner with Xcode/Combine; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md`)**
  - Latest container attempt (`2025-10-12`) confirmed XCTest skips the scenario on Linux because `Combine` is unavailable; macOS hardware run still required. See `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/Summary_of_Work.md` for details.

## 🛠️ Session Persistence Follow-Ups

- [ ] Surface session persistence errors once diagnostics plumbing is available. See `DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/Summary_of_Work.md`.
- [ ] Reconcile CoreData session bookmark diffs with live bookmark entities when reconciliation rules are defined. See `DOCS/TASK_ARCHIVE/52_E3_Session_Persistence/Summary_of_Work.md`.

## 📦 Distribution Follow-Up

- [ ] Evaluate whether automation via Apple Events is required for notarized builds and extend entitlements safely. *In Progress — see `DOCS/INPROGRESS/56_Distribution_Apple_Events_Notarization_Assessment.md`.* Track progress alongside `todo.md` entry “PDD:30m Evaluate whether automation via Apple Events is required for notarized builds and extend entitlements safely.”
