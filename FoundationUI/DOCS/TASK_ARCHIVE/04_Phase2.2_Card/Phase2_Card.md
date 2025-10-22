# Card Component

## 🎯 Objective
Implement a flexible Card component with generic content support, configurable elevation levels, corner radius, and material backgrounds.

## 🧩 Context
- **Phase**: Phase 2.2 - Layer 2: Essential Components (Molecules)
- **Layer**: Layer 2 - Components
- **Priority**: P0 (Critical)
- **Dependencies**:
  - ✅ CardStyle modifier (Phase 2.1)
  - ✅ DS.Radius tokens (Layer 0)
  - ✅ DS.Spacing tokens (Layer 0)
  - ✅ SurfaceStyle modifier (Phase 2.1)

## ✅ Success Criteria
- [ ] Unit tests written and passing
- [ ] Implementation follows DS token usage (zero magic numbers)
- [ ] SwiftUI Preview included
- [ ] DocC documentation complete
- [ ] Accessibility labels added
- [ ] SwiftLint reports 0 violations
- [ ] Platform support verified (iOS/macOS/iPadOS)

## 🔧 Implementation Notes

Card is a foundational component that will be heavily reused throughout the application. It serves as a container with visual emphasis through elevation and corner radius.

### Files to Create/Modify
- `Sources/FoundationUI/Components/Card.swift`
- `Tests/FoundationUITests/ComponentsTests/CardTests.swift`

### Component API Design

```swift
public struct Card<Content: View>: View {
    public init(
        elevation: CardElevation = .medium,
        cornerRadius: CGFloat = DS.Radius.card,
        material: Material? = nil,
        @ViewBuilder content: () -> Content
    )
}

public enum CardElevation {
    case none
    case low
    case medium
    case high
}
```

### Design Token Usage
- **Spacing**: `DS.Spacing.{s|m|l|xl}` for internal padding
- **Radius**: `DS.Radius.card` for corner radius (default)
- **Materials**: Use `SurfaceStyle` modifier for background materials
- **Elevation**: Use `CardStyle` modifier for shadow/elevation

### Key Requirements
1. **Generic Content**: Accept any SwiftUI View via `@ViewBuilder`
2. **Configurable Elevation**: Support none, low, medium, high elevation levels
3. **Corner Radius**: Default to `DS.Radius.card`, but allow custom values
4. **Material Support**: Optional material background (`.thin`, `.regular`, `.thick`)
5. **Platform Adaptation**: Shadows should adapt to platform (macOS vs iOS)
6. **Zero Magic Numbers**: All spacing and sizing via DS tokens

### Accessibility Requirements
- Card container should be accessible as a single container
- Content should maintain its own accessibility labels
- Consider adding `.accessibilityElement(children: .contain)` for proper grouping

### Testing Strategy
- Test all elevation levels render correctly
- Test custom corner radius
- Test with different content types (Text, Image, VStack, etc.)
- Test material backgrounds
- Test nesting cards within cards
- Verify DS token usage (no magic numbers)
- Test accessibility grouping

### Preview Requirements
Create comprehensive previews showing:
1. All elevation levels (none, low, medium, high)
2. Different corner radius values
3. With and without material backgrounds
4. Different content types (text, images, mixed)
5. Light and Dark mode variations
6. Nested cards example
7. Platform-specific rendering differences

## 🧠 Source References
- [FoundationUI Task Plan § 2.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#22-layer-2-essential-components-molecules)
- [FoundationUI PRD § Components](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [Apple SwiftUI Card Patterns](https://developer.apple.com/documentation/swiftui)
- [CardStyle Modifier](../../Sources/FoundationUI/Modifiers/CardStyle.swift)

## 📋 Checklist
- [ ] Read task requirements from Task Plan
- [ ] Create test file and write failing tests
- [ ] Run `swift test` to confirm failure
- [ ] Implement minimal code using DS tokens
- [ ] Run `swift test` to confirm pass
- [ ] Add comprehensive SwiftUI Previews (minimum 6 variations)
- [ ] Add DocC comments with code examples
- [ ] Run `swiftlint` (0 violations)
- [ ] Test on iOS simulator (if available)
- [ ] Test on macOS (if available)
- [ ] Update Task Plan with [x] completion mark
- [ ] Commit with descriptive message
- [ ] Archive task document to TASK_ARCHIVE

## 📝 Implementation Notes

### Component Structure
The Card component should be simple and composable:
- Use `CardStyle` modifier internally for elevation/shadows
- Use `SurfaceStyle` modifier for material backgrounds
- Provide sensible defaults while allowing customization
- Keep the API minimal and focused

### Example Usage
```swift
// Simple card with default settings
Card {
    Text("Hello, World!")
}

// Card with custom elevation
Card(elevation: .high) {
    VStack {
        Text("Title")
        Text("Content")
    }
}

// Card with material background
Card(material: .thin) {
    // Content
}

// Card with custom corner radius
Card(cornerRadius: DS.Radius.small) {
    // Content
}
```

### Integration with Existing Code
- Leverage `CardStyle` modifier for consistent elevation styling
- Use `SurfaceStyle` for material backgrounds
- Follow the same pattern as Badge and SectionHeader components
- Maintain consistent API design across all components

---

**Next Steps**: Follow TDD workflow from [02_TDD_XP_Workflow.md](../../../DOCS/RULES/02_TDD_XP_Workflow.md)
