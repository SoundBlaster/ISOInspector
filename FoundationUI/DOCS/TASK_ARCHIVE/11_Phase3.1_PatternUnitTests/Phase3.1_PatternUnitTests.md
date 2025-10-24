# Phase 3.1 – Pattern Unit Tests (IN PROGRESS)

## 🎯 Objective
Establish comprehensive unit test coverage for FoundationUI patterns to unblock implementation work for SidebarPattern, ToolbarPattern, and BoxTreePattern while reinforcing InspectorPattern regression protection.

## ✅ Dependencies Verified
- **Layer 0–2 foundations available**: Design tokens, modifiers, and core components are implemented in `FoundationUI/Sources/FoundationUI`.
- **Existing pattern baseline**: `InspectorPattern.swift` provides reference APIs and behavior for composing inspector layouts.
- **Testing infrastructure ready**: `Tests/FoundationUITests/PatternsTests/` already hosts InspectorPattern tests and shared XCTest utilities.

## 🔬 Test-First Plan
1. Define XCTest cases for Sidebar, Toolbar, and BoxTree patterns capturing layout state, DS token usage, and accessibility expectations.
   - ✅ Sidebar selection binding and detail builder coverage landed in `Tests/FoundationUITests/PatternsTests/SidebarPatternTests.swift` (2025-10-24)
2. Expand InspectorPattern tests where gaps exist for regression coverage (e.g., material overrides, dynamic content sizing).
3. Introduce reusable test fixtures to simulate representative ISO inspector data sets shared across pattern suites.
4. Ensure new tests fail prior to implementation, validating TDD workflow adherence.

## 📦 Deliverables
- New or expanded test files under `Tests/FoundationUITests/PatternsTests/`.
- Shared fixtures/utilities under `Tests/FoundationUITests/Support/` if additional data builders are required.
- Updated documentation in Task Plan once tests pass and implementations are ready to begin.

## 🔁 Next Steps
1. Audit existing InspectorPattern tests for coverage gaps and document required additions.
2. Draft SidebarPattern unit tests detailing navigation state handling prior to implementation work. ✅ Completed 2025-10-24; next focus: ToolbarPattern coverage.
3. Coordinate with integration and preview tasks to ensure assertions align with forthcoming UI behavior.

## 🔗 References
- [FoundationUI Task Plan – Phase 3.1 Layer 3: UI Patterns](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#31-layer-3-ui-patterns-organisms)
- [FoundationUI PRD – Patterns Requirements](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [FoundationUI Test Plan – Pattern Coverage](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md)
