# SectionHeader Component Implementation

## 🎯 Objective
Implement a SectionHeader component for organizing inspector views and list sections with uppercase title styling, optional divider support, and accessibility compliance.

## 🧩 Context
- **Phase**: Phase 2.2 - Layer 2: Essential Components (Molecules)
- **Layer**: Layer 2 (Components)
- **Priority**: P0 (Critical)
- **Dependencies**: DS.Typography ✅, DS.Spacing ✅
- **Estimated Effort**: S (2-4 hours)

## ✅ Success Criteria
- [ ] Unit tests written and passing
- [ ] Implementation follows DS token usage (zero magic numbers)
- [ ] SwiftUI Preview included
- [ ] DocC documentation complete
- [ ] Accessibility labels added (`.accessibilityAddTraits(.isHeader)`)
- [ ] SwiftLint reports 0 violations
- [ ] Platform support verified (iOS/macOS/iPadOS)
- [ ] Uppercase title styling implemented (`.textCase(.uppercase)`)
- [ ] Optional divider support implemented
- [ ] Consistent spacing via DS.Spacing tokens

## 🔧 Implementation Notes

### Design Requirements
The SectionHeader component is essential for organizing content in inspector views and structured lists. It provides visual hierarchy and clear content separation.

### Key Features
1. **Uppercase Title Styling**: Uses `.textCase(.uppercase)` for visual consistency
2. **Optional Divider**: Supports optional horizontal divider below the title
3. **Spacing Consistency**: All spacing uses DS.Spacing tokens (zero magic numbers)
4. **Accessibility**: Proper heading level with `.accessibilityAddTraits(.isHeader)`
5. **Typography**: Uses DS.Typography tokens for text styling

### Files to Create/Modify
- `Sources/FoundationUI/Components/SectionHeader.swift` (NEW)
- `Tests/FoundationUITests/ComponentsTests/SectionHeaderTests.swift` (NEW)

### Design Token Usage
- **Spacing**:
  - `DS.Spacing.s` (8pt) - for tight internal spacing
  - `DS.Spacing.m` (12pt) - for standard spacing
  - `DS.Spacing.l` (16pt) - for comfortable section spacing
  - `DS.Spacing.xl` (24pt) - for large section separators
- **Typography**:
  - `DS.Typography.caption` - for section header text (small, uppercase)
  - `DS.Typography.subheadline` - alternative for larger headers
- **Colors**: Use system colors for divider (`.secondary` or similar)

### Component API Design
```swift
public struct SectionHeader: View {
    public init(
        title: String,
        showDivider: Bool = false
    )
}
```

### Implementation Checklist
- [ ] Create component file with proper imports
- [ ] Implement public initializer
- [ ] Add title text with uppercase styling
- [ ] Add optional divider support
- [ ] Apply DS.Spacing tokens consistently
- [ ] Add accessibility header trait
- [ ] Create comprehensive DocC documentation
- [ ] Create at least 4 SwiftUI Previews:
  - Preview 1: Basic header without divider
  - Preview 2: Header with divider
  - Preview 3: Multiple headers in a list context
  - Preview 4: Dark Mode variant
- [ ] Write unit tests (minimum 8 test cases):
  - Test title rendering
  - Test divider visibility (show/hide)
  - Test spacing consistency
  - Test accessibility traits
  - Test Dark Mode support
  - Test platform rendering
  - Test text case transformation
  - Test component composition

## 🧠 Source References
- [FoundationUI Task Plan § Phase 2.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
- [FoundationUI PRD § Components](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [Next Tasks § SectionHeader](./next_tasks.md)
- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

## 📋 Implementation Workflow Checklist
Following TDD/XP workflow from [02_TDD_XP_Workflow.md](../../../DOCS/RULES/02_TDD_XP_Workflow.md):

### 1. Test First (Red Phase)
- [ ] Create test file: `Tests/FoundationUITests/ComponentsTests/SectionHeaderTests.swift`
- [ ] Write failing tests for all public API surface
- [ ] Run `swift test` to confirm failure (RED)
- [ ] Commit: "Add failing tests for SectionHeader component"

### 2. Minimal Implementation (Green Phase)
- [ ] Create component file: `Sources/FoundationUI/Components/SectionHeader.swift`
- [ ] Implement minimal code using DS tokens exclusively
- [ ] Run `swift test` to confirm pass (GREEN)
- [ ] Commit: "Implement SectionHeader component (tests passing)"

### 3. Refactor & Polish
- [ ] Add comprehensive DocC documentation
- [ ] Create SwiftUI Previews (minimum 4 variations)
- [ ] Run `swiftlint` (target: 0 violations)
- [ ] Verify zero magic numbers
- [ ] Test on iOS simulator
- [ ] Test on macOS
- [ ] Commit: "Add documentation and previews for SectionHeader"

### 4. Validation & Archive
- [ ] Update Task Plan with [x] completion mark
- [ ] Update next_tasks.md progress tracker
- [ ] Run final verification:
  - [ ] All tests pass
  - [ ] SwiftLint 0 violations
  - [ ] 100% DocC coverage
  - [ ] All previews render correctly
- [ ] Commit all changes with descriptive message
- [ ] Move this file to `TASK_ARCHIVE/03_Phase2.2_SectionHeader/`

## 🎨 Example Preview Code
```swift
#Preview("Basic Header") {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        SectionHeader(title: "File Properties")
        Text("Example content")
    }
    .padding()
}

#Preview("Header with Divider") {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        SectionHeader(title: "Metadata", showDivider: true)
        Text("Example content")
    }
    .padding()
}

#Preview("Multiple Sections") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Basic Information", showDivider: true)
                Text("Content for basic information")
            }

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Technical Details", showDivider: true)
                Text("Content for technical details")
            }
        }
        .padding()
    }
}

#Preview("Dark Mode") {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        SectionHeader(title: "Box Structure", showDivider: true)
        Text("Example content")
    }
    .padding()
    .preferredColorScheme(.dark)
}
```

## 🧪 Example Test Cases
```swift
final class SectionHeaderTests: XCTestCase {
    func testSectionHeaderCreation() {
        // Test basic creation
    }

    func testSectionHeaderWithDivider() {
        // Test divider visibility
    }

    func testSectionHeaderAccessibility() {
        // Test accessibility traits
    }

    func testSectionHeaderTextCase() {
        // Test uppercase transformation
    }

    func testSectionHeaderSpacing() {
        // Test DS.Spacing token usage
    }

    func testSectionHeaderDarkMode() {
        // Test Dark Mode rendering
    }

    func testSectionHeaderPlatformSupport() {
        // Test cross-platform compatibility
    }

    func testSectionHeaderComposition() {
        // Test nesting with other components
    }
}
```

## ⚠️ Common Pitfalls to Avoid
1. **Magic Numbers**: All spacing values MUST use DS.Spacing tokens
2. **Hardcoded Colors**: Use semantic colors or system colors
3. **Missing Accessibility**: Always add `.accessibilityAddTraits(.isHeader)`
4. **No Dark Mode**: Test both Light and Dark modes
5. **Platform Differences**: Verify on both iOS and macOS
6. **Missing Tests**: Achieve minimum 85% code coverage

## 🚀 Next Steps After Completion
After successfully implementing and archiving SectionHeader:
1. Select next component (Card or KeyValueRow)
2. Follow same TDD workflow
3. Continue building Phase 2.2 components
4. Track progress in next_tasks.md

---

**Status**: IN PROGRESS
**Started**: 2025-10-21
**Assigned**: Claude Code Agent
