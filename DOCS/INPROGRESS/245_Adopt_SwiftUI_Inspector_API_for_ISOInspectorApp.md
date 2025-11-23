# Task 245 – Adopt SwiftUI `.inspector` API for ISOInspectorApp

## 🎯 Objective
Replace the custom inspector column plumbing with the native SwiftUI `.inspector` API on macOS, so the inspector behaves like the platform demo: a system-managed pane that can be shown/hidden independently of the main NavigationSplitView (sidebar + content), eliminating nested split views and layout insets.

## 🧩 Context
- Current state (Task 243/244): A single `NavigationSplitView` hosts sidebar/content/inspector. We’ve removed nested split views, but padding/inset issues persist and the inspector still feels “framed” under the toolbar. Selection/Integrity toggles are wired via custom visibility state instead of the platform inspector experience.
- SwiftUI’s `.inspector(isPresented:)` provides a native inspector pane on macOS that avoids layout fights and aligns with the NavigationSplitViewKit demo behavior.
- Goal: Use `.inspector` to host `InspectorDetailView` while keeping the main split for sidebar + content only. The inspector becomes system-managed, and visibility toggles become simple bindings.

## ✅ Success Criteria
- macOS: `NavigationSplitView` contains only sidebar (recents) and content (box tree + filters); inspector is shown via `.inspector(isPresented:)`.
- Inspector content is always `InspectorDetailView` (Selection Details / Integrity), not embedded in the main split columns.
- Toggling inspector visibility uses a single `@State showInspector` bound to `.inspector`; ⌘⌥I toggles it.
- Selecting a box sets `displayMode = .selectionDetails` and does not hide the inspector.
- Integrity/Details toggle switches content inside the inspector without affecting sidebar/content columns.
- Layout parity: no extra frame/inset under the toolbar; columns align like the SwiftUI demo.
- iPad/iPhone: fallback to existing behavior (inspector hidden or alternate UI) without breaking builds.
- Build and basic navigation remain green on macOS.

## 🔧 Implementation Notes
- Apply `.inspector(isPresented:) { InspectorDetailView(...) }` at the AppShell level (macOS only). Keep the main `NavigationSplitView` to two columns (sidebar/content) on macOS; iOS/iPadOS can continue using the existing three-column arrangement if desired.
- State: `@State private var showInspector = true` (macOS); bind ⌘⌥I to toggle it. Keep `displayMode` for integrity/details selection within the inspector.
- Selection handling: on node select, set `displayMode = .selectionDetails`; do not change `showInspector` (only ensure it’s true if we want auto-show).
- Remove `InspectorColumnVisibility` usage on macOS when `.inspector` is active; retain for platforms without `.inspector` if needed.
- Update previews to include `.inspector` usage on macOS.
- Keep accessibility identifiers on inspector content; ensure toggles and keyboard shortcuts still work.

## 🧠 Source References
- [`DOCS/COMMANDS/SELECT_NEXT.md`](../COMMANDS/SELECT_NEXT.md)
- [`DOCS/RULES/02_TDD_XP_Workflow.md`](../RULES/02_TDD_XP_Workflow.md)
- [`DOCS/RULES/04_PDD.md`](../RULES/04_PDD.md)
- [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/INPROGRESS/243_Reorganize_Navigation_SplitView_Inspector_Panel.md`](243_Reorganize_Navigation_SplitView_Inspector_Panel.md)
- [`DOCS/INPROGRESS/244_NavigationSplitView_Parity_With_Demo.md`](244_NavigationSplitView_Parity_With_Demo.md)
