# PDD:1h Provide UIDocumentPicker Integration for iOS/iPadOS

## 🎯 Objective

Ship a FilesystemAccessKit adapter that presents `UIDocumentPickerViewController` on iOS and iPadOS so sandboxed builds can open and save files using the shared `FilesystemAccess` API without relying on macOS-only panels.

## 🧩 Context

- The FilesystemAccessKit PRD requires platform-specific pickers that expose a unified API across macOS and iOS
  families.【F:DOCS/AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md†L12-L36】
- `FilesystemAccess.live()` currently contains `@todo` placeholders for the UIKit path and only wires macOS `NSOpenPanel`/`NSSavePanel` implementations.【F:Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccess+Live.swift†L1-L84】
- Root backlog item `PDD:1h Provide UIDocumentPicker integration for iOS/iPadOS once UIKit adapters are introduced.` tracks this gap and is now marked in progress.【F:todo.md†L29-L33】

## ✅ Success Criteria

- A UIKit-backed adapter presents `UIDocumentPickerViewController` for open/save flows and delivers security-scoped URLs compatible with existing bookmark persistence.
- Shared async `FilesystemAccess` API chooses the UIKit adapter when running on iOS/iPadOS without regressing macOS behaviour.
- Unit or UI-level smoke coverage exercises the new adapter using dependency injection or targeted stubs to validate URL
  handling and sandbox scope lifetimes.
- Documentation in the FilesystemAccess PRD/workplan reflects the completed iOS integration.

## 🔧 Implementation Notes

- Leverage Swift concurrency continuations (or Combine bridges) to await picker completion inside `FilesystemAccess.live()` while ensuring calls run on the main actor.
- Provide injectable presenter hooks so SwiftUI scenes or controllers can trigger the picker without direct UIKit
  coupling in call sites.
- Coordinate with bookmark persistence stores to start/stop security-scoped resource access when the adapter resolves
  returned URLs.
- Update existing tests or add new ones under `FilesystemAccess` or app targets to capture regression coverage for the UIKit path.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md`](../AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md)
- [`DOCS/TASK_ARCHIVE/69_G1_FilesystemAccessKit_Core_API/Summary_of_Work.md`](../TASK_ARCHIVE/69_G1_FilesystemAccessKit_Core_API/Summary_of_Work.md)
