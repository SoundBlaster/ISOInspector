# C3 — tkhd Track Header Parser

## 🎯 Objective

Implement a parser for the `tkhd` (track header) box that extracts flag-dependent fields, duration, transformation matrix, and presentation dimensions for display across ISOInspector surfaces.

## 🧩 Context

- Aligns with Phase C baseline parser goals outlined in the execution workplan and PRD backlog.
- Builds upon completed `mvhd`, `mdhd`, and `hdlr` parsers to surface cohesive track metadata for UI and export consumers.

## ✅ Success Criteria

- Support both version 0 and 1 layouts, honoring flag-driven optional fields (e.g., `duration` and `alternate_group`).
- Decode track and movie times (`creation_time`, `modification_time`, `track_id`, `duration`) using the correct bit widths per version.
- Parse layer, alternate group, volume, and 3x3 transformation matrix values with fixed-point conversion consistent with
  PRD specifications.
- Expose width and height fields as 16.16 fixed-point dimensions and flag zero-sized tracks for validation follow-up.
- Add unit tests covering standard video and audio fixtures, including disabled tracks and zero-duration edge cases.

## 🔧 Implementation Notes

- Reuse `FullBoxReader` to handle version/flags extraction before parsing payload fields.
- Reference the `mvhd` parser for fixed-point math helpers to maintain consistent scaling for rate, volume, and matrix elements.
- Extend `BoxParserRegistry` with a `tkhd` entry that wires parsed values into the detail view models and JSON export structures.
- Coordinate with forthcoming `stsz/stz2` and `stco/co64` tasks to ensure shared validation utilities cover track-level metadata.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
