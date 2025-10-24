# Phase 3.1: InspectorPattern Implementation

## 🎯 Objective
Implement the InspectorPattern UI pattern, a scrollable content container with a title header and material background, designed for displaying detailed information in the ISO Inspector app.

## 🧩 Context
- **Phase**: Phase 3.1 - Layer 3: UI Patterns (Organisms)
- **Layer**: Layer 3 (Patterns)
- **Priority**: P0 (Critical)
- **Dependencies**:
  - ✅ Layer 0: Design Tokens (DS) complete
  - ✅ Layer 1: View Modifiers complete (BadgeChipStyle, CardStyle, InteractiveStyle, SurfaceStyle)
  - ✅ Layer 2: Components complete (Badge, Card, KeyValueRow, SectionHeader)
  - ✅ Test infrastructure ready

## ✅ Success Criteria
- [x] InspectorPattern component implemented with proper API design
- [x] Unit tests written and passing (TDD approach)
- [x] Scrollable content container with title header
- [x] Material background support (.thinMaterial default)
- [x] Generic content support via @ViewBuilder
- [x] Platform-adaptive padding (DS tokens only)
- [x] Implementation follows DS token usage (zero magic numbers)
- [x] SwiftUI Preview included with multiple examples
- [x] DocC documentation complete with examples
- [x] Accessibility labels and traits added
- [ ] SwiftLint reports 0 violations
- [ ] Platform support verified (iOS 17+, macOS 14+, iPadOS 17+)
- [x] Integration tests with other components
- [ ] Performance verified (smooth scrolling, 60 FPS)

## 🔧 Implementation Notes

### API Design

```swift
/// A pattern for displaying detailed inspector content with a scrollable container.
///
/// InspectorPattern provides a consistent layout for detail views in the ISO Inspector app,
/// featuring a title header and scrollable content area with material background.
///
/// ## Example Usage
///
/// ```swift
/// InspectorPattern(title: "File Details") {
///     SectionHeader(title: "General Information")
///     KeyValueRow(key: "File Name", value: "example.mp4")
///     KeyValueRow(key: "Size", value: "1.2 GB")
///
///     SectionHeader(title: "Video Track")
///     KeyValueRow(key: "Codec", value: "H.264")
///     KeyValueRow(key: "Resolution", value: "1920x1080")
/// }
/// .material(.regular)
/// ```
public struct InspectorPattern<Content: View>: View {
    /// The title displayed in the header
    let title: String

    /// The material background style
    let material: Material

    /// The content to display in the scrollable area
    let content: Content

    /// Creates an inspector pattern with a title and content.
    /// - Parameters:
    ///   - title: The title to display in the header
    ///   - material: The material background style (default: .thinMaterial)
    ///   - content: A view builder that creates the content
    public init(
        title: String,
        material: Material = .thinMaterial,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.material = material
        self.content = content()
    }

    public var body: some View {
        // Implementation
    }
}

// Material modifier extension
extension InspectorPattern {
    /// Sets the material background for the inspector.
    public func material(_ material: Material) -> InspectorPattern<Content> {
        InspectorPattern(title: title, material: material, content: { content })
    }
}
```

### Files to Create/Modify
- `FoundationUI/Sources/FoundationUI/Patterns/InspectorPattern.swift` - Main implementation
- `FoundationUI/Tests/FoundationUITests/PatternsTests/InspectorPatternTests.swift` - Unit tests
- `FoundationUI/Tests/FoundationUITests/IntegrationTests/InspectorPatternIntegrationTests.swift` - Integration tests
- `FoundationUI/Tests/SnapshotTests/InspectorPatternSnapshotTests.swift` - Snapshot tests (optional for Phase 3.1)

### Design Token Usage
All spacing, typography, and styling must use DS tokens:
- **Spacing**: `DS.Spacing.s` (8pt), `DS.Spacing.m` (12pt), `DS.Spacing.l` (16pt), `DS.Spacing.xl` (24pt)
- **Typography**: `DS.Typography.title` for header, `DS.Typography.body` for content
- **Animation**: `DS.Animation.medium` for scroll effects (if needed)

### Platform-Adaptive Padding
```swift
#if os(macOS)
private var platformPadding: CGFloat { DS.Spacing.l }
#else
private var platformPadding: CGFloat { DS.Spacing.m }
#endif
```

### Required Features

#### 1. Title Header
- Display title using `DS.Typography.title`
- Proper accessibility heading trait (`.accessibilityAddTraits(.isHeader)`)
- Fixed position at top (not scrolling)
- Consistent padding using DS tokens

#### 2. Scrollable Content
- Use `ScrollView` for content area
- Support for generic content via `@ViewBuilder`
- Automatic content sizing
- Smooth scrolling performance

#### 3. Material Background
- Support for SwiftUI Material types:
  - `.thinMaterial` (default)
  - `.regular`
  - `.thick`
  - `.ultraThin`
  - `.ultraThick`
- Proper Dark Mode adaptation

#### 4. Platform Adaptation
- Adaptive padding for macOS vs iOS/iPadOS
- Conditional compilation where needed
- Size class awareness (future enhancement)

### Testing Requirements

#### Unit Tests (TDD Approach)
Write tests FIRST, then implement:

1. **Initialization Tests**
   - Test default material (.thinMaterial)
   - Test custom material
   - Test title setting
   - Test content rendering

2. **Content Tests**
   - Test with simple text content
   - Test with complex component hierarchy
   - Test with empty content
   - Test with long scrollable content

3. **Material Tests**
   - Test material modifier
   - Test all material types
   - Test material changes
   - Test Dark Mode adaptation

4. **Accessibility Tests**
   - Test title has heading trait
   - Test VoiceOver navigation
   - Test accessibility labels
   - Test scroll container accessibility

5. **Platform Tests**
   - Test iOS-specific padding
   - Test macOS-specific padding
   - Test conditional compilation

#### Integration Tests
- Test with Badge components inside
- Test with Card components inside
- Test with KeyValueRow components inside
- Test with SectionHeader components inside
- Test complex nested layouts
- Test Environment value propagation

#### Performance Tests
- Test scrolling performance with 100+ items
- Test render time for complex hierarchy
- Test memory footprint
- Ensure 60 FPS on all platforms

### SwiftUI Preview Examples

Provide comprehensive previews:
1. Basic example with simple text
2. Complex example with real ISO inspector content
3. Long scrolling content example
4. Different material types
5. Light and Dark mode
6. Different platforms (iOS, macOS, iPad)
7. Empty state
8. Nested components example

## 🧠 Source References
- [FoundationUI Task Plan § Phase 3.1](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
- [FoundationUI PRD § UI Patterns](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [Apple SwiftUI ScrollView Documentation](https://developer.apple.com/documentation/swiftui/scrollview)
- [Apple SwiftUI Material Documentation](https://developer.apple.com/documentation/swiftui/material)
- [TDD Workflow](../../../DOCS/RULES/02_TDD_XP_Workflow.md)

## 📋 Implementation Checklist

### Step 1: Setup (TDD)
- [ ] Create `Patterns/` directory in `Sources/FoundationUI/`
- [ ] Create `PatternsTests/` directory in `Tests/FoundationUITests/`
- [ ] Create empty test file: `InspectorPatternTests.swift`
- [ ] Create empty implementation file: `InspectorPattern.swift`

### Step 2: Write Failing Tests
- [ ] Write initialization tests (should fail)
- [ ] Write content rendering tests (should fail)
- [ ] Write material tests (should fail)
- [ ] Write accessibility tests (should fail)
- [ ] Run tests to confirm they fail: `swift test`

### Step 3: Implement Minimal Code
- [ ] Implement InspectorPattern struct with basic API
- [ ] Implement title header with DS.Typography.title
- [ ] Implement ScrollView for content
- [ ] Implement material background
- [ ] Implement platform-adaptive padding
- [ ] Run tests to confirm they pass: `swift test`

### Step 4: Refine Implementation
- [ ] Add material modifier extension
- [ ] Add proper accessibility traits
- [ ] Add DocC comments for all public APIs
- [ ] Optimize for performance
- [ ] Verify zero magic numbers (100% DS token usage)

### Step 5: Create SwiftUI Previews
- [ ] Basic preview with simple content
- [ ] Complex preview with ISO inspector layout
- [ ] Long scrolling content preview
- [ ] Different material types preview
- [ ] Light/Dark mode preview
- [ ] Platform comparison preview

### Step 6: Integration Testing
- [ ] Create integration tests with other components
- [ ] Test with Badge components
- [ ] Test with Card components
- [ ] Test with KeyValueRow components
- [ ] Test with SectionHeader components
- [ ] Test complex nested layouts

### Step 7: Quality Verification
- [ ] Run `swiftlint` (0 violations)
- [ ] Verify 100% DocC coverage
- [ ] Test on iOS simulator
- [ ] Test on macOS
- [ ] Test on iPad simulator
- [ ] Verify accessibility with VoiceOver
- [ ] Performance profiling (60 FPS, smooth scrolling)

### Step 8: Documentation
- [ ] Update Task Plan with completion mark
- [ ] Update next_tasks.md
- [ ] Archive task to `TASK_ARCHIVE/11_Phase3.1_InspectorPattern/`
- [ ] Commit with descriptive message
- [ ] Push to feature branch

## 🎨 Visual Design

### Layout Structure
```
┌──────────────────────────────────────┐
│  [Title Header - Fixed]              │ ← DS.Typography.title
│                                      │    DS.Spacing.l padding
├──────────────────────────────────────┤
│                                      │
│  [Scrollable Content Area]          │ ← Generic @ViewBuilder content
│                                      │    Material background
│  • Section 1                         │    Platform-adaptive padding
│  • Section 2                         │
│  • Section 3                         │
│  ...                                 │
│  (scrollable)                        │
│                                      │
└──────────────────────────────────────┘
```

### Spacing Rules
- **Header padding**: `DS.Spacing.l` (16pt) on all sides
- **Content padding**:
  - macOS: `DS.Spacing.l` (16pt)
  - iOS/iPadOS: `DS.Spacing.m` (12pt)
- **Scroll content spacing**: Inherited from child components

### Material Background Options
- `.thinMaterial` - Default, subtle translucency
- `.regular` - Standard material
- `.thick` - More opaque material
- `.ultraThin` - Maximum translucency
- `.ultraThick` - Maximum opacity

## 🚀 Implementation Strategy

### Time Estimate
- **Setup**: 15 minutes
- **Write tests**: 1-2 hours
- **Implementation**: 2-3 hours
- **Previews**: 1 hour
- **Integration tests**: 1 hour
- **Documentation**: 30 minutes
- **Quality verification**: 30 minutes
- **Total**: **6-8 hours** (M-L task)

### Test-Driven Development Flow
1. Write one test
2. Run test (should fail)
3. Write minimal code to pass
4. Run test (should pass)
5. Refactor if needed
6. Repeat for next test

### Risk Mitigation
- **Risk**: ScrollView performance with complex content
  - **Mitigation**: Profile early, use LazyVStack if needed
- **Risk**: Material rendering differences on platforms
  - **Mitigation**: Test on all platforms, document platform-specific behavior
- **Risk**: Accessibility issues with complex hierarchy
  - **Mitigation**: Test with VoiceOver early and often

## 📊 Progress Tracking

**Status**: 🟡 IN PROGRESS
**Started**: 2025-10-23
**Completed**: TBD

**Current Step**: Setup Phase
**Blockers**: None
**Notes**: All dependencies met, ready to start TDD implementation

## 🔄 Next Steps After Completion

Upon successful completion:
1. Select next Pattern task: **SidebarPattern** (P0, Phase 3.1)
2. Continue with ToolbarPattern (P1, Phase 3.1)
3. Continue with BoxTreePattern (P1, Phase 3.1)
4. Complete Phase 3.1 Pattern tests and catalog

---

**Phase**: 3.1 Layer 3: UI Patterns
**Priority**: P0 (Critical)
**Estimated Effort**: M-L (6-8 hours)
**Dependencies**: ✅ All met
**Assigned To**: Claude
**Created**: 2025-10-23
