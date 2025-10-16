# G3 — Expose CLI Sandbox Profile Guidance

## 🎯 Objective

Provide actionable CLI documentation that explains how to run ISOInspector headlessly with sandbox profiles, including the `--open`/`--authorize` automation path backed by FilesystemAccessKit.

## 🧩 Context

- Workplan task **G3** requires shipping sandbox profile guidance alongside the CLI entry points so automation owners

  can authorize file access without UI interactions.

- The FilesystemAccessKit PRD mandates that headless flows rely on security-scoped bookmarks and sandbox profile

  allowances rather than unsandboxed execution.

- CLI usage notes must align with existing app entitlements (`com.apple.security.files.user-selected.read-write`, `com.apple.security.files.bookmarks.*`) and the persisted bookmark flows delivered by Task G2.

## ✅ Success Criteria

- Guidance document describes required entitlements and shows a signed sandbox profile snippet granting `com.apple.security.files.user-selected.read-write` access for pre-approved paths.
- Instructions cover invoking the CLI with FilesystemAccessKit-aware flags (`--open`, `--authorize`) and how to supply pre-authorized bookmarks or security-scoped URLs.
- Runbook clarifies notarization or codesign prerequisites for distributing the sandbox profile to automation systems.
- Verification checklist enumerates how to confirm access works (e.g., running `swift test --disable-sandbox` locally, executing CLI against sample files) and references archival validation notes.

## 🔧 Implementation Notes

- Reuse entitlement configuration from `Distribution/Entitlements/` to ensure CLI documentation matches shipping profiles; highlight differences between macOS app sandboxing and headless automation.
- Reference FilesystemAccessKit APIs (`openFile`, `createBookmark`, `resolveBookmarkData`) so operators understand how CLI commands activate security-scoped bookmarks during execution.
- Include troubleshooting tips for bookmark expiry, revocation, and telemetry logging so automation runs remain

  auditable under zero-trust policies.

- Coordinate updates with existing backlog trackers (`next_tasks.md`, Workplan G3, PRD TODO J3) and archive references to avoid duplicate guidance in future tasks.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`09_FilesystemAccessKit_PRD.md`](../AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
