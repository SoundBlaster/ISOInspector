# Next Tasks

## 📋 Ready Queue

- **D2 — Implement `inspect` and `validate` commands**: Build streaming-powered subcommands on top of the new CLI scaffold so parse events and validation output surface end-to-end results.
- **E1 — Build SwiftUI app shell with document browser and recents list**: Wire the CoreData-backed session persistence
  into the app shell once CLI scaffolding stabilizes and C1/C2 foundations remain green.
- **F2 — Configure performance benchmarks for large files**: Stand up benchmarking harnesses using the streaming
  fixtures to measure CLI and app throughput for large MP4 payloads.

## 🔭 Follow-Ups From D1 Archive

- [ ] PDD:45m Surface global logging and telemetry toggles once streaming metrics are exposed to the CLI.
- [ ] PDD:1h Execute streaming inspection by consuming `ParsePipeline` events when Task D2 builds the streaming command.
- [ ] PDD:1h Produce validation reports with the streaming pipeline once Task D2 defines the CLI output contract.
- [ ] PDD:45m Route export operations to streaming capture utilities as they migrate from `ISOInspectorCLIRunner`.
