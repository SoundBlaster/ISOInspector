# DESIGN SYSTEM GUIDE — Composable Clarity

**Project:** ISO Inspector / 0AL Design System  
**Version:** 1.0  
**Author:** 0AL Core Design  
**Applies to:** macOS, iPadOS, iOS (SwiftUI, Agent-driven UI generation)

---

## 1. Core Principle

> **Composable Clarity** — это подход, в котором каждый элемент интерфейса выражает свой смысл через простые, независимые и сочетаемые атомы (ViewModifier, Token, Pattern).  
> UI не рисуется — он **собирается из смыслов**.

---

## 2. Design Values

| Value | Description | Manifestation |
|--------|--------------|----------------|
| **Clarity** | Простая визуальная иерархия | Свет, типографика, отступы вместо рамок |
| **Composition** | Всё строится из атомов | Любая часть может стать новым паттерном |
| **Autonomy** | Самодостаточные компоненты | Легко тестировать и копировать |
| **Semantic consistency** | Цвет и форма = смысл | Один смысл → одно визуальное проявление |
| **Constraint** | Минимализм как стиль | Ограниченный набор токенов и правил |

---

## 3. System Architecture

### Layer 0 — Tokens
Единственный источник числовых значений.

```swift
enum DS {
    enum Spacing { static let s = 8.0; static let m = 12.0; static let l = 16.0 }
    enum Radius  { static let card = 10.0; static let chip = 999.0 }
    enum Font    { static let label = Font.caption2.weight(.semibold) }
    enum Color {
        static let infoBG  = Color.gray.opacity(0.18)
        static let warnBG  = Color.orange.opacity(0.22)
        static let errorBG = Color.red.opacity(0.22)
    }
}
```

---

### Layer 1 — Modifiers (Atoms)
Описывают поведение и стиль без контекста.

```swift
struct BadgeChipStyle: ViewModifier {
    let level: BadgeLevel
    func body(content: Content) -> some View {
        content
            .font(DS.Font.label)
            .textCase(.uppercase)
            .padding(.vertical, DS.Spacing.s / 2)
            .padding(.horizontal, DS.Spacing.m / 2)
            .background(background, in: Capsule())
    }
    private var background: Color {
        switch level {
        case .info: DS.Color.infoBG
        case .warning: DS.Color.warnBG
        case .error: DS.Color.errorBG
        }
    }
}
```

---

### Layer 2 — Components (Molecules)

Комбинация модификаторов + семантика.

```swift
struct Badge: View {
    let text: String
    let level: BadgeLevel
    var body: some View {
        Text(text)
            .modifier(BadgeChipStyle(level: level))
    }
}
```

---

### Layer 3 — Patterns (Organisms)

Собранные участки интерфейса:
- `SidebarPattern`
- `BoxTreePattern`
- `InspectorPattern`
- `ToolbarPattern`

**Пример:**

```swift
struct InspectorPattern: View {
    let box: MP4Box
    var body: some View {
        ScrollView {
            InspectorSection(title: "METADATA") { MetadataGrid(box: box) }
            InspectorSection(title: "VALIDATION") { ValidationList(box: box) }
            InspectorSection(title: "HEX") { HexView(data: box.payload) }
        }
        .padding(.horizontal, DS.Spacing.l)
        .background(.thinMaterial)
    }
}
```

---

### Layer 4 — Contexts (Themes)

Определяют визуальную плотность, фон и материалы.

```swift
extension EnvironmentValues {
    var surfaceStyle: Material { get { self[SurfaceStyleKey.self] } set { self[SurfaceStyleKey.self] = newValue } }
}
```

---

## 4. Visual & Interaction Rules

| Aspect | Rule |
|---------|------|
| **Typography** | SF Pro Rounded / SF Mono; smallCaps для секций |
| **Spacing** | 8 → 12 → 16 pt step grid |
| **Radius** | 8–10 pt (card), capsule для бейджей |
| **Colors** | Только системные; Info / Warning / Error через прозрачные оттенки |
| **Depth** | Материалы и прозрачность вместо теней |
| **Animation** | 100–250 мс, `.snappy` или `.easeInOut` |
| **Accessibility** | Контраст ≥ 4.5 : 1, копирование, VoiceOver |
| **Copyability** | Все значения интерактивны (копируются) |
| **Keyboard** | ⌘ I — Inspector, ⌘ F — поиск, ↑ ↓ — навигация |

---

## 5. Semantic Composition Rules

1. **Semantic before visual.**  
   Любое свойство определяется смыслом: *warning*, *info*, *metadata*.

2. **Local responsibility.**  
   Компонент сам управляет состоянием hover/focus/copy.

3. **Environment over globals.**  
   Общие параметры (цвета, плотность) передаются через `Environment`.

4. **Predictable Composability.**  
   Компоненты не ломаются при вложении.

5. **Zero magic numbers.**  
   Только токены.

6. **Soft motion.**  
   Минимальная, согласованная анимация.

7. **Shadowless depth.**  
   Иерархия строится светом, не тенью.

---

## 6. Example — Badge Composition Flow

```
[TOKENS] + [MODIFIER] → [COMPONENT] → [PATTERN] → [CONTEXT]
```

**Пример:**
```swift
DS.Color.errorBG + BadgeChipStyle → Badge → ValidationList → InspectorPattern
```

---

## 7. The Agent Rule (for 0AL / Hypercode)

Агенты могут описывать UI декларативно:

```yaml
component: Badge
props:
  text: "ERROR"
  level: error
appearance:
  uses: DS.BadgeChipStyle
semantics: "critical validation state"
```

Любой агент, читающий этот YAML, может визуализировать интерфейс, соблюдая правила токенов и модификаторов.

---

## 8. Manifesto

> **Composable Clarity** — это язык проектирования, где форма = функция,  
> ограничения = стиль,  
> а дизайн = декларация смысла.  
>
> Каждый элемент — объясним, копируем и переиспользуем.  
> Так рождается системная красота.

---

## 9. License

MIT © 0AL Core Design System
