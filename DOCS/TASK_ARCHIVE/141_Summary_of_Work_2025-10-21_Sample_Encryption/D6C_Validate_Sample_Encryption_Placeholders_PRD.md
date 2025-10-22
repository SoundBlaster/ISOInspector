# D6.C — Validate & Document Sample Encryption Placeholder Coverage

## 🎯 Objective
Build regression coverage, fixtures, and documentation updates that demonstrate the new `senc`, `saio`, and `saiz` placeholder workflows behave correctly across kit, CLI, and app surfaces while communicating the capability to stakeholders.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L12-L23】

## 🧩 Context
- D6 requires unit and integration tests that exercise each placeholder box, confirming graceful handling of unsupported flags and malformed tables.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L15-L23】
- Existing export and CLI tests provide patterns for validating JSON parity and command output; these must be extended to cover encryption metadata scenarios.【F:Tests/ISOInspectorKitTests/ParseExportTests.swift†L75-L194】【F:Tests/ISOInspectorCLITests/ISOInspectorCLIScaffoldTests.swift†L29-L159】
- Documentation channels (DocC guides, release notes, in-progress tracker) should reflect the new visibility so cross-functional partners know encryption scaffolding is observable without decrypting samples.【F:Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md†L61-L118】【F:Distribution/ReleaseNotes/v0.1.0.md†L1-L36】【F:DOCS/INPROGRESS/next_tasks.md†L1-L5】

## 📦 Scope & Deliverables
- Create synthetic fragmented fixtures (e.g., minimal `moof`/`traf` sample) embedding `senc`, `saio`, and `saiz` tables with varied combinations (constant IVs, zero entries, duplicated boxes) for deterministic tests.
- Add ISOInspectorKit unit tests that parse the fixtures and assert emitted fields, detail structs, and validation issues align with expectations, including 64-bit offset warnings where applicable.【F:Tests/ISOInspectorKitTests/ParseExportTests.swift†L75-L194】
- Extend CLI integration tests to verify `export-json` output, console summaries, and failure handling when placeholders are absent or malformed, following existing runner harness patterns.【F:Tests/ISOInspectorCLITests/ISOInspectorCLIScaffoldTests.swift†L29-L159】
- Introduce SwiftUI regression coverage (snapshot or view-model tests) confirming the detail pane renders encryption metadata without crashing, leveraging document session export tests as references.【F:Tests/ISOInspectorAppTests/DocumentSessionControllerTests.swift†L353-L413】
- Update DocC onboarding guides, release notes, and `DOCS/INPROGRESS/next_tasks.md` to announce placeholder visibility and record remaining follow-ups (e.g., future decryption support).【F:Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md†L61-L118】【F:Distribution/ReleaseNotes/v0.1.0.md†L1-L36】【F:DOCS/INPROGRESS/next_tasks.md†L1-L5】

## ✅ Success Criteria
- Automated tests fail if placeholder parsing regresses (missing fields, incorrect counts, unexpected crashes), providing clear diagnostics for malformed fixtures.【F:Tests/ISOInspectorKitTests/ParseExportTests.swift†L75-L194】【F:Tests/ISOInspectorCLITests/ISOInspectorCLIScaffoldTests.swift†L29-L159】
- Accessibility and export workflows in the app continue to pass existing assertions while including encryption metadata in exported JSON snapshots.【F:Tests/ISOInspectorAppTests/DocumentSessionControllerTests.swift†L353-L413】
- Documentation updates land alongside code changes, and release notes highlight the new visibility so distribution artifacts communicate the enhancement to end users.【F:Distribution/ReleaseNotes/v0.1.0.md†L1-L36】

## 🔧 Implementation Notes
- Generate fixtures with helper builders or inline byte buffers to keep tests self-contained; prefer hex literals with comments describing table entries for readability.
- Use validation utilities to assert warnings rather than hard failures when encountering unsupported flag combinations, matching the graceful degradation goal from D6.A.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L21-L23】
- Document remaining edge cases (e.g., pattern encryption, `tenc` alignment) in `DOCS/INPROGRESS/next_tasks.md` to feed future backlog grooming.【F:DOCS/INPROGRESS/next_tasks.md†L1-L5】

## ⚠️ Risks & Mitigations
- **Fixture brittleness** — Synthetic streams can become stale; store generation scripts or annotated payload tables alongside tests to ease regeneration when specs change.【F:Tests/ISOInspectorKitTests/ParseExportTests.swift†L75-L194】
- **Documentation drift** — Without updates, stakeholders may overlook the new capability; include release note callouts and DocC guide revisions in the review checklist.【F:Distribution/ReleaseNotes/v0.1.0.md†L1-L36】【F:Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md†L61-L118】

## 🚫 Out of Scope
- Shipping full decryption workflows or DRM key management; coverage is limited to placeholder visibility tests.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L4-L23】
- Refreshing third-party fixture licensing (tracked separately in the real-world assets task).【F:DOCS/INPROGRESS/next_tasks.md†L1-L5】

## 🔍 Validation & QA
- Run `swift test` across kit, CLI, and app targets to ensure new fixtures integrate cleanly with CI and maintain deterministic output ordering.【F:Distribution/ReleaseNotes/v0.1.0.md†L17-L35】
- Perform manual QA on at least one encrypted fragment sample (if available) to confirm CLI/app behave as documented, capturing research logs when boxes include unexpected flags for future analysis.【F:DOCS/INPROGRESS/D6_Recognize_senc_saio_saiz_Placeholders.md†L20-L23】

## 📚 Source References
- [`D6 — Recognize Sample Encryption Placeholders`](./D6_Recognize_senc_saio_saiz_Placeholders.md)
- [`ParseExportTests.swift`](../Tests/ISOInspectorKitTests/ParseExportTests.swift)
- [`ISOInspectorCLIScaffoldTests.swift`](../Tests/ISOInspectorCLITests/ISOInspectorCLIScaffoldTests.swift)
- [`DocumentSessionControllerTests.swift`](../Tests/ISOInspectorAppTests/DocumentSessionControllerTests.swift)
- [`DeveloperOnboarding.md`](../Documentation/ISOInspector.docc/Guides/DeveloperOnboarding.md)
- [`Distribution Release Notes`](../Distribution/ReleaseNotes/v0.1.0.md)
- [`next_tasks.md`](./next_tasks.md)
