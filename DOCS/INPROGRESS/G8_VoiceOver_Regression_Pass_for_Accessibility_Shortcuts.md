# G8 — VoiceOver Regression Pass for Accessibility Shortcuts

## 🎯 Objective

Validate on real macOS and iPadOS hardware that the refreshed Focus command menu and shared keyboard shortcuts from Task G8 announce the correct destinations, transfer VoiceOver focus to the expected pane, and restore the previously selected node without pointer input.

## 🧩 Context

- Task G8 unified hardware focus shortcuts and introduced the Focus command menu, with this regression pass called out as the remaining follow-up to confirm VoiceOver behaviour on physical devices.
- The Accessibility Guidelines specify how VoiceOver, focus bindings, and keyboard commands must behave across the tree, detail, notes, and hex panes, and list the automated tests that guard identifier and formatter stability.
- Accessibility research captured in `DOCS/TASK_ARCHIVE/91_R3_Accessibility_Guidelines/` reinforces manual VoiceOver QA expectations for discoverability strings, rotor ordering, and shortcut hints.

## ✅ Success Criteria

- On macOS, enabling VoiceOver and invoking each Focus command (`⌘⌥1` through `⌘⌥4`) announces the pane name from `InspectorFocusShortcutCatalog`, shifts focus into the correct SwiftUI scope, and reselects the previous node when applicable.
- On iPadOS with a hardware keyboard, the discoverability HUD and `commands` menu expose the same shortcuts, VoiceOver announces the menu titles, and focus switches among outline, detail, notes, and hex panes without pointer interaction.
- Manual VoiceOver navigation within each pane (arrow keys in the outline, metadata traversal in the detail view, byte stepping in the hex view) retains accessibility identifiers and announcements that match the formatter expectations documented in the guidelines.
- QA notes summarizing the macOS and iPadOS runs, including any issues or screenshots, are archived alongside Task G8 once testing concludes.

## 🔧 Implementation Notes

- Use the `Focus` menu or associated shortcuts to cycle panes while VoiceOver is active; confirm the `.focused` bindings in `ParseTreeOutlineView` and `ParseTreeDetailView` update as expected when the scene value changes.
- Exercise VoiceOver rotor categories and keyboard navigation within each pane to verify `AccessibilitySupport` descriptors, `HexByteAccessibilityFormatter`, and `NestedA11yIDs` identifiers continue to drive accurate announcements.
- If discrepancies appear, update the relevant accessibility helpers, corresponding XCTest coverage, and DocC guideline sections before finalizing the regression report.
- Record detailed findings (pass/fail, OS versions, device models) and attach them to the Task G8 archive so future iterations know the coverage baseline.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`AccessibilityGuidelines.md`](../../Documentation/ISOInspector.docc/Guides/AccessibilityGuidelines.md)
- [`DOCS/TASK_ARCHIVE/155_G8_Accessibility_and_Keyboard_Shortcuts/`](../TASK_ARCHIVE/155_G8_Accessibility_and_Keyboard_Shortcuts)
- [`DOCS/TASK_ARCHIVE/91_R3_Accessibility_Guidelines/`](../TASK_ARCHIVE/91_R3_Accessibility_Guidelines)

## 🚧 Status — 2025-10-23

- VoiceOver regression verification is **blocked** in the automated container environment because macOS and iPadOS hardware with VoiceOver are unavailable.
- Automated coverage remains green (`swift test`) to ensure `InspectorFocusShortcutCatalog` strings stay synchronized for future manual QA.
- Next manual step: execute the shortcuts regression pass on physical macOS (14+) and iPadOS (17+) devices, capture announcements, and archive the QA notes alongside Task G8.
