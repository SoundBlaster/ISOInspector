# FoundationUI

[![Coverage](https://img.shields.io/badge/coverage-83%25-brightgreen?style=flat-square)](https://github.com/ISOInspector/actions)
[![iOS Coverage](https://img.shields.io/badge/iOS-83.12%25-brightgreen?style=flat-square&logo=apple)](https://github.com/ISOInspector/actions)
[![macOS Coverage](https://img.shields.io/badge/macOS-83.12%25-brightgreen?style=flat-square&logo=apple)](https://github.com/ISOInspector/actions)
[![Tests](https://img.shields.io/badge/tests-200%2B-brightgreen?style=flat-square)](https://github.com/ISOInspector/actions)
[![Swift](https://img.shields.io/badge/Swift-6.0%2B-orange?style=flat-square&logo=swift)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20iPadOS%20%7C%20macOS-lightgrey?style=flat-square)](https://developer.apple.com)

**Version:** 0.1.0
**Platform:** iOS 26+, iPadOS 26+, macOS 26+
**Swift:** 6.0+

A SwiftUI component library following **Composable Clarity Design System** principles, built with TDD, XP, and zero magic numbers for the ISOInspector project.

---

## 📦 Dependencies

FoundationUI relies on the following external packages:

- **[Yams](https://github.com/jpsim/Yams)** (≥5.0.0): YAML parsing for component schemas and agent configuration
- **[NavigationSplitViewKit](https://github.com/SoundBlaster/NavigationSplitView)** (≥1.0.0): Production-ready NavigationSplitView with state management for cross-platform navigation patterns

---

## 🎯 Purpose

FoundationUI provides a unified, accessible, and platform-adaptive component library for building ISO file inspector interfaces across Apple platforms.

### Key Features

- **Zero Magic Numbers**: All values use Design System (DS) tokens
- **Accessibility First**: WCAG 2.1 AA compliance (≥4.5:1 contrast)
- **Platform Adaptive**: Automatic iOS/iPadOS/macOS adaptation
- **Test-Driven**: ≥80% test coverage with unit, snapshot, and integration tests
- **Composable**: Layered architecture from tokens to complex patterns

---

## 🏗️ Architecture

FoundationUI follows a 4-layer design system:

```
Layer 0: Design Tokens (DS namespace)
   ↓
Layer 1: View Modifiers (.badgeChipStyle, .cardStyle, etc.)
   ↓
Layer 2: Components (Badge, Card, KeyValueRow, SectionHeader)
   ↓
Layer 3: Patterns (InspectorPattern, SidebarPattern, etc.)
   ↓
Layer 4: Contexts (Environment keys, platform adaptation)
```

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 27+**
- **Swift 6.4+** toolchain
- **macOS 26+** for development
- **Tuist** (for project generation)

### Using Tuist (Recommended)

**This project uses Tuist for project generation.**

1. **Generate the Xcode workspace:**
   ```bash
   # From the repository root
   cd /path/to/ISOInspector
   tuist generate
   ```

2. **Open the workspace:**
   ```bash
   open ISOInspector.xcworkspace
   ```

3. **Select FoundationUI scheme:**
   - Select `FoundationUI` scheme
   - Choose destination: iPhone/iPad/My Mac

4. **Build and test:**
   ```bash
   # Build framework
   ⌘B

   # Run tests
   ⌘U
   ```

### Installing Tuist

If you don't have Tuist installed:

```bash
# Using Homebrew
brew install tuist/tap/tuist

# Or using Mise (recommended)
mise install tuist
```

See [Tuist documentation](https://docs.tuist.io/guides/quick-start/install-tuist) for more options.

---

## 📚 Components

### Layer 0: Design Tokens

```swift
import FoundationUI

// Spacing
VStack(spacing: DS.Spacing.m) { }     // 12pt
  .padding(DS.Spacing.l)               // 16pt

// Colors
Text("Error")
  .background(DS.Colors.errorBG)        // Semantic red

// Typography
Text("Title")
  .font(DS.Typography.title)           // title3 semibold

// Radius
RoundedRectangle(cornerRadius: DS.Radius.card)  // 10pt

// Animation
withAnimation(DS.Animation.quick) { } // 0.15s snappy
```

### Layer 1: View Modifiers

```swift
// Badge styling
Text("WARNING")
  .badgeChipStyle(level: .warning)

// Card styling
VStack { }
  .cardStyle(elevation: .medium, cornerRadius: DS.Radius.card)

// Interactive effects
Button("Click") { }
  .interactiveStyle(isEnabled: true)

// Material backgrounds
VStack { }
  .surfaceStyle(material: .regular)
```

### Layer 2: Components

```swift
// Badge with icon
Badge(text: "Error", level: .error, showIcon: true)

// Card with content
Card(elevation: .medium, cornerRadius: DS.Radius.card) {
  Text("Content")
}

// Key-value row
KeyValueRow(
  key: "Type",
  value: "ftyp",
  layout: .horizontal,
  isCopyable: true
)

// Section header
SectionHeader(title: "Details", showDivider: true)
```

---

## 🧪 Testing

### Running Tests

```bash
# From Xcode (after tuist generate)
⌘U

# Or specific test target
xcodebuild test -workspace ISOInspector.xcworkspace \
  -scheme FoundationUI -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage

- **Unit Tests**: Component logic, state management, API contracts
- **Snapshot Tests**: Visual regression, Light/Dark mode, Dynamic Type
- **Accessibility Tests**: VoiceOver, contrast ratios, touch targets
- **Performance Tests**: Render time, memory footprint
- **Integration Tests**: Component composition, environment propagation

**Current Coverage**: 80%+ across all layers

---

## 📖 Documentation

### API Documentation

All components have comprehensive DocC documentation:

1. Generate docs in Xcode: `⌃⌘⇧D`
2. Navigate to FoundationUI module
3. Browse by layer: Tokens → Modifiers → Components → Patterns

### Related Documents

- [FoundationUI Task Plan](DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) - Implementation roadmap
- [FoundationUI PRD](DOCS/AI/ISOViewer/FoundationUI_PRD.md) - Product requirements
- [ComponentTestApp](../Examples/ComponentTestApp/README.md) - Demo application

---

## 🎨 Demo Application

Try all components interactively with **ComponentTestApp**:

```bash
# Generate workspace
cd /path/to/ISOInspector
tuist generate

# Open workspace and select ComponentTestApp-iOS or ComponentTestApp-macOS scheme
open ISOInspector.xcworkspace
```

See [ComponentTestApp README](../Examples/ComponentTestApp/README.md) for details.

---

## 🛠️ Development

### Adding New Components

Follow TDD workflow:

1. **Write test first:**
   ```swift
   func testNewComponentInitialization() {
       let component = NewComponent(title: "Test")
       XCTAssertEqual(component.title, "Test")
   }
   ```

2. **Implement component:**
   ```swift
   public struct NewComponent: View {
       public let title: String

       public var body: some View {
           Text(title)
               .font(DS.Typography.body)
       }
   }
   ```

3. **Add DocC comments:**
   ```swift
   /// Brief description
   ///
   /// Detailed explanation with usage examples.
   ///
   /// - Parameters:
   ///   - title: The component title
   public struct NewComponent: View { }
   ```

4. **Add SwiftUI Preview:**
   ```swift
   #Preview {
       NewComponent(title: "Preview")
   }
   ```

### Code Style

- **Zero Magic Numbers**: Use DS tokens exclusively
- **One Entity Per File**: Single struct/class per file
- **DocC Comments**: All public API documented
- **SwiftUI Previews**: 100% preview coverage
- **Platform Conditionals**: `#if os(macOS)` for platform-specific code

---

## 📊 Current Status

**Phase 2: Core Components** - 91% Complete (20/22 tasks)

### Completed
- ✅ Layer 0: Design Tokens (Spacing, Colors, Typography, Radius, Animation)
- ✅ Layer 1: View Modifiers (BadgeChipStyle, CardStyle, InteractiveStyle, SurfaceStyle)
- ✅ Layer 2: Components (Badge, Card, KeyValueRow, SectionHeader)
- ✅ Comprehensive Test Suite (Unit, Snapshot, Accessibility, Performance, Integration)
- ✅ Demo Application (ComponentTestApp)

### In Progress
- 🚧 Layer 3: UI Patterns (InspectorPattern, SidebarPattern, ToolbarPattern, BoxTreePattern)

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2025-10-23 | Initial release with 4 components, 4 modifiers, design tokens |

---

## 👤 Authors

**Claude** (AI Assistant)
Created for the ISOInspector project

---

## 📜 License

This library is part of the ISOInspector project and follows the same license as the parent project.

---

**Last Updated:** 2025-10-23
