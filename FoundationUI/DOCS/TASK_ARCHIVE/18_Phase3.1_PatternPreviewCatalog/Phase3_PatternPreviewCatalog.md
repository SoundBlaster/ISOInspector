# Pattern Preview Catalog

## 🎯 Objective
Build a comprehensive SwiftUI preview catalog for all FoundationUI patterns to validate dynamic layouts, accessibility variants, and platform adaptations before wider integration.

## 🧩 Context
- **Phase**: 3.1 – UI Patterns (Organisms)
- **Layer**: 3 – Patterns
- **Priority**: P0
- **Dependencies**:
  - InspectorPattern, SidebarPattern, ToolbarPattern, and BoxTreePattern implementations are complete
  - DS design tokens (Spacing, Colors, Radius, Typography, Animation) are available
  - Pattern unit and integration test suites already exist for baseline behavior

## ✅ Success Criteria
- [ ] Unit tests written and passing
- [ ] Implementation follows DS token usage (zero magic numbers)
- [ ] SwiftUI Preview included
- [ ] DocC documentation complete
- [ ] Accessibility labels added
- [ ] SwiftLint reports 0 violations
- [ ] Platform support verified (iOS/macOS/iPadOS)

## 🔧 Implementation Notes
- Create preview groups that surface light/dark mode, Dynamic Type, and platform-specific layouts as called out in the Task Plan and PRD.
- Reuse existing sample data from pattern tests or helper fixtures to keep previews deterministic.
- Align with `DOCS/AI/ISOViewer/FoundationUI_PRD.md` guidance for inspector, sidebar, toolbar, and tree navigation scenarios.
- Capture screenshots or notes for outstanding macOS/iPadOS verification listed in `next_tasks.md` once runtime access is available.

### Files to Create/Modify
- `Sources/FoundationUI/Patterns/*Pattern.swift` (add nested `Preview` providers or dedicated preview helpers)
- `Sources/FoundationUI/Patterns/Previews/*Pattern+Preview.swift` (if a dedicated previews namespace is preferred)
- `Documentation/` assets referenced by previews and DocC articles

### Design Token Usage
- Spacing: `DS.Spacing.{s|m|l|xl}`
- Colors: `DS.Colors.{infoBG|warnBG|errorBG|successBG}`
- Radius: `DS.Radius.{card|chip|small}`
- Animation: `DS.Animation.{quick|medium}`

## 🧠 Source References
- [FoundationUI Task Plan §3.1](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
- [FoundationUI PRD §Layer 3 Patterns](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

## 📋 Checklist
- [ ] Read task requirements from Task Plan
- [ ] Create test file and write failing tests
- [ ] Run `swift test` to confirm failure
- [ ] Implement minimal code using DS tokens
- [ ] Run `swift test` to confirm pass
- [ ] Add SwiftUI Preview
- [ ] Add DocC comments
- [ ] Run `swiftlint` (0 violations)
- [ ] Test on iOS simulator
- [ ] Test on macOS
- [ ] Update Task Plan with [x] completion mark
- [ ] Commit with descriptive message
