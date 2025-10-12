# Next Tasks

## 🧪 Streaming UI Coverage

- [x] Add macOS SwiftUI automation for streaming selection defaults once the XCTest UI hooks land, ensuring the

  tree/detail panes update end-to-end during live parses. Covered by `ParseTreeStreamingSelectionAutomationTests` in
  the app test suite, which hosts `ParseTreeExplorerView` and verifies default selection + detail synchronization during
  a streaming parse run. **(Completed in `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`)**

## 🔬 Benchmark Follow-Up

- [ ] Execute the Combine-backed UI benchmark on macOS to capture latency metrics on a platform that ships Combine,

  keeping throughput parity with the CLI harness. **(In Progress — see `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/47_Combine_UI_Benchmark_macOS.md`)**

  - Latest container attempt (`2025-10-12`) confirmed XCTest skips the scenario on Linux because `Combine` is unavailable;

    macOS hardware run still required. See `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/Summary_of_Work.md` for details.

## 🔭 CLI Streaming Follow-Ups

- [ ] Surface global logging and telemetry toggles once streaming metrics are exposed to the CLI.
