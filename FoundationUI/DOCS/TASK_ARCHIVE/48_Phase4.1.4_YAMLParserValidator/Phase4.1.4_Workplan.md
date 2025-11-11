# Phase 4.1.4 Work Plan: YAML Parser/Validator Implementation

**Task**: Implement YAML Parser/Validator
**Phase**: 4.1 Agent-Driven UI Generation
**Priority**: P1
**Estimated Effort**: 2-4 hours
**Status**: Ready to Start
**Created**: 2025-11-09

---

## 🎯 Objectives

1. Add Yams library dependency to Package.swift
2. Implement YAMLParser for parsing YAML component definitions
3. Implement YAMLValidator for schema validation
4. Implement YAMLViewGenerator for SwiftUI view generation
5. Write comprehensive unit tests (45+ tests)
6. Add DocC documentation (100% coverage)
7. Verify with example YAML files

---

## 📋 Task Breakdown

### Step 1: Setup Dependencies (15 min)

**Goal**: Add Yams library to Package.swift

- [ ] Open `Package.swift`
- [ ] Add Yams dependency: `https://github.com/jpsim/Yams.git`, version 5.0.0+
- [ ] Add Yams to FoundationUI target dependencies
- [ ] Run `swift package resolve`
- [ ] Verify Yams integration: `swift build`

**Files Modified**:

- `Package.swift`

**Validation**:

```bash
swift package resolve
swift build
```

---

### Step 2: Implement YAMLParser (45-60 min)

**Goal**: Create parser for YAML component definitions

**File**: `Sources/FoundationUI/AgentSupport/YAMLParser.swift`

**Implementation Checklist**:

- [ ] Create ComponentDescription struct
  - [ ] componentType: String
  - [ ] properties: [String: Any]
  - [ ] semantics: String?
  - [ ] content: [ComponentDescription]?

- [ ] Implement `parse(_ yamlString: String) throws -> [ComponentDescription]`
  - [ ] Use Yams.load() for YAML parsing
  - [ ] Handle multi-document YAML (--- separators)
  - [ ] Parse nested components recursively
  - [ ] Extract properties dictionary
  - [ ] Handle arrays and dictionaries

- [ ] Implement `parse(fileAt url: URL) throws -> [ComponentDescription]`
  - [ ] Read file contents
  - [ ] Call parse(yamlString:)
  - [ ] Handle file I/O errors

- [ ] Add error types
  - [ ] ParseError.invalidYAML
  - [ ] ParseError.missingComponentType
  - [ ] ParseError.invalidStructure

- [ ] Add DocC documentation
  - [ ] Struct documentation
  - [ ] Method documentation
  - [ ] Usage examples
  - [ ] Error handling notes

**Test Cases** (YAMLParserTests.swift):

1. Parse simple Badge component
2. Parse Card with elevation
3. Parse nested Card + Badge
4. Parse multi-document YAML
5. Parse InspectorPattern with sections
6. Handle malformed YAML
7. Handle missing componentType
8. Handle invalid YAML syntax
9. Parse all 8 component types
10. Performance: parse 100 components

**Validation**:

```swift
let yaml = """
- componentType: Badge
  properties:
    text: "Test"
    level: info
"""
let descriptions = try YAMLParser.parse(yaml)
XCTAssertEqual(descriptions.count, 1)
XCTAssertEqual(descriptions[0].componentType, "Badge")
```

---

### Step 3: Implement YAMLValidator (45-60 min)

**Goal**: Validate parsed YAML against ComponentSchema

**File**: `Sources/FoundationUI/AgentSupport/YAMLValidator.swift`

**Implementation Checklist**:

- [ ] Create ValidationError enum
  - [ ] unknownComponentType(String)
  - [ ] missingRequiredProperty(component: String, property: String)
  - [ ] invalidPropertyType(component: String, property: String, expected: String, actual: String)
  - [ ] invalidEnumValue(component: String, property: String, value: String, validValues: [String])
  - [ ] valueOutOfBounds(component: String, property: String, value: Any, min: Any?, max: Any?)
  - [ ] invalidComposition(String)

- [ ] Implement `validate(_ description: ComponentDescription) throws`
  - [ ] Validate componentType against schema
  - [ ] Validate required properties present
  - [ ] Validate property types (String, Bool, Int, Double)
  - [ ] Validate enum values
  - [ ] Validate numeric bounds
  - [ ] Validate string lengths
  - [ ] Validate composition rules

- [ ] Add schema definitions in code
  - [ ] Badge: required=[text, level], optional=[showIcon]
  - [ ] Card: optional=[elevation, cornerRadius, material]
  - [ ] KeyValueRow: required=[key, value], optional=[layout, isCopyable]
  - [ ] SectionHeader: required=[title], optional=[showDivider]
  - [ ] InspectorPattern: required=[title], optional=[material]
  - [ ] SidebarPattern: required=[sections], optional=[selection]
  - [ ] ToolbarPattern: required=[items]
  - [ ] BoxTreePattern: required=[nodeCount], optional=[level]

- [ ] Add typo suggestions (Levenshtein distance)
  - [ ] "erro" → "Did you mean 'error'?"
  - [ ] "waring" → "Did you mean 'warning'?"

- [ ] Add DocC documentation
  - [ ] Error type documentation
  - [ ] Validation method documentation
  - [ ] Schema reference
  - [ ] Examples

**Test Cases** (YAMLValidatorTests.swift):

1. Validate valid Badge
2. Validate valid Card
3. Reject unknown componentType "UnknownComponent"
4. Reject missing required property (Badge without text)
5. Reject invalid property type (text as Int)
6. Reject invalid enum value (level: "invalid")
7. Reject out-of-bounds cornerRadius (100)
8. Suggest typo correction (level: "erro")
9. Validate nested composition (Card + Badge)
10. Reject circular reference
11. Validate all 8 component types
12. Performance: validate 100 components

**Validation**:

```swift
let description = ComponentDescription(
    componentType: "Badge",
    properties: ["text": "Test", "level": "invalid"],
    semantics: nil,
    content: nil
)
XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
    guard case ValidationError.invalidEnumValue = error else {
        XCTFail("Expected invalidEnumValue error")
        return
    }
}
```

---

### Step 4: Implement YAMLViewGenerator (45-60 min)

**Goal**: Generate SwiftUI views from validated YAML

**File**: `Sources/FoundationUI/AgentSupport/YAMLViewGenerator.swift`

**Implementation Checklist**:

- [ ] Create GenerationError enum
  - [ ] unknownComponentType(String)
  - [ ] missingProperty(String)
  - [ ] invalidProperty(String)
  - [ ] emptyYAML

- [ ] Implement `generateView(from: ComponentDescription) throws -> AnyView`
  - [ ] Switch on componentType
  - [ ] Call component-specific generators
  - [ ] Handle nested components recursively

- [ ] Implement component generators:
  - [ ] `generateBadge(from: ComponentDescription) throws -> Badge`
    - Extract text, level, showIcon
    - Create Badge instance
  - [ ] `generateCard(from: ComponentDescription) throws -> Card`
    - Extract elevation, cornerRadius, material
    - Generate nested content recursively
    - Create Card instance
  - [ ] `generateKeyValueRow(from: ComponentDescription) throws -> KeyValueRow`
    - Extract key, value, layout, isCopyable
    - Create KeyValueRow instance
  - [ ] `generateSectionHeader(from: ComponentDescription) throws -> SectionHeader`
    - Extract title, showDivider
    - Create SectionHeader instance
  - [ ] `generateInspectorPattern(from: ComponentDescription) throws -> InspectorPattern`
    - Extract title, material
    - Generate nested content
    - Create InspectorPattern instance
  - [ ] Similar for SidebarPattern, ToolbarPattern, BoxTreePattern

- [ ] Implement `generateView(fromYAML: String) throws -> AnyView`
  - [ ] Parse YAML
  - [ ] Validate
  - [ ] Generate view

- [ ] Add DocC documentation
  - [ ] Generator method documentation
  - [ ] Usage examples
  - [ ] Error handling

**Test Cases** (YAMLViewGeneratorTests.swift):

1. Generate Badge from YAML
2. Generate Card from YAML
3. Generate KeyValueRow from YAML
4. Generate SectionHeader from YAML
5. Generate nested Card + Badge
6. Generate InspectorPattern with sections
7. Handle unknown componentType error
8. Handle missing property error
9. Verify DS token usage in generated views
10. Performance: generate 50 views

**Validation**:

```swift
let yaml = """
- componentType: Badge
  properties:
    text: "Success"
    level: success
    showIcon: true
"""
let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
// View should be Badge(text: "Success", level: .success, showIcon: true)
```

---

### Step 5: Integration Tests (30 min)

**Goal**: Test with real example YAML files

**File**: `Tests/FoundationUITests/AgentSupportTests/YAMLIntegrationTests.swift`

**Implementation Checklist**:

- [ ] Test badge_examples.yaml
  - [ ] Parse all 6 examples
  - [ ] Validate all
  - [ ] Generate all views
  - [ ] Verify no errors

- [ ] Test inspector_pattern_examples.yaml
  - [ ] Parse all 3 examples
  - [ ] Validate all
  - [ ] Generate all views
  - [ ] Verify nested components

- [ ] Test complete_ui_example.yaml
  - [ ] Parse full ISO Inspector UI
  - [ ] Validate complex composition
  - [ ] Generate complete layout
  - [ ] Verify all patterns present

- [ ] Test error handling
  - [ ] Invalid YAML syntax
  - [ ] Unknown componentType
  - [ ] Missing required properties
  - [ ] Invalid enum values

- [ ] Round-trip test
  - [ ] Create Badge via AgentDescribable
  - [ ] Convert to YAML
  - [ ] Parse YAML
  - [ ] Validate
  - [ ] Generate view
  - [ ] Compare original and generated

**Test Cases**:

1. Parse + validate + generate badge_examples.yaml
2. Parse + validate + generate inspector_pattern_examples.yaml
3. Parse + validate + generate complete_ui_example.yaml
4. Handle invalid YAML gracefully
5. Round-trip: Badge → YAML → Badge

---

### Step 6: Documentation (30 min)

**Goal**: 100% DocC coverage and usage guide

**Implementation Checklist**:

- [ ] Add DocC comments to YAMLParser
  - [ ] ComponentDescription struct
  - [ ] parse() methods
  - [ ] Error types
  - [ ] Usage examples

- [ ] Add DocC comments to YAMLValidator
  - [ ] ValidationError enum
  - [ ] validate() methods
  - [ ] Schema reference
  - [ ] Error handling examples

- [ ] Add DocC comments to YAMLViewGenerator
  - [ ] GenerationError enum
  - [ ] generateView() methods
  - [ ] Component generators
  - [ ] Integration examples

- [ ] Create usage examples
  - [ ] Simple Badge generation
  - [ ] Complex InspectorPattern
  - [ ] Error handling workflow
  - [ ] Performance considerations

**Documentation Sections**:

1. Overview (what is YAML parser/validator)
2. Quick Start (parse → validate → generate)
3. API Reference (all public methods)
4. Error Handling (ValidationError, GenerationError)
5. Performance (benchmarks, best practices)
6. Examples (badge, card, inspector, full UI)

---

### Step 7: Performance Testing (15 min)

**Goal**: Verify performance targets met

**File**: `Tests/FoundationUITests/PerformanceTests/YAMLPerformanceTests.swift`

**Implementation Checklist**:

- [ ] Parse 100 components performance test
  - [ ] Target: <100ms
  - [ ] Use XCTClockMetric

- [ ] Validate 100 components performance test
  - [ ] Target: <50ms
  - [ ] Use XCTClockMetric

- [ ] Generate 50 views performance test
  - [ ] Target: <200ms
  - [ ] Use XCTClockMetric

- [ ] Memory footprint test
  - [ ] Target: <5MB
  - [ ] Use XCTStorageMetric

**Test Cases**:

1. Parse 100 Badge components (<100ms)
2. Validate 100 Badge components (<50ms)
3. Generate 50 Badge views (<200ms)
4. Memory footprint for 1000 components (<5MB)

---

### Step 8: Quality Assurance (15 min)

**Goal**: Verify all quality gates

**Checklist**:

- [ ] All unit tests pass (45+ tests)
  - [ ] YAMLParserTests: 10 tests
  - [ ] YAMLValidatorTests: 15 tests
  - [ ] YAMLViewGeneratorTests: 10 tests
  - [ ] YAMLIntegrationTests: 5 tests
  - [ ] YAMLPerformanceTests: 4 tests

- [ ] Test coverage ≥80%
  - [ ] Run: `swift test --enable-code-coverage`
  - [ ] Check coverage report

- [ ] SwiftLint 0 violations
  - [ ] Run: `swiftlint`
  - [ ] Fix any violations

- [ ] Zero magic numbers
  - [ ] Code review
  - [ ] All DS tokens used

- [ ] DocC 100% coverage
  - [ ] All public API documented
  - [ ] Usage examples included

- [ ] Performance targets met
  - [ ] All metrics within targets

- [ ] Example YAML files work
  - [ ] badge_examples.yaml ✅
  - [ ] inspector_pattern_examples.yaml ✅
  - [ ] complete_ui_example.yaml ✅

---

### Step 9: Update Documentation (15 min)

**Goal**: Update project documentation

**Checklist**:

- [ ] Update Task Plan
  - [ ] Mark Phase 4.1.4 as complete `[x]`
  - [ ] Update progress: Phase 4.1 4/7 (57.1%)
  - [ ] Update progress: Phase 4 15/18 (83.3%)
  - [ ] Update overall: 79/118 (67.0%)

- [ ] Update next_tasks.md
  - [ ] Move Phase 4.1.4 to completed
  - [ ] Update Phase 4.1 progress
  - [ ] Highlight Phase 4.1.5 as next

- [ ] Create summary document
  - [ ] Phase4.1.4_YAMLParserValidator_Summary.md
  - [ ] Files created
  - [ ] Tests written
  - [ ] Performance results
  - [ ] Next steps

---

### Step 10: Commit & Archive (15 min)

**Goal**: Commit changes and archive task

**Checklist**:

- [ ] Stage files

  ```bash
  git add Package.swift
  git add Sources/FoundationUI/AgentSupport/YAMLParser.swift
  git add Sources/FoundationUI/AgentSupport/YAMLValidator.swift
  git add Sources/FoundationUI/AgentSupport/YAMLViewGenerator.swift
  git add Tests/FoundationUITests/AgentSupportTests/YAML*.swift
  git add DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md
  git add FoundationUI/DOCS/INPROGRESS/
  ```

- [ ] Commit with message

  ```
  Implement YAML Parser/Validator for Agent Support (#4.1.4)

  - Added Yams library dependency (5.0.0+)
  - Created YAMLParser for parsing YAML component definitions
  - Created YAMLValidator for schema validation
  - Created YAMLViewGenerator for SwiftUI view generation
  - 45+ comprehensive unit tests (parser, validator, generator)
  - 5 integration tests with example YAML files
  - 4 performance tests (all targets met)
  - 100% DocC documentation coverage
  - Zero magic numbers (100% DS token usage)
  - Verified with badge_examples.yaml, inspector_pattern_examples.yaml, complete_ui_example.yaml

  Phase 4.1.4 YAML Parser/Validator ✅ Complete
  ```

- [ ] Push to branch

  ```bash
  git push origin claude/foundation-ui-start-setup-011CUxah5Xy5VDCcm9ityRmX
  ```

- [ ] Archive task
  - [ ] Create `TASK_ARCHIVE/47_Phase4.1.4_YAMLParserValidator/`
  - [ ] Move work files to archive
  - [ ] Create archive README

---

## 📊 Progress Tracking

### Time Estimates

| Step | Estimated | Actual |
|------|-----------|--------|
| 1. Setup Dependencies | 15 min | ___ |
| 2. YAMLParser | 45-60 min | ___ |
| 3. YAMLValidator | 45-60 min | ___ |
| 4. YAMLViewGenerator | 45-60 min | ___ |
| 5. Integration Tests | 30 min | ___ |
| 6. Documentation | 30 min | ___ |
| 7. Performance Testing | 15 min | ___ |
| 8. Quality Assurance | 15 min | ___ |
| 9. Update Documentation | 15 min | ___ |
| 10. Commit & Archive | 15 min | ___ |
| **Total** | **2-4 hours** | **___** |

### Checklist Progress

- [ ] Step 1: Setup Dependencies (0/5 tasks)
- [ ] Step 2: YAMLParser (0/23 tasks)
- [ ] Step 3: YAMLValidator (0/20 tasks)
- [ ] Step 4: YAMLViewGenerator (0/18 tasks)
- [ ] Step 5: Integration Tests (0/13 tasks)
- [ ] Step 6: Documentation (0/10 tasks)
- [ ] Step 7: Performance Testing (0/4 tasks)
- [ ] Step 8: Quality Assurance (0/7 tasks)
- [ ] Step 9: Update Documentation (0/4 tasks)
- [ ] Step 10: Commit & Archive (0/3 tasks)

**Total**: 0/107 tasks complete (0%)

---

## 🎯 Success Criteria Review

At completion, verify:

- [x] YAMLValidator.swift created with Yams integration
- [x] YAML parsing functionality for all components and patterns
- [x] Schema validation against ComponentSchema.yaml
- [x] SwiftUI view generation from parsed YAML
- [x] Comprehensive error handling and reporting
- [x] Type safety for all property conversions
- [x] Unit tests for parser (≥20 test cases)
- [x] Unit tests for validator (≥15 test cases)
- [x] Unit tests for view generation (≥10 test cases)
- [x] Integration tests with example YAML files
- [x] Performance tests (parse 100 components in <100ms)
- [x] Error message quality (clear, actionable messages)
- [x] 100% DocC documentation
- [x] Zero magic numbers (100% DS token usage)

---

## 🔗 References

- [Phase 4.1.4 Task Document](Phase4.1.4_YAMLParserValidator.md)
- [ComponentSchema.yaml](../../Sources/FoundationUI/AgentSupport/ComponentSchema.yaml)
- [Example YAML Files](../../Sources/FoundationUI/AgentSupport/Examples/)
- [Yams Documentation](https://github.com/jpsim/Yams)
- [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)

---

**Status**: Ready to Start
**Created**: 2025-11-09
**Estimated Completion**: 2-4 hours from start
