# C13 — Surface `smhd`/`vmhd` Media Header Fields

## 🎯 Objective

Expose audio (`smhd`) and video (`vmhd`) media header box fields through `BoxParserRegistry` so parsed trees and JSON exports include balance, graphics mode, and opcolor metadata for downstream UI and validation consumers.

## 🧩 Context

- Phase C of the execution workplan calls for baseline coverage of movie metadata boxes to complement the existing track (`tkhd`) and codec (`stsd`) parsing capabilities.
- Prior codec metadata expansions introduced in Task C6 established formatting expectations for audio/video presentation

  data surfaced to the UI and CLI exports.

- JSON export snapshots and UI detail panes rely on consistent field naming to keep handler- and codec-derived metadata

  aligned.

## ✅ Success Criteria

- `smhd` and `vmhd` parsers populate dedicated model structures registered with `BoxParserRegistry` and appear in CLI JSON output.
- Balance and graphics mode/opcolor values are normalized into human-readable representations while retaining raw

  numeric forms for validation.

- Regression fixtures cover representative audio- and video-track samples, updating snapshot baselines as needed without

  breaking unrelated boxes.

- Documentation (DocC or inline developer notes) references the new fields so UI components can bind to them without

  guesswork.

## 🔧 Implementation Notes

- Reuse the shared FullBox decoding utilities introduced in earlier tasks to handle version/flags fields before reading

  payload data.

- Ensure handler metadata from `hdlr` stays consistent when presenting media header fields; cross-check existing archives for codec metadata formatting.
- Update `BoxParserRegistry` mappings, Swift data models, and JSON coding keys together to avoid mismatched exports.
- Validate parsed values against reference material (ISO/IEC 14496-12 §8.4.3) and available fixtures; add TODOs only if

  spec gaps remain.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/INPROGRESS/next_tasks.md`](next_tasks.md)
- [`DOCS/TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/C6_Extend_stsd_Codec_Metadata.md`](../TASK_ARCHIVE/102_C6_Extend_stsd_Codec_Metadata/C6_Extend_stsd_Codec_Metadata.md)
