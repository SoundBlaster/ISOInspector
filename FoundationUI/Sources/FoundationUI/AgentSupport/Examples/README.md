# FoundationUI YAML Examples for AI Agents

This directory contains example YAML configuration files demonstrating how AI agents can generate FoundationUI components from declarative descriptions.

## 📋 Overview

These examples show how to use the `ComponentSchema.yaml` to create complete SwiftUI user interfaces programmatically. Agents can parse these YAML files and instantiate the corresponding FoundationUI components.

## 📁 Example Files

### Component Examples

- **`badge_examples.yaml`**
  - Simple badges (info, warning, error, success)
  - Badges with/without icons
  - Badges composed inside Cards
  - Status dashboards with multiple badges

### Pattern Examples

- **`inspector_pattern_examples.yaml`**
  - ISO file metadata inspector
  - Hex data inspector with copyable values
  - Audio/video track inspectors
  - Multi-section detail panels

### Complete UI Examples

- **`complete_ui_example.yaml`**
  - Full three-column ISO Inspector layout
  - Sidebar + Tree + Inspector composition
  - Platform adaptation notes (macOS/iOS/iPadOS)
  - Design token usage documentation

## 🎯 Usage for Agents

### 1. Parse YAML Configuration

```swift
import Foundation
import Yams

let yamlString = try String(contentsOfFile: "badge_examples.yaml")
let components = try YAMLDecoder().decode([ComponentDescription].self, from: yamlString)
```

### 2. Validate Against Schema

```swift
// Load schema
let schemaURL = Bundle.module.url(forResource: "ComponentSchema", withExtension: "yaml")!
let schema = try ComponentSchema(contentsOf: schemaURL)

// Validate component
for component in components {
    try schema.validate(component)
}
```

### 3. Generate SwiftUI Views

```swift
func generateView(from description: ComponentDescription) -> some View {
    switch description.componentType {
    case "Badge":
        return Badge(
            text: description.properties["text"] as! String,
            level: BadgeLevel(rawValue: description.properties["level"] as! String)!,
            showIcon: description.properties["showIcon"] as? Bool ?? true
        )

    case "Card":
        return Card(
            elevation: CardElevation(rawValue: description.properties["elevation"] as! String)!,
            cornerRadius: description.properties["cornerRadius"] as? CGFloat ?? 10
        ) {
            // Generate nested content recursively
            ForEach(description.content ?? []) { nestedComponent in
                generateView(from: nestedComponent)
            }
        }

    // ... handle other component types
    default:
        fatalError("Unknown component type: \(description.componentType)")
    }
}
```

## 🔍 Validation Rules

All examples adhere to the validation rules defined in `ComponentSchema.yaml`:

1. **Type Safety**
   - ✅ All `componentType` values match schema definitions
   - ✅ All required properties are present
   - ✅ Enum values are valid options
   - ✅ Numeric values within bounds

2. **Design Tokens**
   - ✅ No magic numbers (all values reference DS tokens)
   - ✅ Spacing: `DS.Spacing.{s|m|l|xl}`
   - ✅ Radius: `DS.Radius.{small|medium|card|chip}`
   - ✅ Colors: `DS.Colors.{infoBG|warnBG|errorBG|successBG}`

3. **Accessibility**
   - ✅ VoiceOver labels via `semantics` property
   - ✅ Contrast ratios ≥4.5:1 (WCAG AA)
   - ✅ Touch targets ≥44×44pt on iOS

4. **Composition**
   - ✅ Cards can contain components (Badge, KeyValueRow, etc.)
   - ✅ Patterns can contain components and cards
   - ✅ No circular references

## 🎨 Design Tokens Reference

All examples use FoundationUI design tokens for consistency:

### Spacing
- `DS.Spacing.s` = 8pt
- `DS.Spacing.m` = 12pt
- `DS.Spacing.l` = 16pt
- `DS.Spacing.xl` = 24pt

### Radius
- `DS.Radius.small` = 6pt
- `DS.Radius.medium` = 8pt
- `DS.Radius.card` = 10pt
- `DS.Radius.chip` = 999pt (fully rounded)

### Colors (Semantic)
- `DS.Colors.infoBG` - Info badge background
- `DS.Colors.warnBG` - Warning badge background
- `DS.Colors.errorBG` - Error badge background
- `DS.Colors.successBG` - Success badge background

### Typography
- `DS.Typography.label` - Standard labels
- `DS.Typography.body` - Body text
- `DS.Typography.code` - Monospace values
- `DS.Typography.caption` - Section headers

## 📐 Platform Adaptation

Examples include platform-specific notes for:

### macOS
- Three-column layouts with fixed sidebar widths
- Keyboard shortcuts (⌘ modifiers)
- Always-visible toolbar items

### iOS
- Full-width layouts with safe area insets
- Tab bar navigation
- Toolbar overflow menus for secondary actions

### iPadOS
- Adaptive sidebar (collapses in compact size class)
- Split view layouts in landscape
- Pointer hover effects

## 🧪 Testing Examples

To test these examples:

1. **Manual Validation**
   ```bash
   # Validate YAML syntax
   yamllint badge_examples.yaml

   # Validate against JSON Schema (if converted to JSON)
   ajv validate -s ComponentSchema.json -d badge_examples.json
   ```

2. **Swift Integration**
   ```swift
   // Load and validate in unit tests
   func testBadgeExamplesValid() throws {
       let examples = try loadYAML("badge_examples.yaml")
       for example in examples {
           XCTAssertNoThrow(try schema.validate(example))
       }
   }
   ```

3. **Visual Testing**
   - Generate SwiftUI views from YAML
   - Compare against snapshot baselines
   - Verify accessibility labels

## 📚 Related Documentation

- **Schema Definition**: `../ComponentSchema.yaml`
- **Protocol Documentation**: `../AgentDescribable.swift`
- **Task Plan**: `../../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md` (Phase 4.1.3)
- **PRD**: `../../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md`

## 🤝 Contributing New Examples

When adding new examples:

1. Follow existing YAML structure
2. Include `semantics` for all components
3. Document design token usage
4. Add platform-specific notes if applicable
5. Validate against `ComponentSchema.yaml`
6. Test generation in Swift

## 🔗 See Also

- [FoundationUI Components Documentation](https://docs.foundation-ui.dev/components)
- [Agent Integration Guide](https://docs.foundation-ui.dev/agent-integration)
- [Design Token Reference](https://docs.foundation-ui.dev/design-tokens)

---

**Version**: 1.0
**Last Updated**: 2025-11-09
**Status**: Complete (Phase 4.1.3)
