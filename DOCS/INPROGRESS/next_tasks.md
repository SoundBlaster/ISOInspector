# Next Tasks

## 🚧 In Progress

- **E1 — Build SwiftUI app shell with document browser and recents list**: Continue wiring the CoreData-backed session persistence into the shell now that CLI scaffolding is stable. Reference context in `DOCS/TASK_ARCHIVE/43_E1_Build_SwiftUI_App_Shell/`.

## 🔬 Benchmark Follow-Up

- [ ] Execute the Combine-backed UI benchmark on macOS to capture latency metrics on a platform that ships Combine,
  keeping throughput parity with the CLI harness.

## 🔭 Follow-Ups From D2 Archive

- [ ] PDD:45m Surface global logging and telemetry toggles once streaming metrics are exposed to the CLI.
- [ ] PDD:45m Route export operations to streaming capture utilities as they migrate from `ISOInspectorCLIRunner`.
