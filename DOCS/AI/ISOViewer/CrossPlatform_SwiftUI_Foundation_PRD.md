# Product Requirements Document
# Cross-Platform SwiftUI Foundation Module

**Project:** ISO Inspector / ISOViewer
**Module:** CrossPlatformFoundation
**Version:** 1.0
**Date:** 2025-10-20
**Status:** Planning
**Based on:** Composable Clarity Design System v1.0

---

## 1. Executive Summary

### 1.1 Overview
CrossPlatformFoundation — это универсальный SwiftUI-модуль, предоставляющий единую кроссплатформенную основу для разработки iOS/macOS приложений в рамках экосистемы ISO Inspector. Модуль реализует дизайн-систему **Composable Clarity**, обеспечивая согласованный пользовательский интерфейс и опыт взаимодействия на всех поддерживаемых платформах.

### 1.2 Goals
- **Унификация UI/UX** на iOS, iPadOS и macOS
- **Ускорение разработки** через переиспользуемые компоненты
- **Обеспечение консистентности** дизайна через токены и модификаторы
- **Поддержка agent-driven UI generation** для интеграции с 0AL/Hypercode
- **Упрощение тестирования** через самодостаточные компоненты

### 1.3 Success Criteria
- ✅ 100% компонентов поддерживают iOS 17+, iPadOS 17+, macOS 14+
- ✅ Все визуальные элементы используют только токены (zero magic numbers)
- ✅ Accessibility score ≥ 95% (контраст, VoiceOver, клавиатурная навигация)
- ✅ Unit test coverage ≥ 80% для всех компонентов
- ✅ Preview coverage = 100% для визуальных компонентов
- ✅ Документация API = 100%

---

## 2. Problem Statement

### 2.1 Current Challenges
- **Дублирование кода** при разработке для iOS и macOS
- **Несогласованность дизайна** между платформами
- **Сложность поддержки** множественных UI стилей
- **Отсутствие системного подхода** к композиции интерфейсов
- **Трудности в автоматической генерации UI** для агентов

### 2.2 Proposed Solution
Создание централизованного SwiftUI-модуля, который:
- Реализует 4-слойную архитектуру дизайн-системы (Tokens → Modifiers → Components → Patterns)
- Обеспечивает платформенную адаптацию через Environment
- Предоставляет декларативное API для agent-driven генерации
- Гарантирует семантическую консистентность через type-safe компоненты

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

```
CrossPlatformFoundation/
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
**Purpose:** Единый источник визуальных констант

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

#### Layer 1: View Modifiers (Atoms)
**Purpose:** Переиспользуемые стили без контекста

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
**Purpose:** Семантические компоненты с четким назначением

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
**Purpose:** Сложные композиции для стандартных UI-паттернов

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
**Purpose:** Платформенная адаптация и темизация

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

---

## 5. Core Components Specification

### 5.1 Essential Components (MVP)

| Component | Purpose | Platforms | Priority |
|-----------|---------|-----------|----------|
| **Badge** | Status indicators | All | P0 |
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
- **Zero magic numbers:** Все значения через DS tokens
- **Semantic before visual:** Имена отражают смысл, не стиль
- **Local responsibility:** Компоненты управляют своим состоянием
- **Predictable composability:** Компоненты корректны при вложении

### 6.2 Accessibility Requirements
- **Контраст:** ≥ 4.5:1 для всех текстов
- **VoiceOver:** Полная поддержка для всех интерактивных элементов
- **Dynamic Type:** Поддержка системных размеров шрифтов
- **Keyboard Navigation:** Полная клавиатурная доступность
- **Reduce Motion:** Респект к preferredReduceMotion

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
Компоненты поддерживают описание через структурированные данные для генерации агентами:

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
- **Token validation:** Проверка всех значений DS
- **Modifier behavior:** Тестирование логики стилей
- **Component composition:** Проверка корректности вложений
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
- 100% DocC coverage для public API
- Code examples для каждого компонента
- Best practices guide
- Migration guides (if applicable)

### 11.2 Design Documentation
- Component catalog с визуальными примерами
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
- **Build time:** < 10s для чистой сборки модуля
- **Binary size:** < 500KB для release build
- **Memory footprint:** < 5MB для типичного экрана
- **Render performance:** 60 FPS на всех платформах

### 12.2 Developer Experience Metrics
- **Time to first component:** < 5 минут для нового разработчика
- **Code reuse rate:** ≥ 80% кода совместим между платформами
- **Documentation quality:** ≥ 90% satisfaction в опросах

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
