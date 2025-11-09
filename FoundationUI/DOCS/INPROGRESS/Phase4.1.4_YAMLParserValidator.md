# Phase 4.1.4: Implement YAML Parser/Validator

## 🎯 Objective

Implement a YAML parser and validator that can read YAML component definitions, validate them against the ComponentSchema, and generate SwiftUI views programmatically. This enables AI agents to create FoundationUI user interfaces from declarative YAML files.

## 🧩 Context

- **Phase**: Phase 4: Agent Support & Polish
- **Section**: 4.1 Agent-Driven UI Generation
- **Layer**: Agent Support Infrastructure
- **Priority**: P1 (Critical for agent-driven UI generation)
- **Dependencies**:
  - ✅ Phase 4.1.1: AgentDescribable protocol (completed 2025-11-08)
  - ✅ Phase 4.1.2: AgentDescribable conformance for all components (completed 2025-11-09)
  - ✅ Phase 4.1.3: YAML Schema Definitions (completed 2025-11-09)

## ✅ Success Criteria

- [ ] YAMLValidator.swift created with Yams integration
- [ ] YAML parsing functionality for all components and patterns
- [ ] Schema validation against ComponentSchema.yaml
- [ ] SwiftUI view generation from parsed YAML
- [ ] Comprehensive error handling and reporting
- [ ] Type safety for all property conversions
- [ ] Unit tests for parser (≥20 test cases)
- [ ] Unit tests for validator (≥15 test cases)
- [ ] Unit tests for view generation (≥10 test cases)
- [ ] Integration tests with example YAML files
- [ ] Performance tests (parse 100 components in <100ms)
- [ ] Error message quality (clear, actionable messages)
- [ ] 100% DocC documentation
- [ ] Zero magic numbers (100% DS token usage)

## 🔧 Implementation Plan

### 1. Dependencies Setup

**Add Yams library to Package.swift**:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
],
targets: [
    .target(
        name: "FoundationUI",
        dependencies: ["Yams"]
    ),
]
```

### 2. Core Parser Implementation

**File**: `Sources/FoundationUI/AgentSupport/YAMLParser.swift`

**Key Components**:

```swift
import Foundation
import Yams

/// Parses YAML component definitions into structured ComponentDescription objects.
@available(iOS 17.0, macOS 14.0, *)
public struct YAMLParser {

    /// Parsed component description from YAML
    public struct ComponentDescription {
        public let componentType: String
        public let properties: [String: Any]
        public let semantics: String?
        public let content: [ComponentDescription]?
    }

    /// Parse YAML string into component descriptions
    public static func parse(_ yamlString: String) throws -> [ComponentDescription] {
        // Implementation
    }

    /// Parse YAML file at URL
    public static func parse(fileAt url: URL) throws -> [ComponentDescription] {
        // Implementation
    }
}
```

**Features**:
- Parse YAML strings and files
- Support for nested components (Cards containing Badges, etc.)
- Array and dictionary handling
- Multi-document YAML support (---separators)
- Error handling for malformed YAML

### 3. Schema Validator Implementation

**File**: `Sources/FoundationUI/AgentSupport/YAMLValidator.swift`

**Key Components**:

```swift
import Foundation

/// Validates parsed YAML component descriptions against ComponentSchema.
@available(iOS 17.0, macOS 14.0, *)
public struct YAMLValidator {

    /// Validation error types
    public enum ValidationError: Error {
        case unknownComponentType(String)
        case missingRequiredProperty(component: String, property: String)
        case invalidPropertyType(component: String, property: String, expected: String, actual: String)
        case invalidEnumValue(component: String, property: String, value: String, validValues: [String])
        case valueOutOfBounds(component: String, property: String, value: Any, min: Any?, max: Any?)
        case invalidComposition(String)
    }

    /// Validate component description against schema
    public static func validate(_ description: YAMLParser.ComponentDescription) throws {
        // Implementation
    }

    /// Validate array of component descriptions
    public static func validate(_ descriptions: [YAMLParser.ComponentDescription]) throws {
        // Implementation
    }
}
```

**Validation Rules**:
1. **Component Type Validation**
   - componentType must match schema (Badge, Card, KeyValueRow, etc.)
   - Case-sensitive matching

2. **Required Properties**
   - All required properties must be present
   - Example: Badge requires "text" and "level"

3. **Property Type Validation**
   - String properties are String
   - Boolean properties are Bool
   - Numeric properties are Int/Double within bounds
   - Enum properties match valid values

4. **Enum Validation**
   - level: ["info", "warning", "error", "success"]
   - elevation: ["none", "low", "medium", "high"]
   - material: ["thin", "regular", "thick", "ultraThin", "ultraThick"]

5. **Bounds Validation**
   - cornerRadius: 0-50
   - String lengths: min_length to max_length

6. **Composition Validation**
   - Cards can contain components but not root Cards
   - No circular references

### 4. View Generator Implementation

**File**: `Sources/FoundationUI/AgentSupport/YAMLViewGenerator.swift`

**Key Components**:

```swift
import SwiftUI

/// Generates SwiftUI views from parsed and validated YAML component descriptions.
@available(iOS 17.0, macOS 14.0, *)
public struct YAMLViewGenerator {

    /// Generate SwiftUI view from component description
    public static func generateView(from description: YAMLParser.ComponentDescription) throws -> AnyView {
        // Implementation
    }

    /// Generate SwiftUI view from YAML string
    public static func generateView(fromYAML yamlString: String) throws -> AnyView {
        let descriptions = try YAMLParser.parse(yamlString)
        guard let description = descriptions.first else {
            throw GenerationError.emptyYAML
        }
        try YAMLValidator.validate(description)
        return try generateView(from: description)
    }
}
```

**View Generation Logic**:

```swift
func generateView(from description: ComponentDescription) throws -> AnyView {
    switch description.componentType {
    case "Badge":
        return AnyView(generateBadge(from: description))
    case "Card":
        return AnyView(generateCard(from: description))
    case "KeyValueRow":
        return AnyView(generateKeyValueRow(from: description))
    case "SectionHeader":
        return AnyView(generateSectionHeader(from: description))
    case "InspectorPattern":
        return AnyView(generateInspectorPattern(from: description))
    case "SidebarPattern":
        return AnyView(generateSidebarPattern(from: description))
    case "ToolbarPattern":
        return AnyView(generateToolbarPattern(from: description))
    case "BoxTreePattern":
        return AnyView(generateBoxTreePattern(from: description))
    default:
        throw GenerationError.unknownComponentType(description.componentType)
    }
}

private func generateBadge(from description: ComponentDescription) throws -> Badge {
    guard let text = description.properties["text"] as? String else {
        throw GenerationError.missingProperty("text")
    }
    guard let levelString = description.properties["level"] as? String,
          let level = BadgeLevel(rawValue: levelString) else {
        throw GenerationError.invalidProperty("level")
    }
    let showIcon = description.properties["showIcon"] as? Bool ?? true

    return Badge(text: text, level: level, showIcon: showIcon)
}

// Similar generators for other components...
```

### 5. Error Handling

**Clear, Actionable Error Messages**:

```swift
// Good error message
"Invalid property 'level' in Badge component at line 5:
 Expected one of [info, warning, error, success], got 'erro'.
 Did you mean 'error'?"

// Bad error message
"Parse error"
```

**Error Message Components**:
- Component type and location
- Property name
- Expected vs actual values
- Suggestions for typos (Levenshtein distance)

### 6. Testing Strategy

#### Unit Tests (45+ total)

**YAMLParserTests.swift** (20 tests):
- Parse simple component
- Parse nested components (Card with Badges)
- Parse multi-document YAML
- Parse arrays and dictionaries
- Handle malformed YAML
- Handle missing properties
- Handle invalid syntax
- Performance: parse 100 components

**YAMLValidatorTests.swift** (15 tests):
- Validate valid components (all 8 types)
- Reject unknown componentType
- Reject missing required properties
- Reject invalid property types
- Reject invalid enum values
- Reject out-of-bounds values
- Reject circular references
- Suggest typo corrections

**YAMLViewGeneratorTests.swift** (10 tests):
- Generate Badge from YAML
- Generate Card from YAML
- Generate nested Card+Badge
- Generate InspectorPattern with sections
- Generate all 8 component types
- Handle generation errors gracefully
- Verify DS token usage in generated views
- Performance: generate 50 views

#### Integration Tests (5 tests)

**YAMLIntegrationTests.swift**:
- Parse + validate + generate badge_examples.yaml
- Parse + validate + generate inspector_pattern_examples.yaml
- Parse + validate + generate complete_ui_example.yaml
- Error handling for invalid YAML
- Round-trip: AgentDescribable → YAML → View

### 7. Performance Requirements

| Operation | Target | Measurement |
|-----------|--------|-------------|
| Parse 100 components | <100ms | XCTClockMetric |
| Validate 100 components | <50ms | XCTClockMetric |
| Generate 50 views | <200ms | XCTClockMetric |
| Memory footprint | <5MB | XCTStorageMetric |

### 8. Documentation

**DocC Articles**:
- Agent Integration Guide (how to use YAMLParser)
- YAML Schema Reference (link to ComponentSchema.yaml)
- Error Handling Best Practices
- Performance Considerations

**Code Documentation**:
- 100% DocC coverage for public API
- Usage examples in code comments
- Platform-specific notes

## 📋 Files to Create/Modify

### New Files

1. **Sources/FoundationUI/AgentSupport/YAMLParser.swift**
   - YAML parsing functionality
   - ComponentDescription struct
   - File and string parsing

2. **Sources/FoundationUI/AgentSupport/YAMLValidator.swift**
   - Schema validation logic
   - ValidationError enum
   - Validation rules implementation

3. **Sources/FoundationUI/AgentSupport/YAMLViewGenerator.swift**
   - SwiftUI view generation
   - Component-specific generators
   - Error handling

4. **Tests/FoundationUITests/AgentSupportTests/YAMLParserTests.swift**
   - 20 parser unit tests
   - Performance tests

5. **Tests/FoundationUITests/AgentSupportTests/YAMLValidatorTests.swift**
   - 15 validator unit tests
   - Error message tests

6. **Tests/FoundationUITests/AgentSupportTests/YAMLViewGeneratorTests.swift**
   - 10 view generation unit tests
   - Integration tests

### Modified Files

1. **Package.swift**
   - Add Yams dependency
   - Update targets

## 🔄 Integration Points

### Phase 4.1.3 YAML Schema
- Use ComponentSchema.yaml for validation rules
- Reference example YAML files for testing
- Follow schema structure for parsing

### Phase 4.1.1 AgentDescribable Protocol
- ComponentDescription mirrors AgentDescribable
- Properties dictionary matches AgentDescribable.properties
- Semantics field maps to AgentDescribable.semantics

### Phase 4.1.2 Components
- Generate actual Badge, Card, KeyValueRow, etc.
- Use component initializers directly
- Verify all properties are supported

## 🧪 Testing with Example Files

**Test all example YAML files**:

```swift
func testParseBadgeExamples() throws {
    let url = Bundle.module.url(forResource: "badge_examples", withExtension: "yaml")!
    let descriptions = try YAMLParser.parse(fileAt: url)

    XCTAssertEqual(descriptions.count, 6) // 6 examples

    for description in descriptions {
        try YAMLValidator.validate(description)
        let view = try YAMLViewGenerator.generateView(from: description)
        XCTAssertNotNil(view)
    }
}
```

## 📊 Quality Gates

| Gate | Target | Validation Method |
|------|--------|-------------------|
| Unit test coverage | ≥80% | `swift test --enable-code-coverage` |
| All tests pass | 100% | CI pipeline |
| SwiftLint violations | 0 | `swiftlint` |
| Magic numbers | 0 | Code review |
| DocC coverage | 100% | Documentation audit |
| Performance targets | All met | XCTest metrics |
| Error message quality | Clear & actionable | Manual review |

## 🎯 Design Token Usage

**All generated views must use DS tokens**:

```swift
// Example: Badge generation
Badge(text: text, level: level, showIcon: showIcon)
// Badge internally uses:
// - DS.Spacing.s for padding
// - DS.Radius.chip for corner radius
// - DS.Colors.infoBG/warnBG/etc for backgrounds
```

**Validation**:
- No magic numbers in generated views
- All spacing, colors, radius, typography from DS namespace
- Test assertions verify DS token usage

## 🚀 Next Steps After Completion

**Phase 4.1.5: Create Agent Integration Examples**
- Example YAML definitions for real use cases
- Swift code showing agent integration
- 0AL/Hypercode agent examples
- Documentation guide for agent developers

**Phase 4.1.6-4.1.7: Unit Tests & Documentation**
- Comprehensive test suite for agent support
- Agent integration guide (DocC article)
- API reference for agent developers
- Best practices and troubleshooting

## 🔍 Edge Cases to Handle

1. **Malformed YAML**
   - Invalid syntax
   - Missing separators
   - Incorrect indentation

2. **Invalid Data Types**
   - String where Bool expected
   - Array where Object expected
   - Null values

3. **Missing Properties**
   - Required properties not present
   - Optional properties handling
   - Default values

4. **Enum Typos**
   - "erro" instead of "error"
   - "waring" instead of "warning"
   - Suggest corrections (Levenshtein distance)

5. **Circular References**
   - Card containing itself
   - Infinite nesting detection
   - Maximum depth limit (20 levels)

6. **Platform-Specific Properties**
   - Material effects on iOS vs macOS
   - Keyboard shortcuts (macOS only)
   - Touch targets (iOS only)

## 📚 References

- [Yams Library Documentation](https://github.com/jpsim/Yams)
- [YAML 1.2 Specification](https://yaml.org/spec/1.2/spec.html)
- [ComponentSchema.yaml](../../Sources/FoundationUI/AgentSupport/ComponentSchema.yaml)
- [Example YAML Files](../../Sources/FoundationUI/AgentSupport/Examples/)
- [AgentDescribable Protocol](../../Sources/FoundationUI/AgentSupport/AgentDescribable.swift)
- [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) (Phase 4.1.4)
- [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)

## 🔄 Workflow Integration

**Development Workflow**:
1. Install Yams dependency (`swift package resolve`)
2. Create YAMLParser.swift with parsing logic
3. Create YAMLValidator.swift with validation rules
4. Create YAMLViewGenerator.swift with view generation
5. Write unit tests (45+ tests)
6. Write integration tests (5 tests)
7. Add DocC documentation
8. Run tests: `swift test`
9. Run SwiftLint: `swiftlint`
10. Update Task Plan
11. Commit and push

**After Completion**:
- Archive to `TASK_ARCHIVE/47_Phase4.1.4_YAMLParserValidator/`
- Update Task Plan: Phase 4.1.4 `[ ]` → `[x]`
- Create summary document
- Proceed to Phase 4.1.5

---

**Status**: ⏳ **READY TO START** (All dependencies complete)
**Estimated Effort**: 2-4 hours
**Created**: 2025-11-09
**Dependencies**: Phase 4.1.1 ✅, Phase 4.1.2 ✅, Phase 4.1.3 ✅
