# 2025-10-15-random-slice-benchmark — micro PRD

## Intent

Deliver deterministic random slice performance benchmarks that compare `MappedReader` and `ChunkedFileReader` under identical workloads.

## Scope

- Kit: No code changes; exercises existing `RandomAccessReader` conformers.
- CLI: No changes.
- App: No changes.

## Integration contract

- Public Kit API added/changed: None.
- Call sites updated: `Tests/ISOInspectorPerformanceTests/LargeFileBenchmarkTests.swift` (random slice scenarios).
- Backward compat: Unchanged.
- Tests: `Tests/ISOInspectorPerformanceTests/LargeFileBenchmarkTests.swift` (new benchmark cases for both readers).

## Next puzzles

- [ ] Execute the benchmark suite on macOS hardware to capture Combine-enabled measurements alongside the Linux

  baselines.

## Notes

- Benchmark scenarios reuse `PerformanceBenchmarkConfiguration` iteration controls and print baseline metrics for three slice classes (small/medium/large) derived from a seeded `SplitMix64` generator.
- Default CI intensity yielded 0.06, 8.04, and 34.60 MiB per-iteration throughput samples for both readers (see `DOCS/TASK_ARCHIVE/64_A5_Random_Slice_Benchmarking/Summary_of_Work.md`).
- Build: `swift test`
