# D6 — Recognize Sample Encryption Placeholders

## 🎯 Objective
Implement stub-level parsing for the sample encryption support boxes (`senc`, `saio`, `saiz`) so fragment workflows expose their byte ranges and counts without attempting to decrypt protected payloads.

## 🧩 Context
- The detailed backlog calls for capturing sizes and offsets for these Common Encryption helper boxes to round out the fragment parser surface.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L218-L221】
- Product requirements emphasise recording the presence of encrypted payload structures without decoding their contents, keeping security goals intact while informing users that protection exists.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L52-L64】
- Existing fragment parsers already emit structured payload metadata for `moof`, `tfhd`, and related boxes, providing a natural extension point for additional child handlers.【F:Sources/ISOInspectorKit/ISO/BoxParserRegistry+MovieFragments.swift†L1-L84】
- Sample entry protection metadata is summarised today via helper routines in the registry; placeholder parsing should align with those conventions so downstream UI/CLI surfaces remain consistent.【F:Sources/ISOInspectorKit/ISO/BoxParserRegistry+SampleDescriptionProtection.swift†L1-L60】

## ✅ Success Criteria
- `BoxParserRegistry` registers dedicated handlers for `senc`, `saio`, and `saiz` that read version/flag headers (where applicable) and emit summary fields such as entry counts, default IV sizes, and referenced offsets.
- `ParsedBoxPayload` instances capture the byte ranges for each structure so JSON export, CLI reports, and SwiftUI detail panes can highlight where encryption metadata lives.
- Unit tests cover synthetic fragment fixtures exercising each box type, validating parsed field values and ensuring unknown/unsupported flag combinations degrade gracefully with informational validation issues rather than crashes.
- Documentation and changelog entries mention the new coverage so stakeholders know encrypted sample scaffolding is now visible even without decryption capabilities.

## 🔧 Implementation Notes
- Extend `BoxParserRegistry.DefaultParsers` in `BoxParserRegistry+MovieFragments.swift` to include parser functions for `senc`, `saio`, and `saiz`, wiring them into the registry so they populate `ParsedBoxPayload.Field` entries with offsets, counts, and IV sizing hints.【F:Sources/ISOInspectorKit/ISO/BoxParserRegistry+MovieFragments.swift†L1-L84】
- Use `FullBoxReader` for `senc` to extract version/flags, paying attention to optional constant IV sections before iterating sample records; stub out per-sample payloads by recording counts and sizes rather than storing raw encryption data.
- For `saio`/`saiz`, prefer 32-bit entry arrays initially and gate 64-bit offsets via feature flags or warnings until fixtures exist; surface aggregate totals so validators/UI can warn when offsets fall outside their parent payload range.
- Ensure JSON export and CLI formatting include the new metadata fields without exposing raw encrypted bytes, mirroring how protected sample entries already summarise scheme information.
- Add regression tests in the CLI and kit layers to assert parsing resilience when the boxes are absent, duplicated, or contain zero-entry tables, matching Common Encryption edge cases documented in MP4RA fixtures.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
