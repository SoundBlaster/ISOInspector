# Create Pattern Integration Tests

## 🎯 Objective
Author the integration test suite covering composition flows between existing FoundationUI patterns, ensuring cross-pattern interactions behave correctly across platforms.

## 🧩 Context
- **Phase**: 3 – Patterns & Platform Adaptation
- **Layer**: 3 – UI Patterns (Organisms)
- **Priority**: P0
- **Dependencies**:
  - InspectorPattern implementation (`Sources/FoundationUI/Patterns/InspectorPattern.swift`)
  - SidebarPattern implementation (`Sources/FoundationUI/Patterns/SidebarPattern.swift`)
  - ToolbarPattern implementation (`Sources/FoundationUI/Patterns/ToolbarPattern.swift`)
  - Pattern unit test infrastructure (`Tests/FoundationUITests/PatternsTests/`)

## ✅ Success Criteria
- [ ] Integration tests authored for pattern combinations (Sidebar + Inspector)
- [ ] Environment value propagation covered by tests
- [ ] Platform-specific rendering cases validated (iOS, macOS, iPadOS)
- [ ] Accessibility interactions (keyboard navigation, VoiceOver labels) asserted
- [ ] Tests use DS tokens exclusively (zero magic numbers)
- [ ] SwiftLint passes with 0 violations
- [ ] `swift test` passes on Linux

## 🔧 Implementation Notes
- Focus on verifying how patterns coordinate shared state (selection, inspector content, toolbar actions).
- Reuse existing pattern preview fixtures where possible to avoid duplication.
- Incorporate async test utilities for state propagation timing.

### Files to Create/Modify
- `Tests/FoundationUITests/PatternsIntegrationTests/PatternIntegrationTests.swift`
- `Tests/FoundationUITests/PatternsIntegrationTests/Fixtures/`

### Design Token Usage
- Spacing: `DS.Spacing.{s|m|l|xl}`
- Colors: `DS.Colors.{infoBG|warnBG|errorBG|successBG}`
- Radius: `DS.Radius.{card|chip|small}`
- Animation: `DS.Animation.{quick|medium}`

## 🧠 Source References
- [FoundationUI Task Plan § 3.1 Layer 3: UI Patterns](../AI/ISOViewer/FoundationUI_TaskPlan.md#31-layer-3-ui-patterns-organisms)
- [FoundationUI PRD § 3.1 Patterns](../AI/ISOViewer/FoundationUI_PRD.md#patterns)
- [FoundationUI Test Plan § Integration Tests](../AI/ISOViewer/FoundationUI_TestPlan.md#integration-tests)

## 📋 Checklist
- [ ] Read task requirements from Task Plan
- [ ] Outline integration scenarios covering Inspector + Sidebar + Toolbar interactions
- [ ] Add new integration test target folder structure
- [ ] Write failing integration tests using DS tokens
- [ ] Run `swift test` to confirm failures
- [ ] Implement necessary scaffolding or fixes to pass tests
- [ ] Verify accessibility assertions
- [ ] Run `swift test` until all tests pass
- [ ] Run `swiftlint` (0 violations)
- [ ] Capture platform-specific notes for Apple verification
- [ ] Update Task Plan with completion mark
- [ ] Archive task document when done
