# Summary of Work — 2025-10-15

## ✅ Completed Tasks

- **A5 — Random Slice Benchmarking Harness**: Added deterministic micro-benchmarks that exercise random slice reads across `MappedReader` and `ChunkedFileReader`, wiring them into the shared performance test target.

## 🛠 Implementation Highlights

- Extended `LargeFileBenchmarkTests` with seeded random slice scenarios (small, medium, large) that reuse the existing fixture builder and respect `PerformanceBenchmarkConfiguration` iteration controls.
- Introduced a deterministic `SplitMix64` generator and slice scenario descriptions so both readers run identical workloads, verifying that failures would surface `RandomAccessReaderError` variants.
- Printed per-scenario throughput summaries from the test harness to establish reproducible baseline numbers for future regressions.

## 🔬 Verification

- `swift test`

## 📊 Baseline Metrics (default CI intensity)

| Reader | Scenario | Requests | Total Bytes | Average Slice (bytes) | Bytes per Iteration (MiB) |
| --- | --- | --- | --- | --- | --- |
| ChunkedFileReader | small | 256 | 67,046 | 261.90 | 0.06 |
| ChunkedFileReader | medium | 128 | 8,430,601 | 65,864.07 | 8.04 |
| ChunkedFileReader | large | 64 | 36,284,892 | 566,951.44 | 34.60 |
| MappedReader | small | 256 | 67,046 | 261.90 | 0.06 |
| MappedReader | medium | 128 | 8,430,601 | 65,864.07 | 8.04 |
| MappedReader | large | 64 | 36,284,892 | 566,951.44 | 34.60 |

## 🔭 Follow-Up

- [ ] Capture the same benchmark metrics on macOS hardware to compare Combine-enabled environments and confirm there is no regression relative to Linux baselines.
