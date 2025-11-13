# Next Tasks

## Active

### FoundationUI Integration (Priority Feature)

**See detailed plan in:** `DOCS/TASK_ARCHIVE/212_FoundationUI_Phase_0_Integration_Setup/FoundationUI_Integration_Strategy.md`

#### Phase 0: Setup & Verification (In Progress)
**Duration:** 3-4 days | **Priority:** P0 (blocks all following phases)

- [x] **I0.1 — Add FoundationUI Dependency** (Effort: 0.5d) ✅ **COMPLETED 2025-11-13**
  - Added FoundationUI as dependency in ISOInspectorApp Package.swift
  - Verified builds with FoundationUI target
  - Updated Package.swift platform requirements
  - Created integration test suite at `Tests/ISOInspectorAppTests/FoundationUI/`
  - See `DOCS/TASK_ARCHIVE/212_FoundationUI_Phase_0_Integration_Setup/212_I0_1_Add_FoundationUI_Dependency.md` for full details

- [x] **I0.2 — Create Integration Test Suite** (Effort: 0.5d) ✅ **COMPLETED 2025-11-13**
  - Created comprehensive test suite with 123 tests across 4 test files
  - Added `BadgeComponentTests.swift` with 33 tests for Badge component
  - Added `CardComponentTests.swift` with 43 tests for Card component
  - Added `KeyValueRowComponentTests.swift` with 40 tests for KeyValueRow component
  - Existing `FoundationUIIntegrationTests.swift` has 7 integration tests
  - Test coverage: comprehensive coverage for all three core FoundationUI components (Badge, Card, KeyValueRow)
  - Platform-specific tests included for iOS and macOS
  - See `DOCS/TASK_ARCHIVE/212_FoundationUI_Phase_0_Integration_Setup/212_I0_2_Create_Integration_Test_Suite.md` for full details

- [x] **I0.3 — Build Component Showcase** (Effort: 1.5d) ✅ **COMPLETED (Pre-existing)**
  - **Already implemented as `ComponentTestApp`** in `Examples/ComponentTestApp/`
  - Comprehensive demo application with 14+ showcase screens:
    - ✅ Design Tokens showcase (Spacing, Colors, Typography, Radius, Animation)
    - ✅ View Modifiers showcase (BadgeChipStyle, CardStyle, InteractiveStyle, SurfaceStyle)
    - ✅ Component showcases: Badge, Card, KeyValueRow, SectionHeader
    - ✅ Pattern showcases: InspectorPattern, SidebarPattern, ToolbarPattern, BoxTreePattern
    - ✅ ISO Inspector Demo screen
    - ✅ Accessibility Testing and Performance Monitoring screens
  - Features:
    - ✅ Theme toggle (Light/Dark/System)
    - ✅ Dynamic Type support with custom controls
    - ✅ Live preview capabilities
    - ✅ Interactive component variations
    - ✅ Platform support: iOS 17+, macOS 14+
  - See `Examples/ComponentTestApp/README.md` for full documentation

- [ ] **I0.4 — Document Integration Patterns** (Effort: 0.5d)
  - Add "FoundationUI Integration" section to `03_Technical_Spec.md`
  - Document architecture patterns for wrapping FoundationUI components
  - Add code examples: badge wrappers, card layouts, pattern implementations
  - Document design token usage (DS.Spacing, DS.Colors, etc.)
  - Create "Do's and Don'ts" guidelines

- [ ] **I0.5 — Update Design System Guide** (Effort: 0.5d)
  - Update `10_DESIGN_SYSTEM_GUIDE.md` with FoundationUI integration checklist
  - Document migration path: old UI → FoundationUI
  - Add quality gates per phase
  - Document accessibility requirements (≥98% WCAG 2.1 AA compliance)

#### Phase 1: Foundation Components (Weeks 2-3)
**Subtasks to be created after Phase 0 completion**
- I1.1 Badge & Status Indicators (1-2d)
- I1.2 Card Containers & Sections (2-3d)
- I1.3 Key-Value Rows & Metadata (2-3d)

### Other Prioritized Work

#### User Settings Panel (Floating Preferences)
**Reference:** `DOCS/AI/ISOInspector_Execution_Guide/14_User_Settings_Panel_PRD.md`

- [ ] **C21 — Floating Settings Panel Shell** (Priority: Medium, Effort: 1 day)
  - Implement `SettingsPanelScene` with FoundationUI cards separating permanent vs. session groups.
  - macOS: host inside an `NSPanel` window controller with remembered frame + keyboard shortcut (`⌘,`).
  - iPad/iOS: present via `.sheet` detents; ensure VoiceOver focus starts at the selected section and dismissal events fire automation hooks.
  - Snapshot + accessibility tests validate both presentations.

- [ ] **C22 — Persistence + Reset Wiring** (Priority: Medium, Effort: 1 day)
  - Thread permanent changes through `UserPreferencesStore` and emit diagnostics on failures (reuse Task E6 harness).
  - Update `DocumentSessionController` with `SessionSettingsPayload` mutations for session-only toggles and persist them via CoreData + JSON fallbacks.
  - Add reset actions ("Reset Global", "Reset Session"), logging, and DocC/README callouts describing layered persistence behavior.

#### Future Phases (4-6)
See detailed breakdown in `DOCS/TASK_ARCHIVE/212_FoundationUI_Phase_0_Integration_Setup/FoundationUI_Integration_Strategy.md`:
- Phase 2: Interactive Components (Week 4)
- Phase 3: Layout Patterns (Weeks 5-7)
- Phase 4: Platform Adaptation & Contexts (Week 8)
- Phase 5: Advanced Features (Week 9)
- Phase 6: Full Integration & Validation (Week 10)

## Notes

- FoundationUI Integration Phase 0 is the critical P0 blocker for all subsequent integration phases
- Each phase gates on test coverage ≥80%, accessibility ≥95%, performance baselines
- Roadmap: 9 weeks total (45 working days) if executing serially
- Can parallelize C21/C22 (User Settings) with Phase 1-2 FoundationUI work if needed
