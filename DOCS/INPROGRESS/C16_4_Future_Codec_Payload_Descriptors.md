# C16.4 Future Codec Payload Descriptors

## 🎯 Objective
Deliver typed parsers and export coverage for upcoming codec payload descriptors (Dolby Vision `dvvC`, AV1 `av1C`, VP9 `vpcC`, Dolby AC-4 `dac4`, MPEG-H `mhaC`) so ISOInspector continues surfacing complete metadata as new fixtures land.

## 🧩 Context
- Builds on the `stsd` sample description infrastructure and codec metadata extraction archived in `DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/`.
- Continuation of the research outlined in `DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/C6_Codec_Payload_Additions.md` now promoted to active execution.
- Aligns with the Phase C codec milestones in `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` and the streaming/export integration requirements in the execution workplan.

## ✅ Success Criteria
- Catalog fixtures and decoding references for each targeted payload descriptor, confirming licensing coverage.
- Implement typed `CodecPayload` models and registry wiring for all targeted descriptors with graceful fallback for unknown variants.
- Extend unit tests and JSON snapshot baselines to include the new payload fields without regressing existing coverage.
- Update CLI/UI documentation snippets to showcase the additional codec metadata fields once fixtures validate.

## 🔧 Implementation Notes
- Introduce feature flags or guarded registry entries so incomplete payloads do not ship without fixtures.
- Reuse existing bit reader utilities for packed-field decoding (e.g., AV1 operating point flags) and ensure colour metadata maps onto existing enums.
- Capture VR-006 research log entries for unsupported profile combinations and truncated payload scenarios.
- Coordinate fixture acquisition updates through `scripts/generate_fixtures.py` to record checksums and licenses alongside new samples.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/C6_Codec_Payload_Additions.md`](../TASK_ARCHIVE/103_C2_mvhd_Movie_Header_Parser/C6_Codec_Payload_Additions.md)
