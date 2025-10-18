# Next Tasks

## 📚 Research & Backlog Grooming

- [x] **R2 Fixture Acquisition Research** — Curated multi-source fixture catalog with licensing, download, and storage guidance. (See `DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md` and `DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/Summary_of_Work.md`.)

## 🧱 Fixture Automation

- [x] **PDD:45m Manifest-Driven Fixture Acquisition** — Extend `generate_fixtures.py` to download fixtures from the curated manifest with checksum verification and license mirroring. **(Completed — manifest workflow implemented; see `DOCS/INPROGRESS/Summary_of_Work.md` for current notes.)**

## 📝 Release Readiness Validation

- [ ] Execute macOS DocC generation, notarization, TestFlight export, and hardware-dependent QA once runners are available, following the release readiness runbook. **(Blocked — requires macOS infrastructure; see `Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md` and the archival notes in `DOCS/TASK_ARCHIVE/83_Summary_of_Work_2025-10-Release_Prep/Summary_of_Work.md`.)**

## 🔭 Benchmark Validation

- [ ] Execute the random slice benchmark suite on macOS hardware once Combine support is available so we can compare mapped vs. chunked readers under identical workloads. **(Blocked — requires macOS runner with Combine; see `DOCS/TASK_ARCHIVE/64_A5_Random_Slice_Benchmarking/Summary_of_Work.md` and `DOCS/TASK_ARCHIVE/65_Summary_of_Work_2025-10-15_Benchmark/2025-10-15-random-slice-benchmark.md`.)**

## 🧪 Streaming UI Coverage

- [ ] Run `ParseTreeStreamingSelectionAutomationTests` on macOS hardware with XCTest UI support to validate the end-to-end SwiftUI automation flow introduced in `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`. **(Blocked — macOS UI testing entitlements unavailable in container; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/51_ParseTreeStreamingSelectionAutomation_macOS_Run.md`.)**

## 🔬 Combine UI Benchmark Follow-Up

- [ ] Execute the Combine-backed UI benchmark on macOS to capture latency metrics on a platform that ships Combine, keeping throughput parity with the CLI harness. **(Blocked — requires macOS runner with Xcode/Combine; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md` and the follow-up notes in `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/Summary_of_Work.md`.)**
