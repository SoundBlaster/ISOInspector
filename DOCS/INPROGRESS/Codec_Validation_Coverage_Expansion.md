# Codec Validation Coverage Expansion

## 🎯 Objective
Extend automated coverage so the `CodecConfigurationValidationRule` warnings introduced in Task E4 are exercised end to end across the streaming ParsePipeline, CLI output, and JSON export snapshots.

## 🧩 Context
- Task E4 delivered the codec invariants validator and flagged follow-up coverage work to broaden its regression visibility across user-facing surfaces.【F:DOCS/TASK_ARCHIVE/143_E4_Verify_avcC_hvcC_Invariants/Summary_of_Work.md†L1-L13】
- The execution workplan tracks this follow-up as the active validation focus and expects coordination with existing preset/structural rules so coverage stays representative of real-world codec payloads.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L104-L105】
- The backlog highlights the need to assert these warnings within ParsePipeline smoke tests and CLI/JSON snapshots alongside other validation scenarios.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L228-L232】

## ✅ Success Criteria
- Add or update ParsePipeline integration tests to assert codec validation warnings are emitted for fixtures containing malformed `avcC`/`hvcC` metadata.
- Refresh CLI `validate` command snapshot(s) so codec warnings appear with stable formatting and rule identifiers.
- Update JSON export snapshot baselines (or add targeted fixtures) to include `warnings` entries showing codec validation diagnostics.
- Document any new fixtures or fixture mutations so downstream teams understand how to exercise the warnings manually.

## 🔧 Implementation Notes
- Reuse existing malformed codec fixtures from Task E4 where possible; introduce additional fixture variants only if necessary to capture warning diversity (e.g., truncated SPS/PPS, invalid length size).
- Coordinate updates with validation preset defaults so new warnings appear under standard configurations without requiring manual toggles.
- Maintain deterministic ordering in snapshots to avoid flakey diffs—normalize warning arrays if needed.
- After coverage lands, update affected documentation or archive notes if fixture usage guidance changes.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/143_E4_Verify_avcC_hvcC_Invariants`](../TASK_ARCHIVE/143_E4_Verify_avcC_hvcC_Invariants/Summary_of_Work.md)
