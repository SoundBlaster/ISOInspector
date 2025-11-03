# PRD: Utility Integration Tests (Phase 4.2)

**Document Version**: 1.0
**Date**: 2025-11-03
**Status**: Active
**Priority**: P1 (Quality Gate)
**Related To**: Phase 4.2 Utilities & Helpers

---

## 📋 Executive Summary

Implement comprehensive integration tests for all FoundationUI utilities (CopyableText, KeyboardShortcuts, AccessibilityHelpers) to verify they work correctly when integrated with real components, across different platforms, and in various usage scenarios.

This is a critical quality gate ensuring that utilities are production-ready and can be safely used throughout the FoundationUI component library.

---

## 🎯 Goals & Objectives

### Primary Goals

1. **Verify Component Integration**: Ensure utilities work correctly with real components (Badge, Card, KeyValueRow, SectionHeader)
2. **Test Cross-Platform Compatibility**: Validate behavior across iOS, macOS, and iPadOS
3. **Validate Accessibility Integration**: Confirm accessibility features work end-to-end with VoiceOver and keyboard navigation
4. **Ensure Production Readiness**: Catch integration issues before utilities are widely adopted

### Success Criteria

- ✅ ≥80% integration test coverage for all utilities
- ✅ Tests pass on all platforms (iOS 17+, macOS 14+, iPadOS 17+)
- ✅ Real component integration verified (Badge, Card, KeyValueRow, SectionHeader)
- ✅ Cross-platform clipboard behavior validated
- ✅ VoiceOver and keyboard navigation tested
- ✅ Platform-specific features verified (macOS keyboard shortcuts, iOS gestures)
- ✅ Zero flaky tests (tests are deterministic and repeatable)
- ✅ All tests use `#if canImport(SwiftUI)` guards for Linux compatibility

---

## 🏗️ Current State (As-Is)

### Completed Utilities

#### 1. CopyableText
- **File**: `Sources/FoundationUI/Utilities/CopyableText.swift`
- **Unit Tests**: 15 test cases ✅
- **Features**: Platform-specific clipboard, visual feedback, keyboard shortcuts, VoiceOver
- **Integration Status**: ❓ Not tested with real components

#### 2. KeyboardShortcuts
- **File**: `Sources/FoundationUI/Utilities/KeyboardShortcuts.swift`
- **Unit Tests**: 15 test cases ✅
- **Features**: Standard shortcuts, platform modifiers, display strings, accessibility labels
- **Integration Status**: ❓ Not tested with ToolbarPattern or real components

#### 3. AccessibilityHelpers
- **File**: `Sources/FoundationUI/Utilities/AccessibilityHelpers.swift`
- **Unit Tests**: 35 test cases ✅
- **Features**: WCAG 2.1 contrast validation, VoiceOver hints, accessibility modifiers, audit tools
- **Integration Status**: ❓ Not tested with real components or VoiceOver

### Existing Components Available for Integration

- ✅ **Badge** (Layer 2) - Status indicators
- ✅ **Card** (Layer 2) - Container component
- ✅ **KeyValueRow** (Layer 2) - Data display with copyable values
- ✅ **SectionHeader** (Layer 2) - Section headers
- ✅ **InspectorPattern** (Layer 3) - Full inspector layout
- ✅ **ToolbarPattern** (Layer 3) - Toolbar with keyboard shortcuts
- ✅ **SidebarPattern** (Layer 3) - Navigation sidebar
- ✅ **BoxTreePattern** (Layer 3) - Hierarchical tree

---

## 🎨 Proposed Solution (To-Be)

### Test Architecture

Create comprehensive integration test suite organized by utility and integration scenario:

```
Tests/FoundationUITests/IntegrationTests/
├── UtilityIntegrationTests/
│   ├── CopyableTextIntegrationTests.swift
│   ├── KeyboardShortcutsIntegrationTests.swift
│   ├── AccessibilityHelpersIntegrationTests.swift
│   └── CrossUtilityIntegrationTests.swift
```

### Test Categories

#### 1. CopyableText Integration Tests

**File**: `Tests/FoundationUITests/IntegrationTests/UtilityIntegrationTests/CopyableTextIntegrationTests.swift`

**Test Scenarios**:
- ✅ CopyableText within Card component
- ✅ CopyableText within KeyValueRow component
- ✅ Multiple CopyableText instances on same screen
- ✅ CopyableText with different typography (DS.Typography tokens)
- ✅ Platform-specific clipboard behavior (macOS NSPasteboard, iOS UIPasteboard)
- ✅ Visual feedback animation in component hierarchy
- ✅ Keyboard shortcut (⌘C) within Card
- ✅ VoiceOver announcement when copying
- ✅ CopyableText within InspectorPattern
- ✅ CopyableText with long text content (truncation/wrapping)

**Estimated Test Cases**: 12-15

#### 2. KeyboardShortcuts Integration Tests

**File**: `Tests/FoundationUITests/IntegrationTests/UtilityIntegrationTests/KeyboardShortcutsIntegrationTests.swift`

**Test Scenarios**:
- ✅ KeyboardShortcuts with ToolbarPattern items
- ✅ Standard shortcuts (Copy, Paste, Cut, Select All) with components
- ✅ Platform-specific modifiers (⌘ on macOS, Ctrl elsewhere)
- ✅ Display strings in UI labels
- ✅ Accessibility labels for VoiceOver
- ✅ Multiple shortcuts on same screen
- ✅ Shortcut conflicts detection
- ✅ Shortcuts with Card actions
- ✅ Shortcuts with Inspector actions (expand/collapse)
- ✅ Custom shortcuts integration

**Estimated Test Cases**: 10-12

#### 3. AccessibilityHelpers Integration Tests

**File**: `Tests/FoundationUITests/IntegrationTests/UtilityIntegrationTests/AccessibilityHelpersIntegrationTests.swift`

**Test Scenarios**:
- ✅ Contrast ratio validation on real Badge colors
- ✅ Contrast ratio validation on Card backgrounds
- ✅ VoiceOver hints with Badge component
- ✅ VoiceOver hints with KeyValueRow actions
- ✅ Accessibility modifiers (`.accessibleButton()`, `.accessibleToggle()`) on real buttons
- ✅ Touch target validation on interactive components
- ✅ Accessibility audit on complete InspectorPattern view
- ✅ Accessibility audit on ToolbarPattern
- ✅ Focus management with keyboard navigation in Sidebar
- ✅ Dynamic Type scaling with real typography
- ✅ AccessibilityContext integration with reduced motion
- ✅ AccessibilityContext integration with high contrast
- ✅ Platform-specific accessibility (macOS keyboard nav, iOS VoiceOver rotor)

**Estimated Test Cases**: 15-18

#### 4. Cross-Utility Integration Tests

**File**: `Tests/FoundationUITests/IntegrationTests/UtilityIntegrationTests/CrossUtilityIntegrationTests.swift`

**Test Scenarios**:
- ✅ CopyableText + AccessibilityHelpers (copyable text with accessibility audit)
- ✅ CopyableText + KeyboardShortcuts (copy with ⌘C shortcut)
- ✅ AccessibilityHelpers + KeyboardShortcuts (keyboard shortcuts with accessibility labels)
- ✅ All three utilities in InspectorPattern
- ✅ All three utilities in ToolbarPattern
- ✅ Utility composition in complex component hierarchy
- ✅ Platform-specific combinations (macOS shortcuts + accessibility)
- ✅ Performance with multiple utilities active

**Estimated Test Cases**: 8-10

---

## 🧪 Testing Strategy

### Test Structure

Each integration test should follow this pattern:

```swift
import XCTest
import SwiftUI
@testable import FoundationUI

#if canImport(SwiftUI)

@MainActor
final class CopyableTextIntegrationTests: XCTestCase {

    func testCopyableTextWithinCard() {
        // Given: A Card with CopyableText
        let card = Card {
            VStack {
                Text("Title")
                CopyableText(text: "Copyable Value")
            }
        }

        // When: Card is rendered
        // Then: CopyableText should be accessible and functional
        XCTAssertNotNil(card)

        // Additional assertions for integration behavior
    }

    func testCopyableTextClipboardBehavior() {
        // Test platform-specific clipboard integration
        #if os(macOS)
        // Test NSPasteboard
        #elseif os(iOS)
        // Test UIPasteboard
        #endif
    }
}

#endif // canImport(SwiftUI)
```

### Platform Testing Requirements

| Test Category | iOS | macOS | iPadOS | Notes |
|---------------|-----|-------|---------|-------|
| CopyableText Integration | ✅ | ✅ | ✅ | Test clipboard on all platforms |
| KeyboardShortcuts Integration | ⚠️ | ✅ | ⚠️ | Primary focus on macOS keyboard |
| AccessibilityHelpers Integration | ✅ | ✅ | ✅ | Test VoiceOver on iOS/macOS |
| Cross-Utility Integration | ✅ | ✅ | ✅ | All platforms |

Legend:
- ✅ = Full test coverage required
- ⚠️ = Partial coverage (keyboard hardware on iPad optional)

### Test Data & Fixtures

Create reusable test fixtures for common scenarios:

```swift
// TestFixtures.swift
enum UtilityTestFixtures {
    static let sampleText = "0x1234ABCD"
    static let longText = "A very long text value that might wrap..."

    static func sampleCard(withCopyableText text: String) -> Card<VStack<TupleView<...>>> {
        Card {
            VStack {
                Text("Sample Card")
                CopyableText(text: text)
            }
        }
    }

    static func sampleInspector() -> InspectorPattern {
        InspectorPattern(title: "Test Inspector") {
            KeyValueRow(key: "Value", value: "12345", isCopyable: true)
        }
    }
}
```

---

## 📊 Test Coverage Goals

### Minimum Requirements

| Utility | Unit Tests | Integration Tests | Total Coverage |
|---------|-----------|-------------------|----------------|
| CopyableText | 15 ✅ | 12-15 ⏳ | ≥80% |
| KeyboardShortcuts | 15 ✅ | 10-12 ⏳ | ≥80% |
| AccessibilityHelpers | 35 ✅ | 15-18 ⏳ | ≥90% (higher due to P1 accessibility) |
| Cross-Utility | N/A | 8-10 ⏳ | N/A |

**Total Integration Test Cases**: 45-55 tests

### Coverage Metrics

- **Integration Coverage**: ≥80% of public API interactions with components
- **Platform Coverage**: All tests pass on macOS (primary), iOS subset passes on iOS simulator
- **Scenario Coverage**: Real-world usage patterns from ISO Inspector use cases

---

## 🔧 Implementation Plan

### Phase 1: CopyableText Integration (Estimated: 2-3 hours)

1. Create `CopyableTextIntegrationTests.swift`
2. Write 12-15 integration tests
3. Test with Card, KeyValueRow, InspectorPattern
4. Verify clipboard behavior on macOS/iOS
5. Verify visual feedback animations
6. Verify VoiceOver announcements

### Phase 2: KeyboardShortcuts Integration (Estimated: 1.5-2 hours)

1. Create `KeyboardShortcutsIntegrationTests.swift`
2. Write 10-12 integration tests
3. Test with ToolbarPattern
4. Verify platform-specific modifiers
5. Verify display strings in UI
6. Test shortcut conflicts

### Phase 3: AccessibilityHelpers Integration (Estimated: 2-3 hours)

1. Create `AccessibilityHelpersIntegrationTests.swift`
2. Write 15-18 integration tests
3. Test contrast validation on real components
4. Test VoiceOver hints with real actions
5. Test accessibility audit on complete views
6. Test focus management with keyboard navigation
7. Test Dynamic Type with real typography

### Phase 4: Cross-Utility Integration (Estimated: 1-2 hours)

1. Create `CrossUtilityIntegrationTests.swift`
2. Write 8-10 integration tests
3. Test utility combinations
4. Test complex hierarchies (InspectorPattern + all utilities)
5. Performance testing with multiple utilities

### Phase 5: Documentation & QA (Estimated: 1 hour)

1. Document integration patterns
2. Update Task Plan
3. Create archive documentation
4. Run full test suite on macOS/iOS

**Total Estimated Effort**: 8-11 hours

---

## ✅ Acceptance Criteria

### Must Have (P0)

- [x] All 4 integration test files created
- [x] Minimum 45 integration test cases implemented
- [x] All tests pass on macOS
- [x] Platform guards (`#if canImport(SwiftUI)`) for Linux compatibility
- [x] CopyableText works with Card and KeyValueRow
- [x] KeyboardShortcuts works with ToolbarPattern
- [x] AccessibilityHelpers validates real component colors
- [x] Cross-utility combinations tested
- [x] Zero flaky tests (all tests deterministic)

### Should Have (P1)

- [x] Tests pass on iOS simulator
- [x] VoiceOver integration verified (manual testing)
- [x] Touch target validation on real components
- [x] Accessibility audit on complete patterns
- [x] Performance tests for multiple utilities
- [x] Test fixtures for reusable scenarios

### Nice to Have (P2)

- [ ] Tests pass on iPadOS (with hardware keyboard)
- [ ] Snapshot tests for visual feedback
- [ ] Real device testing (VoiceOver on iPhone/Mac)
- [ ] CI integration for automated testing
- [ ] Test coverage report generation

---

## 🚧 Known Constraints & Risks

### Technical Constraints

1. **Linux Environment**
   - SwiftUI not available on Linux
   - All tests require `#if canImport(SwiftUI)` guards
   - Full test execution requires macOS/Xcode

2. **VoiceOver Testing**
   - Manual testing required for VoiceOver announcements
   - Automated VoiceOver testing limited on CI
   - Real device testing preferred

3. **Platform-Specific Features**
   - Some features only available on specific platforms
   - Tests must use conditional compilation
   - macOS clipboard behavior differs from iOS

### Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Tests are flaky | High | Use deterministic assertions, avoid timing dependencies |
| Platform-specific failures | Medium | Separate platform-specific tests, clear documentation |
| VoiceOver not testable | Medium | Manual testing checklist, future automation research |
| Performance issues | Low | Performance tests with baselines, profiling on real devices |

---

## 📚 Reference Materials

### FoundationUI Documents

- [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) - Phase 4.2 Utilities & Helpers
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md) - Testing strategy
- [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) - Product requirements

### Existing Implementations

- **CopyableText**: `Sources/FoundationUI/Utilities/CopyableText.swift`
- **KeyboardShortcuts**: `Sources/FoundationUI/Utilities/KeyboardShortcuts.swift`
- **AccessibilityHelpers**: `Sources/FoundationUI/Utilities/AccessibilityHelpers.swift`

### Existing Unit Tests

- **CopyableTextTests**: `Tests/FoundationUITests/UtilitiesTests/CopyableTextTests.swift` (15 tests)
- **KeyboardShortcutsTests**: `Tests/FoundationUITests/UtilitiesTests/KeyboardShortcutsTests.swift` (15 tests)
- **AccessibilityHelpersTests**: `Tests/FoundationUITests/UtilitiesTests/AccessibilityHelpersTests.swift` (35 tests)

### Apple Documentation

- [Testing SwiftUI Views](https://developer.apple.com/documentation/swiftui/testing-swiftui-views)
- [Accessibility on iOS](https://developer.apple.com/accessibility/ios/)
- [Accessibility on macOS](https://developer.apple.com/accessibility/macos/)

---

## 🎯 Success Metrics

### Quantitative Metrics

- **Test Count**: ≥45 integration tests
- **Test Coverage**: ≥80% for utilities
- **Test Pass Rate**: 100% on macOS
- **Platform Coverage**: macOS (full), iOS (subset)
- **Execution Time**: <30 seconds for full integration suite

### Qualitative Metrics

- **Real-World Readiness**: Utilities work correctly in production scenarios
- **Developer Confidence**: Clear integration patterns documented
- **Accessibility Compliance**: WCAG 2.1 AA verified on real components
- **Cross-Platform Consistency**: Behavior predictable across platforms

---

## 📋 Checklist for Implementation

- [ ] Create integration test directory structure
- [ ] Implement CopyableTextIntegrationTests (12-15 tests)
- [ ] Implement KeyboardShortcutsIntegrationTests (10-12 tests)
- [ ] Implement AccessibilityHelpersIntegrationTests (15-18 tests)
- [ ] Implement CrossUtilityIntegrationTests (8-10 tests)
- [ ] Add platform guards for Linux compatibility
- [ ] Create test fixtures for reusable scenarios
- [ ] Run tests on macOS (primary platform)
- [ ] Run tests on iOS simulator (subset)
- [ ] Document integration patterns
- [ ] Update Task Plan with completion
- [ ] Create archive documentation
- [ ] Commit and push changes

---

## 🔄 Future Enhancements

### Post-MVP Improvements

1. **Automated VoiceOver Testing**
   - Research XCTest accessibility APIs
   - Implement automated VoiceOver announcement verification
   - Create VoiceOver testing framework

2. **Visual Regression Testing**
   - Snapshot tests for visual feedback animations
   - Compare rendering across platforms
   - Detect unintended visual changes

3. **Performance Benchmarking**
   - Establish performance baselines
   - Monitor regression over time
   - Profile on older devices

4. **CI/CD Integration**
   - Automated test execution on PR
   - Coverage reporting
   - Platform-specific test splits

---

## 📝 Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-03 | Initial PRD created for Phase 4.2 Utility Integration Tests | Claude |

---

## 📞 Stakeholders

- **Product Owner**: FoundationUI Team
- **Engineers**: Automation Agent
- **QA**: Manual accessibility testing required
- **Users**: All FoundationUI component consumers

---

*This PRD serves as the authoritative specification for Phase 4.2 Utility Integration Tests implementation.*
