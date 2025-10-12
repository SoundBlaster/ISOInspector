# Next Tasks

## 🚧 In Progress

- **E2 — Integrate parser event pipeline with UI components in app context**: Focus on bridging the streaming parser
  feed into the SwiftUI shell so opening a file drives live tree/detail refreshes using the existing Combine bridge.

## 🔬 Benchmark Follow-Up

- [ ] Execute the Combine-backed UI benchmark on macOS to capture latency metrics on a platform that ships Combine,

  keeping throughput parity with the CLI harness.

## 🔭 Follow-Ups From D2 Archive

- [ ] PDD:45m Surface global logging and telemetry toggles once streaming metrics are exposed to the CLI.
- [ ] PDD:45m Route export operations to streaming capture utilities as they migrate from `ISOInspectorCLIRunner`.
