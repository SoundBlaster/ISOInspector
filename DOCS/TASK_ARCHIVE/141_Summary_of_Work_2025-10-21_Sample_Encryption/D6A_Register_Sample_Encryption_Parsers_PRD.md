# D6.A — Register Sample Encryption Box Parsers

## 🎯 Objective
Introduce dedicated stub-level parsers for the `senc`, `saio`, and `saiz` Common Encryption helper boxes so fragment workflows capture version headers, entry counts, and byte ranges without touching protected payloads.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L4-L14】

## 🧩 Context
- The D6 backlog item requires rounding out fragment parsing coverage with placeholder metadata for these boxes, ensuring offsets and sizes are visible to downstream tools.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L7-L14】
- `BoxParserRegistry.DefaultParsers` already exposes fragment box hooks (`mfhd`, `tfhd`, etc.), offering a natural location to register new handlers that mirror existing field emission patterns.【F:Sources/ISOInspectorKit/ISO/BoxParserRegistry+MovieFragments.swift†L3-L151】
- Sample description protection helpers rely on consistent field naming (`entries[...].encryption.*`), so placeholder parsers must align with those conventions to avoid UI/CLI regressions.【F:Sources/ISOInspectorKit/ISO/BoxParserRegistry+SampleDescriptionProtection.swift†L1-L120】

## 📦 Scope & Deliverables
- Add parser functions `sampleEncryption`, `sampleAuxInfoOffsets`, and `sampleAuxInfoSizes` under `BoxParserRegistry.DefaultParsers` that consume `BoxHeader` input, read `FullBox` metadata as needed, and return populated `ParsedBoxPayload` instances.
- Record aggregated counts (`sample_count`, `entry_count`), IV sizing, and referenced byte ranges for each structure so downstream exporters can surface the metadata without iterating individual encrypted samples.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L12-L21】
- Wire the new handlers into the fragment registry so `traf` traversal automatically invokes them when the boxes appear, matching how `tfhd` and related parsers are registered today.【F:Sources/ISOInspectorKit/ISO/BoxParserRegistry+MovieFragments.swift†L3-L151】

## ✅ Success Criteria
- `ParsedBoxPayload` objects emitted from the new handlers include version/flags (where applicable), IV size hints, table lengths, and byte ranges for the box content and auxiliary tables.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L12-L21】
- Registry lookups resolve the new parser identifiers so streaming parses of fragmented files capture placeholder metadata without throwing or skipping nodes.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L13-L21】【F:Sources/ISOInspectorKit/ISO/BoxParserRegistry+MovieFragments.swift†L3-L151】

## 🔧 Implementation Notes
- Follow the `FullBoxReader` pattern used by `movieFragmentHeader` and `trackFragmentHeader` to pull version/flag fields before processing the payload cursor, reusing helpers like `readUInt32` and `readUInt64` for table entries.【F:Sources/ISOInspectorKit/ISO/BoxParserRegistry+MovieFragments.swift†L9-L151】
- For `senc`, detect and skip constant IV sections while recording their length; per-sample entries should be summarised via counts rather than storing encrypted vectors.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L19-L21】
- Default to 32-bit `saio` offsets and `saiz` lengths, emitting validation warnings or notes when 64-bit flag combinations appear so future work can promote support once fixtures exist.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L21-L23】

## ⚠️ Risks & Mitigations
- **Incorrect table bounds** — Guard each read with payload range checks and return informational validation issues if entries exceed the box payload to avoid crashes during malformed inputs.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L21-L23】
- **Registry regressions** — Mirror existing registration tests for fragment handlers so new parser wiring does not shadow or override current implementations.【F:Sources/ISOInspectorKit/ISO/BoxParserRegistry+MovieFragments.swift†L3-L151】

## 🚫 Out of Scope
- Decrypting `senc` sample data or emitting per-sample key/IV payloads; the task only covers metadata stubs.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L4-L22】
- Updating downstream exporters or UI surfaces beyond ensuring the parser payload exposes the required summary fields (handled in D6.B).

## 🔍 Validation & QA
- Add focused parser unit tests under `Tests/ISOInspectorKitTests` that feed synthetic `senc`, `saio`, and `saiz` payloads through the registry and assert emitted field values and byte ranges follow expectations.【F:Tests/ISOInspectorKitTests/ParseExportTests.swift†L5-L143】
- Extend streaming integration tests to parse a fragmented fixture containing the placeholder boxes, verifying no crashes occur when tables are empty, duplicated, or contain out-of-range offsets.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L21-L23】

## 📚 Source References
- [`D6 — Recognize Sample Encryption Placeholders`](./D6_Recognize_senc_saio_saiz_Placeholders.md)
- [`BoxParserRegistry+MovieFragments.swift`](../Sources/ISOInspectorKit/ISO/BoxParserRegistry+MovieFragments.swift)
- [`BoxParserRegistry+SampleDescriptionProtection.swift`](../Sources/ISOInspectorKit/ISO/BoxParserRegistry+SampleDescriptionProtection.swift)
- [`ParseExportTests.swift`](../Tests/ISOInspectorKitTests/ParseExportTests.swift)
