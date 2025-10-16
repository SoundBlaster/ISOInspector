# G4 — Zero-Trust Logging & Audit Trail

## 🎯 Objective

Deliver zero-trust logging for FilesystemAccessKit so file access events record hashed identifiers, redact absolute
paths, and expose an auditable trail for sandbox compliance.

## 🧩 Context

- Workplan Task G4 calls for hashed identifiers and diagnostics coverage now that FilesystemAccessKit core APIs (Task
  G1) are complete.
- The FilesystemAccessKit PRD identifies FS-OBJ-04 and Phase P5 as the logging deliverable, emphasizing minimal path
  exposure and audit readiness.
- CLI sandbox documentation requires telemetry parity with bookmark persistence diagnostics to keep headless automation
  compliant.

## ✅ Success Criteria

- Access logging layer produces hashed handles and timestamped events without leaking raw file paths.
- Unit tests cover log hashing, rotation, and failure cases for bookmark resolution.
- CLI automation emits the same redacted diagnostics so documentation examples remain accurate.
- Logging hooks integrate with existing persistence diagnostics without duplicating identifiers.

## 🔧 Implementation Notes

- Extend FilesystemAccessKit logging utilities before wiring through app and CLI targets to avoid API churn.
- Reuse existing diagnostics infrastructure from session persistence work to attach hashed bookmark IDs.
- Update documentation to describe the hashed logging format and how auditors correlate events with bookmark metadata.
- Coordinate with sandbox profile guidance to document any new environment variables or flags required for audit
  exports.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`09_FilesystemAccessKit_PRD.md`](../AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
