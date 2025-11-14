# DESIGN SYSTEM GUIDE — Composable Clarity

**Project:** ISO Inspector / 0AL Design System  
**Version:** 1.0  
**Author:** 0AL Core Design  
**Applies to:** macOS, iPadOS, iOS (SwiftUI, Agent-driven UI generation)

---

## 1. Core Principle

> **Composable Clarity** — это подход, в котором каждый элемент интерфейса выражает свой смысл через простые, независимые и сочетаемые атомы (ViewModifier, Token, Pattern).  
> UI не рисуется — он **собирается из смыслов**.

---

## 2. Design Values

| Value | Description | Manifestation |
|--------|--------------|----------------|
| **Clarity** | Простая визуальная иерархия | Свет, типографика, отступы вместо рамок |
| **Composition** | Всё строится из атомов | Любая часть может стать новым паттерном |
| **Autonomy** | Самодостаточные компоненты | Легко тестировать и копировать |
| **Semantic consistency** | Цвет и форма = смысл | Один смысл → одно визуальное проявление |
| **Constraint** | Минимализм как стиль | Ограниченный набор токенов и правил |

---

## 3. System Architecture

### Layer 0 — Tokens
Единственный источник числовых значений.

```swift
enum DS {
    enum Spacing { static let s = 8.0; static let m = 12.0; static let l = 16.0 }
    enum Radius  { static let card = 10.0; static let chip = 999.0 }
    enum Font    { static let label = Font.caption2.weight(.semibold) }
    enum Color {
        static let infoBG  = Color.gray.opacity(0.18)
        static let warnBG  = Color.orange.opacity(0.22)
        static let errorBG = Color.red.opacity(0.22)
    }
}
```

---

### Layer 1 — Modifiers (Atoms)
Описывают поведение и стиль без контекста.

```swift
struct BadgeChipStyle: ViewModifier {
    let level: BadgeLevel
    func body(content: Content) -> some View {
        content
            .font(DS.Font.label)
            .textCase(.uppercase)
            .padding(.vertical, DS.Spacing.s / 2)
            .padding(.horizontal, DS.Spacing.m / 2)
            .background(background, in: Capsule())
    }
    private var background: Color {
        switch level {
        case .info: DS.Color.infoBG
        case .warning: DS.Color.warnBG
        case .error: DS.Color.errorBG
        }
    }
}
```

---

### Layer 2 — Components (Molecules)

Комбинация модификаторов + семантика.

```swift
struct Badge: View {
    let text: String
    let level: BadgeLevel
    var body: some View {
        Text(text)
            .modifier(BadgeChipStyle(level: level))
    }
}
```

---

### Layer 3 — Patterns (Organisms)

Собранные участки интерфейса:
- `SidebarPattern`
- `BoxTreePattern`
- `InspectorPattern`
- `ToolbarPattern`

**Пример:**

```swift
struct InspectorPattern: View {
    let box: MP4Box
    var body: some View {
        ScrollView {
            InspectorSection(title: "METADATA") { MetadataGrid(box: box) }
            InspectorSection(title: "VALIDATION") { ValidationList(box: box) }
            InspectorSection(title: "HEX") { HexView(data: box.payload) }
        }
        .padding(.horizontal, DS.Spacing.l)
        .background(.thinMaterial)
    }
}
```

---

### Layer 4 — Contexts (Themes)

Определяют визуальную плотность, фон и материалы.

```swift
extension EnvironmentValues {
    var surfaceStyle: Material { get { self[SurfaceStyleKey.self] } set { self[SurfaceStyleKey.self] = newValue } }
}
```

---

## 4. Visual & Interaction Rules

| Aspect | Rule |
|---------|------|
| **Typography** | SF Pro Rounded / SF Mono; smallCaps для секций |
| **Spacing** | 8 → 12 → 16 pt step grid |
| **Radius** | 8–10 pt (card), capsule для бейджей |
| **Colors** | Только системные; Info / Warning / Error через прозрачные оттенки |
| **Depth** | Материалы и прозрачность вместо теней |
| **Animation** | 100–250 мс, `.snappy` или `.easeInOut` |
| **Accessibility** | Контраст ≥ 4.5 : 1, копирование, VoiceOver |
| **Copyability** | Все значения интерактивны (копируются) |
| **Keyboard** | ⌘ I — Inspector, ⌘ F — поиск, ↑ ↓ — навигация |

---

## 5. Semantic Composition Rules

1. **Semantic before visual.**  
   Любое свойство определяется смыслом: *warning*, *info*, *metadata*.

2. **Local responsibility.**  
   Компонент сам управляет состоянием hover/focus/copy.

3. **Environment over globals.**  
   Общие параметры (цвета, плотность) передаются через `Environment`.

4. **Predictable Composability.**  
   Компоненты не ломаются при вложении.

5. **Zero magic numbers.**  
   Только токены.

6. **Soft motion.**  
   Минимальная, согласованная анимация.

7. **Shadowless depth.**  
   Иерархия строится светом, не тенью.

---

## 6. Example — Badge Composition Flow

```
[TOKENS] + [MODIFIER] → [COMPONENT] → [PATTERN] → [CONTEXT]
```

**Пример:**
```swift
DS.Color.errorBG + BadgeChipStyle → Badge → ValidationList → InspectorPattern
```

---

## 7. The Agent Rule (for 0AL / Hypercode)

Агенты могут описывать UI декларативно:

```yaml
component: Badge
props:
  text: "ERROR"
  level: error
appearance:
  uses: DS.BadgeChipStyle
semantics: "critical validation state"
```

Любой агент, читающий этот YAML, может визуализировать интерфейс, соблюдая правила токенов и модификаторов.

---

## 8. Manifesto

> **Composable Clarity** — это язык проектирования, где форма = функция,  
> ограничения = стиль,  
> а дизайн = декларация смысла.  
>
> Каждый элемент — объясним, копируем и переиспользуем.  
> Так рождается системная красота.

---

## 9. FoundationUI Integration

### 9.1 Overview

**FoundationUI** is a comprehensive SwiftUI design system implementing the **Composable Clarity** principles at scale. It provides production-ready components, patterns, and contexts that align with the 0AL design philosophy while adding enterprise-grade testing, accessibility, and platform adaptation.

**Integration Status:**
- ✅ **Phase 0 Complete** — Dependency added, test suite created (123 tests), documentation complete
- ⏳ **Phase 1 Pending** — Foundation components (Badge, Card, KeyValueRow) migration
- 📋 **Phases 2-6 Planned** — Interactive components, patterns, contexts, advanced features

**Key Resources:**
- **Component Showcase:** `Examples/ComponentTestApp/` — Interactive demo app with 14+ screens
- **Integration Tests:** `Tests/ISOInspectorAppTests/FoundationUI/` — 123 comprehensive tests
- **Integration Patterns:** `DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md` — Code examples and architecture
- **Phased Roadmap:** `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md` — 9-week plan

---

### 9.2 FoundationUI Integration Checklist

Before integrating any FoundationUI component into ISOInspectorApp, verify:

#### Design Token Usage ✅
- [ ] All spacing uses `DS.Spacing` tokens (never magic numbers)
- [ ] All colors use `DS.Colors` semantic tokens (`.infoBG`, `.warnBG`, `.errorBG`, etc.)
- [ ] All typography uses `DS.Typography` tokens (`.label`, `.body`, `.caption`, etc.)
- [ ] All animations use `DS.Animation.Timing` predefined curves (`.quick`, `.standard`, `.slow`)
- [ ] No hardcoded platform-specific values (use `@Environment(\.platformAdaptation)` instead)

#### Component Wrapper Pattern ✅
- [ ] FoundationUI component wrapped with domain-specific semantics (e.g., `BoxStatusBadge`, `BoxMetadataCard`)
- [ ] FoundationUI types not exposed in business logic layer (encapsulated within wrapper)
- [ ] Wrapper component documented with DocC comments and usage examples
- [ ] Wrapper follows "One File — One Entity" principle from `07_AI_Code_Structure_Principles.md`

#### Testing Requirements ✅
- [ ] **Unit Tests:** All initialization paths covered (≥80% coverage target)
- [ ] **Snapshot Tests:** Light/dark modes and all component states verified
- [ ] **Accessibility Tests:** VoiceOver labels, keyboard navigation, color contrast validated
- [ ] **Integration Tests:** Component composition patterns tested end-to-end
- [ ] Test suite follows patterns from `Tests/ISOInspectorAppTests/FoundationUI/`

#### Platform Compatibility ✅
- [ ] Component tested on **iOS 17+** (iPhone SE, Pro, Pro Max)
- [ ] Component tested on **macOS 14+** (multiple window sizes, trackpad interaction)
- [ ] Component tested on **iPadOS 17+** (all size classes, portrait/landscape orientations)
- [ ] Platform-specific adaptations use `@Environment(\.platformAdaptation)` context
- [ ] No conditional `#if os(macOS)` blocks (use environment-driven adaptation)

#### Accessibility Compliance ✅
- [ ] **WCAG 2.1 AA:** ≥98% accessibility audit score achieved
- [ ] **VoiceOver:** Labels clear, descriptive, and contextually meaningful
- [ ] **Keyboard Navigation:** All interactive elements reachable via Tab, Return, Escape
- [ ] **Dynamic Type:** All text scales correctly (size categories XS through XXXL)
- [ ] **Color Contrast:** ≥4.5:1 for normal text, ≥3:1 for large text
- [ ] **Reduce Motion:** Animations respect system preference
- [ ] **High Contrast:** Component adapts to high contrast mode

#### Documentation ✅
- [ ] Component wrapper documented with DocC comments (description, parameters, examples)
- [ ] Usage examples added to `Examples/ComponentTestApp/` showcase screens
- [ ] Migration notes documented (if replacing legacy component)
- [ ] Cross-references added to `03_Technical_Spec.md` integration patterns

#### Build Quality Gates ✅
- [ ] **SwiftLint:** 0 violations (strict mode)
- [ ] **Compiler:** 0 warnings
- [ ] **Tests:** All passing (unit + snapshot + accessibility + integration)
- [ ] **Code Coverage:** ≥80% per module
- [ ] **Accessibility Audit:** ≥98% score

---

### 9.3 Migration Path: Old UI Patterns → FoundationUI

#### Component Mapping Table

| Old Pattern | FoundationUI Component | Migration Priority | Phase | Effort |
|-------------|----------------------|-------------------|-------|--------|
| Manual badge styling with `Text + Capsule` | `DS.Badge` | P1 | Phase 1 | 1-2d |
| Manual card containers with `VStack + background` | `DS.Card` | P1 | Phase 1 | 2-3d |
| Manual key-value rows with `HStack` | `DS.KeyValueRow` | P1 | Phase 1 | 2-3d |
| Manual copy buttons via `NSPasteboard`/`UIPasteboard` | `DS.Copyable` | P2 | Phase 2 | 1-2d |
| Manual hover/press state with `@State` | `DS.InteractiveStyle` | P2 | Phase 2 | 2-3d |
| Manual surface backgrounds | `DS.SurfaceStyle` | P2 | Phase 2 | 1-2d |
| Manual sidebar with `NavigationSplitView` | `DS.SidebarPattern` | P3 | Phase 3 | 3-4d |
| Manual inspector layout with `ScrollView` | `DS.InspectorPattern` | P3 | Phase 3 | 2-3d |
| Manual tree view with `OutlineGroup` | `DS.BoxTreePattern` | P3 | Phase 3 | 3-4d |
| Manual toolbar with `ToolbarItem` | `DS.ToolbarPattern` | P3 | Phase 3 | 1-2d |

**Total Estimated Effort:** 9 weeks (45 working days)

---

#### Migration Workflow (Step-by-Step)

**Step 1: Identify Component to Migrate**
- Review current UI code for manual implementations
- Consult mapping table above for FoundationUI equivalent
- Verify component is prioritized for current phase

**Step 2: Review FoundationUI Component API**
- Study `Examples/ComponentTestApp/` showcase screens
- Read FoundationUI component DocC documentation
- Review integration tests in `Tests/ISOInspectorAppTests/FoundationUI/`

**Step 3: Create Domain-Specific Wrapper**
```swift
// ✅ GOOD: Domain-specific wrapper encapsulates FoundationUI
import FoundationUI

struct BoxStatusBadge: View {
    let status: ParseStatus  // Domain type

    var body: some View {
        DS.Badge(text: status.displayText, level: status.badgeLevel)
            .accessibilityLabel(status.accessibilityLabel)
    }
}

private extension ParseStatus {
    var badgeLevel: BadgeLevel {
        switch self {
        case .valid: .success
        case .warning: .warning
        case .error: .error
        case .info: .info
        }
    }
}
```

**Step 4: Write Comprehensive Tests**
```swift
final class BoxStatusBadgeTests: XCTestCase {
    func testBadgeRendersForAllStatuses() {
        for status in ParseStatus.allCases {
            let badge = BoxStatusBadge(status: status)
            XCTAssertNotNil(badge.body)
        }
    }

    func testAccessibilityLabelsAreDescriptive() {
        let badge = BoxStatusBadge(status: .error)
        // Verify VoiceOver label clarity
    }
}
```

**Step 5: Update UI to Use Wrapper**
```swift
// ❌ OLD: Manual badge implementation
Text(status.rawValue)
    .font(.caption2.weight(.semibold))
    .textCase(.uppercase)
    .padding(.vertical, 4)
    .padding(.horizontal, 6)
    .background(statusColor, in: Capsule())

// ✅ NEW: FoundationUI-based wrapper
BoxStatusBadge(status: status)
```

**Step 6: Verify Accessibility**
- Run VoiceOver on iOS and macOS
- Test keyboard navigation (Tab order, focus indicators)
- Verify Dynamic Type scaling (XS to XXXL)
- Check color contrast with accessibility inspector
- Test Reduce Motion and High Contrast modes

**Step 7: Archive Old Implementation**
- Move legacy code to `DOCS/TASK_ARCHIVE/{task_number}/legacy/`
- Document migration in `Summary_of_Work.md`
- Update `next_tasks.md` marking component as migrated

---

#### Before/After Code Examples

**Example 1: Badge Component**

```swift
// ❌ BEFORE: Manual implementation with magic numbers
struct LegacyBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .padding(.vertical, 4)       // ❌ Magic number
            .padding(.horizontal, 6)     // ❌ Magic number
            .background(color, in: Capsule())
    }
}

// ✅ AFTER: FoundationUI with design tokens
struct BoxStatusBadge: View {
    let status: ParseStatus

    var body: some View {
        DS.Badge(text: status.displayText, level: status.badgeLevel)
            .accessibilityLabel(status.accessibilityLabel)
    }
}
```

**Example 2: Card Component**

```swift
// ❌ BEFORE: Manual card with inconsistent styling
VStack(alignment: .leading, spacing: 8) {
    Text("Metadata")
        .font(.headline)
    ForEach(fields) { field in
        HStack {
            Text(field.key)
            Spacer()
            Text(field.value)
        }
    }
}
.padding(16)                           // ❌ Magic number
.background(.regularMaterial)
.cornerRadius(10)                      // ❌ Magic number

// ✅ AFTER: FoundationUI with semantic elevation
DS.Card(elevation: .medium) {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        DS.SectionHeader(title: "Metadata")
        ForEach(fields) { field in
            DS.KeyValueRow(key: field.key, value: field.value)
        }
    }
}
```

**Example 3: KeyValueRow Component**

```swift
// ❌ BEFORE: Manual row with copy button
HStack {
    Text(key)
        .foregroundColor(.secondary)
    Spacer()
    Text(value)
        .font(.system(.body, design: .monospaced))
    Button(action: { copyToClipboard(value) }) {
        Image(systemName: "doc.on.doc")
    }
}

// ✅ AFTER: FoundationUI with built-in copyable
DS.KeyValueRow(
    key: key,
    value: value,
    layout: .horizontal,
    copyable: true
)
.font(.monospaced)  // FoundationUI respects custom fonts
```

---

#### Common Pitfalls & Solutions

**Pitfall 1: Mixing FoundationUI with Legacy UI**
```swift
// ❌ BAD: Mixing old and new patterns in same screen
VStack {
    LegacyBadge(text: "ERROR", color: .red)  // Old
    DS.Card { ... }                           // New FoundationUI
}

// ✅ GOOD: Consistent FoundationUI usage
VStack {
    DS.Badge(text: "ERROR", level: .error)   // FoundationUI
    DS.Card { ... }                           // FoundationUI
}
```

**Pitfall 2: Hardcoding Spacing Instead of Using Tokens**
```swift
// ❌ BAD: Magic numbers
.padding(12)
.spacing(8)

// ✅ GOOD: Design tokens
.padding(DS.Spacing.m)
.spacing(DS.Spacing.s)
```

**Pitfall 3: Skipping Accessibility Tests**
```swift
// ❌ BAD: No accessibility verification
func testBadgeRenders() {
    let badge = BoxStatusBadge(status: .error)
    XCTAssertNotNil(badge.body)
}

// ✅ GOOD: Comprehensive accessibility coverage
func testBadgeAccessibility() {
    let badge = BoxStatusBadge(status: .error)

    // VoiceOver label
    XCTAssertEqual(badge.accessibilityLabel, "Error: Validation failed")

    // Color contrast (automated check via snapshot test)
    assertSnapshot(matching: badge, as: .accessibilityImage)

    // Dynamic Type scaling
    for sizeCategory in ContentSizeCategory.allCases {
        let view = badge.environment(\.sizeCategory, sizeCategory)
        assertSnapshot(matching: view, as: .image)
    }
}
```

**Pitfall 4: Not Using Platform Adaptation Contexts**
```swift
// ❌ BAD: Platform-specific conditionals
#if os(macOS)
    .padding(12)
#else
    .padding(16)
#endif

// ✅ GOOD: Environment-driven adaptation
@Environment(\.platformAdaptation) var platform

var padding: CGFloat {
    platform.spacing.medium  // Automatically 12pt on macOS, 16pt on iOS
}
```

---

### 9.4 Quality Gates Per Integration Phase

Each integration phase has specific quality criteria that must be met before proceeding to the next phase.

---

#### Phase 0: Setup & Verification ✅ **COMPLETE**

**Objective:** Establish FoundationUI infrastructure and integration patterns

**Before Proceeding to Phase 1:**
- [x] FoundationUI dependency builds successfully in ISOInspectorApp
- [x] Integration test suite structure created (`Tests/ISOInspectorAppTests/FoundationUI/`)
- [x] ComponentTestApp runs without crashes on all platforms
- [x] Integration patterns documented in `03_Technical_Spec.md`
- [x] Design System Guide updated with FoundationUI integration checklist

**Validation Metrics:**
- [x] **Tests:** 123 integration tests passing (Badge: 33, Card: 43, KeyValueRow: 40, Integration: 7)
- [x] **Code Coverage:** ≥80% for integration test suite
- [x] **SwiftLint:** 0 violations
- [x] **Compiler:** 0 warnings
- [x] **Documentation:** All Phase 0 tasks (I0.1-I0.5) documented

**Completion Date:** 2025-11-14

---

#### Phase 1: Foundation Components (Weeks 2-3) ⏳ **PENDING**

**Objective:** Migrate Badge, Card, and KeyValueRow components

**Tasks:**
- [ ] I1.1 — Badge & Status Indicators (1-2d)
- [ ] I1.2 — Card Containers & Sections (2-3d)
- [ ] I1.3 — Key-Value Rows & Metadata (2-3d)

**Before Proceeding to Phase 2:**
- [ ] All manual badges replaced with `DS.Badge` wrappers
- [ ] All card containers using `DS.Card` with appropriate elevation
- [ ] All metadata displays using `DS.KeyValueRow`
- [ ] Zero magic numbers in spacing/sizing (100% design token usage)
- [ ] Comprehensive test coverage for all wrappers

**Validation Metrics:**
- [ ] **Tests:** ≥90% unit test coverage for component wrappers
- [ ] **Snapshot Tests:** Light/dark modes verified for all component states
- [ ] **Accessibility:** ≥98% audit score maintained
- [ ] **Build Time:** <5% increase from Phase 0 baseline
- [ ] **SwiftLint:** 0 violations
- [ ] **Visual QA:** All migrated components match ComponentTestApp reference

**Success Criteria:**
- [ ] Code review approved by technical lead
- [ ] No regressions in existing UI functionality
- [ ] Performance benchmarks within tolerance (render time <16ms)
- [ ] Accessibility tests passing on all platforms

---

#### Phase 2: Interactive Components & Modifiers (Weeks 3-4) ⏳ **PENDING**

**Objective:** Add interactivity (Copyable, InteractiveStyle, SurfaceStyle)

**Tasks:**
- [ ] I2.1 — Copyable Text & Actions (1-2d)
- [ ] I2.2 — Interactive Styles & Hover Effects (2-3d)
- [ ] I2.3 — Surface Material & Elevation (1-2d)

**Before Proceeding to Phase 3:**
- [ ] All copyable text using `DS.Copyable` wrapper
- [ ] All interactive elements applying `DS.InteractiveStyle`
- [ ] All surfaces using `DS.SurfaceStyle` environment key
- [ ] Platform-specific feedback verified (hover on macOS, touch on iOS)

**Validation Metrics:**
- [ ] **Tests:** ≥85% coverage for interaction handlers
- [ ] **Platform Tests:** macOS hover + iOS touch feedback verified
- [ ] **Accessibility:** Keyboard shortcuts functional, VoiceOver announcements correct
- [ ] **Performance:** No frame drops during interactions (≥55fps)

**Success Criteria:**
- [ ] Copy functionality works on all platforms
- [ ] Hover/touch feedback consistent with HIG
- [ ] No accessibility conflicts introduced
- [ ] Dark mode shadow/elevation rendering correct

---

#### Phase 3: Layout Patterns & Navigation (Weeks 5-7) ⏳ **PENDING**

**Objective:** Migrate complex structural patterns (Sidebar, Inspector, Tree, Toolbar)

**Tasks:**
- [ ] I3.1 — Sidebar Pattern (3-4d)
- [ ] I3.2 — Inspector Pattern (2-3d)
- [ ] I3.3 — Tree Box Pattern (3-4d)
- [ ] I3.4 — Toolbar Pattern (1-2d)

**Before Proceeding to Phase 4:**
- [ ] Sidebar navigation using `DS.SidebarPattern`
- [ ] Detail inspector using `DS.InspectorPattern`
- [ ] Box tree using `DS.BoxTreePattern` with lazy rendering
- [ ] Toolbar using `DS.ToolbarPattern` with adaptive layout

**Validation Metrics:**
- [ ] **Performance:** Tree renders 1000+ nodes in <500ms
- [ ] **Memory:** No leaks during expand/collapse (verified with Instruments)
- [ ] **Scroll Performance:** ≥55fps on all platforms
- [ ] **Accessibility:** VoiceOver tree navigation functional
- [ ] **Keyboard:** Arrow key navigation working

**Success Criteria:**
- [ ] Large tree (10,000 nodes) renders without freezing
- [ ] Platform-specific adaptations correct (sidebar collapse on iPad, etc.)
- [ ] No regressions in navigation flow
- [ ] Visual hierarchy clear and consistent

---

#### Phase 4: Platform Adaptation & Contexts (Week 8) ⏳ **PENDING**

**Objective:** Apply environment contexts for platform-specific behavior

**Tasks:**
- [ ] I4.1 — Platform Adaptation (1-2d)
- [ ] I4.2 — Accessibility Contexts (2-3d)
- [ ] I4.3 — Color Scheme & Dark Mode (1-2d)

**Before Proceeding to Phase 5:**
- [ ] All platform-specific spacing/sizing using `@Environment(\.platformAdaptation)`
- [ ] Accessibility contexts applied (Reduce Motion, Increase Contrast, Dynamic Type, Bold Text)
- [ ] Dark mode rendering verified on all components
- [ ] Zero hardcoded colors remaining

**Validation Metrics:**
- [ ] **Platform Tests:** Snapshots verified on iOS 17, macOS 14, iPadOS 17
- [ ] **Accessibility:** WCAG 2.1 AA compliance ≥98%
- [ ] **Dynamic Type:** All text scales XS to XXXL without clipping
- [ ] **Color Contrast:** Automated checks passing

**Success Criteria:**
- [ ] No conditional `#if os(macOS)` blocks (100% environment-driven)
- [ ] Accessibility audit score maintained
- [ ] Dark mode + High Contrast combinations working
- [ ] Performance impact <2%

---

#### Phase 5: Advanced Features & Integration (Week 9) ⏳ **PENDING**

**Objective:** Integrate advanced FoundationUI features with ISOInspector business logic

**Tasks:**
- [ ] I5.1 — Search & Filter with DS Components (2-3d)
- [ ] I5.2 — Progress & Async Streaming (2-3d)
- [ ] I5.3 — Export & Share Actions (2-3d)
- [ ] I5.4 — Hex Viewer Enhancement (2-3d)

**Before Proceeding to Phase 6:**
- [ ] Search UI using FoundationUI typography/spacing
- [ ] Progress indicators connected to async parsing streams
- [ ] Export modal using FoundationUI design system
- [ ] Hex viewer using `DS.Typography.monospaced`

**Validation Metrics:**
- [ ] **Search Performance:** <100ms for 10K boxes
- [ ] **Async UI:** No freezing during large file parsing
- [ ] **Export UI:** All platforms functional
- [ ] **Hex Performance:** <50ms render time for 1MB display

**Success Criteria:**
- [ ] Search keyboard shortcuts working (⌘F)
- [ ] Progress announcements via Live Region (accessibility)
- [ ] Share sheet integration verified
- [ ] Hex content readable to screen readers

---

#### Phase 6: Full Integration & Validation (Week 10) ⏳ **PENDING**

**Objective:** Complete integration, validation, and release preparation

**Tasks:**
- [ ] I6.1 — Integration Testing Suite (2-3d)
- [ ] I6.2 — Performance Validation (1-2d)
- [ ] I6.3 — Documentation & Migration Guide (2-3d)
- [ ] I6.4 — Beta Testing & Rollout (2-3d)

**Before Release:**
- [ ] 100% app launch success rate
- [ ] All navigation flows functional
- [ ] WCAG 2.1 AA compliance verified
- [ ] Performance within budget (see metrics below)
- [ ] Zero snapshot regressions

**Performance Budgets:**
| Metric | Target | Measurement Tool |
|--------|--------|------------------|
| App Launch Time | <2s | XCTest + Instruments |
| Tree Render (1000 nodes) | <500ms | XCTest Benchmark |
| Tree Scroll FPS | ≥55fps | Instruments (CoreAnimation) |
| Memory (idle) | <100MB | Xcode Memory Debugger |
| Memory (1000 nodes) | <250MB | Xcode Memory Debugger |
| Binary Size Impact | <10% | xcodesign + dsymutil |

**Success Criteria:**
- [ ] Beta testers report positive feedback
- [ ] Zero critical bugs in production candidate
- [ ] All documentation complete (migration guide, API docs, examples)
- [ ] Release notes drafted

---

### 9.5 Accessibility Requirements (WCAG 2.1 AA Compliance)

**Target:** ≥98% accessibility audit score across all platforms

---

#### WCAG 2.1 AA Compliance Checklist

**Perceivable:**
- [ ] **1.1.1 Non-text Content:** All images, icons, and non-text elements have text alternatives
- [ ] **1.3.1 Info and Relationships:** Semantic HTML/SwiftUI structure (headings, landmarks, labels)
- [ ] **1.4.1 Use of Color:** Information not conveyed by color alone
- [ ] **1.4.3 Contrast (Minimum):** ≥4.5:1 for normal text, ≥3:1 for large text
- [ ] **1.4.4 Resize Text:** Text scales up to 200% without loss of content or functionality
- [ ] **1.4.11 Non-text Contrast:** ≥3:1 for UI components and graphical objects

**Operable:**
- [ ] **2.1.1 Keyboard:** All functionality available via keyboard
- [ ] **2.1.2 No Keyboard Trap:** Focus can move away from all components
- [ ] **2.4.3 Focus Order:** Focus order preserves meaning and operability
- [ ] **2.4.7 Focus Visible:** Keyboard focus indicator visible
- [ ] **2.5.5 Target Size:** Interactive targets ≥44×44pt (iOS), ≥24×24pt (macOS)

**Understandable:**
- [ ] **3.1.1 Language of Page:** Primary language identified
- [ ] **3.2.1 On Focus:** Focus does not trigger unexpected context changes
- [ ] **3.3.1 Error Identification:** Errors identified and described in text
- [ ] **3.3.2 Labels or Instructions:** Labels provided for all input fields

**Robust:**
- [ ] **4.1.2 Name, Role, Value:** All UI components have accessible names and roles
- [ ] **4.1.3 Status Messages:** Status messages announced to assistive technologies

---

#### VoiceOver Testing Requirements

**macOS VoiceOver:**
- [ ] All interactive elements have descriptive labels
- [ ] Navigation order logical (tree → detail → hex)
- [ ] Rotor functionality working (headings, landmarks, links)
- [ ] Table navigation functional (grid cells, rows, columns)
- [ ] Actions announced (copy, export, expand/collapse)

**iOS VoiceOver:**
- [ ] Swipe gestures navigate correctly
- [ ] Double-tap activates controls
- [ ] Three-finger swipe scrolls content
- [ ] Rotor gestures functional
- [ ] VoiceOver hints provided for complex interactions

**Testing Procedure:**
1. Enable VoiceOver (⌘F5 on macOS, Settings on iOS)
2. Navigate entire app using only VoiceOver
3. Verify all content readable and interactive elements actionable
4. Test Rotor functionality (headings, landmarks, etc.)
5. Verify notifications and status updates announced

---

#### Keyboard Navigation Requirements

**macOS:**
- [ ] **Tab:** Move focus forward through interactive elements
- [ ] **Shift+Tab:** Move focus backward
- [ ] **Space:** Activate buttons, toggle checkboxes
- [ ] **Return:** Activate default button, select list items
- [ ] **Arrow Keys:** Navigate within lists, trees, grids
- [ ] **⌘I:** Toggle inspector panel
- [ ] **⌘F:** Focus search field
- [ ] **⌘,:** Open settings
- [ ] **Escape:** Dismiss modals, cancel operations

**iOS/iPadOS (with external keyboard):**
- [ ] **Tab:** Same as macOS
- [ ] **Arrow Keys:** Navigate tree and lists
- [ ] **⌘Tab:** Switch between panes (sidebar, detail, inspector)
- [ ] **Space:** Activate controls

**Testing Procedure:**
1. Disconnect mouse/trackpad (macOS) or use external keyboard (iOS)
2. Navigate entire app using only keyboard
3. Verify all features accessible
4. Check focus indicators visible
5. Ensure no keyboard traps

---

#### Dynamic Type Support Requirements

**Size Categories to Test:**
- [ ] **XS** (Extra Small)
- [ ] **S** (Small)
- [ ] **M** (Medium / default)
- [ ] **L** (Large)
- [ ] **XL** (Extra Large)
- [ ] **XXL** (Extra Extra Large)
- [ ] **XXXL** (Extra Extra Extra Large)
- [ ] **Accessibility Large** (A1-A5)

**Verification:**
- [ ] Text scales proportionally without clipping
- [ ] Layout adapts to accommodate larger text
- [ ] No horizontal scrolling required
- [ ] Interactive targets maintain minimum size (44×44pt)

**Testing Procedure:**
1. Open Settings → Accessibility → Display & Text Size → Larger Text
2. Adjust slider through all size categories
3. Verify app UI scales correctly
4. Check for clipping, overlapping, or unreadable text
5. Test on smallest device (iPhone SE) and largest (iPad Pro)

---

#### Color Contrast Requirements

**WCAG 2.1 AA Standards:**
- **Normal Text:** ≥4.5:1 contrast ratio
- **Large Text (≥18pt or ≥14pt bold):** ≥3:1 contrast ratio
- **UI Components:** ≥3:1 contrast ratio
- **Graphical Objects:** ≥3:1 contrast ratio

**Design Token Compliance:**
```swift
// ✅ GOOD: Pre-verified contrast ratios
DS.Colors.infoBG     // 5.2:1 contrast (PASS)
DS.Colors.warnBG     // 4.8:1 contrast (PASS)
DS.Colors.errorBG    // 6.1:1 contrast (PASS)
DS.Colors.label      // System-provided (always compliant)
```

**Testing Tools:**
- **macOS:** Accessibility Inspector → Color Contrast Calculator
- **Xcode:** Environment Overrides → Increase Contrast
- **Web:** WebAIM Contrast Checker (for custom colors)

**Testing Procedure:**
1. Enable High Contrast mode (Settings → Accessibility)
2. Verify all text readable
3. Use Accessibility Inspector to measure ratios
4. Check custom colors with contrast calculator
5. Test in light and dark modes

---

#### Reduce Motion Support

**Requirements:**
- [ ] All animations respect `accessibilityReduceMotion` preference
- [ ] Critical animations replaced with instant transitions
- [ ] Decorative animations removed entirely
- [ ] Parallax effects disabled

**Implementation:**
```swift
// ✅ GOOD: Respects Reduce Motion preference
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .easeInOut(duration: 0.25)
}
```

**Testing Procedure:**
1. Enable Reduce Motion (Settings → Accessibility → Motion)
2. Navigate app and verify no animations
3. Test expand/collapse, navigation transitions
4. Ensure functionality preserved (instant transitions)

---

#### High Contrast Mode Support

**Requirements:**
- [ ] All colors adapt to increased contrast
- [ ] Borders and separators more prominent
- [ ] Focus indicators enhanced
- [ ] Icon outlines strengthened

**FoundationUI Automatic Support:**
- `DS.Colors` tokens automatically adapt to High Contrast
- `DS.SurfaceStyle` increases elevation contrast
- `DS.InteractiveStyle` enhances focus indicators

**Testing Procedure:**
1. Enable Increase Contrast (Settings → Accessibility)
2. Verify UI remains readable
3. Check borders and separators visible
4. Test focus indicators prominent
5. Verify in light and dark modes

---

#### Accessibility Testing Tools

**macOS:**
- **Accessibility Inspector:** Xcode → Open Developer Tool → Accessibility Inspector
- **VoiceOver Utility:** System Preferences → Accessibility → VoiceOver → Open VoiceOver Utility
- **Color Contrast Calculator:** Accessibility Inspector → Audit → Color Contrast

**iOS:**
- **Accessibility Inspector:** Xcode → Devices and Simulators → Select device → Accessibility Inspector
- **VoiceOver Practice:** Settings → Accessibility → VoiceOver → VoiceOver Practice
- **Settings Shortcuts:** Settings → Accessibility → Accessibility Shortcut (triple-click)

**Automated Testing:**
```swift
// Snapshot tests with accessibility verification
func testAccessibilityContrast() {
    assertSnapshot(matching: view, as: .accessibilityImage)
}

func testDynamicTypeScaling() {
    for category in ContentSizeCategory.allCases {
        let view = BadgeView().environment(\.sizeCategory, category)
        assertSnapshot(matching: view, as: .image)
    }
}
```

---

#### Accessibility Audit Procedure

**Before Each Release:**
1. Run Accessibility Inspector audit on all screens
2. Verify 0 critical issues, <2% warnings
3. Test VoiceOver on macOS and iOS
4. Test keyboard navigation
5. Test all Dynamic Type categories
6. Verify color contrast in light/dark/high-contrast modes
7. Test Reduce Motion and Bold Text preferences
8. Document findings in `DOCS/TASK_ARCHIVE/{release}/accessibility_audit.md`

**Target Score:** ≥98% (critical issues: 0, warnings: <2%)

---

### 9.6 Cross-References

**Integration Resources:**
- **Technical Spec:** [`03_Technical_Spec.md`](03_Technical_Spec.md) — Integration architecture and code examples
- **Integration Strategy:** [`DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`](../../TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md) — 9-week phased roadmap
- **Component Showcase:** [`Examples/ComponentTestApp/README.md`](../../../Examples/ComponentTestApp/README.md) — Interactive demo app
- **Integration Tests:** [`Tests/ISOInspectorAppTests/FoundationUI/`](../../../Tests/ISOInspectorAppTests/FoundationUI/) — 123 comprehensive tests

**Design System Documentation:**
- **FoundationUI PRD:** [`DOCS/AI/FoundationUI/FoundationUI_PRD.md`](../FoundationUI/FoundationUI_PRD.md)
- **FoundationUI Task Plan:** [`DOCS/AI/FoundationUI/FoundationUI_Task_Plan.md`](../FoundationUI/FoundationUI_Task_Plan.md)
- **FoundationUI Test Plan:** [`DOCS/AI/FoundationUI/FoundationUI_Test_Plan.md`](../FoundationUI/FoundationUI_Test_Plan.md)

**Quality Standards:**
- **TDD/XP Workflow:** [`DOCS/RULES/02_TDD_XP_Workflow.md`](../../RULES/02_TDD_XP_Workflow.md)
- **Code Structure Principles:** [`DOCS/RULES/07_AI_Code_Structure_Principles.md`](../../RULES/07_AI_Code_Structure_Principles.md)
- **Accessibility Guidelines:** [`Documentation/ISOInspector.docc/Guides/AccessibilityGuidelines.md`](../../../Documentation/ISOInspector.docc/Guides/AccessibilityGuidelines.md)

---

## 10. License

MIT © 0AL Core Design System
