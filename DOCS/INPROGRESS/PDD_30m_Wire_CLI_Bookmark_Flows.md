# PDD: Wire CLI Bookmark Flows to FilesystemAccessAuditTrail

## 🎯 Objective

Connect the CLI bookmark authorization and reuse paths to the shared `FilesystemAccessAuditTrail` so zero-trust telemetry captures headless file access operations alongside existing logging toggles.

## 🧩 Context

- Zero-trust logging introduced `FilesystemAccessAuditTrail`, append-only audit events, and logger helpers that redact file identifiers for sandbox compliance.【F:DOCS/TASK_ARCHIVE/74_G4_Zero_Trust_Logging/Summary_of_Work.md†L5-L13】
- The CLI wraps file parsing through `ISOInspectorCLIEnvironment`, which owns reader factories, research log writers, and telemetry switches exposed via the global `--enable-telemetry/--disable-telemetry` flags.【F:Sources/ISOInspectorCLI/CLI.swift†L5-L60】【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L57-L103】
- Automation flows rely on FilesystemAccessKit bookmarks and sandbox profiles to operate without interactive prompts, so
  CLI executions must emit auditable traces for compliance
  reporting.【F:Documentation/ISOInspector.docc/Guides/CLISandboxProfileGuide.md†L1-L27】

## ✅ Success Criteria

- CLI bookmark acquisition, refresh, and reuse paths append structured events to a process-scoped `FilesystemAccessAuditTrail`, even when running headless.
- Telemetry flags remain authoritative: disabling telemetry suppresses audit publishing, while enabling telemetry
  ensures audit output is flushed or exported for automation logs.
- Unit tests cover CLI bookmark flows with audit assertions, and documentation cross-references are updated to reflect
  the new telemetry behavior.

## 🔧 Implementation Notes

- Extend `ISOInspectorCLIEnvironment` to vend a `FilesystemAccessLogger` (or audit-aware wrapper) that threads a shared `FilesystemAccessAuditTrail` into bookmark helpers without mutating the existing reader/parsing contracts.【F:Sources/ISOInspectorCLI/CLI.swift†L5-L60】【F:Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccessLogger.swift†L1-L46】
- Ensure quiet/verbose logging options still work by routing audit persistence separately from user-facing output, preserving existing `logVerbosity` semantics.【F:Sources/ISOInspectorCLI/CLI.swift†L61-L88】
- Update CLI tests to validate that bookmark commands respect telemetry mode defaults and emit (or suppress) audit entries accordingly, mirroring the patterns established in `FilesystemAccessLoggerTests` and related fixtures.【F:Tests/ISOInspectorKitTests/FilesystemAccessLoggerTests.swift†L5-L52】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
