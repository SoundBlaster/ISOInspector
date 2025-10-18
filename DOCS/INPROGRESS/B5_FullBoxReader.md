# B5 — FullBoxReader Utility

## 🎯 Objective

Introduce a reusable helper that extracts the common `(version, flags)` header shared by ISO Base Media File Format "full boxes" so downstream parsers can focus on box-specific payload fields instead of repeating boilerplate bit parsing.

## 🧩 Context

- Phase B of the execution plan calls for foundational parser utilities once the streaming pipeline is stable; the detailed backlog lists **B5. Introduce `FullBoxReader` for (version,flags) extraction.**
- Recent default parsers (`ftyp`, `mvhd`, `tkhd`) decode the header bytes manually inside `BoxParserRegistry.swift`, highlighting duplication that the helper should eliminate.
- Validation rules VR-001–VR-006 already ensure structural integrity, so this task can rely on existing header ranges reported by `BoxHeader` and the `RandomAccessReader` protocol delivered in Task B1.

## ✅ Success Criteria

- A `FullBoxReader` (or similarly named) type lives in `ISOInspectorKit`, exposes validated `version` and `flags` values, and handles both truncated and complete payload ranges gracefully.
- Unit tests cover version/flag decoding for representative fixtures, including short reads and large payloads.
- Existing parsers that currently hand-roll version/flags extraction (`mvhd`, `tkhd`, and upcoming timeline boxes) adopt the helper without regressing current test coverage.
- Documentation sources (`next_tasks.md`, execution workplan/backlog) reflect Task B5 as in progress until code lands.

## 🔧 Implementation Notes

- Reuse the `RandomAccessReader` protocol utilities (e.g., `read(at:count:)`, endian helpers) to keep the helper pure and testable.
- Consider returning a lightweight struct (e.g., `FullBoxHeader`) that encapsulates decoded values plus the payload offset where box-specific fields begin.
- Ensure error reporting aligns with existing parsing errors (`IOError`, `BoundsError`, `OverflowError`) so callers can surface consistent diagnostics.
- Update `BoxParserRegistry.DefaultParsers` to call the helper and stage future parser registrations (e.g., `mdhd`, `hdlr`) on top of it.
- Run `scripts/fix_markdown.py` after editing documentation, per repository guidelines.

## 🧠 Source References

- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`BoxParserRegistry.swift`](../../Sources/ISOInspectorKit/ISO/BoxParserRegistry.swift)
