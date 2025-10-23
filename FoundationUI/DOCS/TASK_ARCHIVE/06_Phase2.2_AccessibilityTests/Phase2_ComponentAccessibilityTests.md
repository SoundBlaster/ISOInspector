# Component Accessibility Tests

## 🎯 Objective
Implement comprehensive accessibility tests for all Phase 2.2 components (Badge, Card, KeyValueRow, SectionHeader) to ensure WCAG 2.1 AA compliance and excellent VoiceOver experience.

## 🧩 Context
- **Phase**: Phase 2.2 - Layer 2: Essential Components (Testing)
- **Layer**: Layer 2 - Components
- **Priority**: P1 (Important for quality)
- **Dependencies**:
  - ✅ Badge component implemented
  - ✅ Card component implemented
  - ✅ KeyValueRow component implemented
  - ✅ SectionHeader component implemented
  - ✅ Test infrastructure exists

## ✅ Success Criteria
- [ ] VoiceOver navigation tests for all 4 components
- [ ] Contrast ratio validation (≥4.5:1 for all text/background combinations)
- [ ] Keyboard navigation tests (macOS specific)
- [ ] Focus management verification
- [ ] Touch target size validation (≥44×44 pt on iOS/iPadOS)
- [ ] Accessibility trait verification (isButton, isHeader, etc.)
- [ ] Dynamic Type testing (XS, M, XXL, XXXL)
- [ ] VoiceOver hint validation
- [ ] Accessibility identifier validation
- [ ] SwiftLint reports 0 violations in test files
- [ ] All tests passing in CI/CD pipeline
- [ ] Test coverage ≥90% for accessibility code paths

## 🔧 Implementation Notes

### Test Strategy

#### 1. VoiceOver Tests
- Test accessibilityLabel for all components
- Test accessibilityHint for interactive elements
- Test accessibilityValue for stateful components
- Test accessibilityTraits (isButton, isHeader, isStaticText)
- Verify VoiceOver announcement content

#### 2. Contrast Ratio Tests
Using ColorContrast calculations:
- Badge levels: info (≥4.5:1), warning (≥4.5:1), error (≥4.5:1), success (≥4.5:1)
- Card backgrounds: Verify all text/background combinations
- SectionHeader: Title text vs background
- KeyValueRow: Key and value text vs background

#### 3. Keyboard Navigation Tests (macOS)
- Tab order verification
- Focus ring visibility
- Keyboard shortcuts (if applicable)
- Arrow key navigation (for tree structures)

#### 4. Touch Target Tests (iOS/iPadOS)
- Minimum touch target: 44×44 pt
- Interactive area calculation
- Spacing between interactive elements

#### 5. Dynamic Type Tests
- Test all text scales from XS to XXXL
- Ensure no text truncation
- Layout adaptation verification

### Files to Create/Modify

#### New Test Files
- `Tests/FoundationUITests/AccessibilityTests/BadgeAccessibilityTests.swift`
- `Tests/FoundationUITests/AccessibilityTests/CardAccessibilityTests.swift`
- `Tests/FoundationUITests/AccessibilityTests/KeyValueRowAccessibilityTests.swift`
- `Tests/FoundationUITests/AccessibilityTests/SectionHeaderAccessibilityTests.swift`

#### Test Helper Utilities
- `Tests/FoundationUITests/AccessibilityTests/AccessibilityTestHelpers.swift`
  - Contrast ratio calculator
  - Touch target size validator
  - VoiceOver label builder
  - Dynamic Type size iterator

### Design Token Usage
These tests verify that components use DS tokens correctly:
- `DS.Colors.*` for all color values
- `DS.Spacing.*` for all spacing/padding
- `DS.Typography.*` for all text styles
- `DS.Radius.*` for corner radii

### Testing Frameworks
- **XCTest** - Unit testing framework
- **SwiftUI ViewInspector** (if needed) - For inspecting SwiftUI view hierarchy
- **AccessibilitySnapshot** (optional) - For visual accessibility testing

## 🧠 Source References
- [FoundationUI Task Plan § Phase 2.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#22-layer-2-essential-components-molecules)
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Apple Accessibility Documentation](https://developer.apple.com/documentation/accessibility)
- [SwiftUI Accessibility Modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility)

## 📋 Checklist

### Setup
- [ ] Create `Tests/FoundationUITests/AccessibilityTests/` directory
- [ ] Create `AccessibilityTestHelpers.swift` with utility functions
- [ ] Review WCAG 2.1 AA requirements
- [ ] Review existing component implementations for accessibility features

### Badge Component Tests
- [ ] Test Badge.accessibilityLabel for all levels (info, warning, error, success)
- [ ] Test Badge icon + text VoiceOver announcement
- [ ] Verify Badge color contrast ratios (≥4.5:1)
- [ ] Test Badge with Dynamic Type (XS to XXXL)
- [ ] Verify Badge touch target size (≥44×44 pt)

### Card Component Tests
- [ ] Test Card.accessibilityElement grouping
- [ ] Test Card content VoiceOver traversal order
- [ ] Verify Card background/content contrast
- [ ] Test Card with nested interactive elements
- [ ] Test Card focus management (macOS)

### KeyValueRow Component Tests
- [ ] Test KeyValueRow.accessibilityLabel format ("Key: Value")
- [ ] Test copyable value VoiceOver hint ("Double-tap to copy")
- [ ] Verify KeyValueRow text contrast (key vs value)
- [ ] Test KeyValueRow with Dynamic Type
- [ ] Test KeyValueRow touch target (when copyable)

### SectionHeader Component Tests
- [ ] Test SectionHeader.accessibilityTraits includes .isHeader
- [ ] Test SectionHeader uppercase text announcement
- [ ] Verify SectionHeader heading level
- [ ] Test SectionHeader divider accessibility (decorative)
- [ ] Test SectionHeader with Dynamic Type

### Integration Tests
- [ ] Test component nesting accessibility
- [ ] Test Environment value propagation
- [ ] Test accessibility in Light/Dark mode
- [ ] Test RTL layout accessibility

### Documentation & Quality
- [ ] Add DocC comments to all test methods
- [ ] Run `swiftlint` on test files (0 violations)
- [ ] Verify test coverage ≥90% with Xcode coverage tool
- [ ] Update Task Plan with [x] completion mark
- [ ] Archive task document

### Commit & Archive
- [ ] Commit with message: "Add comprehensive accessibility tests for Phase 2.2 components"
- [ ] Move this file to `TASK_ARCHIVE/06_Phase2.2_AccessibilityTests/`
- [ ] Update `next_tasks.md` with next recommended task

## 📊 Expected Test Metrics

### Test Coverage Targets
- Badge accessibility: ≥95% coverage
- Card accessibility: ≥90% coverage
- KeyValueRow accessibility: ≥95% coverage
- SectionHeader accessibility: ≥95% coverage

### Test Count Estimate
- Badge: ~15 accessibility tests
- Card: ~12 accessibility tests
- KeyValueRow: ~15 accessibility tests
- SectionHeader: ~10 accessibility tests
- Integration: ~8 tests
- **Total: ~60 accessibility tests**

### Quality Gates
- ✅ All tests passing
- ✅ Zero SwiftLint violations
- ✅ No force unwrapping in test code
- ✅ All tests are deterministic (no flakiness)
- ✅ Test execution time <30 seconds for full suite

## 🚀 Getting Started

1. Create the AccessibilityTests directory
2. Implement AccessibilityTestHelpers with contrast ratio calculator
3. Start with Badge accessibility tests (simplest component)
4. Move to SectionHeader tests
5. Implement KeyValueRow tests (includes copyable interaction)
6. Finish with Card tests (most complex)
7. Add integration tests
8. Verify all tests pass
9. Check code coverage metrics

## 📝 Notes

- Focus on automated tests that can run in CI/CD
- Manual VoiceOver testing should be documented separately
- Contrast ratios can be calculated programmatically using color components
- Touch target sizes can be verified in SwiftUI previews
- Dynamic Type testing should cover all standard sizes
- Consider using AccessibilitySnapshot for visual regression if available

---

**Created**: 2025-10-22
**Status**: Ready to start
**Estimated Effort**: M (4-6 hours)
**Related Archive**: Will be archived to `TASK_ARCHIVE/06_Phase2.2_AccessibilityTests/`
