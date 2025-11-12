# FoundationUI Integration Strategy for ISOInspectorApp
**Project:** ISO Inspector
**Created:** 2025-11-12
**Status:** Planning & Documentation
**Scope:** Gradual, phased integration of FoundationUI into ISOInspectorApp starting with small components

---

## 📋 Overview

This document describes a **gradual, step-by-step integration strategy** for FoundationUI into ISOInspectorApp. The approach prioritizes stability, testability, and continuous validation while scaling from small components to full-scale UI migration.

### Key Principles
1. **Start Small** — Begin with isolated, low-risk UI elements
2. **Test Thoroughly** — Each phase includes comprehensive unit, integration, and snapshot tests
3. **Iterate Safely** — No breaking changes to existing app functionality
4. **Document Incrementally** — Update PRD and technical specs as we progress
5. **Maintain Backward Compatibility** — Old and new UI systems coexist during transition
6. **Platform-Aware** — Leverage platform adaptation contexts (macOS, iOS, iPadOS)

---

## 🎯 Integration Phases

### Phase 0: Setup & Verification (Phase 6.1-6.2 from FoundationUI)
**Duration:** 3-4 days
**Status:** ⏳ Pending
**Effort:** Low-Medium

#### Objectives
- Verify FoundationUI Swift Package in ISOInspectorApp build
- Establish integration test patterns
- Create Component Showcase module for incremental UI testing
- Document integration points in technical spec

#### Subtasks
- [ ] **I0.1** — Add FoundationUI as dependency in `ISOInspectorApp` target (Package.swift)
- [ ] **I0.2** — Create integration test suite: `Tests/ISOInspectorAppTests/FoundationUI/`
- [ ] **I0.3** — Build Component Showcase SwiftUI view for development/testing
- [ ] **I0.4** — Document "FoundationUI Integration Patterns" in 03_Technical_Spec.md
- [ ] **I0.5** — Update 10_DESIGN_SYSTEM_GUIDE.md with integration checklist

**Success Criteria:**
- ✅ ISOInspectorApp builds with FoundationUI dependency
- ✅ Integration test suite structure in place
- ✅ All FoundationUI components render in Showcase (no crashes)
- ✅ Zero SwiftLint violations
- ✅ Code coverage ≥80%

---

### Phase 1: Foundation Components (Weeks 1-2)
**Duration:** 5-7 days
**Status:** ⏳ Pending
**Effort:** Low

These are **atomic, reusable UI elements** with minimal state dependencies. No breaking changes to app logic.

#### 1.1 Badge & Status Indicators
**Priority:** P1 | **Effort:** 1-2 days | **Risk:** Low

**Current State:** ISOInspectorApp has manual badge implementations scattered in views.
**Target:** Consolidate into `DS.Badge` and `DS.Indicator` components.

**Components to Replace:**
- Manual text styling for status indicators
- Parse error/warning badges
- Processing status indicators

**Subtasks:**
- [ ] **I1.1.1** — Audit current badge usage in codebase (grep for status indicators)
- [ ] **I1.1.2** — Create `BoxStatusBadgeView` wrapper around `DS.Badge` (level: .info/.warning/.error/.success)
- [ ] **I1.1.3** — Create `ParseStatusIndicator` for tree view nodes (mini/small/medium sizes)
- [ ] **I1.1.4** — Add unit tests for badge/indicator variants
- [ ] **I1.1.5** — Add snapshot tests for light/dark modes and all 4 status levels
- [ ] **I1.1.6** — Add accessibility tests (VoiceOver label, contrast, focus)
- [ ] **I1.1.7** — Update component showcase with badge/indicator examples
- [ ] **I1.1.8** — Document migration path in MIGRATION.md

**Files to Modify:**
```
Sources/ISOInspectorApp/UI/Components/BoxStatusBadgeView.swift (NEW)
Sources/ISOInspectorApp/UI/Components/ParseStatusIndicator.swift (NEW)
Tests/ISOInspectorAppTests/FoundationUI/BadgeIndicatorTests.swift (NEW)
Tests/ISOInspectorAppTests/FoundationUI/BadgeIndicatorSnapshotTests.swift (NEW)
Tests/ISOInspectorAppTests/FoundationUI/BadgeIndicatorAccessibilityTests.swift (NEW)
DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md (UPDATE)
DOCS/MIGRATION.md (NEW)
```

**Success Criteria:**
- ✅ All manual badges replaced with `DS.Badge`
- ✅ All status indicators use `DS.Indicator`
- ✅ Unit test coverage ≥90%
- ✅ Snapshot tests pass for all variants (light/dark, all levels)
- ✅ Accessibility score ≥98%
- ✅ Build time impact <5%

---

#### 1.2 Card Containers & Sections
**Priority:** P1 | **Effort:** 2-3 days | **Risk:** Low-Medium

**Current State:** Details panel uses manual padding/corners/shadows.
**Target:** Migrate to `DS.Card` and `DS.SectionHeader` components.

**Components to Replace:**
- Details panel sections with borders/backgrounds
- Manual section headers with dividers
- Info/metadata card containers

**Subtasks:**
- [ ] **I1.2.1** — Audit current container styles (CardStyle, elevation levels)
- [ ] **I1.2.2** — Create `BoxDetailsCard` wrapper around `DS.Card`
- [ ] **I1.2.3** — Create `BoxSectionHeader` wrapper around `DS.SectionHeader`
- [ ] **I1.2.4** — Refactor details panel layout to use Cards
- [ ] **I1.2.5** — Add unit + snapshot tests for card variants (elevation, material)
- [ ] **I1.2.6** — Add integration tests for card nesting
- [ ] **I1.2.7** — Add accessibility tests (semantic structure, landmarks)
- [ ] **I1.2.8** — Verify dark mode adaptation

**Files to Modify:**
```
Sources/ISOInspectorApp/UI/Components/BoxDetailsCard.swift (NEW)
Sources/ISOInspectorApp/UI/Components/BoxSectionHeader.swift (NEW)
Sources/ISOInspectorApp/Views/Details/BoxDetailView.swift (MAJOR UPDATE)
Tests/ISOInspectorAppTests/FoundationUI/CardSectionTests.swift (NEW)
Tests/ISOInspectorAppTests/FoundationUI/CardSectionSnapshotTests.swift (NEW)
Tests/ISOInspectorAppTests/FoundationUI/CardSectionAccessibilityTests.swift (NEW)
```

**Success Criteria:**
- ✅ All container styling uses `DS.Card`
- ✅ All section headers use `DS.SectionHeader`
- ✅ No manual padding/corners magic numbers (use DS.Spacing tokens)
- ✅ Dark mode fully functional
- ✅ Snapshot regression tests pass on all platforms

---

#### 1.3 Key-Value Rows & Metadata Display
**Priority:** P1 | **Effort:** 2-3 days | **Risk:** Low

**Current State:** Details panel displays metadata as manual HStack/VStack layouts.
**Target:** Use `DS.KeyValueRow` component for consistent metadata presentation.

**Subtasks:**
- [ ] **I1.3.1** — Audit metadata display patterns (horizontal vs. vertical layouts)
- [ ] **I1.3.2** — Create `BoxMetadataRow` wrapper around `DS.KeyValueRow` with ISO-specific formatting
- [ ] **I1.3.3** — Refactor all field displays to use KeyValueRow
- [ ] **I1.3.4** — Add copyable action to key-value rows
- [ ] **I1.3.5** — Unit + snapshot tests for layout variants
- [ ] **I1.3.6** — Accessibility tests (label-value pairing, focus management)
- [ ] **I1.3.7** — Add to component showcase

**Files to Modify:**
```
Sources/ISOInspectorApp/UI/Components/BoxMetadataRow.swift (NEW)
Sources/ISOInspectorApp/Views/Details/BoxDetailView.swift (REFACTOR)
Tests/ISOInspectorAppTests/FoundationUI/KeyValueRowTests.swift (NEW)
Tests/ISOInspectorAppTests/FoundationUI/KeyValueRowSnapshotTests.swift (NEW)
```

**Success Criteria:**
- ✅ All metadata displayed via `DS.KeyValueRow`
- ✅ Consistent spacing via DS tokens (no magic numbers)
- ✅ Copyable actions integrated
- ✅ Test coverage ≥85%

---

### Phase 2: Interactive Components & Modifiers (Weeks 3-4)
**Duration:** 5-7 days
**Status:** ⏳ Pending
**Effort:** Low-Medium

These components involve **user interaction** and **state changes**. Requires careful integration with existing event handlers.

#### 2.1 Copyable Text & Actions
**Priority:** P2 | **Effort:** 1-2 days | **Risk:** Low

**Current State:** Manual copy buttons next to text fields.
**Target:** Use `DS.Copyable` wrapper for universal copy functionality.

**Subtasks:**
- [ ] **I2.1.1** — Integrate `DS.CopyableText` into metadata values
- [ ] **I2.1.2** — Integrate `DS.Copyable` wrapper into hex viewer addresses
- [ ] **I2.1.3** — Add platform-specific shortcuts (Cmd+C on macOS, Ctrl+C on iOS)
- [ ] **I2.1.4** — Test clipboard feedback on all platforms
- [ ] **I2.1.5** — Unit tests for copy functionality
- [ ] **I2.1.6** — Snapshot tests for copy feedback UI

**Success Criteria:**
- ✅ Copy works on all platforms
- ✅ Visual feedback appears (toast/confirmation)
- ✅ Keyboard shortcuts functional
- ✅ Accessibility labels correct

---

#### 2.2 Interactive Styles & Hover Effects
**Priority:** P2 | **Effort:** 2-3 days | **Risk:** Medium

**Current State:** Manual hover/press state handling.
**Target:** Use `DS.InteractiveStyle` modifier for consistent interaction feedback.

**Subtasks:**
- [ ] **I2.2.1** — Apply `DS.InteractiveStyle` to clickable rows
- [ ] **I2.2.2** — Apply to expand/collapse tree controls
- [ ] **I2.2.3** — Apply to toolbar buttons
- [ ] **I2.2.4** — Test hover feedback on macOS
- [ ] **I2.2.5** — Test touch feedback on iOS
- [ ] **I2.2.6** — Integration tests for interaction sequences

**Success Criteria:**
- ✅ All interactive elements have consistent feedback
- ✅ macOS: hover state working
- ✅ iOS: touch feedback visible
- ✅ No accessibility conflicts (focus management preserved)

---

#### 2.3 Surface Material & Elevation
**Priority:** P2 | **Effort:** 1-2 days | **Risk:** Low

**Current State:** Manual background and shadow application.
**Target:** Use `DS.SurfaceStyle` environment key for layered material design.

**Subtasks:**
- [ ] **I2.3.1** — Apply `.surfaceStyle(.thin)` to primary surfaces
- [ ] **I2.3.2** — Apply `.surfaceStyle(.regular)` to detail panels
- [ ] **I2.3.3** — Apply `.surfaceStyle(.thick)` to modals/popovers
- [ ] **I2.3.4** — Verify shadow rendering across platforms
- [ ] **I2.3.5** — Dark mode shadow adaptation tests
- [ ] **I2.3.6** — Accessibility tests (no color-only differentiation)

**Success Criteria:**
- ✅ All surfaces use appropriate SurfaceStyle
- ✅ Elevation hierarchy clear visually
- ✅ Dark mode shadows correct
- ✅ No accessibility violations

---

### Phase 3: Layout Patterns & Navigation (Weeks 5-6)
**Duration:** 7-10 days
**Status:** ⏳ Pending
**Effort:** Medium-High

These are **complex, structural components** that significantly impact app layout. Requires extensive testing and phased rollout.

#### 3.1 Sidebar Pattern (macOS/iPad)
**Priority:** P3 | **Effort:** 3-4 days | **Risk:** Medium

**Current State:** Manual NavigationSplitView with custom sidebar styling.
**Target:** Replace with `DS.SidebarPattern` for consistent sidebar layout.

**Components to Replace:**
- Manual sidebar section headers
- Manual navigation styling
- Search/filter placement

**Subtasks:**
- [ ] **I3.1.1** — Create `BoxesSidebar` using `DS.SidebarPattern`
- [ ] **I3.1.2** — Move file browser to sidebar pattern
- [ ] **I3.1.3** — Integrate search/filter into pattern
- [ ] **I3.1.4** — Test NavigationLink behavior in pattern
- [ ] **I3.1.5** — macOS-specific shortcut integration
- [ ] **I3.1.6** — iPad layout adaptation tests
- [ ] **I3.1.7** — Snapshot tests for sidebar appearance
- [ ] **I3.1.8** — VoiceOver and keyboard navigation tests

**Platform-Specific:**
```
macOS:   SidebarPattern + Cmd+1,2,3 shortcuts for sections
iPad:    SidebarPattern + CollapsibleButton on portrait
iOS:     Hide sidebar behind NavigationStack (fallback)
```

**Files to Modify:**
```
Sources/ISOInspectorApp/Views/Sidebar/BoxesSidebar.swift (NEW)
Sources/ISOInspectorApp/Views/ContentView.swift (REFACTOR)
Tests/ISOInspectorAppTests/FoundationUI/SidebarPatternTests.swift (NEW)
Tests/ISOInspectorAppTests/FoundationUI/SidebarPatternSnapshotTests.swift (NEW)
Tests/ISOInspectorAppTests/FoundationUI/SidebarPatternAccessibilityTests.swift (NEW)
```

**Success Criteria:**
- ✅ Sidebar pattern working on macOS/iPad
- ✅ File browser navigation functional
- ✅ Search/filter integrated
- ✅ iOS fallback (NavigationStack) working
- ✅ Keyboard shortcuts operational
- ✅ VoiceOver fully functional

---

#### 3.2 Inspector Pattern (Details Panel)
**Priority:** P3 | **Effort:** 2-3 days | **Risk:** Medium

**Current State:** Manual scrollable details layout.
**Target:** Replace with `DS.InspectorPattern` for consistent inspector layout.

**Subtasks:**
- [ ] **I3.2.1** — Create `BoxInspector` using `DS.InspectorPattern`
- [ ] **I3.2.2** — Migrate all detail sections to pattern
- [ ] **I3.2.3** — Test fixed header positioning
- [ ] **I3.2.4** — Platform-adaptive spacing and sizing
- [ ] **I3.2.5** — Integration with scroll behavior
- [ ] **I3.2.6** — Snapshot tests for all screen sizes
- [ ] **I3.2.7** — Accessibility: heading hierarchy, landmarks

**Files to Modify:**
```
Sources/ISOInspectorApp/Views/Details/BoxInspector.swift (NEW)
Sources/ISOInspectorApp/Views/Details/BoxDetailView.swift (REFACTOR)
Tests/ISOInspectorAppTests/FoundationUI/InspectorPatternTests.swift (NEW)
```

**Success Criteria:**
- ✅ Inspector pattern applied to all detail sections
- ✅ Fixed header sticky and functional
- ✅ Scroll performance maintained
- ✅ Accessibility tests pass

---

#### 3.3 Tree Box Pattern (Hierarchical Structure)
**Priority:** P3 | **Effort:** 3-4 days | **Risk:** Medium-High

**Current State:** Manual OutlineGroup with custom tree styling.
**Target:** Replace with `DS.BoxTreePattern` for optimized hierarchical display.

**Key Features:**
- Lazy rendering (virtualization for large trees)
- Expand/collapse animations
- Selection highlighting
- Node metadata display

**Subtasks:**
- [ ] **I3.3.1** — Create `BoxTree` wrapper around `DS.BoxTreePattern`
- [ ] **I3.3.2** — Adapt BoxNode model to pattern requirements
- [ ] **I3.3.3** — Integrate lazy rendering
- [ ] **I3.3.4** — Animate expand/collapse
- [ ] **I3.3.5** — Test virtualization with large trees (1000+ nodes)
- [ ] **I3.3.6** — Memory profiling (no leaks on expand/collapse)
- [ ] **I3.3.7** — Performance tests: render time <16ms per frame
- [ ] **I3.3.8** — Snapshot tests for tree appearance
- [ ] **I3.3.9** — VoiceOver tree navigation tests (OutlineGroup accessible already)
- [ ] **I3.3.10** — Keyboard arrow key navigation tests

**Considerations:**
```
⚠️ Large Trees: OutlineGroup + lazy rendering can be slow
   Solution: Use LazyVStack with .id(_:) for lazy rendering

⚠️ Selection State: Must integrate with BoxNodeStore
   Solution: Use @EnvironmentObject for selection propagation

⚠️ Memory: Expand/collapse must not leak nodes
   Solution: Test with Xcode Memory debugger
```

**Files to Modify:**
```
Sources/ISOInspectorApp/Views/Tree/BoxTree.swift (NEW/REFACTOR)
Sources/ISOInspectorApp/Models/BoxNode.swift (MINOR UPDATE)
Sources/ISOInspectorApp/Models/BoxNodeStore.swift (INTEGRATION)
Tests/ISOInspectorAppTests/FoundationUI/BoxTreePatternTests.swift (NEW)
Tests/ISOInspectorAppTests/FoundationUI/BoxTreePatternPerformanceTests.swift (NEW)
```

**Success Criteria:**
- ✅ Tree renders with <16ms frame time
- ✅ Memory stable during expand/collapse (monitor with Instruments)
- ✅ Large tree (1000+ nodes) renders responsively
- ✅ Snapshot tests pass for all node states
- ✅ VoiceOver navigation functional

---

#### 3.4 Toolbar Pattern
**Priority:** P3 | **Effort:** 1-2 days | **Risk:** Low

**Current State:** Manual toolbar button arrangement.
**Target:** Use `DS.ToolbarPattern` for adaptive toolbar layout.

**Subtasks:**
- [ ] **I3.4.1** — Apply `DS.ToolbarPattern` to top toolbar
- [ ] **I3.4.2** — Test icon+label rendering
- [ ] **I3.4.3** — Test overflow menu on small screens
- [ ] **I3.4.4** — Platform-specific layout (macOS: top, iOS: bottom)
- [ ] **I3.4.5** — Snapshot tests for toolbar variants
- [ ] **I3.4.6** — Accessibility: button labels, focus

**Success Criteria:**
- ✅ Toolbar layout adaptive
- ✅ Overflow menu functional
- ✅ Icons + labels clear
- ✅ Accessibility score ≥98%

---

### Phase 4: Platform Adaptation & Contexts (Week 7)
**Duration:** 4-5 days
**Status:** ⏳ Pending
**Effort:** Medium

Apply FoundationUI **environment contexts** for platform-specific behavior and accessibility.

#### 4.1 Platform Adaptation
**Priority:** P4 | **Effort:** 1-2 days | **Risk:** Low

**Current State:** Manual platform-specific spacing/sizing.
**Target:** Use `DS.PlatformAdaptation` context for automatic adaptation.

**Subtasks:**
- [ ] **I4.1.1** — Apply `@Environment(\.platformAdaptation)` in key views
- [ ] **I4.1.2** — Test macOS 12pt vs iOS 16pt spacing
- [ ] **I4.1.3** — Size class adaptation (regular vs. compact)
- [ ] **I4.1.4** — Test on all screen sizes (iPhone SE, iPhone 15 Pro Max, iPad, Mac)
- [ ] **I4.1.5** — Snapshot tests for platform-specific layouts

**Files to Modify:**
```
Sources/ISOInspectorApp/Contexts/PlatformAdaptationSetup.swift (NEW)
Sources/ISOInspectorApp/Views/ContentView.swift (ADD CONTEXT)
```

**Success Criteria:**
- ✅ Spacing correct on all platforms
- ✅ Size classes respected
- ✅ Snapshot tests pass platform-specific variants

---

#### 4.2 Accessibility Contexts
**Priority:** P4 | **Effort:** 2-3 days | **Risk:** Low

**Current State:** Manual accessibility implementations scattered.
**Target:** Use `DS.AccessibilityContext` for Reduce Motion, Increase Contrast, Dynamic Type, Bold Text.

**Subtasks:**
- [ ] **I4.2.1** — Apply AccessibilityContext to animations (reduce motion)
- [ ] **I4.2.2** — Test high contrast mode on all components
- [ ] **I4.2.3** — Dynamic Type support for all text elements
- [ ] **I4.2.4** — Bold Text accessibility setting
- [ ] **I4.2.5** — VoiceOver narration for all interactive elements
- [ ] **I4.2.6** — Keyboard navigation (Tab, Return, Escape)
- [ ] **I4.2.7** — Focus indicators visible on all platforms
- [ ] **I4.2.8** — Accessibility audit: WCAG 2.1 AA level

**Test Coverage:**
```
Accessibility Tests:
- [ ] 50+ VoiceOver narration tests
- [ ] 20+ keyboard navigation tests
- [ ] 30+ color contrast tests
- [ ] 20+ dynamic type tests
- [ ] 15+ motion reduction tests
Target: 98%+ accessibility score
```

**Files to Modify:**
```
Sources/ISOInspectorApp/Contexts/AccessibilitySetup.swift (NEW)
Sources/ISOInspectorApp/Views/ContentView.swift (ADD CONTEXT)
Tests/ISOInspectorAppTests/FoundationUI/AccessibilityTests.swift (NEW)
```

**Success Criteria:**
- ✅ WCAG 2.1 AA compliance verified
- ✅ 98%+ accessibility audit score
- ✅ All animations respect Reduce Motion
- ✅ Dynamic Type scales correctly (all size categories)
- ✅ High contrast mode fully functional

---

#### 4.3 Color Scheme & Dark Mode
**Priority:** P4 | **Effort:** 1-2 days | **Risk:** Low

**Current State:** Some manual dark mode handling.
**Target:** Centralized dark mode via `DS.ColorSchemeAdapter` context.

**Subtasks:**
- [ ] **I4.3.1** — Apply `DS.ColorSchemeAdapter` globally
- [ ] **I4.3.2** — Audit all hardcoded colors (replace with DS.Colors)
- [ ] **I4.3.3** — Test dark mode on all views
- [ ] **I4.3.4** — Snapshot tests: light + dark modes
- [ ] **I4.3.5** — High contrast + dark mode combination test

**Success Criteria:**
- ✅ Zero hardcoded colors in UI code
- ✅ Dark mode rendering consistent
- ✅ Snapshots pass for light/dark/high-contrast
- ✅ Performance impact <2%

---

### Phase 5: Advanced Features & Integration (Week 8)
**Duration:** 5-7 days
**Status:** ⏳ Pending
**Effort:** High

Integrate advanced FoundationUI features with ISOInspectorApp business logic.

#### 5.1 Search & Filter with DS Components
**Priority:** P5 | **Effort:** 2-3 days | **Risk:** Medium

**Current State:** Manual search box and filter logic.
**Target:** Integrate with FoundationUI and create consistent search patterns.

**Subtasks:**
- [ ] **I5.1.1** — Create `BoxSearchView` using FoundationUI typography/spacing
- [ ] **I5.1.2** — Create `BoxFilterView` with filter chips
- [ ] **I5.1.3** — Connect to existing BoxTreeStore search
- [ ] **I5.1.4** — Test search performance (large trees)
- [ ] **I5.1.5** — Keyboard shortcuts for search (Cmd+F)
- [ ] **I5.1.6** — Snapshot tests for search UI
- [ ] **I5.1.7** — Accessibility: search input labels, filter results announcement

**Success Criteria:**
- ✅ Search UI using FoundationUI
- ✅ Search performance <100ms for 10K boxes
- ✅ Filter chips interactive
- ✅ Keyboard navigation functional

---

#### 5.2 Progress & Async Streaming
**Priority:** P5 | **Effort:** 2-3 days | **Risk:** Medium

**Current State:** Manual progress indicator and async handling.
**Target:** Integrate FoundationUI ProgressView with async parsing updates.

**Subtasks:**
- [ ] **I5.2.1** — Create `BoxParsingProgressView` using FoundationUI
- [ ] **I5.2.2** — Connect to AsyncThrowingStream from ISOInspectorCore
- [ ] **I5.2.3** — Display live progress percentage
- [ ] **I5.2.4** — Show parsing status (Parsing... / Complete / Error)
- [ ] **I5.2.5** — Test with large files (performance)
- [ ] **I5.2.6** — Accessibility: progress announcement via Live Region

**Success Criteria:**
- ✅ Progress updates in real-time
- ✅ Status updates clear
- ✅ No freezing during async operations
- ✅ Accessibility announcements correct

---

#### 5.3 Export & Share Actions
**Priority:** P5 | **Effort:** 2-3 days | **Risk:** Low-Medium

**Current State:** Basic export functionality.
**Target:** Enhanced export UI using FoundationUI patterns.

**Subtasks:**
- [ ] **I5.3.1** — Create `BoxExportView` modal using FoundationUI
- [ ] **I5.3.2** — Add export format selection (JSON, YAML, CSV)
- [ ] **I5.3.3** — Share sheet integration
- [ ] **I5.3.4** — Test on all platforms
- [ ] **I5.3.5** — Snapshot tests for export UI
- [ ] **I5.3.6** — Accessibility: export options selectable via keyboard

**Success Criteria:**
- ✅ Export modal using FoundationUI design system
- ✅ All format options functional
- ✅ Share sheet working
- ✅ Tests pass on all platforms

---

#### 5.4 Hex Viewer Enhancement
**Priority:** P5 | **Effort:** 2-3 days | **Risk:** Medium

**Current State:** Basic hex display.
**Target:** Enhanced hex viewer with FoundationUI typography and copyable data.

**Subtasks:**
- [ ] **I5.4.1** — Apply DS.Typography for hex content (monospace)
- [ ] **I5.4.2** — Create `HexCopyableRow` wrapper
- [ ] **I5.4.3** — Implement byte highlighting selection
- [ ] **I5.4.4** — Performance test: 1MB hex display
- [ ] **I5.4.5** — Snapshot tests for hex rendering
- [ ] **I5.4.6** — Accessibility: hex content readable to screen readers

**Success Criteria:**
- ✅ Hex viewer using DS typography
- ✅ Copy functionality for hex ranges
- ✅ Performance: <50ms render time
- ✅ Accessibility: selectable text properly announced

---

### Phase 6: Full App Integration & Validation (Week 9)
**Duration:** 5-7 days
**Status:** ⏳ Pending
**Effort:** High

Complete integration, validation, and release preparation.

#### 6.1 Integration Testing Suite
**Priority:** P6 | **Effort:** 2-3 days | **Risk:** Medium

Comprehensive end-to-end tests covering all integrated FoundationUI components.

**Test Suites to Create:**
```
Tests/ISOInspectorAppTests/FoundationUI/IntegrationTests/
├── AppLaunchTests.swift                    — App startup with FoundationUI
├── NavigationFlowTests.swift               — Sidebar/patterns navigation
├── EditingFlowTests.swift                  — Search/filter/select/view details
├── AccessibilityFlowTests.swift            — VoiceOver + keyboard complete flow
├── DarkModeIntegrationTests.swift          — Light/dark/high-contrast modes
├── PlatformAdaptationTests.swift           — macOS/iOS/iPadOS layouts
├── PerformanceIntegrationTests.swift       — Memory, CPU, render time
└── SnapshotIntegrationTests.swift          — Visual regression across platforms
```

**Subtasks:**
- [ ] **I6.1.1** — Create app launch test (no crashes)
- [ ] **I6.1.2** — Navigation flow: sidebar → tree → details
- [ ] **I6.1.3** — Search/filter workflow integration
- [ ] **I6.1.4** — Export workflow integration
- [ ] **I6.1.5** — Dark mode switching integration
- [ ] **I6.1.6** — Accessibility compliance: WCAG 2.1 AA
- [ ] **I6.1.7** — Platform-specific tests (shortcuts, gestures)
- [ ] **I6.1.8** — Performance baselines: memory, CPU, battery
- [ ] **I6.1.9** — Visual regression snapshots (all platforms)

**Success Criteria:**
- ✅ 100% app launch success rate
- ✅ All navigation flows functional
- ✅ WCAG 2.1 AA compliance verified
- ✅ Performance within budget (see metrics below)
- ✅ Zero snapshot regressions

---

#### 6.2 Performance Validation
**Priority:** P6 | **Effort:** 1-2 days | **Risk:** Medium

**Performance Budgets:**
```
Metric                      Target        Measurement Tool
─────────────────────────────────────────────────────────
App Launch Time             <2s           XCTest + Instruments
Tree Render (1000 nodes)    <500ms        XCTest Benchmark
Tree Scroll FPS             ≥55fps        Instruments (CoreAnimation)
Memory (idle)               <100MB        Xcode Memory Debugger
Memory (1000 nodes)         <250MB        Xcode Memory Debugger
Binary Size Impact          <10%          xcodesign + dsymutil
```

**Subtasks:**
- [ ] **I6.2.1** — Measure app launch time (baseline + FoundationUI)
- [ ] **I6.2.2** — Profile tree rendering (1000 node benchmark)
- [ ] **I6.2.3** — Monitor memory during expand/collapse cycles
- [ ] **I6.2.4** — Scroll performance FPS monitoring
- [ ] **I6.2.5** — Binary size analysis
- [ ] **I6.2.6** — Identify and optimize bottlenecks

**Success Criteria:**
- ✅ App launch <2s
- ✅ Tree scroll ≥55fps
- ✅ Memory leak-free
- ✅ Binary size increase <10%

---

#### 6.3 Documentation & Migration Guide
**Priority:** P6 | **Effort:** 2-3 days | **Risk:** Low

**Documents to Create/Update:**
- [ ] **I6.3.1** — Update 03_Technical_Spec.md with full integration details
- [ ] **I6.3.2** — Create MIGRATION.md documenting old → new component mapping
- [ ] **I6.3.3** — Create INTEGRATION_GUIDE.md for future FoundationUI updates
- [ ] **I6.3.4** — API documentation for all new wrapper components
- [ ] **I6.3.5** — Add integration examples to ComponentShowcase

**Files to Create:**
```
DOCS/AI/ISOInspector_Execution_Guide/MIGRATION.md (NEW)
DOCS/AI/ISOInspector_Execution_Guide/INTEGRATION_GUIDE.md (NEW)
DOCS/INPROGRESS/FoundationUI_Integration_Completed.md (NEW)
```

**Success Criteria:**
- ✅ All migration paths documented
- ✅ Integration guide covers all scenarios
- ✅ API documentation complete
- ✅ Examples runnable in ComponentShowcase

---

#### 6.4 Beta Testing & Rollout
**Priority:** P6 | **Effort:** 2-3 days | **Risk:** Medium

**Testing Plan:**
```
1. Internal Testing (1 day)
   - All team members test on own devices
   - File bug reports in GitHub Issues

2. Beta Testers (3 days)
   - 5-10 external testers on TestFlight
   - Gather feedback on performance, crashes, UX

3. Release Validation (1 day)
   - Fix critical bugs
   - Prepare release notes
```

**Success Criteria:**
- ✅ Zero critical bugs in beta
- ✅ Positive feedback from beta testers
- ✅ Performance metrics confirmed
- ✅ Ready for production release

---

## 📊 Integration Roadmap

```
Week 1     Phase 0: Setup & Verification
├─ I0.1 Add FoundationUI dependency ⏳
├─ I0.2 Create integration test suite ⏳
├─ I0.3 Component Showcase ⏳
├─ I0.4 Documentation ⏳
└─ I0.5 Technical spec updates ⏳

Week 2-3   Phase 1: Foundation Components
├─ I1.1 Badges & Indicators (1-2d)
├─ I1.2 Cards & Sections (2-3d)
└─ I1.3 Key-Value Rows (2-3d)

Week 4-5   Phase 2: Interactive Components
├─ I2.1 Copyable Text (1-2d)
├─ I2.2 Interactive Styles (2-3d)
└─ I2.3 Surface Material (1-2d)

Week 5-7   Phase 3: Layout Patterns
├─ I3.1 Sidebar Pattern (3-4d)
├─ I3.2 Inspector Pattern (2-3d)
├─ I3.3 Tree Box Pattern (3-4d)
└─ I3.4 Toolbar Pattern (1-2d)

Week 7-8   Phase 4: Adaptation & Contexts
├─ I4.1 Platform Adaptation (1-2d)
├─ I4.2 Accessibility Contexts (2-3d)
└─ I4.3 Dark Mode Integration (1-2d)

Week 8-9   Phase 5: Advanced Features
├─ I5.1 Search & Filter (2-3d)
├─ I5.2 Progress & Async (2-3d)
├─ I5.3 Export & Share (2-3d)
└─ I5.4 Hex Viewer (2-3d)

Week 9     Phase 6: Full Integration
├─ I6.1 Integration Testing (2-3d)
├─ I6.2 Performance Validation (1-2d)
├─ I6.3 Documentation (2-3d)
└─ I6.4 Beta & Rollout (2-3d)

TOTAL: 9 weeks (45 working days)
```

---

## 🎯 Success Criteria (All Phases)

### Code Quality
- ✅ SwiftLint: 0 violations (strict mode)
- ✅ Test Coverage: ≥80% per phase
- ✅ Type Safety: No `@unchecked Sendable`
- ✅ Concurrency: All actors/tasks properly isolated

### Testing
- ✅ Unit Tests: 300+ total (all phases)
- ✅ Snapshot Tests: 150+ visual regressions
- ✅ Accessibility Tests: 150+ a11y checks
- ✅ Integration Tests: 50+ end-to-end flows
- ✅ Performance Tests: Memory, CPU, render time

### Documentation
- ✅ API docs: 100% coverage (DocC)
- ✅ Migration guide: Complete old→new mapping
- ✅ Technical spec: Updated per phase
- ✅ Examples: All components in ComponentShowcase

### Accessibility
- ✅ WCAG 2.1 AA compliance
- ✅ VoiceOver: All content readable
- ✅ Keyboard: All features accessible
- ✅ Color: No color-only differentiation
- ✅ Motion: Respect Reduce Motion setting
- ✅ Audit Score: ≥98%

### Performance
- ✅ App Launch: <2s
- ✅ Tree Scroll: ≥55fps (1000 nodes)
- ✅ Memory: No leaks, <250MB (large files)
- ✅ Binary Size: <10% increase
- ✅ Battery: No regression vs. baseline

### User Experience
- ✅ Dark Mode: Fully functional
- ✅ Platform Adaptation: Correct on macOS/iOS/iPadOS
- ✅ Responsiveness: No freezing, smooth animations
- ✅ Consistency: All UI elements follow DS guidelines
- ✅ Error Handling: Clear error messages to users

---

## 🔄 Iteration & Feedback Loop

### Weekly Reviews
```
Every Friday (End of Phase):
- Review completed tasks (code + tests)
- Run full test suite (unit + snapshot + integration)
- Performance baseline measurements
- Accessibility audit (automated + manual)
- Document decisions in next_tasks.md
- Plan next week's priorities
```

### Phase Gate Criteria
**Before proceeding to next phase:**
1. ✅ All tasks in current phase complete
2. ✅ Tests pass (unit + integration + snapshots)
3. ✅ Code review approved
4. ✅ No performance regressions
5. ✅ Accessibility audit ≥95%
6. ✅ Documentation updated

### Rollback Plan
**If critical issues found:**
```
1. Identify affected components (via test failures)
2. Revert latest changes (git revert)
3. Create hotfix branch (branch off main)
4. Fix issue + add regression test
5. Re-test all dependent components
6. Merge after approval
7. Resume phased integration from next component
```

---

## 📝 Decision Log

### Decision 1: Gradual vs. Big Bang
**Date:** 2025-11-12
**Decision:** Gradual, phased integration (9 weeks)
**Rationale:**
- Safer for production app (minimize risk of regressions)
- Allows testing each component independently
- Enables parallel work (multiple phases simultaneously)
- Provides clear feedback loops and validation points

### Decision 2: Phase 0 (Setup)
**Date:** 2025-11-12
**Decision:** Add Phase 0 for dependency setup and test infrastructure
**Rationale:**
- Ensures FoundationUI builds correctly in ISOInspectorApp context
- Establishes integration test patterns before actual integration
- Creates Component Showcase for development velocity

### Decision 3: Phase Sequencing
**Date:** 2025-11-12
**Decision:** Foundation → Interactive → Patterns → Contexts → Advanced → Integration
**Rationale:**
- Dependencies: Patterns depend on Components depend on Foundation
- Risk: Low-risk components first (Foundation), high-risk later (Patterns)
- Testability: Each phase builds on previous tests

### Decision 4: Accessibility as Cross-Cutting Concern
**Date:** 2025-11-12
**Decision:** Accessibility tests in every phase, not a separate phase
**Rationale:**
- WCAG 2.1 AA compliance must be maintained throughout
- Accessibility == core feature, not "nice to have"
- Testing early catches issues before they compound

---

## 🚨 Known Risks & Mitigation

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Large tree rendering slow | Medium | Phase 3.3 includes virtualization + performance tests |
| Dark mode colors inconsistent | Low | Phase 4.3 centralizes via ColorSchemeAdapter |
| Navigation conflicts | Medium | Careful state management review + integration tests |
| Binary size increase | Low | Monitor in Phase 6.2, optimize if needed |
| Accessibility regressions | Medium | 98%+ audit score + 150+ a11y tests |
| Platform-specific bugs | Medium | Snapshot tests on all 3 platforms |

---

## 📚 Dependencies & Prerequisites

### FoundationUI Status
- ✅ Foundation (Layer 0) — Complete
- ✅ Components (Layer 2) — Complete (95.7%)
- ✅ Patterns (Layer 3) — Complete
- ✅ Contexts (Layer 4) — Complete

### ISOInspectorApp Status
- ✅ Core parsing — Complete
- ✅ Current UI — Functional
- ⏳ FoundationUI integration — Pending

### External Dependencies
- ✅ Swift 5.9+
- ✅ iOS 17+, iPadOS 17+, macOS 14+
- ✅ Xcode 15+

---

## 📞 Communication & Handoff

### Documentation Updates
- Update `DOCS/INPROGRESS/next_tasks.md` after each phase
- Archive completed phases to `DOCS/TASKS_ARCHIVE/`
- Publish milestone summaries weekly

### Team Synchronization
- Weekly standups (Monday/Friday)
- Slack #iso-inspector-foundationui channel
- GitHub issues for bug tracking

### External Communication
- Product updates on ISOInspector website
- Beta tester feedback loop
- Release notes for v1.0-foundationui

---

## ✅ Next Actions (Immediate)

1. **I0.1** — Add FoundationUI dependency to ISOInspectorApp Package.swift
2. **I0.2** — Create integration test directory structure
3. **I0.3** — Build Component Showcase view
4. **I0.4** — Document integration patterns in Technical Spec
5. **I0.5** — Update Design System Guide with integration checklist

**Estimated Duration:** 3-4 days
**Start Date:** 2025-11-12
**Target Completion:** 2025-11-15

---

**Document Version:** 1.0
**Last Updated:** 2025-11-12
**Status:** Planning Phase
**Author:** Claude (AI Assistant)
**Approval:** Pending
