# C6 Codec Payload Additions Follow-Up

## 🎯 Objective

Document the plan for extending `BoxParserRegistry` with future codec-specific payload parsers so new fixtures (e.g., Dolby Vision descriptors or novel audio profiles) surface rich metadata without regressions.

## 🧩 Context

- `DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/Summary_of_Work.md` highlights the need to monitor upcoming codec payload additions after landing AVC/HEVC/AAC coverage.
- `DOCS/INPROGRESS/next_tasks.md` tracks this follow-up under "Upcoming Parser Enhancements" to keep streaming and export paths aligned with new payload types.
- `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` maintains codec configuration milestones under Phase C, ensuring UI and CLI consumers display codec metadata consistently.

## ✅ Success Criteria

- Inventory target codec payloads (e.g., Dolby Vision `dvvC`, enhanced audio descriptors) with fixture sources and decoding references.
- Define parser requirements, emitted fields, and validation hooks per payload while preserving existing snapshot/export
  regressions.
- Outline test coverage updates (unit + JSON snapshot) required for each new payload and identify fixture gaps.
- Enumerate documentation updates needed across PRD, user guides, and archived follow-up notes once implementations
  land.

## 🔧 Implementation Notes

- Review MP4RA and vendor specs for new sample entry extensions; capture fourccs, struct layouts, and compatibility
  constraints.
- Prototype parser stubs in `BoxParserRegistry` mirroring the existing AVC/HEVC/AAC implementations for consistent field naming.
- Coordinate fixture acquisition via `generate_fixtures.py` manifests so new payloads have reproducible samples.
- Plan validation updates to flag unsupported or malformed payload data, keeping telemetry aligned with VR-006 research
  logging when parsers fall back to opaque payloads.

## 🧠 Source References

- [`DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/Summary_of_Work.md`](../TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/Summary_of_Work.md)
- [`DOCS/INPROGRESS/next_tasks.md`](next_tasks.md)
- [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
