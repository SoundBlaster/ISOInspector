# Phase 4.1.3: Create YAML Schema Definitions

## 🎯 Objective

Define comprehensive YAML schema files for all FoundationUI components and patterns, enabling AI agents to programmatically generate SwiftUI views from declarative YAML configuration. This schema will serve as the contract between agents and FoundationUI for type-safe component instantiation.

## 🧩 Context

- **Phase**: Phase 4: Agent Support & Polish
- **Section**: 4.1 Agent-Driven UI Generation
- **Layer**: Agent Support Infrastructure
- **Priority**: P1 (Natural progression after AgentDescribable protocol)
- **Dependencies**:
  - ✅ Phase 4.1.1: AgentDescribable protocol (completed 2025-11-08)
  - ✅ Phase 4.1.2: AgentDescribable conformance for all components (completed 2025-11-09)

## ✅ Success Criteria

- [ ] YAML schema file created with all component definitions
- [ ] All Layer 2 components documented (Badge, Card, KeyValueRow, SectionHeader)
- [ ] All Layer 3 patterns documented (InspectorPattern, SidebarPattern, ToolbarPattern, BoxTreePattern)
- [ ] Schema validation rules defined (type constraints, enums, required properties)
- [ ] Example YAML configurations for each component/pattern
- [ ] Documentation with schema structure and usage guidelines
- [ ] Schema validation tested with example files
- [ ] Zero magic numbers (all references to DS tokens)
- [ ] 100% schema completeness (all AgentDescribable properties included)

## 🔧 Implementation Notes

### Schema Structure

The YAML schema should follow this structure:

```yaml
# Components Schema
components:
  Badge:
    description: "Semantic status badge with configurable level"
    properties:
      text:
        type: string
        required: true
        description: "Badge text content"
      level:
        type: enum
        enum: ["info", "warning", "error", "success"]
        required: true
        description: "Semantic level affecting colors and icons"
      showIcon:
        type: boolean
        required: false
        default: true
        description: "Whether to display status icon"
    example: |
      - type: Badge
        text: "In Progress"
        level: info
        showIcon: true

  Card:
    description: "Elevated container with configurable styling"
    properties:
      elevation:
        type: enum
        enum: ["none", "low", "medium", "high"]
        required: false
        default: "medium"
      material:
        type: enum
        enum: ["thin", "regular", "thick", "ultraThin", "ultraThick"]
        required: false
        default: "regular"
      cornerRadius:
        type: number
        required: false
        description: "Corner radius in points (use DS.Radius values)"
    example: |
      - type: Card
        elevation: medium
        material: regular
        content:
          - type: Badge
            text: "Nested content"
            level: success

  # KeyValueRow, SectionHeader, etc.

# Patterns Schema
patterns:
  InspectorPattern:
    description: "Scrollable inspector layout with fixed header"
    properties:
      title:
        type: string
        required: true
      sections:
        type: array
        required: true
        items:
          type: object
          properties:
            header:
              type: string
            rows:
              type: array

  # SidebarPattern, ToolbarPattern, BoxTreePattern, etc.
```

### Files to Create/Modify

- `Sources/FoundationUI/AgentSupport/ComponentSchema.yaml` (NEW)
  - Master schema file with all component and pattern definitions
  - Validation rules and constraints
  - Examples for each component/pattern

### Design Token References in Schema

All property values should reference DS tokens:
- Spacing: `DS.Spacing.{s|m|l|xl}` (8, 12, 16, 24 points)
- Radius: `DS.Radius.{small|medium|card|chip}` (6, 8, 10, 999)
- Colors: `DS.Colors.{infoBG|warnBG|errorBG|successBG}` (semantic)
- Animation: `DS.Animation.{quick|medium|slow}` (0.15s, 0.25s, 0.35s)

### Schema Validation Rules

1. **Type Safety**
   - All string properties have max length
   - Numeric properties have min/max bounds
   - Enum properties list all valid values

2. **Required Properties**
   - Mark essential properties (text, title, level) as required
   - Document defaults for optional properties

3. **Composition Rules**
   - Components can nest inside Cards
   - Patterns can contain Components
   - Circular references prevented (e.g., Card cannot directly contain another Card at root)

4. **Platform-Specific Properties**
   - Document iOS vs macOS differences
   - Note platform-specific constraints

### Examples to Include

For each component/pattern, provide 2-3 example YAML files:

1. **Badge Examples**
   - Simple info badge
   - Warning badge with icon
   - Success badge in a Card

2. **Card Examples**
   - Basic card with elevation
   - Card with multiple badges
   - Nested Card structure

3. **KeyValueRow Examples**
   - Horizontal layout
   - Vertical layout with copyable text
   - Multiple rows in a section

4. **InspectorPattern Example**
   - Multi-section inspector
   - With cards and badges
   - Real ISO Inspector scenario

## 🧠 Source References

- [FoundationUI Task Plan § 4.1 Agent-Driven UI Generation](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
- [FoundationUI PRD § Agent Support](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [AgentDescribable Protocol](../../TASK_ARCHIVE/45_Phase4.1_AgentDescribable/)
- [AgentDescribable Components](../../TASK_ARCHIVE/46_Phase4.1.2_AgentDescribableComponents/)

## 📋 Checklist

- [ ] Read AgentDescribable protocol and conformance implementations
- [ ] Extract all properties from AgentDescribable conformances
- [ ] Design YAML schema structure (components, patterns sections)
- [ ] Document all component properties with types and constraints
- [ ] Document all pattern properties with types and constraints
- [ ] Create example YAML files for each component/pattern
- [ ] Write validation rules section in schema
- [ ] Document design token references (DS.Spacing, DS.Colors, etc.)
- [ ] Add platform-specific notes for iOS/macOS differences
- [ ] Create usage guide for agents generating YAML
- [ ] Test schema with provided example files
- [ ] Add SwiftUI Previews showing YAML → SwiftUI rendering (optional)
- [ ] Update Task Plan with [x] completion mark
- [ ] Commit with descriptive message

## 📝 Next Steps

After completing YAML schema definitions:
1. Phase 4.1.4: Implement YAML parser/validator (2-4 hours)
   - Parse YAML files into FoundationUI components
   - Validate against schema
   - Generate SwiftUI views from parsed YAML
   - Error handling and reporting

2. Phase 4.1.5: Create agent integration examples (2-3 hours)
   - Example YAML definitions
   - Agent integration guide
   - Best practices documentation

## 🔄 Integration with Workflow

After completing this task:
- Use the ARCHIVE command to move to task archive
- Update Task Plan: `4.1.3 [ ] Create YAML schema definitions → [x]`
- Proceed to Phase 4.1.4: Implement YAML parser/validator

---

**Status**: ⏳ IN PROGRESS (Created 2025-11-09)
**Estimated Effort**: 2-3 hours
**Last Updated**: 2025-11-09
