# R4 — Large File Performance Benchmarks

## Benchmark Charter

- Validate ISOInspector against 20 GB media so Phase F2 budgets (<100 MB peak memory, <200 ms UI latency) remain

  credible before hardware validation.

- Exercise both the CLI validator and the SwiftUI streaming bridge because they share the same streaming parser but

  surface different back-pressure risks.

- Capture repeatable metrics that can gate regressions inside XCTest Metric harnesses and inform release readiness

  sign-off.

## Scenario Matrix

| Scenario | Runner | Fixture Size | Runtime Budget | Memory Budget | Observability Hooks | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| CLI validation sweep | `isoinspector validate <fixture>` executed from XCTest Metric harness | 20 GB progressive MP4 (single `mdat`) | ≤ 7 minutes (≈ 50 MB/s sustained throughput) | < 90 MB RSS sustained, < 100 MB peak | Signposts around chunk ingestion, `os_signpost` for validation loop, `XCTMemoryMetric`, `XCTClockMetric` | Baseline scenario that matches shipping CLI workflows and feeds regression dashboards.
| CLI streaming export | `isoinspector inspect --stream` piping to `/dev/null` | 20 GB fragmented MP4 with interleaved `moof`/`mdat` | ≤ 9 minutes (fragment traversal adds allocator churn) | < 95 MB sustained, < 105 MB peak | Signposts for fragment boundaries, `XCTCPUMetric` to track decode overhead, CLI stdout captured for drift checks | Ensures parse loop handles interleaved fragments without regressing throughput.
| SwiftUI streaming session | UI automation host running `ISOInspectorApp` with 20 GB fixture attached | 20 GB progressive MP4 | First frame < 350 ms, steady-state latency per update < 200 ms | < 120 MB peak combined app + CoreData caches, < 80 MB for parser process | Unified logging category `com.chimehq.isoinspector.benchmark`, metric overlays via `MeasureOptions.signpostInterval`, `Instruments` template for manual confirmation | Validates that Combine bridge and diffing layers do not stall when tree updates stream from large fixtures.
| SwiftUI fragmented session | UI automation host running `ISOInspectorApp` with fragmented 20 GB fixture | 20 GB fragmented MP4 | Initial render < 500 ms, steady-state < 250 ms per fragment batch | Same as progressive scenario; focus on delta memory | Signposts tied to `ParseTreeViewModel` diff apply, `XCTClockMetric` on automation harness | Captures worst-case tree churn to validate scheduler headroom prior to shipping Combine-backed UI benchmarks.

## Fixture Acquisition Strategy

| Approach | Description | Storage Footprint | Licensing & Source | Notes |
| --- | --- | --- | --- | --- |
| Synthetic filler via Bento4 `mp4mux` + `dd` | Generate baseline 20 GB progressive MP4 by muxing a short GOP video repeatedly and padding with zeroed `mdat` chunks using `dd` | ~21 GB per variant (raw file + checksum) | Bento4 tools are BSD-licensed; filler content derived from CC0 sample (e.g., Big Buck Bunny) | Deterministic content suitable for diff-based validation; stored in macOS CI cache with SHA256 manifest.
| Fragmented stressor via Bento4 `mp4fragment` | Take synthetic progressive asset and fragment into 8 MB segments with alternating track payloads | ~22 GB (fragmented copy + logs) | Same as above | Adds metadata churn; includes manifest describing fragment boundaries for UI automation scripts.
| Vendor dataset mirror (e.g., DASH or Apple HLS sample) | Acquire publicly redistributable 4K mezzanine asset (~5 GB) and duplicate with bitrate ladders to reach 20 GB | ≤ 25 GB (source + expanded copy) | Confirm redistribution terms (Apple sample code license, DASH-IF test vectors) before mirroring | Provides realistic codec distribution and metadata density; stored in restricted S3 bucket referenced by manifest.
| Synthetic error fixture | Use GPAC `MP4Box` to inject malformed boxes or truncated fragments into synthetic filler | +2 GB over baseline (store pristine + malformed variants) | GPAC is LGPL; mutations are locally generated | Enables regression coverage for failure handling within benchmarks without exposing licensed footage.

## Tooling & Instrumentation Matrix

| Category | Tooling | Purpose | Integration Notes |
| --- | --- | --- | --- |
| Fixture creation | Bento4 (`mp4mux`, `mp4fragment`), GPAC `MP4Box`, `dd`, `cat` | Build deterministic 20 GB assets with known layouts | Recipes scripted via `scripts/generate_fixtures.py` extension; manifest includes checksum, provenance, and license tags.
| Baseline analysis | `ffprobe`, `mp4dump`, Bento4 `mp4info` | Validate track tables, fragment layouts, and codec metadata pre-run | Store command outputs alongside fixture manifest for diffing.
| Benchmark harness | XCTest Metrics (`XCTClockMetric`, `XCTCPUMetric`, `XCTMemoryMetric`), `measure(options:baselineSignpost:)` | Capture timing and memory budgets inside CI | CLI scenarios instrumented via `PerformanceBenchmarkTests`; UI scenarios rely on macOS-only automation runner.
| Observability | `os_log` categories (`benchmark.cli`, `benchmark.ui`), `os_signpost`, unified logging, Instruments templates | Collect fine-grained latency data and align with metrics thresholds | Signpost IDs follow `<scenario>-<phase>` naming to simplify cross-run comparisons.
| Automation & virtualization | macOS runner images with Xcode 16+, Apple Virtualization framework for local dry runs, Linux degraded smoke harness | Document hardware SKU (8-core M2 Pro baseline), virtualization settings, and fallback Linux invocation | Linux smoke run uses truncated 4 GB fixtures to verify harness while macOS hardware is unavailable.

## Execution Workflow

1. Provision fixtures via `scripts/generate_fixtures.py --profile large-bench`, which orchestrates Bento4/GPAC steps and writes manifests with SHA256, source URL, license tag, and expected runtime budget.
1. Warm macOS runner caches by preloading fixtures onto an attached NVMe volume (document mount path `/Volumes/ISOInspectorBench`).
1. Run CLI XCTest Metric suite:
   - `swift test --filter PerformanceBenchmarkTests/testCLIValidateLargeFile` (progressive) and `.../testCLIStreamLargeFile` (fragmented).
   - Harness enforces runtime and memory budgets; results exported as `.xcresult` attachments with summary JSON.
1. Run UI automation benchmarks when macOS UI runners are available:
   - `xcodebuild test -scheme ISOInspectorApp -destination 'platform=macOS' -only-testing ISOInspectorAppUITests/PerformanceBenchmarks`.
   - Automation script drives the document picker to mount fixtures, captures signpost intervals, and exports

     Instruments traces.

1. Record outcomes in `Distribution/Benchmarks/large-file/` with run metadata (runner SKU, commit SHA, fixture manifest revision).
1. Publish regression dashboards by parsing `.xcresult` metrics into `benchmarks.json` consumed by the CI reporting step.

## Risk Mitigation & Fallbacks

- **macOS hardware unavailable:** run Linux smoke harness with 4 GB fixtures to verify tooling, then schedule a manual macOS slot; track outstanding runs in `DOCS/INPROGRESS/next_tasks.md`.
- **Storage pressure:** rotate fixtures via manifest TTL, keeping only the latest synthetic and vendor mirrors while

  archiving older runs to S3.

- **Toolchain drift (Bento4/GPAC updates):** pin tool versions in `Scripts/Fixtures/requirements.txt` and record SHAs in the manifest.
- **Benchmark flakiness:** configure XCTest Metric baseline tolerances (±5%) and auto-rerun on failure; if variance

  persists, capture an Instruments trace and attach it to the research log.

- **Licensing red flags:** restrict vendor-derived fixtures to private S3 with access logs and document approval status

  in the manifest.

## Deliverables & Follow-Ups

- Update F2 implementation notes to reference this benchmark matrix and fixture manifest requirements.
- Add new blocked tasks to `DOCS/INPROGRESS/next_tasks.md` for macOS automation coverage once hardware is available.
- Archive fixture recipes and manifests under `Documentation/FixtureCatalog/large-file-benchmarks/` during implementation handoff.
- Coordinate with release readiness owners so benchmark runs become a gating checklist item prior to shipping GA builds.
