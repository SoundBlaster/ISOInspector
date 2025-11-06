# Accessibility Audit (≥95% Score)

## 🎯 Objective
Perform comprehensive accessibility audit of all FoundationUI components and patterns to achieve ≥95% accessibility score, ensuring WCAG 2.1 Level AA compliance and excellent user experience for assistive technology users.

## 🧩 Context
- **Phase**: 5.2 Testing & Quality Assurance
- **Section**: Accessibility Testing
- **Priority**: P0 (Critical for release)
- **Dependencies**:
  - ✅ All components and patterns implemented (Phase 1-4 complete)
  - ✅ Test infrastructure ready (Phase 5.2 unit test infrastructure)
  - ✅ AccessibilityHelpers utility implemented (Phase 4.2)
  - ✅ AccessibilityContext implemented (Phase 3.2)

## ✅ Success Criteria
- [ ] AccessibilitySnapshot framework installed and configured
- [ ] Automated contrast ratio testing implemented (≥4.5:1 for WCAG AA)
- [ ] VoiceOver label and hint validation for all components
- [ ] Keyboard navigation testing implemented
- [ ] Focus order verification complete
- [ ] Touch target size validation (≥44×44 pt on iOS)
- [ ] Accessibility score ≥95% achieved
- [ ] All WCAG 2.1 Level AA criteria met
- [ ] Test suite integrated into CI/CD pipeline
- [ ] Comprehensive accessibility test report generated

## 🔧 Implementation Notes

### Components to Audit (Layer 2)
- Badge component
- Card component
- KeyValueRow component
- SectionHeader component
- CopyableText utility
- Copyable generic wrapper

### Patterns to Audit (Layer 3)
- InspectorPattern
- SidebarPattern
- ToolbarPattern
- BoxTreePattern

### View Modifiers to Audit (Layer 1)
- BadgeChipStyle
- CardStyle
- InteractiveStyle
- SurfaceStyle
- CopyableModifier

### Accessibility Testing Framework

Install and configure AccessibilitySnapshot:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/cashapp/AccessibilitySnapshot.git", from: "0.4.0")
]
```

### Test Categories

#### 1. Contrast Ratio Testing
- All text colors against their backgrounds
- Badge colors (info, warning, error, success)
- Focus indicators
- Target: ≥4.5:1 for normal text, ≥3:1 for large text (WCAG AA)

#### 2. VoiceOver Testing
- Accessibility labels present and descriptive
- Accessibility hints provide context
- Accessibility traits correctly set (.isButton, .isHeader, etc.)
- Custom actions exposed where appropriate
- Dynamic content announces changes

#### 3. Keyboard Navigation Testing
- All interactive elements keyboard accessible
- Focus order logical and predictable
- Focus indicators visible and high-contrast
- Keyboard shortcuts work as expected (⌘C, ⌘V, etc.)
- Escape key dismisses overlays

#### 4. Touch Target Testing
- Minimum size 44×44 pt on iOS (Apple HIG requirement)
- Minimum size 24×24 pt on macOS
- Adequate spacing between targets
- No overlapping interactive areas

#### 5. Dynamic Type Testing
- Text scales correctly from XS to XXXL
- Layout adapts without clipping
- Touch targets remain accessible at all sizes
- Scrolling enabled when content exceeds bounds

#### 6. Reduce Motion Testing
- Animations disabled or simplified when `accessibilityReduceMotion` is true
- Uses `DS.Animation.ifMotionEnabled` helper
- Content remains functional without motion

#### 7. Increase Contrast Testing
- High-contrast mode supported
- Uses `ColorSchemeAdapter` for adaptive colors
- Focus indicators enhanced in high-contrast mode

#### 8. Bold Text Testing (iOS)
- Font weights adapt via `legibilityWeight` environment value
- Text remains readable when bold text enabled

### Files to Create/Modify
- `Tests/FoundationUITests/AccessibilityTests/AccessibilityAuditTests.swift`
- `Tests/FoundationUITests/AccessibilityTests/ContrastRatioTests.swift`
- `Tests/FoundationUITests/AccessibilityTests/VoiceOverTests.swift`
- `Tests/FoundationUITests/AccessibilityTests/KeyboardNavigationTests.swift`
- `Tests/FoundationUITests/AccessibilityTests/TouchTargetTests.swift`
- `Tests/FoundationUITests/AccessibilityTests/DynamicTypeTests.swift`
- `Tests/FoundationUITests/AccessibilityTests/AccessibilityIntegrationTests.swift`
- `FoundationUI/DOCS/REPORTS/AccessibilityAuditReport.md` (results)

### Existing Accessibility Features to Validate

From AccessibilityHelpers (Phase 4.2):
```swift
// Verify these helpers work correctly
- .accessibleButton(label:hint:)
- .accessibleToggle(label:value:hint:)
- .accessibleHeading(level:)
- .accessibleValue(_:hint:)
- AccessibilityHintBuilder
- ContrastRatioValidator.meetsWCAG_AA()
- TouchTargetValidator.meetsMinimumSize()
- AccessibilityAuditor.audit(view:)
```

From AccessibilityContext (Phase 3.2):
```swift
// Verify context integration
- AccessibilityContext.reduceMotion
- AccessibilityContext.increaseContrast
- AccessibilityContext.boldText
- AccessibilityContext.dynamicTypeSize
- .adaptiveAccessibility() modifier
```

### WCAG 2.1 Level AA Criteria

| Criterion | Guideline | Target |
|-----------|-----------|--------|
| 1.4.3 Contrast (Minimum) | Text ≥4.5:1, Large text ≥3:1 | ✅ Target |
| 1.4.11 Non-text Contrast | UI components ≥3:1 | ✅ Target |
| 2.1.1 Keyboard | All functionality keyboard accessible | ✅ Target |
| 2.4.3 Focus Order | Focus order logical | ✅ Target |
| 2.4.7 Focus Visible | Keyboard focus indicator visible | ✅ Target |
| 2.5.5 Target Size | Touch targets ≥44×44 pt | ✅ Target |
| 4.1.2 Name, Role, Value | Accessible names and roles | ✅ Target |

### Automated Testing with AccessibilitySnapshot

Example test structure:
```swift
import XCTest
import AccessibilitySnapshot
@testable import FoundationUI

final class ComponentAccessibilityTests: XCTestCase {
    func testBadgeAccessibility() throws {
        let badge = Badge(text: "Error", level: .error, showIcon: true)

        // Snapshot test with accessibility hierarchy
        assertSnapshot(matching: badge, as: .accessibilityImage)

        // Validate contrast ratios
        let validator = ContrastRatioValidator()
        XCTAssertTrue(validator.meetsWCAG_AA(
            foreground: DS.Colors.textPrimary,
            background: DS.Colors.errorBG
        ))

        // Validate accessibility labels
        // ... test VoiceOver labels
    }
}
```

## 🧠 Source References
- [FoundationUI Task Plan § Phase 5.2 Accessibility Testing](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#accessibility-testing)
- [FoundationUI PRD § Accessibility Requirements](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [Apple Accessibility Guidelines](https://developer.apple.com/accessibility/)
- [WCAG 2.1 Level AA](https://www.w3.org/WAI/WCAG21/quickref/?currentsidebar=%23col_overview&levels=aaa)
- [AccessibilitySnapshot Documentation](https://github.com/cashapp/AccessibilitySnapshot)
- [AccessibilityHelpers Implementation](../../Sources/FoundationUI/Utilities/AccessibilityHelpers.swift)
- [AccessibilityContext Implementation](../../Sources/FoundationUI/Contexts/AccessibilityContext.swift)

## 📋 Checklist

### Setup
- [ ] Install AccessibilitySnapshot framework (Package.swift)
- [ ] Create accessibility test directory structure
- [ ] Set up test helpers and utilities
- [ ] Configure CI/CD for accessibility testing

### Layer 0: Design Tokens
- [ ] Validate color contrast ratios (DS.Colors)
- [ ] Test spacing tokens with touch targets (DS.Spacing)
- [ ] Verify typography scales with Dynamic Type (DS.Typography)

### Layer 1: View Modifiers
- [ ] BadgeChipStyle accessibility audit
- [ ] CardStyle accessibility audit
- [ ] InteractiveStyle accessibility audit
- [ ] SurfaceStyle accessibility audit
- [ ] CopyableModifier accessibility audit

### Layer 2: Components
- [ ] Badge accessibility audit (VoiceOver, contrast, touch targets)
- [ ] Card accessibility audit (focus order, keyboard navigation)
- [ ] KeyValueRow accessibility audit (copyable text, labels)
- [ ] SectionHeader accessibility audit (heading levels, traits)
- [ ] CopyableText accessibility audit (VoiceOver announcements)
- [ ] Copyable wrapper accessibility audit (generic content)

### Layer 3: Patterns
- [ ] InspectorPattern accessibility audit (scroll, focus management)
- [ ] SidebarPattern accessibility audit (navigation, selection)
- [ ] ToolbarPattern accessibility audit (keyboard shortcuts, menu)
- [ ] BoxTreePattern accessibility audit (hierarchy, expand/collapse)

### Layer 4: Contexts
- [ ] AccessibilityContext validation (all features)
- [ ] ColorSchemeAdapter contrast validation
- [ ] PlatformAdaptation keyboard navigation

### Cross-Cutting Concerns
- [ ] Contrast ratio tests for all color combinations
- [ ] VoiceOver label tests for all components
- [ ] Keyboard navigation tests for all interactive elements
- [ ] Touch target size tests (iOS ≥44×44, macOS ≥24×24)
- [ ] Dynamic Type tests (XS to XXXL)
- [ ] Reduce Motion tests (animation fallbacks)
- [ ] Increase Contrast tests (high-contrast mode)
- [ ] Bold Text tests (iOS legibilityWeight)

### Integration Testing
- [ ] Test component compositions (Card → Section → KeyValue → Badge)
- [ ] Test pattern integrations (Sidebar + Inspector + Toolbar)
- [ ] Test real-world scenarios (ISO Inspector use cases)
- [ ] Test accessibility in demo app

### Reporting
- [ ] Generate comprehensive accessibility audit report
- [ ] Calculate overall accessibility score
- [ ] Document all issues found and resolutions
- [ ] Create remediation plan for any failures
- [ ] Update Task Plan with results

### CI/CD Integration
- [ ] Add accessibility tests to CI pipeline
- [ ] Configure test result reporting
- [ ] Set up accessibility score monitoring
- [ ] Fail builds on accessibility violations (≥95% threshold)

## 🎯 Target Metrics

| Metric | Target | Current |
|--------|--------|---------|
| **Overall Accessibility Score** | ≥95% | TBD |
| **WCAG AA Compliance** | 100% | TBD |
| **VoiceOver Coverage** | 100% | TBD |
| **Contrast Ratio Pass Rate** | 100% | TBD |
| **Touch Target Pass Rate** | 100% | TBD |
| **Keyboard Navigation** | 100% | TBD |

## 📊 Estimated Effort
- Setup (AccessibilitySnapshot, test structure): 2 hours
- Layer 0-1 testing (Tokens, Modifiers): 3 hours
- Layer 2 testing (Components): 4 hours
- Layer 3 testing (Patterns): 4 hours
- Layer 4 testing (Contexts): 2 hours
- Integration testing: 3 hours
- Report generation and remediation: 3 hours
- CI/CD integration: 2 hours
- **Total**: ~23 hours

## 🔄 Next Steps After Completion
1. Review accessibility audit report
2. Fix any identified issues
3. Proceed to **Manual Accessibility Testing** (Phase 5.2 next task)
4. Then **Accessibility CI Integration** (Phase 5.2)
5. Continue to Performance Testing (Phase 5.2)

---

*Created: 2025-11-06*
*Status: IN PROGRESS*
*Archive Location: Will be moved to `TASK_ARCHIVE/41_Phase5.2_AccessibilityAudit/` upon completion*
