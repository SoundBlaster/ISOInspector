# G8 — Accessibility & Keyboard Shortcuts

## 🎯 Objective
Ensure ISOInspector delivers consistent hardware keyboard navigation and accessibility focus management across macOS and iPadOS so tree, detail, notes, and hex panes remain operable without pointer input and adhere to the published accessibility guidelines.

## 🧩 Context
- `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md` tracks Phase G follow-ups for FilesystemAccessKit and UI polish; this task extends the phase with explicit accessibility coverage.
- `Documentation/ISOInspector.docc/Guides/AccessibilityGuidelines.md` documents required VoiceOver, Dynamic Type, and keyboard affordances for the outline, detail, and hex surfaces.
- Existing focus routing relies on `InspectorFocusTarget` bindings inside `ParseTreeOutlineView` and `ParseTreeDetailView` to coordinate selection, keyboard shortcuts, and accessibility identifiers.
- R3 accessibility research (`DOCS/TASK_ARCHIVE/91_R3_Accessibility_Guidelines/Summary_of_Work.md`) lists VoiceOver and keyboard verification practices that should be repeated when expanding shortcut coverage.

## ✅ Success Criteria
- Hardware shortcuts (`⌘⌥1`–`⌘⌥4` on macOS; discoverable key commands on iPadOS) shift focus between outline, detail, notes, and hex panes and restore the prior selection where available.
- Arrow key and move-command handling in the outline, detail, and hex panes maintains focus scopes while VoiceOver announces the active element using the descriptors from `AccessibilitySupport`.
- Keyboard shortcuts and focus flows are documented in the Accessibility Guidelines and, where applicable, surfaced in user-facing help or menu command titles.
- Automated coverage (e.g., `ParseTreeAccessibilityIdentifierTests`, `ParseTreeAccessibilityFormatterTests`) reflects any new identifiers or descriptors introduced during shortcut work.

## 🔧 Implementation Notes
- Review `ParseTreeOutlineView` and `ParseTreeDetailView` focus management to ensure `.focused` bindings update consistently when commands trigger pane switches, including iPadOS compatibility via `compatibilityFocusable()` helpers.
- Add or refine key command registration so iPad hardware keyboards expose the same focus commands as macOS, using hidden `Button.keyboardShortcut` registrations or platform-specific `commands` modifiers as needed.
- Update `AccessibilitySupport` helpers and related tests if new labels or hints are required for shortcut discoverability or VoiceOver announcements.
- Refresh documentation (`AccessibilityGuidelines.md`, DocC tutorials, or release notes) to describe the finalized shortcut map and accessibility expectations.
- Capture verification notes (manual QA runs, Accessibility Inspector findings) for the task archive once testing completes.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`AccessibilityGuidelines.md`](../../Documentation/ISOInspector.docc/Guides/AccessibilityGuidelines.md)
- [`ParseTreeOutlineView.swift`](../../Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift)
- [`ParseTreeDetailView.swift`](../../Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift)
- [`AccessibilitySupport.swift`](../../Sources/ISOInspectorApp/Accessibility/AccessibilitySupport.swift)
- [`ParseTreeAccessibilityIdentifierTests.swift`](../../Tests/ISOInspectorAppTests/ParseTreeAccessibilityIdentifierTests.swift)
- [`ParseTreeAccessibilityFormatterTests.swift`](../../Tests/ISOInspectorAppTests/ParseTreeAccessibilityFormatterTests.swift)
- [`DOCS/TASK_ARCHIVE/91_R3_Accessibility_Guidelines/Summary_of_Work.md`](../TASK_ARCHIVE/91_R3_Accessibility_Guidelines/Summary_of_Work.md)
