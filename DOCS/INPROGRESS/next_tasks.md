# Next Tasks

## 🚧 Active Parser Tasks

- [x] C2 — Implement `mvhd` movie header parser (**Completed — parser, detail struct, and tests documented in `DOCS/INPROGRESS/Summary_of_Work.md` and `DOCS/INPROGRESS/C2_mvhd_Movie_Header_Parser.md`).

## 🎯 Upcoming Parser Enhancements

- [x] Monitor upcoming codec payload additions (e.g., Dolby Vision boxes, descriptor extensions) so the `BoxParserRegistry` gains dedicated entries when new fixtures arrive. Planning roadmap captured in `DOCS/INPROGRESS/C6_Codec_Payload_Additions.md`; implementation follow-ups will graduate into dedicated puzzles.

## 🔄 Follow-Ups from C5 `hdlr` Parser

- [ ] Evaluate additional handler type categorizations if future boxes require specialized roles beyond the current mapping set. *(Track notes in `DOCS/TASK_ARCHIVE/96_C5_hdlr_Handler_Parser/Summary_of_Work.md` once refined.)*

## 📈 Performance Benchmark Planning

- [ ] Schedule macOS CLI/UI large-file benchmark execution using the R4 protocol once dedicated hardware runners come online. *(Blocked — requires macOS automation with Instruments support; track fixtures and manifest revisions in `DOCS/TASK_ARCHIVE/93_R4_Large_File_Performance_Benchmarks/R4_Large_File_Performance_Benchmarks.md`.)*

## 📝 Release Readiness Validation

- [ ] Execute macOS DocC generation, notarization, TestFlight export, and hardware-dependent QA once runners are available, following the release readiness runbook. *(Blocked — requires macOS infrastructure; see `Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md` and archival notes in `DOCS/TASK_ARCHIVE/83_Summary_of_Work_2025-10-Release_Prep/Summary_of_Work.md`.)*

## 🔭 Benchmark Validation

- [ ] Execute the random slice benchmark suite on macOS hardware once Combine support is available so we can compare mapped vs. chunked readers under identical workloads. *(Blocked — requires macOS runner with Combine; see `DOCS/TASK_ARCHIVE/64_A5_Random_Slice_Benchmarking/Summary_of_Work.md` and `DOCS/TASK_ARCHIVE/65_Summary_of_Work_2025-10-15_Benchmark/2025-10-15-random-slice-benchmark.md`.)*

## 🧪 Streaming UI Coverage

- [ ] Run `ParseTreeStreamingSelectionAutomationTests` on macOS hardware with XCTest UI support to validate the end-to-end SwiftUI automation flow introduced in `DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md`. *(Blocked — macOS UI testing entitlements unavailable in container; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/51_ParseTreeStreamingSelectionAutomation_macOS_Run.md`.)*

## 🔬 Combine UI Benchmark Follow-Up

- [ ] Execute the Combine-backed UI benchmark on macOS to capture latency metrics on a platform that ships Combine, keeping throughput parity with the CLI harness. *(Blocked — requires macOS runner with Xcode/Combine; see `DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md` and the follow-up notes in `DOCS/TASK_ARCHIVE/47_Combine_UI_Benchmark_macOS/Summary_of_Work.md`.)*

## 📚 Recently Archived Reference

- ✅ Task H3 — JSON export snapshot tests now archived. Implementation details and snapshot update workflow live in `DOCS/TASK_ARCHIVE/98_H3_JSON_Export_Snapshot_Tests/Summary_of_Work.md` and `DOCS/TASK_ARCHIVE/98_H3_JSON_Export_Snapshot_Tests/H3_JSON_Export_Snapshot_Tests.md`.
- ✅ Task C6 — Codec metadata extraction archived at `DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/` with verification notes in `Summary_of_Work.md`.
