# Next Tasks

## 🧪 Streaming UI Coverage

- [ ] Run `ParseTreeStreamingSelectionAutomationTests` on macOS hardware with XCTest UI support to validate the end-to-end SwiftUI automation flow introduced in `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`.

## 🔬 Benchmark Follow-Up

- [ ] Execute the Combine-backed UI benchmark on macOS to capture latency metrics on a platform that ships Combine, keeping throughput parity with the CLI harness. **(In Progress — see `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/47_Combine_UI_Benchmark_macOS.md`)**
  - Latest container attempt (`2025-10-12`) confirmed XCTest skips the scenario on Linux because `Combine` is unavailable; macOS hardware run still required. See `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/Summary_of_Work.md` for details.

## 🔭 CLI Streaming Follow-Ups

- [ ] Surface global logging and telemetry toggles once streaming metrics are exposed to the CLI. **(In Progress — see `DOCS/INPROGRESS/49_CLI_Global_Logging_and_Telemetry_Toggles.md`.)**
