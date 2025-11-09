# Phase 4.1.2: Implement AgentDescribable for All Components

## 🎯 Objective

Extend the `AgentDescribable` protocol (Phase 4.1.1) to all FoundationUI components and patterns, enabling AI agents to programmatically understand, generate, and manipulate FoundationUI UIs through type-safe property descriptions.

## 🧩 Context

- **Phase**: 4.1 (Agent-Driven UI Generation)
- **Layer**: Layer 4 (Contexts / Agent Support)
- **Priority**: P1 (Critical for agent integration)
- **Estimated Effort**: 4-6 hours
- **Dependencies**:
  - ✅ Phase 4.1.1 AgentDescribable Protocol Complete
  - ✅ All components implemented (Phase 2)
  - ✅ All patterns implemented (Phase 3)
  - ✅ Test infrastructure ready (Phase 5.2)

## ✅ Success Criteria

- [ ] Badge component conforms to AgentDescribable with all properties
- [ ] Card component conforms to AgentDescribable with all properties
- [ ] KeyValueRow component conforms to AgentDescribable with all properties
- [ ] SectionHeader component conforms to AgentDescribable with all properties
- [ ] InspectorPattern conforms to AgentDescribable with all properties
- [ ] SidebarPattern conforms to AgentDescribable with all properties
- [ ] ToolbarPattern conforms to AgentDescribable with all properties
- [ ] BoxTreePattern conforms to AgentDescribable with all properties
- [ ] Unit tests written (≥10 test cases per component/pattern)
- [ ] All properties are JSON serializable
- [ ] SwiftUI Preview examples included for each component
- [ ] DocC documentation updated with AgentDescribable conformance
- [ ] SwiftLint reports 0 violations
- [ ] Platform support verified (iOS/macOS/iPadOS)

## 🔧 Implementation Plan

### Components to Extend (Layer 2)

#### 1. Badge Component
- **File**: `Sources/FoundationUI/Components/Badge.swift`
- **Properties to expose**:
  - `text: String` (required)
  - `level: BadgeLevel` (required)
  - `showIcon: Bool` (optional)
- **Semantic description**: "A colored badge component for status/category labels"
- **Example YAML**:
  ```yaml
  component: Badge
  properties:
    text: "Info"
    level: "info"
    showIcon: true
  ```

#### 2. Card Component
- **File**: `Sources/FoundationUI/Components/Card.swift`
- **Properties to expose**:
  - `elevation: CardElevation` (optional, default: .none)
  - `material: SurfaceMaterial` (optional, default: .regular)
  - `cornerRadius: CGFloat` (optional, default: DS.Radius.card)
- **Semantic description**: "A container component for content with elevation and material background"
- **Example YAML**:
  ```yaml
  component: Card
  properties:
    elevation: "medium"
    material: "regular"
    cornerRadius: 10
  ```

#### 3. KeyValueRow Component
- **File**: `Sources/FoundationUI/Components/KeyValueRow.swift`
- **Properties to expose**:
  - `key: String` (required)
  - `value: String` (required)
  - `layout: KeyValueRowLayout` (optional, default: .horizontal)
  - `isCopyable: Bool` (optional, default: false)
- **Semantic description**: "A row component for displaying key-value pairs with optional copyable values"
- **Example YAML**:
  ```yaml
  component: KeyValueRow
  properties:
    key: "File Size"
    value: "1.5 MB"
    layout: "horizontal"
    isCopyable: true
  ```

#### 4. SectionHeader Component
- **File**: `Sources/FoundationUI/Components/SectionHeader.swift`
- **Properties to expose**:
  - `title: String` (required)
  - `showDivider: Bool` (optional, default: false)
- **Semantic description**: "A section header component with optional divider"
- **Example YAML**:
  ```yaml
  component: SectionHeader
  properties:
    title: "Box Details"
    showDivider: true
  ```

### Patterns to Extend (Layer 3)

#### 5. InspectorPattern
- **File**: `Sources/FoundationUI/Patterns/InspectorPattern.swift`
- **Properties to expose**:
  - `title: String` (required)
  - `material: SurfaceMaterial` (optional, default: .regular)
  - `sections: [InspectorSection]` (required)
- **Semantic description**: "A scrollable pattern for displaying detailed metadata with sections"
- **Example YAML**:
  ```yaml
  pattern: InspectorPattern
  properties:
    title: "ISO Box Inspector"
    material: "regular"
    sections:
      - title: "Box Type"
        items:
          - key: "Type"
            value: "ftyp"
  ```

#### 6. SidebarPattern
- **File**: `Sources/FoundationUI/Patterns/SidebarPattern.swift`
- **Properties to expose**:
  - `items: [SidebarItem]` (required)
  - `selection: String` (optional)
- **Semantic description**: "A navigation sidebar pattern with hierarchical items"
- **Example YAML**:
  ```yaml
  pattern: SidebarPattern
  properties:
    items:
      - id: "item1"
        label: "Video"
        icon: "film"
  ```

#### 7. ToolbarPattern
- **File**: `Sources/FoundationUI/Patterns/ToolbarPattern.swift`
- **Properties to expose**:
  - `items: [ToolbarItem]` (required)
  - `layout: ToolbarLayout` (optional, default: .compact)
- **Semantic description**: "A toolbar pattern with icon-based actions and overflow menu"
- **Example YAML**:
  ```yaml
  pattern: ToolbarPattern
  properties:
    items:
      - id: "open"
        label: "Open"
        icon: "folder"
        keyboardShortcut: "cmd+o"
  ```

#### 8. BoxTreePattern
- **File**: `Sources/FoundationUI/Patterns/BoxTreePattern.swift`
- **Properties to expose**:
  - `boxes: [BoxNode]` (required)
  - `selectionMode: SelectionMode` (optional, default: .single)
- **Semantic description**: "A hierarchical tree pattern for ISO box structure display"
- **Example YAML**:
  ```yaml
  pattern: BoxTreePattern
  properties:
    boxes:
      - id: "root"
        name: "ISO File"
        children:
          - id: "ftyp"
            name: "ftyp"
    selectionMode: "single"
  ```

## 🧪 Testing Strategy

### Unit Tests
- Create `Tests/FoundationUITests/AgentSupportTests/ComponentAgentDescribableTests.swift`
- Create `Tests/FoundationUITests/AgentSupportTests/PatternAgentDescribableTests.swift`
- For each component/pattern:
  - Test protocol conformance
  - Test property encoding (JSON serialization)
  - Test `agentDescription()` returns valid structure
  - Test edge cases (empty strings, nil values)
  - Test accessibility label generation
  - Test platform-specific properties

### Integration Tests
- Test component nesting with AgentDescribable
- Test pattern composition with multiple components
- Test YAML-to-component mapping (preparation for YAML parser)

## 🔧 Files to Create/Modify

### Components (Layer 2)
- `Sources/FoundationUI/Components/Badge.swift` - Add AgentDescribable conformance
- `Sources/FoundationUI/Components/Card.swift` - Add AgentDescribable conformance
- `Sources/FoundationUI/Components/KeyValueRow.swift` - Add AgentDescribable conformance
- `Sources/FoundationUI/Components/SectionHeader.swift` - Add AgentDescribable conformance

### Patterns (Layer 3)
- `Sources/FoundationUI/Patterns/InspectorPattern.swift` - Add AgentDescribable conformance
- `Sources/FoundationUI/Patterns/SidebarPattern.swift` - Add AgentDescribable conformance
- `Sources/FoundationUI/Patterns/ToolbarPattern.swift` - Add AgentDescribable conformance
- `Sources/FoundationUI/Patterns/BoxTreePattern.swift` - Add AgentDescribable conformance

### Tests
- `Tests/FoundationUITests/AgentSupportTests/ComponentAgentDescribableTests.swift` - NEW
- `Tests/FoundationUITests/AgentSupportTests/PatternAgentDescribableTests.swift` - NEW

### Documentation
- Update all component DocC comments with AgentDescribable examples
- Add "Agent Integration" section to each component documentation

## 🧠 Implementation Notes

### AgentDescribable Protocol Recap
```swift
public protocol AgentDescribable {
    var componentType: String { get }
    var properties: [String: Any] { get }
    var semantics: String { get }

    func agentDescription() -> [String: Any]
    func isJSONSerializable() -> Bool
}
```

### Key Requirements
1. **Type Safety**: Use `@dynamicMemberLookup` or dictionary encoding for properties
2. **JSON Serialization**: All properties must be encodable to JSON
3. **Accessibility**: Include accessibility labels in semantics
4. **Platform Awareness**: Mark platform-specific properties in metadata
5. **Zero Magic Numbers**: Use DS tokens in property descriptors

### Example Implementation Pattern
```swift
extension Badge: AgentDescribable {
    public var componentType: String { "Badge" }

    public var properties: [String: Any] {
        [
            "text": text,
            "level": level.rawValue,
            "showIcon": showIcon
        ]
    }

    public var semantics: String {
        """
        A colored badge component displaying '\(text)' at level '\(level.rawValue)'.
        Shows icon: \(showIcon).
        Accessibility: '\(level.accessibilityLabel)'.
        """
    }
}
```

### Test Pattern
```swift
func testBadgeAgentDescribable() {
    let badge = Badge(text: "Info", level: .info, showIcon: true)

    // Test protocol conformance
    XCTAssertEqual(badge.componentType, "Badge")
    XCTAssertTrue(badge.properties.keys.contains("text"))
    XCTAssertTrue(badge.isJSONSerializable())

    // Test property values
    XCTAssertEqual(badge.properties["text"] as? String, "Info")
    XCTAssertEqual(badge.properties["level"] as? String, "info")
    XCTAssertEqual(badge.properties["showIcon"] as? Bool, true)
}
```

## 📊 Design Token Usage

- Spacing: `DS.Spacing.{s|m|l|xl}` (in property descriptions)
- Colors: `DS.Colors.{infoBG|warnBG|errorBG|successBG}` (in semantics)
- Radius: `DS.Radius.{card|chip|small}` (in property descriptors)
- Animation: `DS.Animation.{quick|medium}` (in interaction descriptions)

## 🔗 Source References

- [FoundationUI Task Plan § Phase 4.1](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#phase-4-agent-support--polish)
- [FoundationUI PRD § Agent Support](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [AgentDescribable Protocol](../../../FoundationUI/DOCS/TASK_ARCHIVE/45_Phase4.1_AgentDescribable/)
- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Codable Swift Documentation](https://developer.apple.com/documentation/swift/codable)

## 📋 Checklist

- [ ] **Badge component**
  - [ ] Read Badge.swift implementation
  - [ ] Implement AgentDescribable conformance
  - [ ] Write 2-3 unit tests
  - [ ] Test JSON serialization
  - [ ] Update DocC documentation
  - [ ] Add SwiftUI Preview example

- [ ] **Card component**
  - [ ] Read Card.swift implementation
  - [ ] Implement AgentDescribable conformance
  - [ ] Write 2-3 unit tests
  - [ ] Test JSON serialization
  - [ ] Update DocC documentation
  - [ ] Add SwiftUI Preview example

- [ ] **KeyValueRow component**
  - [ ] Read KeyValueRow.swift implementation
  - [ ] Implement AgentDescribable conformance
  - [ ] Write 2-3 unit tests
  - [ ] Test JSON serialization
  - [ ] Update DocC documentation
  - [ ] Add SwiftUI Preview example

- [ ] **SectionHeader component**
  - [ ] Read SectionHeader.swift implementation
  - [ ] Implement AgentDescribable conformance
  - [ ] Write 1-2 unit tests
  - [ ] Test JSON serialization
  - [ ] Update DocC documentation
  - [ ] Add SwiftUI Preview example

- [ ] **InspectorPattern**
  - [ ] Read InspectorPattern.swift implementation
  - [ ] Implement AgentDescribable conformance
  - [ ] Write 2-3 unit tests
  - [ ] Update DocC documentation
  - [ ] Add SwiftUI Preview example

- [ ] **SidebarPattern**
  - [ ] Read SidebarPattern.swift implementation
  - [ ] Implement AgentDescribable conformance
  - [ ] Write 2-3 unit tests
  - [ ] Update DocC documentation
  - [ ] Add SwiftUI Preview example

- [ ] **ToolbarPattern**
  - [ ] Read ToolbarPattern.swift implementation
  - [ ] Implement AgentDescribable conformance
  - [ ] Write 2-3 unit tests
  - [ ] Update DocC documentation
  - [ ] Add SwiftUI Preview example

- [ ] **BoxTreePattern**
  - [ ] Read BoxTreePattern.swift implementation
  - [ ] Implement AgentDescribable conformance
  - [ ] Write 2-3 unit tests
  - [ ] Update DocC documentation
  - [ ] Add SwiftUI Preview example

- [ ] **Test Coverage**
  - [ ] Write ComponentAgentDescribableTests.swift (10+ tests)
  - [ ] Write PatternAgentDescribableTests.swift (10+ tests)
  - [ ] Run `swift test` to confirm all pass
  - [ ] Verify 80%+ coverage

- [ ] **Code Quality**
  - [ ] Run `swiftlint` (0 violations)
  - [ ] Verify all types are JSON serializable
  - [ ] Check accessibility labels

- [ ] **Integration Testing**
  - [ ] Test component composition with AgentDescribable
  - [ ] Test pattern combinations
  - [ ] Test real-world ISO Inspector scenarios

- [ ] **Documentation**
  - [ ] Update all component DocC comments
  - [ ] Add "Agent Integration" examples
  - [ ] Create migration guide if needed

- [ ] **Commit & Archive**
  - [ ] Commit with descriptive message (Phase 4.1.2)
  - [ ] Archive task: `TASK_ARCHIVE/46_Phase4.1.2_AgentDescribableComponents/`
  - [ ] Update Task Plan with completion mark

## 📈 Effort Estimation

| Phase | Hours | Notes |
|-------|-------|-------|
| Component implementation (4 components) | 2.0h | ~30min per component |
| Pattern implementation (4 patterns) | 2.0h | ~30min per pattern |
| Unit tests (8 components/patterns) | 1.0h | ~8min per test file |
| Integration tests | 0.5h | Cross-component/pattern scenarios |
| Documentation & polish | 0.5h | DocC updates, examples |
| **Total** | **6.0h** | Within estimate |

---

## 📝 Notes

- **Layer dependencies**: Components (Layer 2) should be extended before patterns (Layer 3)
- **JSON serialization**: Test all property types can be serialized to JSON
- **Accessibility**: Include accessibility labels in semantic descriptions
- **Platform coverage**: Test on iOS/macOS/iPadOS
- **Backward compatibility**: All changes are additive (no breaking changes)

---

**Created**: 2025-11-09
**Status**: READY FOR IMPLEMENTATION
**Phase**: 4.1.2 (Agent-Driven UI Generation)
