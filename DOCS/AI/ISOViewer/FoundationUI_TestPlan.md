# FoundationUI Test Plan
**Project:** ISO Inspector - FoundationUI Framework
**Version:** 1.0
**Date:** 2025-10-20
**Status:** Active
**Based on:** FoundationUI PRD v1.0

---

## Test Plan Overview

### Objectives
- Ensure ≥80% code coverage across all layers
- Achieve ≥95% accessibility compliance
- Verify cross-platform compatibility (iOS 17+, iPadOS 17+, macOS 14+)
- Maintain 60 FPS rendering performance
- Validate zero magic numbers policy (100% DS token usage)

### Scope
This test plan covers all aspects of the FoundationUI framework:
- Design Tokens (Layer 0)
- View Modifiers (Layer 1)
- Components (Layer 2)
- Patterns (Layer 3)
- Contexts (Layer 4)
- Utilities
- Agent Support

---

## Testing Pyramid Strategy

```
           ┌─────────────────┐
           │   E2E Tests     │  10% - Full user flows in demo apps
           │                 │
           ├─────────────────┤
           │ Integration     │  20% - Component composition,
           │ Tests           │       navigation, state flow
           │                 │
           ├─────────────────┤
           │  Unit Tests     │  70% - Component logic, tokens,
           │                 │       modifiers, utilities
           └─────────────────┘
```

---

## Test Coverage Matrix

| Layer | Component | Unit | Snapshot | Integration | Accessibility | Performance | Target Coverage |
|-------|-----------|------|----------|-------------|---------------|-------------|-----------------|
| **Layer 0** | Design Tokens | ✅ | N/A | N/A | N/A | N/A | 100% |
| **Layer 1** | BadgeChipStyle | ✅ | ✅ | ✅ | ✅ | ✅ | ≥90% |
| **Layer 1** | CardStyle | ✅ | ✅ | ✅ | ✅ | ✅ | ≥90% |
| **Layer 1** | InteractiveStyle | ✅ | ✅ | ✅ | ✅ | ✅ | ≥90% |
| **Layer 1** | SurfaceStyle | ✅ | ✅ | ✅ | N/A | ✅ | ≥90% |
| **Layer 2** | Badge | ✅ | ✅ | ✅ | ✅ | ✅ | ≥85% |
| **Layer 2** | Indicator | ✅ | ✅ | ✅ | ✅ | ✅ | ≥85% |
| **Layer 2** | Card | ✅ | ✅ | ✅ | ✅ | ✅ | ≥85% |
| **Layer 2** | KeyValueRow | ✅ | ✅ | ✅ | ✅ | ✅ | ≥85% |
| **Layer 2** | SectionHeader | ✅ | ✅ | ✅ | ✅ | N/A | ≥85% |
| **Layer 2** | CopyableText | ✅ | ✅ | ✅ | ✅ | ✅ | ≥85% |
| **Layer 3** | InspectorPattern | ✅ | ✅ | ✅ | ✅ | ✅ | ≥80% |
| **Layer 3** | SidebarPattern | ✅ | ✅ | ✅ | ✅ | ✅ | ≥80% |
| **Layer 3** | ToolbarPattern | ✅ | ✅ | ✅ | ✅ | N/A | ≥80% |
| **Layer 3** | BoxTreePattern | ✅ | ✅ | ✅ | ✅ | ✅ | ≥80% |
| **Layer 4** | SurfaceStyleKey | ✅ | N/A | ✅ | N/A | N/A | ≥80% |
| **Layer 4** | PlatformAdaptation | ✅ | ✅ | ✅ | N/A | N/A | ≥80% |
| **Layer 4** | ColorSchemeAdapter | ✅ | ✅ | ✅ | N/A | N/A | ≥80% |
| **Utilities** | CopyableText | ✅ | ✅ | ✅ | ✅ | ✅ | ≥80% |
| **Utilities** | KeyboardShortcuts | ✅ | N/A | ✅ | ✅ | N/A | ≥80% |
| **Utilities** | AccessibilityHelpers | ✅ | N/A | ✅ | ✅ | N/A | ≥90% |
| **Agent** | AgentDescribable | ✅ | N/A | ✅ | N/A | N/A | ≥70% |
| **Agent** | YAMLValidator | ✅ | N/A | ✅ | N/A | ✅ | ≥70% |

---

## Test Types & Implementation

### 1. Unit Tests (70% of test effort)

#### 1.1 Design Tokens Tests
**File:** `Tests/DesignTokensTests/TokenValidationTests.swift`

**Test Cases:**
- ✅ All spacing values are positive and non-zero
- ✅ All radius values are valid (≥0)
- ✅ All animation durations are reasonable (0.1-1.0s)
- ✅ Typography tokens use system fonts
- ✅ Color tokens have proper opacity (0.0-1.0)
- ✅ Platform-specific values are correctly applied
- ✅ No magic numbers (all values are constants)

**Example:**
```swift
func testSpacingTokensArePositive() {
    XCTAssertGreaterThan(DS.Spacing.s, 0)
    XCTAssertGreaterThan(DS.Spacing.m, 0)
    XCTAssertGreaterThan(DS.Spacing.l, 0)
    XCTAssertGreaterThan(DS.Spacing.xl, 0)
}
```

#### 1.2 View Modifier Tests
**File:** `Tests/ModifiersTests/BadgeChipStyleTests.swift`

**Test Cases:**
- ✅ Badge displays correct background color for each level
- ✅ Badge uses DS.Font.label
- ✅ Badge uses DS.Spacing tokens
- ✅ Badge has correct accessibility label
- ✅ Badge supports all BadgeLevel variants
- ✅ Badge renders correctly in Light/Dark mode

**Example:**
```swift
func testBadgeChipStyleAppliesCorrectBackground() {
    let view = Text("TEST").modifier(BadgeChipStyle(level: .error))
    // Assert background color matches DS.Color.errorBG
}
```

#### 1.3 Component Tests
**File:** `Tests/ComponentsTests/BadgeTests.swift`

**Test Cases:**
- ✅ Badge initializes with text and level
- ✅ Badge applies BadgeChipStyle modifier
- ✅ Badge accessibility label includes level
- ✅ Badge supports all BadgeLevel cases
- ✅ Badge composition with other views
- ✅ Badge state changes update UI

**File:** `Tests/ComponentsTests/IndicatorTests.swift`

**Test Cases:**
- ✅ Indicator renders circular dot sized per `IndicatorSize`
- ✅ Indicator fills use `BadgeChipStyle` colors for each level
- ✅ Indicator exposes accessibility label “{Level} indicator — {reason}”
- ✅ Indicator triggers tooltip/context menu per platform
- ✅ Indicator integrates with `.copyable(text:)` modifier
- ✅ Indicator respects Reduce Motion + high contrast settings

**Example:**
```swift
func testIndicatorUsesWarningColor() {
    let indicator = Indicator(level: .warning, size: .small, reason: "Checksum mismatch")
    assertIndicator(indicator, matchesFill: DS.Colors.warnBG)
}
```

#### 1.4 Pattern Tests
**File:** `Tests/PatternsTests/InspectorPatternTests.swift`

**Test Cases:**
- ✅ InspectorPattern displays title
- ✅ InspectorPattern renders content
- ✅ InspectorPattern uses correct spacing
- ✅ InspectorPattern supports scrolling
- ✅ InspectorPattern applies material background
- ✅ InspectorPattern adapts to platform

#### 1.5 Context Tests
**File:** `Tests/ContextsTests/PlatformAdaptationTests.swift`

**Test Cases:**
- ✅ Platform detection works correctly
- ✅ PlatformAdaptiveModifier applies correct spacing on macOS
- ✅ PlatformAdaptiveModifier adapts to size classes on iOS
- ✅ Environment values propagate correctly
- ✅ ColorSchemeAdapter responds to system changes

---

### 2. Snapshot Tests (Visual Regression)

#### 2.1 Setup
**Framework:** [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
**Storage:** `Tests/__Snapshots__/`

#### 2.2 Snapshot Test Matrix

| Component | Light Mode | Dark Mode | Dynamic Type (S/M/L/XL) | Platforms | RTL |
|-----------|------------|-----------|-------------------------|-----------|-----|
| Badge | ✅ | ✅ | ✅ (4 sizes) | iOS, macOS | ✅ |
| Indicator | ✅ | ✅ | ✅ (size variants) | iOS, macOS | ✅ |
| Card | ✅ | ✅ | ✅ (4 sizes) | iOS, macOS | ✅ |
| KeyValueRow | ✅ | ✅ | ✅ (4 sizes) | iOS, macOS | ✅ |
| SectionHeader | ✅ | ✅ | ✅ (4 sizes) | iOS, macOS | N/A |
| InspectorPattern | ✅ | ✅ | ✅ (3 sizes) | iOS, macOS, iPad | N/A |
| SidebarPattern | ✅ | ✅ | ✅ (3 sizes) | macOS, iPad | N/A |
| BoxTreePattern | ✅ | ✅ | ✅ (3 sizes) | iOS, macOS, iPad | N/A |

**Total Snapshots:** ~150 baseline images

**Example:**
```swift
func testBadgeSnapshotLightMode() {
    let badge = Badge(text: "ERROR", level: .error)
    assertSnapshot(matching: badge, as: .image(layout: .sizeThatFits))
}

func testBadgeDarkMode() {
    let badge = Badge(text: "ERROR", level: .error)
        .environment(\.colorScheme, .dark)
    assertSnapshot(matching: badge, as: .image(layout: .sizeThatFits))
}
```

#### 2.3 Snapshot Update Workflow
1. Run tests: `swift test`
2. Review failed snapshots in `Tests/__Snapshots__/__Failures__/`
3. If changes are intentional: `RECORD_MODE=true swift test`
4. Commit updated snapshots to git
5. Document changes in PR description

---

### 3. Accessibility Tests

#### 3.1 Automated Accessibility Tests
**Framework:** XCTest + [cashapp/AccessibilitySnapshot](https://github.com/cashapp/AccessibilitySnapshot)

**Test Cases:**
- ✅ All interactive elements have accessibility labels
- ✅ All badges have accessibility hints
- ✅ Indicators announce status level and reason text
- ✅ Contrast ratio ≥4.5:1 for all text
- ✅ Touch target size ≥44×44 pt
- ✅ VoiceOver navigation order is logical
- ✅ Focus indicators are visible
- ✅ All images have accessibility descriptions

**Example:**
```swift
func testBadgeAccessibility() {
    let badge = Badge(text: "ERROR", level: .error)
    // Assert accessibility label exists
    // Assert contrast ratio meets WCAG 2.1 AA
    assertSnapshot(matching: badge, as: .accessibilityImage)
}
```

#### 3.2 Manual Accessibility Testing Checklist

**VoiceOver (iOS):**
- [ ] All components are announced correctly
- [ ] Badge level is announced ("Error badge")
- [ ] Indicator announces "{Level} indicator" and reason tooltip
- [ ] CopyableText announces "Double tap to copy"
- [ ] Navigation order is logical
- [ ] Headings are properly marked
- [ ] Lists are properly structured

**VoiceOver (macOS):**
- [ ] Keyboard navigation works (Tab, Shift+Tab)
- [ ] VO+Right Arrow navigates correctly
- [ ] Focus indicators are visible
- [ ] Tooltip text announced when Indicator receives focus
- [ ] Toolbar items are announced with shortcuts

**Dynamic Type:**
- [ ] Test all sizes (XS, S, M, L, XL, XXL, XXXL)
- [ ] Text doesn't truncate
- [ ] Layouts adjust correctly
- [ ] Touch targets remain ≥44×44 pt

**Reduce Motion:**
- [ ] Animations respect `preferredReduceMotion`
- [ ] No automatic animations when enabled
- [ ] Transitions are instant

**Increase Contrast:**
- [ ] Colors adjust for better contrast
- [ ] Borders become more visible
- [ ] All text remains readable

---

### 4. Performance Tests

#### 4.1 Render Performance
**Tool:** Instruments (Time Profiler, Core Animation)

**Test Cases:**
- ✅ Component render time <16ms (60 FPS)
- ✅ SwiftUI body execution <1ms
- ✅ No hitches during scrolling
- ✅ BoxTreePattern with 1000+ items remains smooth
- ✅ Indicator hover/tap tooltip latency <50ms on all platforms

**Example:**
```swift
func testBadgeRenderPerformance() {
    measure {
        let badge = Badge(text: "TEST", level: .info)
        // Measure view body execution time
    }
}
```

#### 4.2 Memory Performance
**Tool:** Instruments (Allocations, Leaks)

**Test Cases:**
- ✅ No memory leaks in any component
- ✅ Memory footprint <5MB per screen
- ✅ Proper cleanup on navigation
- ✅ No retain cycles in closures

#### 4.3 Build Performance
**Metrics:**
- ✅ Clean build time <10s
- ✅ Incremental build <2s
- ✅ SwiftUI Preview compilation <5s

---

### 5. Integration Tests

#### 5.1 Component Composition Tests
**File:** `Tests/IntegrationTests/ComponentCompositionTests.swift`

**Test Cases:**
- ✅ Badge inside Card renders correctly
- ✅ Indicator pairs with KeyValueRow and Copyable wrappers
- ✅ KeyValueRow with CopyableText works
- ✅ InspectorPattern with SectionHeader and Cards
- ✅ Nested patterns (Sidebar + Inspector + Toolbar)
- ✅ Environment values propagate through hierarchy

**Example:**
```swift
func testCardWithBadgeComposition() {
    let view = Card {
        VStack {
            Badge(text: "NEW", level: .info)
            Text("Content")
        }
    }
    // Assert both components render
    // Assert spacing is correct
}

func testIndicatorTooltipComposition() {
    let view = Indicator(level: .warning, size: .small, reason: "Checksum mismatch")
        .contextMenu {
            Badge(text: "Checksum mismatch", level: .warning)
        }
    // Verify tooltip/context menu attaches and accessibility label includes reason
}
```

#### 5.2 Navigation Tests
**Test Cases:**
- ✅ SidebarPattern selection updates
- ✅ NavigationStack integration
- ✅ Deep linking works
- ✅ State preservation on navigation

#### 5.3 Platform Adaptation Tests
**Test Cases:**
- ✅ Components render correctly on iOS
- ✅ Components render correctly on macOS
- ✅ Components adapt to iPad size classes
- ✅ Toolbar shows correctly on each platform
- ✅ Sidebar behavior matches platform conventions

---

### 6. Cross-Platform Tests

#### 6.1 Platform Matrix

| Test Case | iOS 17 (iPhone) | iOS 17 (iPad) | macOS 14 | Notes |
|-----------|-----------------|---------------|----------|-------|
| Badge rendering | ✅ | ✅ | ✅ | |
| Indicator rendering | ✅ | ✅ | ✅ | Tooltip/context menu parity |
| Card with elevation | ✅ | ✅ | ✅ | macOS uses lighter shadow |
| InspectorPattern | ✅ | ✅ | ✅ | |
| SidebarPattern | N/A | ✅ | ✅ | iPhone uses NavigationStack |
| ToolbarPattern | ✅ | ✅ | ✅ | Platform-specific styling |
| Keyboard shortcuts | N/A | ✅ (hw kbd) | ✅ | |
| Hover effects | N/A | ✅ (pointer) | ✅ | |

#### 6.2 Size Class Tests (iPad)
- ✅ Compact width (portrait, split view)
- ✅ Regular width (landscape, full screen)
- ✅ Compact height (landscape, multitasking)
- ✅ Regular height (portrait, split view)

---

### 7. End-to-End Tests (UI Tests)

#### 7.1 User Flow Tests
**Framework:** XCUITest
**File:** `UITests/ISOInspectorUITests.swift`

**Test Cases:**
- ✅ Launch app and select ISO file
- ✅ Navigate box tree hierarchy
- ✅ View box details in inspector
- ✅ Copy hex value from KeyValueRow
- ✅ Search for specific box type
- ✅ Toggle Dark Mode
- ✅ Resize inspector panel (macOS)

**Example:**
```swift
func testCopyHexValue() {
    let app = XCUIApplication()
    app.launch()

    // Navigate to box
    app.buttons["ftyp"].tap()

    // Find hex value row
    let hexRow = app.staticTexts["0x66747970"]

    // Copy value
    hexRow.tap()

    // Verify copy confirmation
    XCTAssertTrue(app.staticTexts["Copied"].exists)
}
```

---

## Test Execution Strategy

### Phase-by-Phase Testing

#### Phase 1: Foundation
- **Focus:** Design Tokens validation
- **Tests:** Unit tests for all token values
- **Coverage Target:** 100%
- **Duration:** 1 day

#### Phase 2: Core Components
- **Focus:** Modifiers and Components
- **Tests:** Unit + Snapshot + Accessibility
- **Coverage Target:** ≥85%
- **Duration:** 3 days

#### Phase 3: Patterns
- **Focus:** Pattern composition and integration
- **Tests:** Unit + Integration + Performance
- **Coverage Target:** ≥80%
- **Duration:** 2 days

#### Phase 4: Agent Support
- **Focus:** YAML parsing and validation
- **Tests:** Unit + Integration
- **Coverage Target:** ≥70%
- **Duration:** 1 day

#### Phase 5: Documentation & QA
- **Focus:** Final testing and validation
- **Tests:** All types, cross-platform
- **Coverage Target:** ≥80% overall
- **Duration:** 4 days

#### Phase 6: Integration
- **Focus:** Real-world usage in demo apps
- **Tests:** E2E UI tests
- **Coverage Target:** Critical user flows
- **Duration:** 3 days

---

## CI/CD Integration

### GitHub Actions Workflow

```yaml
name: FoundationUI CI

on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        platform: [iOS-17, macOS-14, iPadOS-17]

    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Run Unit Tests
        run: swift test --enable-code-coverage

      - name: Run Snapshot Tests
        run: swift test --filter SnapshotTests

      - name: Run Accessibility Tests
        run: swift test --filter AccessibilityTests

      - name: Generate Coverage Report
        run: xcov --scheme FoundationUI --minimum_coverage_percentage 80

      - name: Upload Coverage
        uses: codecov/codecov-action@v3

      - name: SwiftLint
        run: swiftlint --strict
```

### Test Triggers

| Event | Tests Run | Coverage Check | Snapshot Compare |
|-------|-----------|----------------|------------------|
| **PR Created** | All | ✅ | ✅ |
| **Commit to PR** | Affected | ✅ | ✅ |
| **Main Branch** | All + E2E | ✅ | ✅ |
| **Nightly** | All + Performance | ✅ | ✅ |
| **Release** | All + Manual QA | ✅ | ✅ |

---

## Test Metrics & Reporting

### Coverage Metrics
- **Overall Coverage:** ≥80%
- **Layer 0 (Tokens):** 100%
- **Layer 1 (Modifiers):** ≥90%
- **Layer 2 (Components):** ≥85%
- **Layer 3 (Patterns):** ≥80%
- **Layer 4 (Contexts):** ≥80%

### Quality Gates

| Metric | Target | Blocker if Failed |
|--------|--------|-------------------|
| Unit Test Pass Rate | 100% | ✅ Yes |
| Snapshot Failures | 0 (or explained) | ✅ Yes |
| Code Coverage | ≥80% | ✅ Yes |
| SwiftLint Violations | 0 | ✅ Yes |
| Accessibility Score | ≥95% | ✅ Yes |
| Build Time | <10s | ⚠️ Warning |
| Memory Footprint | <5MB/screen | ⚠️ Warning |
| FPS | ≥60 | ⚠️ Warning |

### Test Reporting Dashboard

**Weekly Report Includes:**
- Test pass/fail trends
- Coverage trends
- Flaky test identification
- Performance metrics
- Accessibility compliance score
- Platform-specific issues

---

## Test Data & Fixtures

### Sample ISO Files
**Location:** `Tests/Fixtures/ISO/`

- `minimal.iso` (10KB) - Minimal valid ISO structure
- `typical.iso` (1MB) - Typical ISO with common boxes
- `complex.iso` (10MB) - Complex hierarchy, 1000+ boxes
- `invalid.iso` (5KB) - Intentionally malformed

### Mock Data
**Location:** `Tests/Mocks/`

- `MockBoxData.swift` - Sample box structures
- `MockEnvironment.swift` - Test environment values
- `MockClipboard.swift` - Clipboard operations

---

## Known Testing Limitations

1. **SwiftUI Preview Testing:** Previews are compiled but not automatically tested
2. **Real Device Testing:** CI only supports simulators
3. **Localization Testing:** Limited to RTL layout testing
4. **watchOS/tvOS:** Not in scope for v1.0

---

## Test Maintenance

### Snapshot Updates
- Review quarterly or when design system changes
- Document all intentional changes
- Archive old snapshots for reference

### Test Refactoring
- Remove duplicate tests
- Consolidate similar test cases
- Keep test code DRY

### Test Performance
- Monitor test execution time
- Parallelize when possible
- Optimize slow tests

---

## Bug Fix Regression Testing

### Bug Fix: DS.Colors.tertiary macOS Low Contrast

**Regression Prevention Target**: This bug must never recur

**Specification**: [`FoundationUI/DOCS/SPECS/BUG_Colors_Tertiary_macOS_LowContrast.md`](../../FoundationUI/DOCS/SPECS/BUG_Colors_Tertiary_macOS_LowContrast.md)

#### Root Cause
`DS.Colors.tertiary` uses `.tertiaryLabelColor` (label/text color) instead of proper background color on macOS, causing severe low contrast in all components using this token.

#### Reproduction Test (Should Fail Before Fix)
```swift
@available(macOS 10.15, *)
func testTertiaryColorIsNotLabelColorOnMacOS() {
    #if os(macOS)
    // This test documents the bug: DS.Colors.tertiary should NOT use label colors
    // After fix, this should use .controlBackgroundColor or similar background color
    let tertiaryColor = DS.Colors.tertiary
    XCTAssertNotNil(tertiaryColor, "DS.Colors.tertiary must be defined")
    // Visual inspection: tertiary should provide adequate contrast when used as background
    #endif
}
```

#### Unit Tests (Verify Fix)
- **Test 1**: Verify DS.Colors.tertiary uses background color on macOS
  ```swift
  func testTertiaryColorUsesMacOSBackgroundColor() {
      #if os(macOS)
      // After fix: should use .controlBackgroundColor, .windowBackgroundColor,
      // or .underPageBackgroundColor - NOT .tertiaryLabelColor
      XCTAssertNotNil(DS.Colors.tertiary)
      #endif
  }
  ```

- **Test 2**: Platform parity - macOS intent matches iOS
  ```swift
  func testTertiaryColorPlatformParity() {
      // iOS uses .tertiarySystemBackground (background color)
      // macOS should also use background color, not label color
      XCTAssertNotNil(DS.Colors.tertiary)
  }
  ```

#### Snapshot Tests (Visual Regression)
**Platform**: macOS only (iOS already correct)

- **SidebarPattern** detail content background
  - Light mode: verify clear contrast between sidebar and detail area
  - Dark mode: verify clear contrast between sidebar and detail area
  - Location: `Tests/__Snapshots__/SidebarPattern_macOS_DetailBackground_*.png`

- **Card** component background
  - Light mode: verify card stands out from window background
  - Dark mode: verify card stands out from window background
  - Location: `Tests/__Snapshots__/Card_macOS_Background_*.png`

- **InspectorPattern** content area
  - Light mode: verify content area has distinct background
  - Dark mode: verify content area has distinct background

- **ToolbarPattern** toolbar background
  - Light mode: verify toolbar differentiates from content
  - Dark mode: verify toolbar differentiates from content

**Snapshot Baseline**:
- Before fix: Low contrast, blended appearance
- After fix: Clear visual separation, adequate contrast

#### Accessibility Tests
**Target**: WCAG 2.1 AA compliance (≥4.5:1 contrast ratio)

```swift
@available(macOS 10.15, *)
func testTertiaryColorContrastRatio() {
    #if os(macOS)
    // Verify contrast ratio between DS.Colors.tertiary background
    // and typical content colors (textPrimary, textSecondary)
    // Must meet ≥4.5:1 for WCAG AA compliance
    let backgroundColor = DS.Colors.tertiary
    let textColor = DS.Colors.textPrimary

    // Use AccessibilitySnapshot or manual contrast calculation
    // XCTAssert(contrastRatio >= 4.5)
    #endif
}
```

- VoiceOver navigation: verify content boundaries are clear
- Keyboard shortcuts: verify focus indicators are visible
- Increase Contrast mode: verify enhanced contrast works correctly

**Accessibility Impact**:
- Before fix: Fails WCAG AA (contrast <4.5:1)
- After fix: Passes WCAG AA (contrast ≥4.5:1)

#### Integration Tests
**Affected Components**:
1. SidebarPattern (detail content background) - Line 176
2. Card (background fallback) - Lines 159, 162
3. SurfaceStyle (material fallback) - Lines 85, 195
4. InteractiveStyle (hover states) - Multiple locations
5. ToolbarPattern (toolbar background) - Lines 51, 263

**Test Strategy**:
```swift
func testAllComponentsUsingTertiaryColorOnMacOS() {
    #if os(macOS)
    // Verify all components using DS.Colors.tertiary show proper contrast
    // Test each component in Light/Dark mode
    // Verify visual separation from window background
    #endif
}
```

#### Manual Testing Checklist
**Test Environment**: ComponentTestApp on macOS

- [ ] Launch ComponentTestApp on macOS Sonoma or later
- [ ] Navigate to "Patterns" > "SidebarPattern"
- [ ] Verify detail content area has clear contrast with window
- [ ] Toggle Dark Mode - verify contrast maintained
- [ ] Enable Increase Contrast - verify enhanced separation
- [ ] Navigate to all pattern screens (Inspector, Toolbar, BoxTree)
- [ ] Verify all use proper background colors
- [ ] Test on different macOS versions (14.0+)
- [ ] Compare with iOS version for semantic consistency

#### Test Coverage Target
**100% for bug fix code paths**

- Colors.swift line 111: Platform-specific color mapping
- All components using DS.Colors.tertiary on macOS
- Snapshot baselines for all affected components

#### Success Criteria
- [ ] All unit tests pass
- [ ] All snapshot tests show clear visual separation
- [ ] Contrast ratio ≥4.5:1 verified
- [ ] VoiceOver announces content boundaries correctly
- [ ] Increase Contrast mode enhances separation
- [ ] ComponentTestApp demonstrates fix visually
- [ ] No regression in iOS/iPadOS (already correct)
- [ ] Platform parity: macOS semantic intent matches iOS
- [ ] SwiftLint 0 violations
- [ ] Test coverage ≥100% for bug fix lines

---

## Success Criteria

✅ **All quality gates passed**
✅ **≥80% code coverage achieved**
✅ **≥95% accessibility score**
✅ **0 SwiftLint violations**
✅ **All platforms tested (iOS, iPadOS, macOS)**
✅ **100% snapshot baselines created**
✅ **E2E tests for critical user flows**
✅ **CI/CD pipeline fully automated**

---

## Appendix

### Tools & Frameworks
- **XCTest** - Unit and UI testing framework
- **swift-snapshot-testing** - Snapshot testing
- **AccessibilitySnapshot** - Accessibility testing
- **Instruments** - Performance profiling
- **SwiftLint** - Code quality
- **xcov** - Coverage reporting
- **Percy** - Visual regression (optional)

### References
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Snapshot Testing](https://github.com/pointfreeco/swift-snapshot-testing)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [iOS Testing Best Practices](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)

---

**Document Version:** 1.0
**Last Updated:** 2025-10-20
**Next Review:** 2025-10-27
