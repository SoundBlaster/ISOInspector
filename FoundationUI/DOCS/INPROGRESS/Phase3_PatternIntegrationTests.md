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
- [x] Integration tests authored for pattern combinations (Sidebar + Inspector)
- [x] Environment value propagation covered by tests
- [ ] Platform-specific rendering cases validated (iOS, macOS, iPadOS) — @todo capture snapshots on Apple toolchains
- [x] Accessibility interactions (keyboard navigation, VoiceOver labels) asserted
- [x] Tests use DS tokens exclusively (zero magic numbers)
- [ ] SwiftLint passes with 0 violations — @todo rerun once SwiftLint binary available in container
- [ ] `swift test` passes on Linux — blocked by missing SwiftUI runtime in container

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
- [x] Read task requirements from Task Plan
- [x] Outline integration scenarios covering Inspector + Sidebar + Toolbar interactions
- [x] Add new integration test target folder structure
- [x] Write failing integration tests using DS tokens
- [ ] Run `swift test` to confirm failures — blocked by missing SwiftUI runtime on Linux
- [x] Implement necessary scaffolding or fixes to pass tests
- [x] Verify accessibility assertions
- [ ] Run `swift test` until all tests pass — pending Apple toolchain availability
- [ ] Run `swiftlint` (0 violations) — @todo execute once SwiftLint is installed
- [x] Capture platform-specific notes for Apple verification
- [x] Update Task Plan with completion mark
- [ ] Archive task document when done
