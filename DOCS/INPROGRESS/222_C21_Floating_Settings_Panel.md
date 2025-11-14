# C21 — Floating Settings Panel Shell

## 🎯 Objective

Build a floating or modal user settings panel that consolidates preference management across macOS, iPadOS, and iOS platforms. The panel must clearly separate **permanent settings** (persisted across launches) from **session-scoped settings** (affect only the current document) while reusing FoundationUI components and honoring existing layered persistence architecture.

## 🧩 Context

- **Background:** ISOInspectorApp has validation presets in the macOS Settings scene (C19), but users cannot modify preferences without leaving the inspection canvas. Operator feedback requests a consolidated, floating surface accessible from anywhere in the app.
- **Relation to FoundationUI:** Phase 1 of FoundationUI integration is complete (I1.5 archived 2025-11-14). C21 will use Design System components (cards, badges, inspector patterns) to maintain consistency.
- **Architecture:** Two persistent layers:
  - **Permanent:** Stored in `Application Support/ISOInspector/UserPreferences.json` via `UserPreferencesStore`
  - **Session:** Stored in `DocumentSessionController` snapshots via `SessionSettingsPayload`
- **Related prior work:**
  - B7 — `ValidationConfiguration` layer with rule metadata and presets
  - C19 — Validation settings UI in macOS Settings (provides UX reference)
  - E3 — Session persistence and `DocumentSessionController` infrastructure
  - E6 — Diagnostics logging for persistence failures
  - G2 — Bookmark persistence patterns

## ✅ Success Criteria

1. **`SettingsPanelView` implemented** with FoundationUI cards and clearly labeled sections for permanent vs. session settings.
2. **Platform-adaptive presentation:**
   - macOS: floating `NSPanel` or detent-based sheet anchored to the current document window
   - iPadOS/iOS: modal sheet with drag-to-dismiss, full-screen on iPhone
3. **Keyboard shortcut support** (`⌘,` or equivalent) toggles panel open/closed consistently across platforms.
4. **Permanent settings persist** correctly across app relaunch (verified by unit + UI tests).
5. **Session settings** survive document reopen but do **not** leak to other sessions.
6. **VoiceOver focus** starts on the first control in the previously active section; all interactive elements have accessible labels.
7. **Reset affordances:**
   - "Reset to Global" clears all permanent settings overrides and reloads from defaults
   - "Reset Session" clears only the current session-scoped payload
8. **Snapshot tests** pass for light/dark modes and all platform variants.
9. **Zero SwiftLint violations**; code coverage ≥80%.

## 🔧 Implementation Notes

### Subtasks

1. **Architecture & Data Flow**
   - Define `SettingsPanelViewModel` to bridge `UserPreferencesStore` (permanent) and `DocumentSessionController` (session)
   - Create a `SettingsPanelState` struct capturing permanent, session, and UI state (search filter, active section)
   - Document concurrency model (async preference loads, debounced writes)

2. **Platform-Specific UI Components**
   - `SettingsPanelScene` — shared SwiftUI view with conditional modifiers:
     - macOS: `.windowStyle(.hiddenTitleBar)` in an `NSPanel` wrapper
     - iPad: `.sheet(detents: [.medium, .large])` or `.fullScreenCover` on portrait
     - iPhone: `.fullScreenCover` for full-screen modal
   - Keyboard shortcut binding (`Command+Comma`) to toggle open/closed state
   - Left sidebar listing sections: Permanent, Session, Advanced
   - Right content pane scrollable with FoundationUI cards per section

3. **Permanent Settings Section**
   - Reuse existing `ValidationSettingsViewModel` and controls
   - Add controls for telemetry/logging verbosity (if plumbing exists)
   - Include "Reset to Global" button linked to `UserPreferencesStore.reset()`
   - Show badges indicating whether a value deviates from app defaults

4. **Session Settings Section**
   - Surface recent workspace scope toggles (per-document vs. shared)
   - Surface pane layout toggles (if persisted in `DocumentSessionController`)
   - Include "Reset Session" button that clears the session payload
   - Disable controls if no document is currently open

5. **Testing**
   - **Unit tests:** Verify state mutations, persistence calls, and reset logic
   - **Snapshot tests:** Capture light/dark mode renderings for macOS/iPad/iPhone
   - **Accessibility tests:** VoiceOver focus order, keyboard navigation, WCAG 2.1 AA compliance
   - **UI tests:** Keyboard shortcut invocation, state synchronization after reopen
   - **Integration tests:** Permanent changes survive relaunch; session changes do not leak

6. **Documentation & Polish**
   - Update `03_Technical_Spec.md` with panel architecture and concurrency guidelines
   - Add DocC articles linking to related tasks (C19, E3, E6, B7)
   - Create a MIGRATION.md entry describing the shift from scattered settings to the floating panel
   - Document keyboard shortcut and VoiceOver patterns for accessibility

### File Structure

```
Sources/ISOInspectorApp/
├── UI/
│   ├── Components/
│   │   └── SettingsPanelView.swift (NEW)
│   ├── Scenes/
│   │   └── SettingsPanelScene.swift (NEW)
│   └── ViewModels/
│       └── SettingsPanelViewModel.swift (NEW)
│
Tests/ISOInspectorAppTests/
├── UI/
│   ├── SettingsPanelViewModelTests.swift (NEW)
│   ├── SettingsPanelViewTests.swift (NEW)
│   └── SettingsPanelSnapshotTests.swift (NEW)
└── Accessibility/
    └── SettingsPanelAccessibilityTests.swift (NEW)

DOCS/
├── MIGRATION.md (NEW/UPDATE)
└── AI/ISOInspector_Execution_Guide/
    └── 03_Technical_Spec.md (UPDATE with panel architecture)
```

### Puzzle-Driven Development (PDD) Markers

- Mark incomplete FoundationUI integrations (e.g., replacing native SwiftUI modals with DS sheets) with `@todo #222`
- Mark future features (e.g., telemetry controls, iCloud sync) with `@todo #222` or defer to Phase 2
- Use conditional compilation (`#if os(macOS)`, `#if os(iOS)`) for platform-specific code paths

### Risk Mitigation

- **State Divergence:** Use a shared `SettingsPanelBridge` actor or single `SettingsPanelViewModel` that coordinates both stores to prevent drift.
- **Platform Inconsistency:** Keep shared SwiftUI view with platform-aware modifiers (detents, fullScreenCover, NSPanel wrapper) and parity snapshot tests.
- **Performance:** Cache decoded preferences in-memory; debounce writes with Combine to avoid stutter while ensuring final state persists.

## 🧠 Source References

- [`14_User_Settings_Panel_PRD.md`](../AI/ISOInspector_Execution_Guide/14_User_Settings_Panel_PRD.md) — Full product requirements
- [`13_Validation_Rule_Toggle_Presets_PRD.md`](../AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md) — Validation configuration baseline
- [`DOCS/TASK_ARCHIVE/220_I1_4_Form_Controls_Input_Wrappers/Summary_of_Work.md`](../TASK_ARCHIVE/220_I1_4_Form_Controls_Input_Wrappers/Summary_of_Work.md) — Form controls reference
- [`DOCS/TASK_ARCHIVE/221_I1_5_Advanced_Layouts_Navigation/Summary_of_Work.md`](../TASK_ARCHIVE/221_I1_5_Advanced_Layouts_Navigation/Summary_of_Work.md) — Layout patterns completed in Phase 1
- [`DOCS/RULES`](../RULES) — Development workflow and standards
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE) — Related task archives (C19, E3, E6, B7, G2)

---

**Started:** 2025-11-14
**Phase:** C — User Interface Package
**Priority:** Medium (P2)
**Effort:** 1 day
**Dependencies:** C3 ✅, C19 ✅
**Status:** 🔄 In Progress
