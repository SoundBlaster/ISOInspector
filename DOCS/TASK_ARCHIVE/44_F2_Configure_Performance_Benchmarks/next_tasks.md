# Next Tasks

## 🚧 In Progress

- **E1 — Build SwiftUI app shell with document browser and recents list**: Wiring the CoreData-backed session

  persistence into the app shell is underway now that CLI scaffolding is stable and C1/C2 foundations remain green. See
  [E1_Build_SwiftUI_App_Shell.md](../TASK_ARCHIVE/43_E1_Build_SwiftUI_App_Shell/E1_Build_SwiftUI_App_Shell.md) for the
archived PRD context.

- **F2 — Configure performance benchmarks for large files**: Benchmark harness implementation has started to validate

  CLI and app throughput for streaming MP4 analysis. Tracking against performance NFRs called out in the execution
  guide and PRD while instrumentation hooks land.

## 📋 Ready Queue

Empty — select from backlog sources when new capacity opens.

## 🔭 Follow-Ups From D2 Archive

- [ ] PDD:45m Surface global logging and telemetry toggles once streaming metrics are exposed to the CLI.
- [x] PDD:1h Execute streaming inspection by consuming `ParsePipeline` events when Task D2 builds the streaming command.
- [x] PDD:1h Produce validation reports with the streaming pipeline once Task D2 defines the CLI output contract.
- [x] PDD:45m Route export operations to streaming capture utilities as they migrate from `ISOInspectorCLIRunner`.
