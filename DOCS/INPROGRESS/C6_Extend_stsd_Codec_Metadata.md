# C6 — Extend `stsd` Codec Metadata Extraction

## 🎯 Objective

Implement codec-specific payload parsing for `stsd` sample entries so ISOInspector surfaces rich metadata for H.264/AVC, H.265/HEVC, and MPEG-4 Audio tracks, including encrypted variants, across the CLI and SwiftUI front ends.

## 🧩 Context

- Phase C of the execution workplan elevates parser coverage as a priority, and follow-up notes from Task C6 call out

  codec metadata extraction as the next milestone.

【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L28-L36】【F:DOCS/TASK_ARCHIVE/97_C6_stsd_Sample_Description_Parser/Summary_of_Work.md†L5-L22】

- The master PRD requires ISOInspector to expose codec configuration boxes (`avcC`, `hvcC`, `esds`) so validation, navigation, and export pipelines can report detailed stream properties. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L23-L76】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L189-L210】
- Root TODO item “PDD:45m Extract codec-specific metadata…” and the `next_tasks.md` backlog both track this as the next unblocker for media sample visibility. 【F:todo.md†L40-L44】【F:DOCS/INPROGRESS/next_tasks.md†L7-L18】

## ✅ Success Criteria

- Parse `avcC` boxes nested under `avc1/avc2/avc3/avc4` sample entries, extracting profile, compatibility flags, level, and SPS/PPS descriptors.
- Parse `hvcC` boxes under `hvc1/hev1/dvh1/dvhe` entries, capturing profile space, tier, level, constraint flags, and VPS/SPS/PPS lists.
- Parse `esds` descriptors for `mp4a` entries to expose AudioSpecificConfig (object type, sampling frequency, channel configuration) and any extension descriptors.
- Preserve encrypted sample entry metadata (`encv`/`enca`) by threading sinf/schi/tenc relationships without losing codec payload access.
- Extend JSON/export models and SwiftUI detail views so newly parsed codec fields appear in CLI exports and the detail

  pane with regression test coverage.

## ✅ Status

- Implemented the codec payload parsers in `BoxParserRegistry` for `avcC`, `hvcC`, and `esds`, including encrypted entry handling, and expanded tests plus JSON snapshots to cover the new metadata surfaces. See `DOCS/INPROGRESS/Summary_of_Work.md` for verification details.

## 🔧 Implementation Notes

- Reuse existing `FullBoxReader`/`BitReader` utilities where possible; add targeted helpers if new bit-level parsing is required.
- Introduce strongly typed models for codec payloads so validation rules and UI bindings remain type-safe; add Codable

  conformance for JSON export.

- Update the parser registry to associate codec sample entries with the new payload decoders while keeping unknown

  codecs resilient.

- Expand fixture coverage (or reuse existing fixtures) to assert parsing across AVC, HEVC, and AAC samples, including

  encrypted variants if available.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/97_C6_stsd_Sample_Description_Parser`](../TASK_ARCHIVE/97_C6_stsd_Sample_Description_Parser)
