# Phase 3.1: ToolbarPattern Implementation

## 🎯 Objective
Design and implement the FoundationUI `ToolbarPattern`, a platform-adaptive toolbar that aligns action controls with ISO Inspector workflows while honoring DS tokens and accessibility rules.

## 🧩 Context
- **Phase**: 3.1 – UI Patterns (Organisms)
- **Layer**: 3 (Patterns)
- **Priority**: P1 (High)
- **Status**: ✅ Completed (2025-10-24, snapshot tests pending Apple toolchain)
- **Related Documents**:
  - [FoundationUI Task Plan](../AI/ISOViewer/FoundationUI_TaskPlan.md)
  - [FoundationUI PRD](../AI/ISOViewer/FoundationUI_PRD.md)
  - [`next_tasks.md`](./next_tasks.md)

## ✅ Dependency Check
- ✅ Layer 0 Design Tokens implemented (`Sources/FoundationUI/DesignTokens/`)
- ✅ Layer 1 View Modifiers ready (`Sources/FoundationUI/Modifiers/`)
- ✅ Layer 2 Core Components available (`Sources/FoundationUI/Components/`)
- ✅ Pattern unit test scaffolding prepared (`Tests/FoundationUITests/PatternsTests/`)
- ⚠️ Pattern integration tests pending (blocked until ToolbarPattern + BoxTreePattern exist)

## 🧠 Problem Statement
ToolbarPattern must expose a unified toolbar abstraction that can:
- Present icon + label controls with SF Symbols alignment.
- Adapt layout between compact (iOS) and expanded (macOS/iPadOS) idioms.
- Surface keyboard shortcut metadata for power users.
- Maintain zero-magic-number compliance by consuming DS tokens exclusively.
- Remain fully accessible (VoiceOver labels, hints, size, Dynamic Type, reduced motion).

## 📋 Requirements & Acceptance Criteria
- [x] API surface documented with DocC, including usage examples and customization guidance.
- [x] Supports declarative item configuration (primary, secondary, overflow) with adaptive layout rules.
- [x] Keyboard shortcut metadata surfaced via accessibility labels and optional overlay badge.
- [x] Honors DS spacing/typography tokens for item padding, spacing, and sizing.
- [x] Provides platform-conditional presentation (segmented control style on macOS, compact toolbar on iOS, adaptive grid on iPadOS large).
- [x] Includes VoiceOver labels, hints, and rotor ordering for toolbar items.
- [x] Offers previews covering icon-only, icon+label, and overflow scenarios across platforms.
- [ ] Ships with unit tests (existing scaffolding extended) plus targeted snapshot/interaction tests where feasible. *(Snapshot capture blocked by missing SwiftUI runtime in container)*
- [x] Integrates with future Pattern integration tests without additional API churn.

## 🔬 Test-First Plan
1. Extend `ToolbarPatternTests` to capture keyboard shortcut exposure, adaptive layout metrics, and accessibility traits before writing production code.
2. Add placeholder integration coverage (skipped or pending) outlining expected interactions with SidebarPattern/InspectorPattern, to be activated post-implementation.
3. Run `swift test` to validate failing state prior to implementation.

## 🛠️ Implementation Outline
1. Define `ToolbarPattern` structure under `Sources/FoundationUI/Patterns/ToolbarPattern.swift` with configurable item model.
2. Implement adaptive layout helpers leveraging DS tokens and platform checks.
3. Wire keyboard shortcut metadata to accessibility modifiers and optional tooltips.
4. Update previews and README sections to reflect new pattern usage.
5. Ensure zero SwiftLint violations and update coverage metrics.

## ⚠️ Risks & Mitigations
- **Platform divergence**: Start with shared item model; add conditional groups per platform to avoid duplication.
- **Accessibility regressions**: Leverage AccessibilitySnapshot once available; maintain manual VoiceOver checks in interim.
- **Performance with large button counts**: Profile repeated toolbar items using Instruments after implementation.

## 📦 Deliverables
- `Sources/FoundationUI/Patterns/ToolbarPattern.swift`
- `Tests/FoundationUITests/PatternsTests/ToolbarPatternTests.swift`
- Preview entries + README updates showcasing toolbar variants.
- Updated Task Plan + coverage metrics once code lands.

## 🔜 Next Steps
1. Create/extend `ToolbarPatternTests` with failing assertions (keyboard shortcut metadata, layout options, accessibility traits).
2. Draft toolbar item model and layout logic.
3. Implement SwiftUI view and modifiers.
4. Produce previews/documentation.
5. Run full `swift test` + linting.
6. Coordinate with Pattern integration tests once BoxTreePattern task begins.
