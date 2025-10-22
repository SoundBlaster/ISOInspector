# E4 — Verify avcC/hvcC Invariants

## 🎯 Objective
Deliver validation coverage that enforces codec configuration invariants in `avcC` and `hvcC` boxes so malformed entries are surfaced consistently across ISOInspectorKit, the CLI, and JSON exports.

## 🧩 Context
- Master PRD codec requirements call out strict bounds on `lengthSizeMinusOne`, parameter set arrays, and decoder configuration details for `avcC`/`hvcC`. Use these constraints to define validation rules and messaging.
- The detailed backlog highlights Task E4 as the remaining validation item to ensure codec metadata stays trustworthy for downstream tooling.
- Existing parsers already expose the structured metadata (`ISOInspectorKit` payload models, CLI formatting, JSON export); this task layers additional checks rather than introducing new parsing logic.

## ✅ Success Criteria
- Validation detects and flags `lengthSizeMinusOne` values outside `{0,1,2,3}` for both `avcC` and `hvcC` payloads.
- Mismatched array counts (e.g., SPS/PPS/VPS descriptors with inconsistent lengths) trigger actionable warnings/errors that flow through CLI output, UI badges, and JSON export metadata.
- Unit and snapshot tests cover representative fixtures (valid + invalid) ensuring regression protection across Kit, CLI, and export modules.
- Documentation/backlog entries updated to reflect completion, including removal from `next_tasks.md` once delivered.

## 🔧 Implementation Notes
- Extend existing validation infrastructure (e.g., VR-series rules) with codec-specific checks, ensuring they run during streaming parse without requiring payload re-reads.
- Reuse fixture coverage from codec parser tasks; add targeted malformed fixtures if gaps exist (consider synthetic descriptors that violate array counts or contain zero-length NAL units).
- Ensure CLI and JSON export surfaces include clear messaging (e.g., warning identifiers) so downstream automation can react to codec inconsistencies.
- Coordinate with ongoing E1 containment work to avoid duplicated error reporting—codec validations should supplement structural checks, not mask them.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
