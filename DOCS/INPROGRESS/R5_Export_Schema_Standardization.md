# R5 — Export Schema Standardization

## 🎯 Objective
Define an export schema recommendation so ISOInspector's JSON and report outputs align with widely used MP4 inspection tools while preserving round-trip fidelity requirements.

## 🧩 Context
- Functional requirement **FR-CORE-004** mandates JSON and binary export capabilities with re-import verification, making schema alignment critical for interoperability. 
- The research backlog lists **R5** to compare Bento4, ffprobe, and similar report formats, aiming to map their fields onto ISOInspector exports. 
- Master PRD deliverables include export support within ISOInspectorCore, ensuring research outcomes stay tied to core product goals.

## ✅ Success Criteria
- Document a comparative analysis of at least Bento4 `mp4dump --format json`, FFmpeg/ffprobe, and any other relevant schema, highlighting coverage gaps and incompatible structures.
- Recommend a canonical ISOInspector export schema (or adaptations) with explicit field mappings and conversion notes for existing exporters.
- Identify verification steps needed so future automated tests can validate exports against the chosen schema.

## 🔧 Implementation Notes
- Gather representative export samples from Bento4, ffprobe, and other reference tools to catalog field naming, typing, and nesting conventions.
- Compare samples against current ISOInspector JSON output to note missing metadata, divergent typing, or naming mismatches.
- Propose schema updates or adapters that satisfy FR-CORE-004 while minimizing breaking changes to existing CLI/UI workflows.
- Outline follow-up engineering tasks (if any) required to implement the recommended schema changes and associated regression tests.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`05_Research_Gaps.md`](../AI/ISOInspector_Execution_Guide/05_Research_Gaps.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)

## 📦 Samples Collected
- Bento4 `mp4dump --format json` export for `video-h264-001.mp4`, capturing raw box hierarchy output from the official SDK binary.【F:DOCS/INPROGRESS/R5_mp4dump_video-h264-001.json†L1-L40】
- ISOInspector snapshot fixture (`baseline-sample.json`) representing the current `JSONParseTreeExporter` payload for the same asset class.【F:Tests/ISOInspectorKitTests/Fixtures/Snapshots/baseline-sample.json†L1-L95】
- FFmpeg `ffprobe -of json -show_format -show_streams` export for `video-h264-001.mp4`, providing stream-centric metadata and container summary fields.【F:DOCS/INPROGRESS/R5_ffprobe_video-h264-001.json†L1-L136】

## 🔍 Schema Comparison
### Bento4 `mp4dump --format json`
Bento4 emits a flat array of boxes, each with `name`, `header_size`, and `size` plus optional fields appended directly to the object. Repeated structures such as `compatible_brand` appear as duplicated keys instead of arrays, and child boxes are only visible when a parent box adds a nested `children` array.【F:DOCS/INPROGRESS/R5_mp4dump_video-h264-001.json†L1-L40】 This layout is easy to diff against raw atom tables but lacks explicit offsets or payload typing.

### ISOInspector JSON exporter
ISOInspector wraps results in a top-level object with a `nodes` array. Each node carries `fourcc`, byte `offsets`, `sizes`, descriptive `metadata`, optional `payload` field descriptors with byte ranges, and an optional `structured` view that normalizes well-known box semantics.【F:Tests/ISOInspectorKitTests/Fixtures/Snapshots/baseline-sample.json†L1-L95】 The implementation constructs these objects via `JSONParseTreeExporter`, which also records validation issues and metadata for downstream consumers.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L3-L172】

### FFmpeg `ffprobe -of json`
`ffprobe` exposes a container-centric object with top-level `streams` (per elementary stream) and `format` metadata summarizing duration, bitrate, brands, and encoder.【F:DOCS/INPROGRESS/R5_ffprobe_video-h264-001.json†L1-L136】 It omits explicit MP4 box hierarchy but provides codec, timing, and tagging data that operators commonly diff across files.

## ⚖️ Coverage Gaps & Incompatibilities
- Bento4 lacks byte offsets and differentiates repeated values by repeating the same key, which makes correlation with ISOInspector’s indexed `compatible_brand[n]` entries lossy unless we provide aliases or flatten our arrays for compatibility exports.【F:DOCS/INPROGRESS/R5_mp4dump_video-h264-001.json†L1-L35】【F:Tests/ISOInspectorKitTests/Fixtures/Snapshots/baseline-sample.json†L19-L74】
- ffprobe surfaces format-level aggregates (duration, bitrate, encoder, stream dispositions) that ISOInspector currently omits from its export, making it harder to compare high-level container traits without inspecting every box payload manually.【F:DOCS/INPROGRESS/R5_ffprobe_video-h264-001.json†L23-L135】
- ISOInspector’s rich `metadata`, `structured`, and validation fields have no equivalents in Bento4 or ffprobe, so consumers expecting concise, schema-stable keys must bridge these nested structures manually.【F:Tests/ISOInspectorKitTests/Fixtures/Snapshots/baseline-sample.json†L7-L95】

## 🧭 Recommended Canonical Schema
1. **Dual-view node records.** Continue emitting ISOInspector’s detailed node objects but add optional compatibility aliases (`name`, `header_size`, `size`) alongside `fourcc`, `offsets`, and `sizes` so Bento4 consumers can map fields without transforming arrays.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L34-L88】【F:DOCS/INPROGRESS/R5_mp4dump_video-h264-001.json†L1-L40】
2. **Format summary block.** Introduce an optional top-level `format` section mirroring ffprobe’s key metrics (filename, duration, bitrate, brands, encoder) sourced from the parsed `ftyp`, `mvhd`, and stream headers so operators can diff high-level properties quickly.【F:DOCS/INPROGRESS/R5_ffprobe_video-h264-001.json†L119-L135】【F:Tests/ISOInspectorKitTests/Fixtures/Snapshots/baseline-sample.json†L7-L95】
3. **Schema descriptor manifest.** Publish a machine-readable schema version (e.g., `schema.version`, `schema.compatibility = ["bento4", "ffprobe"]`) and include a per-node `type` hint describing whether payload data is raw, structured, or validation-only to aid downstream adapters.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L18-L61】
4. **Adapter guides.** Document deterministic mappings—for example, mapping `structured.file_type.compatible_brands` back to Bento4’s repeated `compatible_brand` entries and deriving ffprobe-style stream dispositions from track header boxes—so CLI and UI layers can export alternate views without duplicating parsing logic.【F:Tests/ISOInspectorKitTests/Fixtures/Snapshots/baseline-sample.json†L80-L107】【F:DOCS/INPROGRESS/R5_mp4dump_video-h264-001.json†L1-L40】

## ✅ Verification Steps
- Extend `JSONExportSnapshotTests` with new fixtures that exercise the compatibility aliases and format summary, keeping snapshot regeneration workflows intact for schema upgrades.【F:Tests/ISOInspectorKitTests/JSONExportSnapshotTests.swift†L5-L132】
- Add CLI integration tests (e.g., `swift test --filter JSONExportSnapshotTests`) that compare exported JSON against stored Bento4 and ffprobe fixtures to ensure adapters produce byte-for-byte compatible payloads for common assets.【F:DOCS/INPROGRESS/R5_mp4dump_video-h264-001.json†L1-L40】【F:DOCS/INPROGRESS/R5_ffprobe_video-h264-001.json†L1-L136】
- Gate schema changes behind a documented version bump in the export payload so downstream tooling can negotiate compatibility explicitly before consuming new fields.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L18-L61】
