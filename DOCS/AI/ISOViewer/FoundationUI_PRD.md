# Product Requirements Document
# FoundationUI - Cross-Platform SwiftUI Framework

**Project:** ISO Inspector
**Module:** FoundationUI
**Version:** 1.0
**Date:** 2025-10-20
**Status:** Planning
**Based on:** Composable Clarity Design System v1.0

---

## 1. Executive Summary

### 1.1 Overview
FoundationUI is a universal SwiftUI framework that provides a unified cross-platform foundation for developing iOS/macOS applications within the ISO Inspector ecosystem. The framework implements the **Composable Clarity** design system, ensuring consistent user interface and experience across all supported platforms.

### 1.2 Goals
- **Unify UI/UX** across iOS, iPadOS, and macOS
- **Accelerate development** through reusable components
- **Ensure design consistency** via tokens and modifiers
- **Support agent-driven UI generation** for integration with 0AL/Hypercode
- **Simplify testing** through self-contained components

### 1.3 Success Criteria
- ✅ 100% of components support iOS 17+, iPadOS 17+, macOS 14+
- ✅ All visual elements use only tokens (zero magic numbers)
- ✅ Accessibility score ≥ 95% (contrast, VoiceOver, keyboard navigation)
- ✅ Unit test coverage ≥ 80% for all components
- ✅ Preview coverage = 100% for visual components
- ✅ API documentation = 100%

---

## 2. Problem Statement

### 2.1 Current Challenges
- **Code duplication** when developing for iOS and macOS
- **Design inconsistency** between platforms
- **Complexity in maintaining** multiple UI styles
- **Lack of systematic approach** to interface composition
- **Difficulties in automatic UI generation** for agents

### 2.2 Proposed Solution
Create a centralized SwiftUI framework that:
- Implements a 4-layer design system architecture (Tokens → Modifiers → Components → Patterns)
- Provides platform adaptation through Environment
- Offers declarative API for agent-driven generation
- Guarantees semantic consistency through type-safe components

---

## 3. Target Platforms

| Platform | Minimum Version | UI Paradigm | Adaptation Strategy |
|----------|----------------|-------------|---------------------|
| **iOS** | 17.0+ | Touch-first | Compact spacing, large touch targets |
| **iPadOS** | 17.0+ | Hybrid | Adaptive layouts, pointer support |
| **macOS** | 14.0+ | Pointer-first | Dense UI, keyboard shortcuts, menus |

### 3.1 Platform-Specific Considerations
- **iOS/iPadOS:** Sheet presentations, tab bars, navigation stacks
- **macOS:** Window management, toolbars, sidebars, split views
- **Shared:** Materials, SF Symbols, Dark Mode, Dynamic Type

---

## 4. Architecture

### 4.1 Module Structure

```bash
FoundationUI/
├── Sources/
│   ├── DesignTokens/           # Layer 0: Tokens
│   │   ├── Spacing.swift
│   │   ├── Typography.swift
│   │   ├── Colors.swift
│   │   ├── Radius.swift
│   │   └── Animation.swift
│   ├── Modifiers/              # Layer 1: Atoms
│   │   ├── BadgeChipStyle.swift
│   │   ├── CardStyle.swift
│   │   ├── InteractiveStyle.swift
│   │   └── SurfaceStyle.swift
│   ├── Components/             # Layer 2: Molecules
│   │   ├── Badge.swift
│   │   ├── Card.swift
│   │   ├── KeyValueRow.swift
│   │   └── SectionHeader.swift
│   ├── Patterns/               # Layer 3: Organisms
│   │   ├── SidebarPattern.swift
│   │   ├── InspectorPattern.swift
│   │   ├── ToolbarPattern.swift
│   │   └── BoxTreePattern.swift
│   ├── Contexts/               # Layer 4: Themes
│   │   ├── SurfaceStyleKey.swift
│   │   ├── PlatformAdaptation.swift
│   │   └── ColorSchemeAdapter.swift
│   └── Utilities/
│       ├── CopyableText.swift
│       ├── KeyboardShortcuts.swift
│       └── AccessibilityHelpers.swift
├── Tests/
│   ├── DesignTokensTests/
│   ├── ModifiersTests/
│   ├── ComponentsTests/
│   └── PatternsTests/
└── Package.swift
```

### 4.2 Layer Responsibilities

#### Layer 0: Design Tokens
**Purpose:** Single source of truth for visual constants

```swift
public enum DS {
    public enum Spacing {
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        public static let xl: CGFloat = 24
    }

    public enum Radius {
        public static let card: CGFloat = 10
        public static let chip: CGFloat = 999 // Capsule
        public static let small: CGFloat = 6
    }

    public enum Font {
        public static let label = Font.caption2.weight(.semibold)
        public static let body = Font.body
        public static let title = Font.title3.weight(.semibold)
    }

    public enum Color {
        public static let infoBG = Color.gray.opacity(0.18)
        public static let warnBG = Color.orange.opacity(0.22)
        public static let errorBG = Color.red.opacity(0.22)
        public static let successBG = Color.green.opacity(0.20)
    }

    public enum Animation {
        public static let quick = SwiftUI.Animation.snappy(duration: 0.15)
        public static let medium = SwiftUI.Animation.easeInOut(duration: 0.25)
    }
}
```

##### Bug Fix: DS.Colors.tertiary macOS Low Contrast

**Layer**: Layer 0 (Design Tokens)
**Severity**: High
**Affected Component**: DS.Colors.tertiary token
**Platform Scope**: macOS only (iOS already correct)

The `DS.Colors.tertiary` token incorrectly uses `.tertiaryLabelColor` (a label/text color) instead of a proper background color on macOS. This causes severe low contrast issues between window backgrounds and content areas in all components that use this token.

**Root Cause**: Platform-specific conditional compilation in `Colors.swift:111` maps to wrong system color on macOS.

**Fix Requirements**:
- Change `Colors.swift:111` from `.tertiaryLabelColor` to `.controlBackgroundColor`
- Add macOS-specific snapshot tests for affected components
- Verify WCAG AA contrast compliance (≥4.5:1 ratio)
- Test in Light/Dark mode and with Increase Contrast setting

**Affected Components**:
- SidebarPattern (detail content background)
- Card (background fallback)
- InspectorPattern (content background)
- ToolbarPattern (toolbar background)
- All components using DS.Colors.tertiary on macOS

**Success Criteria**:
- [ ] macOS uses proper background color (.controlBackgroundColor)
- [ ] Contrast ratio ≥4.5:1 verified for all affected components
- [ ] Platform parity: macOS semantic intent matches iOS
- [ ] All snapshot tests pass on macOS (Light/Dark mode)
- [ ] Accessibility tests pass (VoiceOver, Increase Contrast)
- [ ] Design system integrity maintained (zero magic numbers)

**Specification**: [`FoundationUI/DOCS/SPECS/BUG_Colors_Tertiary_macOS_LowContrast.md`](../../FoundationUI/DOCS/SPECS/BUG_Colors_Tertiary_macOS_LowContrast.md)

#### Layer 1: View Modifiers (Atoms)
**Purpose:** Reusable styles without context

```swift
public struct BadgeChipStyle: ViewModifier {
    public let level: BadgeLevel

    public func body(content: Content) -> some View {
        content
            .font(DS.Font.label)
            .textCase(.uppercase)
            .padding(.vertical, DS.Spacing.s / 2)
            .padding(.horizontal, DS.Spacing.m)
            .background(background, in: Capsule())
            .accessibilityLabel(accessibilityLabel)
    }

    private var background: Color {
        switch level {
        case .info: DS.Color.infoBG
        case .warning: DS.Color.warnBG
        case .error: DS.Color.errorBG
        case .success: DS.Color.successBG
        }
    }

    private var accessibilityLabel: String {
        "\(level.rawValue) badge"
    }
}

public enum BadgeLevel: String, CaseIterable {
    case info, warning, error, success
}
```

#### Layer 2: Components (Molecules)
**Purpose:** Semantic components with clear purpose

```swift
public struct Badge: View {
    public let text: String
    public let level: BadgeLevel

    public init(text: String, level: BadgeLevel) {
        self.text = text
        self.level = level
    }

    public var body: some View {
        Text(text)
            .modifier(BadgeChipStyle(level: level))
    }
}
```

#### Layer 3: Patterns (Organisms)
**Purpose:** Complex compositions for standard UI patterns

```swift
public struct InspectorPattern<Content: View>: View {
    public let title: String
    public let content: Content

    public init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                Text(title)
                    .font(DS.Font.title)
                    .textCase(.uppercase)

                content
            }
            .padding(DS.Spacing.l)
        }
        .background(.thinMaterial)
    }
}
```

#### Layer 4: Contexts (Themes)
**Purpose:** Platform adaptation and theming

```swift
public struct SurfaceStyleKey: EnvironmentKey {
    public static let defaultValue: Material = .regular
}

public extension EnvironmentValues {
    var surfaceStyle: Material {
        get { self[SurfaceStyleKey.self] }
        set { self[SurfaceStyleKey.self] = newValue }
    }
}

public struct PlatformAdaptiveModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    public func body(content: Content) -> some View {
        #if os(macOS)
        content.padding(DS.Spacing.m)
        #else
        if horizontalSizeClass == .compact {
            content.padding(DS.Spacing.s)
        } else {
            content.padding(DS.Spacing.m)
        }
        #endif
    }
}
```

### 4.3 NavigationSplitViewKit Integration

To deliver a first-class navigation experience across iOS, iPadOS, and macOS, FoundationUI will depend on [`NavigationSplitViewKit`](https://github.com/SoundBlaster/NavigationSplitView). The package provides a production-ready implementation of SwiftUI's `NavigationSplitView` with synchronized state management and adaptive behaviors.

**Key Capabilities**

- ✅ Adaptive three-column layout (Sidebar → Content → Inspector)
- ✅ Shared `NavigationModel` state with `@Bindable` support
- ✅ Column visibility orchestration for compact size classes
- ✅ Inspector pinning and resize behaviors on desktop/tablet
- ✅ Comprehensive DocC reference and Tuist demo for onboarding

**FoundationUI Integration Requirements**

1. Add `NavigationSplitViewKit` as an SPM dependency (Package.swift, Project.swift, Package.resolved).
2. Expose a `NavigationSplitScaffold` wrapper that applies Composable Clarity tokens (spacing, colors, typography, animation).
3. Provide environment keys so existing patterns (`SidebarPattern`, `InspectorPattern`, `ToolbarPattern`) can access the shared navigation model.
4. Support single-/two-/three-column variants automatically based on size class and platform via PlatformAdaptation utilities.
5. Publish DocC tutorials demonstrating ISOInspector navigation flows and agent YAML schemas for navigation-driven layouts.

**Success Criteria**

- [ ] Dependency compiles across all supported platforms (iOS 17+, iPadOS 17+, macOS 14+).
- [ ] Navigation scaffold passes unit, snapshot, and integration tests for three-column and compact states.
- [ ] Accessibility: VoiceOver exposes column toggle controls; keyboard shortcuts (⌘1/⌘2/⌘3) focus each column.
- [ ] Zero magic numbers — all layout constants sourced from DS tokens.
- [ ] ISOInspector demo apps adopt the shared navigation scaffold without platform-specific forks.

**Specification**: [`FoundationUI/DOCS/INPROGRESS/NEW_NavigationSplitViewKit_Proposal.md`](../../../FoundationUI/DOCS/INPROGRESS/NEW_NavigationSplitViewKit_Proposal.md)

---

## 5. Core Components Specification

### 5.1 Essential Components (MVP)

| Component | Purpose | Platforms | Priority |
|-----------|---------|-----------|----------|
| **Badge** | Status indicators | All | P0 |
| **Indicator** | Compact status dots | All | P0 |
| **Card** | Content containers | All | P0 |
| **KeyValueRow** | Metadata display | All | P0 |
| **SectionHeader** | Section titles | All | P0 |
| **CopyableText** | Interactive text | All | P0 |
| **InspectorPattern** | Inspector layout | All | P0 |
| **SidebarPattern** | Navigation sidebar | macOS, iPad | P0 |
| **ToolbarPattern** | Top toolbar | All | P1 |
| **BoxTreePattern** | Hierarchical tree | All | P1 |

### 5.2 Component API Examples

#### Badge Component
```swift
// Usage
Badge(text: "ERROR", level: .error)
Badge(text: "OK", level: .success)

// Agent YAML
component: Badge
props:
  text: "WARNING"
  level: warning
semantics: "validation state indicator"
```

#### Indicator Component
**Layer**: 2 (Component)
**Priority**: P0

Indicator delivers the Badge semantic vocabulary in a minimal, text-free form. It renders a circular status dot sized with DS spacing tokens and colored via the existing `BadgeLevel` → `BadgeChipStyle` mapping. Tooltips/context menus surface the descriptive badge/text when users hover (macOS) or long-press/tap (iOS, iPadOS), ensuring the meaning remains discoverable.

**API Example**:
```swift
Indicator(
    level: .warning,
    size: .small,
    reason: "Checksum mismatch",
    tooltip: .badge(text: "Checksum mismatch", level: .warning)
)
.copyable(text: "Checksum mismatch") // Opt-in Copyable protocol support

Indicator(
    level: .error,
    size: .mini,
    tooltip: .text("Integrity check failed")
)
.indicatorTooltipStyle(.automatic)
```

**Behavior Notes**:
- Size presets map to DS spacing tokens: `.mini` → `DS.Spacing.s`, `.small` → `DS.Spacing.m`, `.medium` → `DS.Spacing.l`.
- Default fill + optional halo reuse `BadgeChipStyle` colors to preserve semantic meaning (info/warning/error/success).
- macOS uses `.help(reason)` to show the status description; iOS/iPadOS expose a `contextMenu` with Badge or text fallback.
- Supports pointer hover effects (macOS/iPadOS) and respects Reduce Motion by disabling tooltip animations when required.
- Adopts Copyable protocol expectations via `.copyable(text:)` or automatic conformance when used inside `Copyable` wrappers.

**Success Criteria**:
- ≥85% unit test coverage across levels, size variants, and tooltip triggers.
- Snapshot coverage for Light/Dark, Dynamic Type (where applicable), and RTL layouts.
- VoiceOver exposes “{Level} indicator — {reason}” semantics and hit target ≥44×44 pt.
- Zero magic numbers — all radii/spacing derived from DS tokens or Badge utilities.
- SwiftUI previews document platform-specific tooltip presentations.

#### Card Component
```swift
// Usage
Card {
    VStack {
        Text("Title")
        Text("Content")
    }
}

// With customization
Card(elevation: .medium, cornerRadius: DS.Radius.card) {
    // Content
}
```

#### KeyValueRow
```swift
// Usage
KeyValueRow(key: "Type", value: "ftyp")
KeyValueRow(key: "Size", value: "1024 bytes", copyable: true)
```

---

## 6. Design Principles Implementation

### 6.1 Composable Clarity
- **Zero magic numbers:** All values through DS tokens
- **Semantic before visual:** Names reflect meaning, not style
- **Local responsibility:** Components manage their own state
- **Predictable composability:** Components work correctly when nested

### 6.2 Accessibility Requirements
- **Contrast:** ≥ 4.5:1 for all text
- **VoiceOver:** Full support for all interactive elements
- **Dynamic Type:** Support for system font sizes
- **Keyboard Navigation:** Full keyboard accessibility
- **Reduce Motion:** Respect for preferredReduceMotion

### 6.3 Platform Adaptation Strategy

```swift
// Example: Platform-specific spacing
extension DS.Spacing {
    public static var platformDefault: CGFloat {
        #if os(macOS)
        return m  // 12pt for macOS
        #else
        return l  // 16pt for iOS/iPadOS
        #endif
    }
}
```

---

## 7. Agent-Driven UI Generation

### 7.1 Declarative Component Description
Components support description through structured data for agent generation:

```swift
public protocol AgentDescribable {
    var componentType: String { get }
    var properties: [String: Any] { get }
    var semantics: String { get }
}

extension Badge: AgentDescribable {
    public var componentType: String { "Badge" }
    public var properties: [String: Any] {
        ["text": text, "level": level.rawValue]
    }
    public var semantics: String {
        "Status indicator for \(level.rawValue) state"
    }
}
```

### 7.2 YAML Schema for Agents

```yaml
# Example: Inspector UI definition for agents
view: InspectorPattern
props:
  title: "File Metadata"
children:
  - component: SectionHeader
    props:
      text: "BASIC INFO"
  - component: KeyValueRow
    props:
      key: "Type"
      value: "ftyp"
      copyable: true
  - component: Badge
    props:
      text: "VALID"
      level: success
```

---

## 8. Testing Strategy

### 8.1 Unit Tests
- **Token validation:** Verify all DS values
- **Modifier behavior:** Test style logic
- **Component composition:** Verify correct nesting
- **Accessibility:** Automated a11y checks

### 8.2 Snapshot Tests
- Light/Dark mode
- Different platform idioms
- Dynamic Type sizes
- Locale variations

### 8.3 Integration Tests
- Pattern composition
- Environment value propagation
- Platform-specific behavior

---

## 9. Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] SPM package setup
- [ ] Layer 0: Design Tokens
- [ ] Layer 1: Core Modifiers (Badge, Card, Interactive)
- [ ] Basic documentation

### Phase 2: Core Components (Week 3-4)
- [ ] Layer 2: Essential Components
  - [ ] Badge
  - [ ] Card
  - [ ] KeyValueRow
  - [ ] SectionHeader
  - [ ] CopyableText
- [ ] Unit tests (≥ 80% coverage)
- [ ] SwiftUI Previews

### Phase 3: Patterns (Week 5-6)
- [ ] Layer 3: UI Patterns
  - [ ] InspectorPattern
  - [ ] SidebarPattern
  - [ ] ToolbarPattern
- [ ] Platform adaptation layer
- [ ] Integration tests

### Phase 4: Polish & Agent Support (Week 7-8)
- [ ] Agent-driven UI protocol
- [ ] YAML schema validation
- [ ] Accessibility audit
- [ ] Performance optimization
- [ ] Complete documentation
- [ ] Example projects (iOS, macOS)

---

## 10. Dependencies

### 10.1 System Requirements
- **Swift:** 5.9+
- **Xcode:** 15.0+
- **iOS:** 17.0+
- **iPadOS:** 17.0+
- **macOS:** 14.0+

### 10.2 External Dependencies
```swift
// Package.swift
dependencies: [
    // No external dependencies - pure SwiftUI
]
```

### 10.3 Internal Dependencies
- ISO Inspector Core (for domain models)
- 0AL Agent SDK (optional, for agent integration)

---

## 11. Documentation Requirements

### 11.1 API Documentation
- 100% DocC coverage for public API
- Code examples for each component
- Best practices guide
- Migration guides (if applicable)

### 11.2 Design Documentation
- Component catalog with visual examples
- Design token reference
- Platform adaptation guide
- Accessibility guidelines

### 11.3 Integration Guides
- Getting started tutorial
- Agent integration guide
- Custom component creation
- Performance best practices

---

## 12. Success Metrics

### 12.1 Technical Metrics
- **Build time:** < 10s for clean module build
- **Binary size:** < 500KB for release build
- **Memory footprint:** < 5MB for typical screen
- **Render performance:** 60 FPS on all platforms

### 12.2 Developer Experience Metrics
- **Time to first component:** < 5 minutes for new developer
- **Code reuse rate:** ≥ 80% of code compatible between platforms
- **Documentation quality:** ≥ 90% satisfaction in surveys

### 12.3 Quality Metrics
- **Test coverage:** ≥ 80%
- **Accessibility score:** ≥ 95%
- **Zero magic numbers:** 100% compliance
- **SwiftLint violations:** 0

---

## 13. Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Platform API changes | High | Medium | Conditional compilation, version checks |
| Performance issues on older devices | Medium | Low | Profiling, optimization passes |
| Incomplete accessibility | High | Medium | Automated tests, manual audits |
| Agent integration complexity | Medium | Medium | Phased rollout, clear protocols |
| Design system evolution | Low | High | Semantic versioning, deprecation policy |

---

## 14. Future Enhancements

### 14.1 Phase 2 Features (Post-MVP)
- Advanced animations (spring physics, gestures)
- Custom material effects
- Advanced typography controls
- Theme customization API

### 14.2 Phase 3 Features
- watchOS support
- tvOS support
- visionOS support (spatial UI)
- Component playground app

---

## 15. Appendix

### 15.1 References
- [10_DESIGN_SYSTEM_GUIDE.md](../ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md) — Composable Clarity Design System
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

### 15.2 Glossary
- **DS:** Design System namespace
- **Atom:** Smallest composable unit (modifier)
- **Molecule:** Simple component (Badge, Card)
- **Organism:** Complex pattern (Inspector, Sidebar)
- **Token:** Design constant (spacing, color, etc.)
- **Material:** SwiftUI background effect
- **Composable Clarity:** Core design philosophy
- **FoundationUI:** Cross-platform SwiftUI framework for ISO Inspector

---

## 16. Approval & Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| **Product Owner** | TBD | — | — |
| **Tech Lead** | TBD | — | — |
| **Design Lead** | 0AL Core Design | 2025-10-20 | ✓ |
| **QA Lead** | TBD | — | — |

---

**Document Version:** 1.0
**Last Updated:** 2025-10-20
**Status:** Ready for Review
**Next Review:** 2025-10-27

---

## License

MIT © 0AL Core Design System / ISO Inspector Project
