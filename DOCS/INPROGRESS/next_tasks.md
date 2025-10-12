# Next Tasks

## 🧪 Streaming UI Coverage

- [ ] Add macOS SwiftUI automation for streaming selection defaults once the XCTest UI hooks land, ensuring the

  tree/detail panes update end-to-end during live parses. (Follow-up from archived E2 work.)

## 🔬 Benchmark Follow-Up

- [ ] Execute the Combine-backed UI benchmark on macOS to capture latency metrics on a platform that ships Combine,

  keeping throughput parity with the CLI harness. **(In Progress — see `DOCS/INPROGRESS/47_Combine_UI_Benchmark_macOS.md`)**

  - Latest container attempt (`2025-10-12`) confirmed XCTest skips the scenario on Linux because `Combine` is unavailable;

    macOS hardware run still required. See `DOCS/INPROGRESS/Summary_of_Work.md` for details.

## 🔭 CLI Streaming Follow-Ups

- [ ] Surface global logging and telemetry toggles once streaming metrics are exposed to the CLI.
