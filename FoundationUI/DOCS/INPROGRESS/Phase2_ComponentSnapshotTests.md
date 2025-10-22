# Component Snapshot Tests

## 🎯 Objective
Implement comprehensive snapshot testing for all Phase 2.2 components (Badge, Card, SectionHeader, KeyValueRow) to prevent visual regressions and ensure consistent rendering across platforms, themes, and accessibility settings.

## 🧩 Context
- **Phase**: Phase 2.2 - Core Components Testing
- **Layer**: Layer 2 - Components (Testing Infrastructure)
- **Priority**: P0 (Critical)
- **Dependencies**:
  - ✅ Badge component implemented
  - ✅ Card component implemented
  - ✅ SectionHeader component implemented
  - ✅ KeyValueRow component implemented
  - ✅ Unit tests for all components exist

## ✅ Success Criteria
- [ ] SnapshotTesting framework integrated into project
- [ ] Snapshot tests created for all 4 components
- [ ] Light/Dark mode variants tested for all components
- [ ] Dynamic Type sizes tested (XS, M, XXL minimum)
- [ ] Platform-specific layouts tested (iOS/macOS/iPadOS where applicable)
- [ ] RTL locale support tested
- [ ] Snapshot storage configured in repository
- [ ] CI pipeline documentation for snapshot updates
- [ ] All snapshot tests pass on first run
- [ ] Documentation on snapshot update workflow

## 🔧 Implementation Notes

### Why This Task Is Critical
Visual regression testing is essential now that we have 4 complete components. Without snapshot tests:
- UI changes could accidentally break existing component appearance
- Platform-specific rendering issues could go unnoticed
- Dark mode regressions could slip through
- Accessibility features (Dynamic Type) could break silently

### Files to Create
```
Tests/SnapshotTests/
├── BadgeSnapshotTests.swift
├── CardSnapshotTests.swift
├── SectionHeaderSnapshotTests.swift
├── KeyValueRowSnapshotTests.swift
└── SnapshotHelpers.swift (optional utilities)

__Snapshots__/
└── (Generated snapshot images will be stored here)
```

### SnapshotTesting Framework Setup
1. Add SnapshotTesting dependency to Package.swift
   ```swift
   .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0")
   ```
2. Add to test target dependencies
3. Configure snapshot storage path

### Test Coverage Requirements

#### For Each Component (Badge, Card, SectionHeader, KeyValueRow):

**1. Theme Variants** (Minimum):
- Light mode baseline
- Dark mode variant

**2. Dynamic Type Sizes** (Minimum):
- Extra Small (XS)
- Medium (default)
- Extra Extra Large (XXL)

**3. Platform-Specific** (Where applicable):
- iOS 17+ rendering
- macOS 14+ rendering
- iPadOS 17+ rendering (for adaptive components)

**4. Component-Specific Variants**:

**Badge**:
- All BadgeLevel variants (info, warning, error, success)
- With and without icons
- Long text vs short text

**Card**:
- All elevation levels (none, low, medium, high)
- All corner radius options (via DS.Radius)
- Different content types (text, images, nested components)
- Material backgrounds (thin, regular, thick)

**SectionHeader**:
- With and without divider
- Long vs short titles
- With and without accessibility heading trait

**KeyValueRow**:
- Horizontal and vertical layouts
- With and without copyable text
- Long keys and values (truncation testing)
- Monospaced vs regular fonts

**5. RTL Support**:
- Test at least one snapshot per component in RTL locale (Arabic/Hebrew)
- Verify text alignment and layout mirroring

### Example Snapshot Test Structure

```swift
import XCTest
import SwiftUI
import SnapshotTesting
@testable import FoundationUI

final class BadgeSnapshotTests: XCTestCase {
    func testBadgeInfoLightMode() {
        let badge = Badge(text: "Info", level: .info)
        assertSnapshot(
            matching: badge,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeInfoDarkMode() {
        let badge = Badge(text: "Info", level: .info)
            .preferredColorScheme(.dark)
        assertSnapshot(
            matching: badge,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeDynamicTypeXXL() {
        let badge = Badge(text: "Warning", level: .warning)
            .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
        assertSnapshot(
            matching: badge,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }
}
```

### Snapshot Recording Workflow
1. **Initial Recording**: Set `record: true` to generate baseline snapshots
2. **Run tests**: Execute test suite to capture snapshots
3. **Commit snapshots**: Add generated images to version control
4. **Switch to comparison mode**: Set `record: false`
5. **Verify**: Run tests again to ensure they pass against baselines

### CI Integration Notes
- Snapshots must be committed to repository
- CI should fail if snapshots don't match
- Document process for intentionally updating snapshots
- Consider snapshot diff previews in PR reviews

## 🧠 Source References
- [FoundationUI Task Plan § Phase 2.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#22-layer-2-essential-components-molecules)
- [SnapshotTesting Documentation](https://github.com/pointfreeco/swift-snapshot-testing)
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md)
- [Apple Human Interface Guidelines - Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

## 📋 Checklist

### Setup Phase
- [ ] Add SnapshotTesting framework to Package.swift
- [ ] Configure test target dependencies
- [ ] Create Tests/SnapshotTests/ directory structure
- [ ] Configure snapshot storage location

### Badge Snapshot Tests
- [ ] Create BadgeSnapshotTests.swift
- [ ] Test all BadgeLevel variants (info, warning, error, success)
- [ ] Test Light/Dark mode
- [ ] Test Dynamic Type (XS, M, XXL)
- [ ] Test with/without icons
- [ ] Test RTL layout

### Card Snapshot Tests
- [ ] Create CardSnapshotTests.swift
- [ ] Test all elevation levels
- [ ] Test all corner radius options
- [ ] Test Light/Dark mode
- [ ] Test Dynamic Type
- [ ] Test different material backgrounds
- [ ] Test with various content types

### SectionHeader Snapshot Tests
- [ ] Create SectionHeaderSnapshotTests.swift
- [ ] Test with/without divider
- [ ] Test Light/Dark mode
- [ ] Test Dynamic Type
- [ ] Test long vs short titles
- [ ] Test RTL layout

### KeyValueRow Snapshot Tests
- [ ] Create KeyValueRowSnapshotTests.swift
- [ ] Test horizontal/vertical layouts
- [ ] Test Light/Dark mode
- [ ] Test Dynamic Type
- [ ] Test with/without copyable text
- [ ] Test long text truncation
- [ ] Test RTL layout

### Verification Phase
- [ ] Run all snapshot tests with `record: true`
- [ ] Verify generated snapshots look correct
- [ ] Commit snapshot images to repository
- [ ] Switch to `record: false`
- [ ] Run tests again to verify comparison mode works
- [ ] Ensure all tests pass (0 failures)
- [ ] Run swift test to confirm full test suite passes

### Documentation Phase
- [ ] Document snapshot update workflow
- [ ] Add README for snapshot testing
- [ ] Document CI integration requirements
- [ ] Update Task Plan with completion status
- [ ] Commit with descriptive message

### Quality Gates
- [ ] All snapshot tests pass
- [ ] Minimum 3 snapshot variants per component (Light/Dark/Accessibility)
- [ ] Platform-specific snapshots where applicable
- [ ] RTL support validated
- [ ] CI documentation complete

## 📊 Expected Deliverables

**Test Files**: 4 snapshot test files (one per component)
**Snapshot Images**: ~40-60 baseline snapshot images
**Documentation**: Snapshot workflow guide
**Success Metric**: 100% snapshot coverage for all Phase 2.2 components

## ⏱️ Estimated Effort
**Large (L)**: 1-2 days
- Framework setup: 2-4 hours
- Badge snapshots: 2-3 hours
- Card snapshots: 3-4 hours
- SectionHeader snapshots: 2-3 hours
- KeyValueRow snapshots: 3-4 hours
- Documentation: 1-2 hours

## 🔄 Next Steps After Completion
1. Component Accessibility Tests (P1)
2. Component Performance Tests (P1)
3. Component Integration Tests (P1)
4. Code Quality Verification (P1)
5. Demo Application (P0)

---

**Status**: 🔵 Ready to Start
**Created**: 2025-10-22
**Dependencies Met**: ✅ All Phase 2.2 components complete
