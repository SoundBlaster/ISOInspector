# C6 — `stsd` Sample Description Parser

## 🎯 Objective

Implement parsing support for the `stsd` (Sample Description) box so the pipeline can enumerate media sample entries, classify audio versus visual codecs, and expose structured metadata for downstream validation and UI layers.

## 🧩 Context

- The master PRD calls for extracting detailed sample table metadata, including `stsd` contents, to power validation and navigation experiences in both CLI and UI frontends. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L23-L75】
- Phase C of the backlog flags parser coverage for `stsd` as a P0 follow-up after the header decoders and initial metadata integrations landed. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L189-L204】

## ✅ Success Criteria

- `BoxParserRegistry` registers a parser for `stsd`, returning a `ParsedBoxPayload` that surfaces `entry_count` plus a collection of parsed sample entries. 【F:Sources/ISOInspectorKit/ISO/BoxParserRegistry.swift†L1-L120】【F:Sources/ISOInspectorKit/ISO/ParsedBoxPayload.swift†L1-L120】
- Each sample entry records its format (`fourcc`), size, and critical header fields (e.g., width/height for visual, channel/sample rate for audio).
- Unit tests feed representative audio and visual fixtures to ensure parsed entries align with ISO/IEC 14496-12

  structure.

- Exporters and UI components can render the parsed metadata without additional manual decoding.

## 🔧 Implementation Notes

- Reuse the existing `FullBoxReader` helpers for version/flags to simplify parsing and maintain consistent byte range accounting. 【F:Sources/ISOInspectorKit/ISO/FullBoxReader.swift†L1-L160】
- Leverage the streaming tree builders to attach parsed entry data to `ParseTreeNode` instances so validation and export layers consume a uniform structure. 【F:Sources/ISOInspectorKit/Export/ParseTreeNode.swift†L1-L32】
- Start with baseline support for ISO base media sample entries (`mp4a`, `avc1`, `hvc1`, `hev1`) and design extensible decoding to add codecs iteratively.
- Ensure byte range calculations guard against malformed lengths, matching the validation expectations outlined in the

  existing structural rules. 【F:Sources/ISOInspectorKit/Validation/BoxValidator.swift†L1-L220】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
