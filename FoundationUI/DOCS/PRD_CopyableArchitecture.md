# PRD: Copyable Architecture Refactoring

**Document Version**: 1.0
**Date**: 2025-10-26
**Status**: Proposed
**Priority**: P2 (Future Enhancement)
**Related To**: FoundationUI Layer 1 (Modifiers) & Layer 2 (Components)

---

## 📋 Executive Summary

Refactor the current `CopyableText` component into a more composable, flexible architecture following SwiftUI best practices and FoundationUI's Composable Clarity Design System principles. This will provide three complementary APIs:
1. **`.copyable()` modifier** (Layer 1) - Universal, composable base functionality
2. **`CopyableText` component** (Layer 2) - Convenience wrapper for common use case
3. **`Copyable<Content>` wrapper** (Layer 2) - Generic wrapper for complex views

---

## 🎯 Goals & Objectives

### Primary Goals
1. **Improve Composability**: Make copy functionality work with any View, not just text
2. **Follow SwiftUI Patterns**: Use modifier-based architecture like `.padding()`, `.background()`
3. **Maintain Backward Compatibility**: Keep existing `CopyableText` API working
4. **Enhance Flexibility**: Support complex content, custom styling, and various use cases

### Success Criteria
- ✅ `.copyable()` modifier works with any View
- ✅ Existing `CopyableText(text:)` API remains functional
- ✅ New `Copyable<Content>` wrapper supports complex views
- ✅ Zero magic numbers (100% DS token usage)
- ✅ Full test coverage (≥80%)
- ✅ 100% DocC documentation
- ✅ Maintains platform-specific behavior (macOS/iOS clipboard)

---

## 🏗️ Current Architecture (As-Is)

### Existing Implementation

```swift
// Layer 2: Component
public struct CopyableText: View {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        // Platform-specific clipboard implementation
        // Visual feedback ("Copied!" indicator)
        // Keyboard shortcut (⌘C on macOS)
    }
}
```

### Limitations
- ❌ Only works with plain text strings
- ❌ Cannot wrap other Views or styled content
- ❌ Not composable - can't apply to existing components
- ❌ Doesn't follow SwiftUI modifier pattern
- ❌ Limited customization options

---

## 🎨 Proposed Architecture (To-Be)

### Three-Layer Approach

#### Layer 1: Copyable Modifier (Base Functionality)
```swift
// Sources/FoundationUI/Modifiers/CopyableModifier.swift

/// View modifier that adds copy-to-clipboard functionality
public struct CopyableModifier: ViewModifier {
    let textToCopy: String
    let showFeedback: Bool
    @State private var showCopiedIndicator = false

    public func body(content: Content) -> some View {
        // Implementation with platform-specific clipboard
    }
}

public extension View {
    /// Adds copy-to-clipboard functionality to any view
    ///
    /// ## Usage
    /// ```swift
    /// Text("Value")
    ///     .font(DS.Typography.code)
    ///     .copyable(text: "Value")
    /// ```
    func copyable(text: String, showFeedback: Bool = true) -> some View {
        modifier(CopyableModifier(textToCopy: text, showFeedback: showFeedback))
    }
}
```

#### Layer 2: CopyableText Component (Convenience)
```swift
// Sources/FoundationUI/Components/CopyableText.swift

/// Convenience component for copyable text (backward compatible)
public struct CopyableText: View {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(DS.Typography.code)
            .copyable(text: text) // Uses Layer 1 modifier
    }
}
```

#### Layer 2: Copyable Wrapper (Generic)
```swift
// Sources/FoundationUI/Components/Copyable.swift

/// Generic wrapper that makes any content copyable
///
/// ## Usage
/// ```swift
/// Copyable(text: "Complex value") {
///     HStack {
///         Image(systemName: "doc.text")
///         Text("Complex")
///     }
/// }
/// ```
public struct Copyable<Content: View>: View {
    let content: Content
    let textToCopy: String
    let showFeedback: Bool

    public init(
        text: String,
        showFeedback: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.textToCopy = text
        self.showFeedback = showFeedback
        self.content = content()
    }

    public var body: some View {
        content.copyable(text: textToCopy, showFeedback: showFeedback)
    }
}
```

---

## 📊 Architecture Benefits

| Aspect | Current | Proposed |
|--------|---------|----------|
| **Composability** | ❌ Low | ✅✅ Excellent |
| **Flexibility** | ❌ Low | ✅✅ Excellent |
| **SwiftUI Patterns** | ⚠️ Partial | ✅✅ Full |
| **Reusability** | ⚠️ Limited | ✅✅ Universal |
| **Backward Compatibility** | ✅ N/A | ✅✅ 100% |
| **Code Complexity** | ✅ Simple | ✅ Moderate |

---

## 🔧 Use Cases

### Use Case 1: Simple Text (Backward Compatible)
```swift
// Existing API - no changes needed
CopyableText(text: "Simple value")
```

### Use Case 2: Styled Text with Modifier
```swift
Text("Formatted Value")
    .font(DS.Typography.code)
    .foregroundColor(DS.Colors.accent)
    .padding(DS.Spacing.m)
    .copyable(text: "Formatted Value")
```

### Use Case 3: Complex View with Wrapper
```swift
Copyable(text: "0x1A2B3C") {
    HStack(spacing: DS.Spacing.s) {
        Image(systemName: "doc.text")
            .foregroundColor(DS.Colors.accent)
        Text("0x1A2B3C")
            .font(DS.Typography.code)
        Badge(text: "Hex", level: .info)
    }
}
```

### Use Case 4: KeyValueRow Integration
```swift
KeyValueRow(key: "File ID", value: "ABC123")
    .copyable(text: "ABC123") // Makes entire row copyable
```

### Use Case 5: Custom Feedback
```swift
Text("Value")
    .copyable(text: "Value", showFeedback: false) // No visual feedback
```

---

## 🧪 Testing Strategy

### Test Coverage Requirements

#### Layer 1: CopyableModifier Tests
- ✅ Modifier applies correctly to Text views
- ✅ Modifier applies correctly to complex views
- ✅ Platform-specific clipboard integration (macOS/iOS)
- ✅ Visual feedback appears and disappears
- ✅ Keyboard shortcut works (⌘C on macOS)
- ✅ VoiceOver announcements (platform-specific)
- ✅ Feedback can be disabled

#### Layer 2: CopyableText Tests
- ✅ Backward compatibility with existing API
- ✅ Uses CopyableModifier internally
- ✅ Maintains DS.Typography.code styling
- ✅ All existing tests continue to pass

#### Layer 2: Copyable Wrapper Tests
- ✅ Wraps complex views correctly
- ✅ Generic Content type works
- ✅ ViewBuilder closure works
- ✅ Copies correct text value
- ✅ Feedback configuration works

#### Integration Tests
- ✅ Works with Badge component
- ✅ Works with Card component
- ✅ Works with KeyValueRow component
- ✅ Multiple copyable elements on same screen
- ✅ Nested copyable elements

### Minimum Test Coverage
- **Target**: ≥85% (higher than standard 80% due to utility nature)
- **Unit Tests**: 40+ test cases
- **Snapshot Tests**: 15+ visual tests (Light/Dark mode)
- **Accessibility Tests**: 10+ VoiceOver/keyboard tests
- **Platform Tests**: macOS and iOS specific tests

---

## 📚 Documentation Requirements

### DocC Documentation
- ✅ Complete API reference for all three components
- ✅ Usage examples for each use case
- ✅ Platform-specific notes (macOS/iOS differences)
- ✅ Migration guide from old to new API
- ✅ Best practices and patterns
- ✅ Accessibility guidelines

### Code Documentation
- ✅ Triple-slash comments (`///`) on all public APIs
- ✅ Parameter documentation with examples
- ✅ Code examples in documentation
- ✅ See Also references between related components

### User Documentation
- ✅ Tutorial: "Making Content Copyable"
- ✅ Guide: "Copyable Architecture Patterns"
- ✅ Migration guide for existing CopyableText users

---

## 🎯 Implementation Phases

### Phase 1: Core Modifier (P2)
**Estimated Effort**: 4-6 hours

- [ ] Create `CopyableModifier` struct
- [ ] Implement platform-specific clipboard logic
- [ ] Add visual feedback with DS tokens
- [ ] Add keyboard shortcut support (macOS)
- [ ] Write unit tests (≥20 tests)
- [ ] Write DocC documentation

### Phase 2: Refactor CopyableText (P2)
**Estimated Effort**: 2-3 hours

- [ ] Refactor `CopyableText` to use `CopyableModifier`
- [ ] Ensure backward compatibility
- [ ] Update existing tests
- [ ] Verify all existing usage continues to work

### Phase 3: Generic Wrapper (P2)
**Estimated Effort**: 3-4 hours

- [ ] Create `Copyable<Content>` generic wrapper
- [ ] Implement ViewBuilder support
- [ ] Add configuration options
- [ ] Write unit tests (≥15 tests)
- [ ] Write DocC documentation

### Phase 4: Integration & Testing (P2)
**Estimated Effort**: 4-5 hours

- [ ] Integration tests with existing components
- [ ] Snapshot tests (Light/Dark mode)
- [ ] Accessibility tests (VoiceOver, keyboard)
- [ ] Platform-specific tests (macOS/iOS)
- [ ] Performance tests

### Phase 5: Documentation & Examples (P2)
**Estimated Effort**: 3-4 hours

- [ ] Complete DocC documentation
- [ ] Update demo app with examples
- [ ] Write migration guide
- [ ] Create tutorial documentation
- [ ] Update component catalog

**Total Estimated Effort**: 16-22 hours

---

## 🚧 Migration Strategy

### Backward Compatibility

✅ **Existing code continues to work without changes**:
```swift
// No changes needed - works as before
CopyableText(text: "Value")
```

### Gradual Migration Path

**Step 1**: Update to modifier where beneficial
```swift
// Before
CopyableText(text: "Value")

// After (optional)
Text("Value")
    .font(DS.Typography.code)
    .copyable(text: "Value")
```

**Step 2**: Use wrapper for complex content
```swift
// New capability
Copyable(text: "Value") {
    HStack {
        Image(systemName: "doc")
        Text("Value")
    }
}
```

### Deprecation Strategy (Optional Future)

Not recommended, but if needed:
1. Keep `CopyableText` for 2-3 major versions
2. Add deprecation warning: `@available(*, deprecated, message: "Use .copyable() modifier instead")`
3. Provide automated migration guide

---

## 🔍 Design System Compliance

### Layer Hierarchy (Composable Clarity)
✅ **Layer 1**: `CopyableModifier` - Base functionality, composable
✅ **Layer 2**: `CopyableText` - Convenience component, uses Layer 1
✅ **Layer 2**: `Copyable<Content>` - Generic wrapper, uses Layer 1

### Design Token Usage
✅ All spacing uses `DS.Spacing.*`
✅ All colors use `DS.Colors.*`
✅ All typography uses `DS.Typography.*`
✅ All animations use `DS.Animation.*`
✅ Zero magic numbers

### SwiftUI Best Practices
✅ Modifier-based architecture
✅ ViewBuilder support
✅ Environment value propagation
✅ Platform-specific conditional compilation
✅ Accessibility built-in

---

## ⚠️ Risks & Mitigation

### Risk 1: Breaking Changes
**Likelihood**: Low
**Impact**: High
**Mitigation**:
- Maintain 100% backward compatibility
- Extensive regression testing
- Comprehensive migration documentation

### Risk 2: Performance Impact
**Likelihood**: Low
**Impact**: Medium
**Mitigation**:
- Profile with Instruments
- Optimize view hierarchy
- Lazy evaluation where possible

### Risk 3: Platform-Specific Issues
**Likelihood**: Medium
**Impact**: Medium
**Mitigation**:
- Comprehensive platform-specific tests
- Conditional compilation
- Test on all platforms (macOS, iOS, iPadOS)

### Risk 4: Increased Complexity
**Likelihood**: Medium
**Impact**: Low
**Mitigation**:
- Clear documentation
- Usage examples for all cases
- Migration guide

---

## 📈 Success Metrics

### Code Quality Metrics
- ✅ Test coverage ≥85%
- ✅ SwiftLint violations = 0
- ✅ Magic numbers = 0
- ✅ DocC coverage = 100%
- ✅ API naming consistency = 100%

### Adoption Metrics
- ✅ Backward compatibility = 100% (no breaking changes)
- ✅ New use cases enabled ≥5
- ✅ Code reusability +200% (from 1 to 3 APIs)
- ✅ Flexibility score +300% (qualitative assessment)

### Performance Metrics
- ✅ No measurable performance degradation
- ✅ Memory footprint unchanged
- ✅ Render time ≤ existing implementation

---

## 🔗 Related Documents

- [FoundationUI PRD](./AI/ISOViewer/FoundationUI_PRD.md) - Main product requirements
- [FoundationUI Task Plan](../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) - Implementation roadmap
- [Composable Clarity Design System](./AI/ISOViewer/FoundationUI_PRD.md#architecture--design-system) - Architecture principles
- [SwiftUI Best Practices](https://developer.apple.com/documentation/swiftui/) - Apple guidelines

---

## 📝 Open Questions

1. **Q**: Should we add `.copyable()` without parameters that auto-extracts text from Text views?
   **A**: Future enhancement - requires reflection/introspection (Phase 6+)

2. **Q**: Should visual feedback be customizable (different colors, positions)?
   **A**: Future enhancement - use DS tokens for now, defer customization to Phase 6+

3. **Q**: Should we support copying images or other non-text content?
   **A**: Future enhancement - focus on text for MVP (Phase 6+)

---

## 🎓 References

### SwiftUI Patterns
- [ViewModifier Documentation](https://developer.apple.com/documentation/swiftui/viewmodifier)
- [ViewBuilder Documentation](https://developer.apple.com/documentation/swiftui/viewbuilder)
- [Environment Values](https://developer.apple.com/documentation/swiftui/environment)

### Platform Guidelines
- [Apple Human Interface Guidelines - Clipboard](https://developer.apple.com/design/human-interface-guidelines/patterns/managing-data/)
- [macOS Keyboard Shortcuts](https://developer.apple.com/design/human-interface-guidelines/inputs/keyboards/)

---

## ✅ Approval & Sign-off

| Role | Name | Date | Status |
|------|------|------|--------|
| **Product Owner** | TBD | - | ⏳ Pending |
| **Tech Lead** | TBD | - | ⏳ Pending |
| **Designer** | TBD | - | ⏳ Pending |

---

**Document Status**: 📝 Proposed
**Next Review**: After Phase 3.2 completion
**Implementation Priority**: P2 (Future Enhancement)
**Created**: 2025-10-26 by Claude Code
**Last Updated**: 2025-10-26
