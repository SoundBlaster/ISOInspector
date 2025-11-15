# C22 — User Settings Panel: Persistence + Reset Wiring

## 🎯 Objective

Complete the floating user settings panel implementation by threading persistence flows for both permanent and session-scoped settings, implementing reset affordances (global and session-scoped), adding keyboard shortcut support (⌘,), and finalizing platform-specific presentation (NSPanel on macOS, sheet on iPad/iOS).

## 🧩 Context

**Previous Phase Completion:**
- C21 (Floating Settings Panel Shell) completed 2025-11-14
  - Established `SettingsPanelViewModel` with section navigation
  - Created `SettingsPanelView` with three sections: Permanent, Session, Advanced
  - Built accessibility infrastructure with hierarchical identifiers
  - Snapshot tests for light/dark modes on all platforms

**Architecture Dependencies:**
- **B7** — `ValidationConfiguration` and preset registry for rule metadata and serialization
- **C19** — Existing `ValidationSettingsViewModel` and per-rule toggles (reusable patterns)
- **E3** — Session persistence layer via `DocumentSessionController` for session snapshot storage
- **E6** — Diagnostics logging hooks for persistence failures

**Related Documentation:**
- [14_User_Settings_Panel_PRD.md](../AI/ISOInspector_Execution_Guide/14_User_Settings_Panel_PRD.md) — Full requirements and acceptance criteria
- [C21 Summary of Work](../TASK_ARCHIVE/222_C21_Floating_Settings_Panel/Summary_of_Work.md) — Implementation details and scaffolding
- [04_TODO_Workplan.md](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) — Phase C context and parallelization notes

## ✅ Success Criteria

### 1. UserPreferencesStore Integration (Puzzle #222.1)
- [ ] Thread permanent settings changes through `UserPreferencesStore`
- [ ] Load global preferences on app startup into ViewModel
- [ ] Save permanent changes immediately (optimistic writes with failure diagnostics)
- [ ] Verify persistence across app relaunch via automated tests

### 2. SessionSettingsPayload Mutations (Puzzle #222.2)
- [ ] Update `DocumentSessionController` to support session settings mutations
- [ ] Bind session settings changes from SettingsPanelViewModel
- [ ] Implement dirty tracking for session scope (badge indicators)
- [ ] Ensure session snapshots serialize/deserialize with `SessionSettingsPayload`

### 3. Reset Actions (Puzzle #222.3)
- [ ] Implement "Reset Global" button → restore permanent defaults via `UserPreferencesStore.reset()`
- [ ] Implement "Reset Session" button → restore session defaults (reload snapshot)
- [ ] Add confirmation dialogs (native alerts) for both reset types
- [ ] Verify reset behavior across platform-specific presentations (NSPanel vs. sheet)

### 4. Keyboard Shortcut (⌘,) (Puzzle #222.4)
- [ ] Bind keyboard shortcut handler to toggle panel visibility
- [ ] Register shortcut across macOS, iPad, and iPhone targets
- [ ] Ensure shortcut works throughout app lifecycle
- [ ] Test focus restoration when panel toggles open

### 5. Platform-Specific Presentation (Puzzle #222.5)
- [ ] macOS: Host in NSPanel window controller with remembered frame/position
- [ ] iPad: Present via `.sheet` modifier with 2-3 detents
- [ ] iPhone: Full-screen cover or modal card presentation
- [ ] Implement platform detection and conditional rendering

### 6. Snapshot Tests (Puzzle #222.6)
- [ ] Test all platforms (iOS 17+, macOS 14+, iPadOS 17+)
- [ ] Test all color schemes (light, dark, auto)
- [ ] Validate responsive behavior across screen sizes
- [ ] Capture state transitions (empty, loading, with errors)

### 7. Advanced Accessibility Tests (Puzzle #222.7)
- [ ] Dynamic Type scaling across all sizes (XS–XXXL)
- [ ] Reduce Motion compliance for animations
- [ ] Advanced VoiceOver focus order tests (confirm focus starts on first control)
- [ ] Keyboard-only navigation across all sections and controls

## 🔧 Implementation Notes

### Data Flow

**Permanent Settings (UserPreferencesStore):**
```
User changes toggle
  → SettingsPanelViewModel mutates @Published state
  → UserPreferencesStore.persist(changes)
  → On success: UI remains consistent
  → On failure: Emit diagnostic event, show toast/inline error
```

**Session Settings (DocumentSessionController):**
```
User changes session toggle
  → SettingsPanelViewModel mutates @Published state
  → DocumentSessionController.updateSessionSettings(for: documentID)
  → Session snapshot updates CoreData + JSON fallback
  → Badge indicators highlight deviation from global defaults
```

**Reset Actions:**
```
User taps "Reset Global"
  → Confirmation alert
  → UserPreferencesStore.reset()
  → Reload ViewModel from defaults
  → Refresh UI state
```

### Platform Presentation Strategy

**macOS:**
- Use `NSPanel` (floating window style) or `NSWindow` with detents
- Remember size/position in user preferences (store frame rect)
- Support title-bar menu for quick access
- Integrate with existing Settings scene (supplement, not replace)

**iPad:**
- `.sheet(isPresented:)` with detents (e.g., `.medium`, `.large`)
- Drag-to-dismiss enabled by default
- Keyboard shortcut toggles sheet visibility

**iPhone:**
- Full-screen modal or `.sheet` depending on size availability
- Detents limited to `.large` for usability
- Navigation back button to dismiss

### Testing Strategy

1. **Unit Tests** (SettingsPanelViewModel)
   - Verify state mutations and ViewModel methods
   - Test UserPreferencesStore integration (mock store)
   - Test DocumentSessionController integration (mock controller)

2. **Snapshot Tests** (SettingsPanelView)
   - All 3 sections with sample data
   - Light/dark mode variants
   - Loading and error states
   - All platform sizes (SE, iPhone 15, iPad Pro, Mac)

3. **Integration Tests**
   - Full flow: open panel → change setting → persist → relaunch → verify
   - Reset confirmations and state cleanup
   - Keyboard shortcut invocation and focus restoration

4. **Accessibility Tests**
   - VoiceOver focus order and control announcements
   - Dynamic Type scaling without layout breakage
   - Reduce Motion respected in animations

### Known Constraints

- **No Cross-Device Sync:** iCloud/CloudKit out of scope per PRD
- **No New Rules:** C22 reuses existing validation presets from B7/C19
- **CLI Not in Scope:** CLI settings exposure deferred to future backlog

## 🧠 Source References

- [14_User_Settings_Panel_PRD.md](../AI/ISOInspector_Execution_Guide/14_User_Settings_Panel_PRD.md) — Requirements, risks, and acceptance criteria
- [04_TODO_Workplan.md](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) — Phase C dependencies and parallelization notes
- [222_C21_Floating_Settings_Panel/Summary_of_Work.md](../TASK_ARCHIVE/222_C21_Floating_Settings_Panel/Summary_of_Work.md) — Scaffolding completed in C21
- [13_Validation_Rule_Toggle_Presets_PRD.md](../AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md) — Validation preset reference
- [DOCS/RULES/02_TDD_XP_Workflow.md](../RULES/02_TDD_XP_Workflow.md) — XP/TDD iteration process
- [DOCS/RULES/03_Next_Task_Selection.md](../RULES/03_Next_Task_Selection.md) — Task selection methodology

---

**Task Created:** 2025-11-15
**Estimated Duration:** 1 day
**Status:** 🎬 Ready to Start
