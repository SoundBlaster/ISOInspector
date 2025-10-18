# Next Tasks

## 🧠 Parser Infrastructure

- [ ] B5 — Introduce `FullBoxReader` for (version,flags) extraction. **(In Progress — see `DOCS/INPROGRESS/B5_FullBoxReader.md`.)**

## 🎨 App Theming (In Review)

- [x] I3 — App theming (icon, light/dark). **(Completed — production icon rasterization automated via `scripts/generate_app_icon.py`; see `DOCS/INPROGRESS/Summary_of_Work.md`.)**
  - Accent palette and SwiftUI tint wiring landed in `DOCS/TASK_ARCHIVE/80_Summary_of_Work_2025-10-17_App_Theming/Summary_of_Work.md` (2025-10-17); rasterization summary captured in `DOCS/INPROGRESS/I3_App_Icon_Rasterization.md`.

## 🔭 Benchmark Validation

- [ ] Execute the random slice benchmark suite on macOS hardware once Combine support is available so we can compare

  mapped vs.

  chunked readers under identical workloads. **(Blocked — requires macOS runner with Combine; see `DOCS/TASK_ARCHIVE/64_A5_Random_Slice_Benchmarking/Summary_of_Work.md` and
  `DOCS/TASK_ARCHIVE/65_Summary_of_Work_2025-10-15_Benchmark/2025-10-15-random-slice-benchmark.md`.)**

## 🧪 Streaming UI Coverage

- [ ] Run `ParseTreeStreamingSelectionAutomationTests` on macOS hardware with XCTest UI support to validate the end-to-end SwiftUI

  automation flow introduced in `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`.
  **(Blocked — macOS UI testing entitlements unavailable in container; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/51_ParseTreeStreamingSelectionAutomation_macOS_Run.md`.)**

## 🔬 Combine UI Benchmark Follow-Up

- [ ] Execute the Combine-backed UI benchmark on macOS to capture latency metrics on a platform that ships Combine,

  keeping throughput parity with the CLI harness.

  **(Blocked — requires macOS runner with Xcode/Combine; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md`.)**

  - Latest container attempt (`2025-10-12`) confirmed XCTest skips the scenario on Linux because `Combine` is unavailable; macOS hardware run still required. See

    `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/Summary_of_Work.md` for details.
