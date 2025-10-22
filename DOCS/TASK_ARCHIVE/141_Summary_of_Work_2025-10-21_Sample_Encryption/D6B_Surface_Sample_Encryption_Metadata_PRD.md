# D6.B — Surface Sample Encryption Metadata Across Outputs

## 🎯 Objective
Propagate the placeholder metadata emitted by the new `senc`, `saio`, and `saiz` parsers through kit models, JSON exports, CLI formatting, and SwiftUI detail panes so users can see encryption scaffolding without decrypting payloads.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L12-L16】

## 🧩 Context
- D6’s success criteria require `ParsedBoxPayload` instances to expose byte ranges and summary fields that downstream consumers can render.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L12-L16】
- `JSONParseTreeExporter` encodes payload fields and structured details into persisted JSON, which powers CLI exports and UI replay flows; new metadata must map cleanly into this schema.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L3-L128】
- CLI streaming output (`EventConsoleFormatter`) and the SwiftUI detail pane derive descriptions from `ParseTreeNode` payloads, so additional summary text and annotations are needed to highlight encryption presence.【F:Sources/ISOInspectorCLI/EventConsoleFormatter.swift†L7-L169】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L42-L176】

## 📦 Scope & Deliverables
- Extend `ParsedBoxPayload.Detail` with lightweight structures for sample encryption placeholders (e.g., `SampleEncryptionBox`, `SampleAuxInfoOffsetsBox`, `SampleAuxInfoSizesBox`) capturing counts, IV sizing, and referenced offsets.【F:Sources/ISOInspectorKit/ISO/ParsedBoxPayload.swift†L3-L31】
- Populate the new detail cases and supporting `Field` entries from the D6.A parser outputs, ensuring field names align with existing protection metadata conventions (`entries[...].encryption.*`).【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L10-L22】
- Update `JSONParseTreeExporter` encoders to include the new detail payloads and any additional scalar fields so exported trees mirror CLI/UI summaries.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L28-L170】
- Teach `EventConsoleFormatter` to append concise encryption summaries (entry counts, IV sizes, aux-info offsets) and update SwiftUI detail renderers to surface the new fields with accessible labels.【F:Sources/ISOInspectorCLI/EventConsoleFormatter.swift†L42-L168】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L42-L176】

## ✅ Success Criteria
- Exported JSON contains new structured nodes for `senc`, `saio`, and `saiz`, including counts and byte ranges, and existing snapshot tests are updated accordingly.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L28-L170】
- CLI streaming output indicates when encryption metadata is present (e.g., `encryption entries=... iv_size=...`), and SwiftUI detail panes list the same information alongside validation issues without regressions to existing layouts.【F:Sources/ISOInspectorCLI/EventConsoleFormatter.swift†L42-L168】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L42-L176】
- No raw encrypted payload bytes are persisted; only metadata and ranges are surfaced, maintaining alignment with product security requirements.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L4-L23】

## 🔧 Implementation Notes
- Reuse existing naming patterns for field keys (e.g., `entries[x].encryption.*`) from the sample description protection helpers so analytics and UI code paths remain compatible.【F:Sources/ISOInspectorKit/ISO/BoxParserRegistry+SampleDescriptionProtection.swift†L1-L120】
- When extending `JSONParseTreeExporter`, prefer optional encoding (omit keys when tables are empty) to avoid bloating diff noise for fragments lacking encryption placeholders.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L28-L128】
- Add localized string resources or reuse existing label helpers for SwiftUI to keep accessibility announcements concise when describing encryption metadata.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L86-L176】

## ⚠️ Risks & Mitigations
- **Schema drift** — Updating JSON payloads can break downstream automation; gate changes behind versioned snapshots and document the schema additions in release notes before shipping.【F:Tests/ISOInspectorKitTests/ParseExportTests.swift†L75-L194】
- **Console noise** — Excessive CLI summary text can overwhelm users; provide terse summaries by default and reuse verbosity toggles if detailed listings are required.【F:Sources/ISOInspectorCLI/EventConsoleFormatter.swift†L42-L168】

## 🚫 Out of Scope
- Visual redesigns of the SwiftUI detail panes beyond adding the required metadata rows.
- Streaming decryption workflows or key management UIs; placeholders only expose structural metadata.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L4-L23】

## 🔍 Validation & QA
- Refresh JSON export snapshot tests and CLI golden outputs to capture the new fields, ensuring deterministic ordering (`.sortedKeys`) keeps diffs stable.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L3-L40】【F:Tests/ISOInspectorKitTests/ParseExportTests.swift†L75-L194】
- Run manual accessibility checks in the SwiftUI app to verify new encryption metadata is reachable via VoiceOver and includes descriptive labels, following the onboarding checklist guidance.【F:Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md†L61-L118】

## 📚 Source References
- [`D6 — Recognize Sample Encryption Placeholders`](./D6_Recognize_senc_saio_saiz_Placeholders.md)
- [`ParsedBoxPayload.swift`](../Sources/ISOInspectorKit/ISO/ParsedBoxPayload.swift)
- [`JSONParseTreeExporter.swift`](../Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift)
- [`EventConsoleFormatter.swift`](../Sources/ISOInspectorCLI/EventConsoleFormatter.swift)
- [`ParseTreeDetailView.swift`](../Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift)
- [`ParseExportTests.swift`](../Tests/ISOInspectorKitTests/ParseExportTests.swift)
- [`DeveloperOnboarding.md`](../Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md)
