# G1 – Implement FilesystemAccessKit Core API

## 🎯 Objective
Deliver a unified FilesystemAccessKit surface that exposes async `openFile`, `saveFile`, `createBookmark`, and `resolveBookmarkData` operations for ISOInspector targets so sandboxed platforms can authorize, persist, and reopen user-selected files safely.

## 🧩 Context
- Phase G of the execution workplan elevates FilesystemAccessKit as the next high-priority dependency-free task, hinging only on the completed parser/UI integration from Task E2.
- The dedicated FilesystemAccessKit PRD defines the API surface, persistence expectations, and sandbox obligations that this task must implement across macOS, iOS, and iPadOS targets.
- Master PRD safeguards mandate security-scoped access and zero-trust logging, so the core module must integrate with existing diagnostics and persistence infrastructure.

## ✅ Success Criteria
- Async APIs return security-scoped URLs validated by unit tests covering bookmark creation, resolution, and failure recovery scenarios.
- Platform adapters bridge the shared API to `NSOpenPanel`/`NSSavePanel` on macOS and `UIDocumentPickerViewController` on iOS/iPadOS without regressing existing document commands.
- Bookmark data persists alongside recents/session stores with migration notes for integrating Phase G2 once defined.
- Logging and diagnostics redact absolute paths while capturing hashed identifiers so compliance requirements remain intact.

## 🔧 Implementation Notes
- Reuse entitlements and notarization artifacts from Task E4, verifying that sandbox profiles expose `com.apple.security.files.user-selected.read-write` and bookmark scopes before wiring new APIs.
- Model bookmark persistence in a dedicated store under Application Support with identifiers referenced by existing recents/session entities; note reconciliation hooks required for future G2 work.
- Provide CLI affordances or stubs that can accept pre-authorized paths, aligning with the sandbox profile guidance tracked in distribution follow-up tasks.
- Document access auditing and error surfaces so diagnostics align with the persistence logging already emitting recents/session failures.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md`](../AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
