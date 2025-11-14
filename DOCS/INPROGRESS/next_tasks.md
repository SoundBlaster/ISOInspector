# Next Tasks

## Active

### Core Work (Current Priority)

- [ ] **T6.3 — SDK Tolerant Parsing Documentation** (Priority: Medium, Effort: 1 day)
  - Create DocC article `TolerantParsingGuide.md` in `Sources/ISOInspectorKit/ISOInspectorKit.docc/Articles/`
  - Add code examples for tolerant parsing setup and `ParseIssueStore` usage
  - Update inline documentation for `ParsePipeline.Options`, `.strict`, `.tolerant`
  - Link new guide from main `Documentation.md` Topics section
  - Verify examples with test file in `Tests/ISOInspectorKitTests/`
  - See `DOCS/INPROGRESS/211_T6_3_SDK_Tolerant_Parsing_Documentation.md` for full PRD

### FoundationUI Integration (Priority Feature)

**See detailed plan in:** `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`

#### Phase 0: Setup & Verification ✅ **COMPLETE**
**Duration:** 4 days | **Priority:** P0 | **Status:** ✅ All tasks completed (2025-11-14)

Completed tasks:
- [x] **I0.1 — Add FoundationUI Dependency** (Completed 2025-11-13)
- [x] **I0.2 — Create Integration Test Suite** (Completed 2025-11-13, 123 tests)
- [x] **I0.3 — Build Component Showcase** (Pre-existing via ComponentTestApp)
- [x] **I0.4 — Document Integration Patterns** (Completed 2025-11-13)
- [x] **I0.5 — Update Design System Guide** (Completed 2025-11-14)

**Phase 0 Deliverables:**
- ✅ FoundationUI dependency integrated and building successfully
- ✅ 123 comprehensive integration tests (Badge: 33, Card: 43, KeyValueRow: 40, Integration: 7)
- ✅ ComponentTestApp provides live component showcase (14+ screens)
- ✅ Integration patterns documented in `03_Technical_Spec.md` (~685 lines)
- ✅ Design System Guide updated with migration roadmap (~800 lines added)
- ✅ Zero SwiftLint violations, ≥80% test coverage

---

#### Phase 1: Foundation Components (Weeks 2-3) 🔄 **IN PROGRESS**
**Duration:** 5-7 days | **Priority:** P1 | **Dependencies:** Phase 0 ✅ complete
**Started:** 2025-11-14

**Completed Tasks:**
- [x] **I1.1 — Badge & Status Indicators** ✅ **COMPLETED** (2025-11-14)
  - Migrated CorruptionBadge, SeverityBadge, ParseStateBadge to `DS.Badge`
  - Unit tests inherited from Phase 0 (33 tests, ≥90% coverage)
  - Accessibility ≥98% WCAG 2.1 AA compliance
  - Archived: `DOCS/TASK_ARCHIVE/216_I1_1_Badge_Status_Indicators/`

**Queued Tasks:**

- [ ] **I1.2 — Card Containers & Sections** (Priority: P1, Effort: 2-3d)
  - Audit current container styles
  - Create `BoxDetailsCard` wrapper around `DS.Card`
  - Create `BoxSectionHeader` wrapper around `DS.SectionHeader`
  - Refactor details panel layout to use Cards
  - Add unit + snapshot + accessibility tests
  - Verify dark mode adaptation

- [ ] **I1.3 — Key-Value Rows & Metadata Display** (Priority: P1, Effort: 2-3d)
  - Audit metadata display patterns
  - Create `BoxMetadataRow` wrapper around `DS.KeyValueRow`
  - Refactor all field displays to use KeyValueRow
  - Add copyable action integration
  - Add unit + snapshot + accessibility tests
  - Add to component showcase

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
See detailed breakdown in `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`:
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
