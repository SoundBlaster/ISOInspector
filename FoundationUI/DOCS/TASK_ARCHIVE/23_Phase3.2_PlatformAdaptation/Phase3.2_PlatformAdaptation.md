# Phase 3.2: PlatformAdaptation Modifiers

## 🎯 Objective
Implement platform-adaptive view modifiers that automatically adjust spacing, layout, and behavior based on the current platform (iOS/iPadOS/macOS) and size class, ensuring consistent user experiences while respecting platform conventions.

## 🧩 Context
- **Phase**: Phase 3: Patterns & Platform Adaptation
- **Layer**: Layer 4 - Contexts
- **Priority**: P0 (Critical)
- **Dependencies**:
  - ✅ Design Tokens (Phase 1.2 - Complete)
  - ✅ View Modifiers (Phase 2.1 - Complete)
  - ✅ Components (Phase 2.2 - Complete)
  - ✅ SurfaceStyleKey environment key (Phase 3.2 - Complete)

## ✅ Success Criteria
- [ ] PlatformAdaptiveModifier ViewModifier created with platform-specific spacing logic
- [ ] Conditional compilation for macOS vs iOS using `#if os(macOS)` / `#if os(iOS)`
- [ ] Size class adaptation for iPad using `@Environment(\.horizontalSizeClass)` and `@Environment(\.verticalSizeClass)`
- [ ] Convenient View extensions for easy API usage (`.platformAdaptive()`, `.platformSpacing()`)
- [ ] Unit tests written and passing (≥90% coverage)
- [ ] Implementation follows DS token usage (zero magic numbers)
- [ ] SwiftUI Previews included for all platforms
- [ ] DocC documentation complete
- [ ] Accessibility labels added where applicable
- [ ] SwiftLint reports 0 violations
- [ ] Platform support verified (iOS 17+, macOS 14+, iPadOS 17+)

## 🔧 Implementation Notes

### Key Requirements from PRD
The PlatformAdaptation system must provide:

1. **Platform Detection**
   - Detect current platform (iOS/macOS/iPadOS)
   - Detect size class (compact/regular) on iOS/iPadOS
   - Detect window size on macOS

2. **Adaptive Spacing**
   - macOS: Typically uses smaller spacing (DS.Spacing.m as default)
   - iOS/iPadOS: Typically uses larger spacing (DS.Spacing.l as default)
   - Adjust based on size class (compact vs regular)

3. **Adaptive Layout**
   - Adapt component sizing for touch vs pointer input
   - Respect minimum touch target sizes (44×44 pt on iOS)
   - Support window resizing on macOS

4. **Conditional Compilation**
   - Use `#if os(macOS)` for macOS-specific code
   - Use `#if os(iOS)` for iOS/iPadOS-specific code
   - Avoid runtime platform checks where possible

### Files to Create/Modify
- **Primary**: `FoundationUI/Sources/FoundationUI/Contexts/PlatformAdaptation.swift`
- **Tests**: `FoundationUI/Tests/FoundationUITests/ContextsTests/PlatformAdaptationTests.swift`

### Design Token Usage
All spacing values must use DS tokens:
- **macOS default**: `DS.Spacing.m` (12pt)
- **iOS default**: `DS.Spacing.l` (16pt)
- **Compact size class**: `DS.Spacing.s` or `DS.Spacing.m` (8pt or 12pt)
- **Regular size class**: `DS.Spacing.l` or `DS.Spacing.xl` (16pt or 24pt)

### API Design

#### ViewModifier
```swift
struct PlatformAdaptiveModifier: ViewModifier {
    func body(content: Content) -> some View {
        // Platform-specific layout and spacing
    }
}
```

#### View Extension
```swift
extension View {
    /// Applies platform-adaptive spacing and layout
    func platformAdaptive() -> some View {
        modifier(PlatformAdaptiveModifier())
    }

    /// Applies platform-specific spacing value
    func platformSpacing(_ base: CGFloat = DS.Spacing.platformDefault) -> some View {
        // Platform-adaptive spacing
    }
}
```

#### Platform Detection Helpers
```swift
#if os(macOS)
let isPlatformMacOS = true
let isPlatformIOS = false
#else
let isPlatformMacOS = false
let isPlatformIOS = true
#endif
```

### Size Class Handling
Use SwiftUI environment values:
```swift
@Environment(\.horizontalSizeClass) private var horizontalSizeClass
@Environment(\.verticalSizeClass) private var verticalSizeClass

var isCompactLayout: Bool {
    horizontalSizeClass == .compact || verticalSizeClass == .compact
}
```

### Testing Strategy

**Unit Tests** (`PlatformAdaptationTests.swift`):
- Test platform detection logic
- Test spacing calculations for each platform
- Test size class adaptation (compact vs regular)
- Test ViewModifier integration
- Test View extension methods
- Mock environment values for testing

**Integration Tests**:
- Test with real components (Card, Badge, etc.)
- Test with patterns (InspectorPattern, SidebarPattern)
- Verify consistent behavior across platforms

**Snapshot Tests** (if applicable):
- Visual regression for platform-specific layouts
- Compare macOS vs iOS rendering
- Compare compact vs regular size classes

## 🧠 Source References
- [FoundationUI Task Plan § Phase 3.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#32-layer-4-contexts--platform-adaptation)
- [FoundationUI PRD § Platform Adaptation](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [Apple Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
- [Apple Human Interface Guidelines - iOS](https://developer.apple.com/design/human-interface-guidelines/ios)
- [SwiftUI Environment Values](https://developer.apple.com/documentation/swiftui/environmentvalues)
- [SwiftUI Size Classes](https://developer.apple.com/documentation/swiftui/userinterfacesizeclass)

## 📋 Checklist

### Planning & Setup
- [x] Read task requirements from Task Plan
- [x] Review Design Token usage requirements
- [x] Review platform-specific design guidelines
- [ ] Identify all platform-specific behaviors to implement

### Test-Driven Development
- [ ] Create test file: `Tests/FoundationUITests/ContextsTests/PlatformAdaptationTests.swift`
- [ ] Write failing tests for platform detection
- [ ] Write failing tests for spacing adaptation
- [ ] Write failing tests for size class handling
- [ ] Write failing tests for ViewModifier integration
- [ ] Run `swift test` to confirm all tests fail

### Implementation
- [ ] Create `Sources/FoundationUI/Contexts/PlatformAdaptation.swift`
- [ ] Implement platform detection helpers
- [ ] Implement PlatformAdaptiveModifier ViewModifier
- [ ] Implement View extensions for convenient API
- [ ] Add size class adaptation logic
- [ ] Use DS tokens exclusively (zero magic numbers)
- [ ] Run `swift test` to confirm tests pass

### Documentation & Previews
- [ ] Add DocC documentation to all public APIs
- [ ] Add inline code comments for complex logic
- [ ] Create SwiftUI Previews for macOS
- [ ] Create SwiftUI Previews for iOS
- [ ] Create SwiftUI Previews for iPad (compact and regular)
- [ ] Create SwiftUI Previews for Dark Mode
- [ ] Document platform-specific behaviors

### Quality Assurance
- [ ] Run `swiftlint` - verify 0 violations
- [ ] Test on iOS simulator (iPhone, iPad)
- [ ] Test on macOS
- [ ] Verify all platforms (iOS 17+, iPadOS 17+, macOS 14+)
- [ ] Test with different size classes
- [ ] Test with different window sizes (macOS)
- [ ] Verify accessibility with VoiceOver
- [ ] Verify Dynamic Type support

### Finalization
- [ ] Update Task Plan with [x] completion mark
- [ ] Move task to `TASK_ARCHIVE/23_Phase3.2_PlatformAdaptation/`
- [ ] Commit with descriptive message
- [ ] Update `next_tasks.md` with next priority

## 📝 Implementation Log

### 2025-10-26: Task Created
- Task document created following SELECT_NEXT.md algorithm
- Phase 3.2 marked as IN PROGRESS
- Priority: P0 (Critical)
- All prerequisites verified
- Ready to begin TDD implementation

## 🎬 Next Steps After Completion
After completing PlatformAdaptation modifiers, the next task will be:
1. **Phase 3.2: Implement ColorSchemeAdapter** (P0)
2. Write Context unit tests
3. Write Platform adaptation integration tests
4. Create platform comparison previews

---

**Status**: 🚧 IN PROGRESS
**Started**: 2025-10-26
**Expected Completion**: TBD
