# Accessibility Contrast Flag Validation

## Objective
Validate and, if necessary, correct the `AccessibilityContext` contrast detection logic so that FoundationUI honours the platform "Increase Contrast" preference.

## Symptoms
- Reported mismatch between the `prefersIncreasedContrast` helper and the actual accessibility preference.
- Helper allegedly consults `accessibilityDifferentiateWithoutColor`, causing users with only "Increase Contrast" enabled to be treated as if contrast is unchanged.

## Environment
- Module: `FoundationUI`
- File: `Sources/FoundationUI/Contexts/AccessibilityContext.swift`
- Reported lines: 161-164 (environment-derived helper logic)
- Platforms: iOS / macOS accessibility settings

## Reproduction Steps
1. Enable "Increase Contrast" on iOS or macOS.
2. Leave "Differentiate Without Color" disabled.
3. Query `accessibilityContext.prefersIncreasedContrast` within a FoundationUI-powered view hierarchy.

## Expected vs. Actual
- **Expected:** `prefersIncreasedContrast` returns `true` when "Increase Contrast" is enabled regardless of the "Differentiate Without Color" setting.
- **Actual (reported):** Returns `false` unless "Differentiate Without Color" is also enabled.

## Open Questions
- Does the current implementation derive contrast from `accessibilityDifferentiateWithoutColor` or some other proxy?
- Are there platform availability constraints around using `EnvironmentValues.accessibilityContrast` directly?
- How can this behaviour be reproduced or simulated within existing Linux-based CI where SwiftUI types may be unavailable?

## Scope & Hypotheses
- **Front of work:** Accessibility environment aggregation in `AccessibilityContext`.
- **Likely touchpoints:**
  - `AccessibilityContext` environment accessor in `FoundationUI/Sources/FoundationUI/Contexts/AccessibilityContext.swift`.
  - Unit tests in `FoundationUI/Tests/FoundationUITests/ContextsTests/AccessibilityContextTests.swift`.
- **Hypothesis A:** The helper still references `accessibilityDifferentiateWithoutColor` (directly or via a wrapper) and should use `accessibilityContrast == .increased` instead.
- **Hypothesis B:** If the helper already uses `UIAccessibility.isDarkerSystemColorsEnabled`, we must confirm whether this maps to the correct flag across platforms.

## Diagnostics Plan
- Inspect the implementation around lines 160-200 of `AccessibilityContext.swift` to confirm which environment flag is used.
- Trace any wrappers (e.g., `baselinePrefersIncreasedContrast`) to identify platform-specific behaviour.
- Determine whether the SwiftUI environment already exposes `accessibilityContrast` for use without importing UIKit/AppKit.

## TDD Testing Plan
- Add a new unit test that simulates an environment with `accessibilityContrast = .increased` while `accessibilityDifferentiateWithoutColor` remains `false`, verifying that `prefersIncreasedContrast` evaluates to `true`.
- If direct simulation is infeasible on Linux, guard the test with `#if canImport(SwiftUI)` and rely on macOS/iOS execution while ensuring compilation succeeds via availability checks.
- Ensure existing tests still pass to prevent regressions.

## PRD Update Summary
- Customer impact: High-contrast users currently do not receive enhanced spacing/styling, reducing accessibility compliance.
- Acceptance criteria:
  - Contrast detection aligns with the "Increase Contrast" preference.
  - Automated tests cover the scenario where contrast and differentiate flags diverge.
- Technical approach: Switch the detection logic to consult `AccessibilityContrast` when available, falling back to legacy APIs for older platforms.

## Findings & Resolution
- Confirmed the environment accessor was only using `baselinePrefersIncreasedContrast`, which did not consider the SwiftUI `AccessibilityContrast` flag before deferring to platform APIs.
- Updated `baselinePrefersIncreasedContrast` to prioritise `EnvironmentValues.accessibilityContrast == .increased`, ensuring "Increase Contrast" is recognised even when "Differentiate Without Color" is disabled.
- Added a guarded unit test (`testEnvironmentValues_RespectsAccessibilityContrast`) to exercise the scenario on Apple platforms while skipping unsupported targets.
- Full `swift test` suite executed on Linux to verify no regressions.

