# Next Tasks

## Active

- [ ] **T6.3 — SDK Tolerant Parsing Documentation** (Priority: Medium, Effort: 1 day)
  - Create DocC article `TolerantParsingGuide.md` in `Sources/ISOInspectorKit/ISOInspectorKit.docc/Articles/`
  - Add code examples for tolerant parsing setup and `ParseIssueStore` usage
  - Update inline documentation for `ParsePipeline.Options`, `.strict`, `.tolerant`
  - Link new guide from main `Documentation.md` Topics section
  - Verify examples with test file in `Tests/ISOInspectorKitTests/`
  - See `DOCS/INPROGRESS/211_T6_3_SDK_Tolerant_Parsing_Documentation.md` for full PRD

## Blocked (Hardware)

- [ ] Run the lenient-versus-strict benchmark on macOS hardware with Combine enabled using the 1 GiB fixture:
  - Export `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824`.
  - Invoke `swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget`.
  - Archive the printed runtime and RSS metrics under `Documentation/Performance/` alongside the existing 32 MiB results.
  - Cross-check results against the archived Linux baseline in `Documentation/Performance/2025-11-04-lenient-vs-strict-benchmark.log` and note deviations in the summary log.
