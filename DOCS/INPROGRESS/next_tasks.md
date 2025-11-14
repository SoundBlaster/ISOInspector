# Next Tasks

## Active

### FoundationUI Integration (Priority Feature)

**See detailed plan in:** `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`

#### Phase 0: Setup & Verification (Completion)
**Duration:** 1 day | **Priority:** P0 (blocks all following phases)

Remaining item:
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
