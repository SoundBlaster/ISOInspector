# Phase 2 – Indicator Component Test Suite

## 📍 Status
- **Phase:** 2.2 Layer 2 – Essential Components
- **Task:** Author comprehensive tests for the Indicator component (pre-implementation)
- **Priority:** P0
- **Owner:** Automation Agent (FoundationUI)
- **Start Date:** 2025-11-12

## 🎯 Objective
Establish a failing test suite that codifies the full Indicator component requirements before implementation, covering behavior, accessibility, visual appearance, and performance guardrails.

## 🔗 Dependencies
- ✅ Phase 1 design tokens (Spacing, Colors, Radius, Animation)
- ✅ BadgeLevel semantics (info, warning, error, success)
- ✅ BadgeChipStyle modifier for color usage
- ✅ Copyable infrastructure (`CopyableText`, `.copyable` modifier)
- ✅ SnapshotTesting + AccessibilitySnapshot frameworks in test target

## ✅ Selection Rationale
- Phase 2 remains incomplete until the Indicator component ships; lower phases must close before advancing.
- Indicator is the only remaining **P0** task in the layer hierarchy.
- Writing tests first satisfies the TDD workflow and de-risks later implementation.
- Manual priority list (`next_tasks.md`) highlights the Indicator component as the top target.

## 🧪 Test Coverage Plan
1. **Unit Tests** (`IndicatorTests.swift`)
   - Validate size variants (`mini`, `small`, `medium`) map to DS.Spacing without magic numbers.
   - Confirm BadgeLevel colors are forwarded to fill/outline styles.
   - Ensure `.copyable` integration emits feedback on success and honors `showFeedback` flag.
2. **Snapshot Tests** (`IndicatorSnapshotTests.swift`)
   - Light/Dark mode snapshots across all BadgeLevel × size combinations.
   - Right-to-left layout and high-contrast mode coverage.
3. **Accessibility Tests** (`IndicatorAccessibilityTests.swift`)
   - VoiceOver label/hint verification derived from BadgeLevel.
   - Hit target sizing ≥44×44 pt and Reduce Motion compliance.
4. **Performance Tests** (`IndicatorPerformanceTests.swift`)
   - Render time budget: ≤1ms average for 100 render iterations.
   - Memory footprint baseline assertions.

## 📋 Next Steps
1. Scaffold new test files under `Tests/FoundationUITests/ComponentsTests/` following existing naming conventions.
2. Implement failing assertions capturing the requirements above.
3. Update test manifests if necessary (LinuxMain / XCTMain not required with XCTest on SwiftPM 5.9+).
4. Run `swift test` to confirm failures prior to implementation work.
5. After tests fail as expected, proceed with the Indicator implementation task via the START workflow.

## 📝 Reporting
- Update `FoundationUI_TaskPlan.md` with "IN PROGRESS" status ✅
- Remove Indicator from `next_tasks.md` backlog once implementation begins.
- Link resulting PRs to Phase 2 Indicator milestone.
