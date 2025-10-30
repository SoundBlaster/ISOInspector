# Bug Report: Duplicate Share Toolbar Button on macOS

## Objective
Eliminate the duplicate Share toolbar button in the macOS ISOInspector app so that a single Share control exposes the full export menu without redundant toolbar items.

## Symptoms
- Two identical Share icons appear on the right side of the macOS toolbar.
- The rightmost button presents a truncated menu compared to the adjacent Share button.
- Creates user confusion and suggests mismatched export capabilities.

## Environment
- Platform: macOS (macOS version unspecified; assume latest supported by ISOInspector).
- Application: ISOInspector desktop build.
- Toolbar configuration likely defined via SwiftUI `ToolbarItem`s within `ToolbarPattern` or the main window scene configuration.

## Reproduction Steps
1. Launch ISOInspector on macOS.
2. Observe the toolbar region in the main window.
3. Note the presence of two Share buttons with identical `square.and.arrow.up` icons but differing menu contents.

## Expected vs. Actual
- **Expected:** A single Share toolbar button exposing all export/share actions (JSON, report exports, etc.).
- **Actual:** Two Share toolbar buttons; one exposes the full menu, the other a reduced subset.

## Open Questions
- Which code path instantiates the second Share button (e.g., default app toolbar vs. FoundationUI pattern)?
- Should any menu items be consolidated or removed as part of the fix?
- Are there platform-conditional toolbar configurations that require a fallback when exports are unavailable?

## Scope and Hypotheses
- **Front of Work:** macOS app UI, specifically the toolbar composition within `ToolbarPattern` and any app scene that integrates it.
- **Likely Code Locations:** `FoundationUI/Sources/FoundationUI/Patterns/ToolbarPattern.swift`, and the macOS scene in `Sources/ISOInspectorApp/*` that composes toolbar items.
- **Existing Tests:** `ToolbarPatternTests` under `FoundationUI/Tests` cover toolbar item composition but may not assert duplicate identifiers.
- **Hypotheses:**
  1. Both the pattern and host scene are injecting a Share item, resulting in duplication.
  2. Platform-specific toolbar variants might re-add Share when the pattern already includes it.
  3. Menu discrepancies stem from different `MenuBuilder` configurations bound to each Share item.

## Diagnostics Plan
- Inspect `ToolbarPattern` to map toolbar groups and confirm whether multiple `share` items are defined for macOS.
- Trace toolbar construction in the macOS app scene to identify additional Share `ToolbarItem`s.
- Validate menu bindings for each Share control to ensure a single menu receives the consolidated actions.
- If necessary, add logging or preview instrumentation to ensure only one Share item is produced.

## TDD Testing Plan
- Add unit coverage that validates the new toolbar policy helper so macOS cannot emit the secondary Share menu while iOS retains it.
- Extend `IntegritySummaryViewTests` to exercise the policy, ensuring the menu only appears when both export handlers are supplied.
- Execute the `ISOInspectorAppTests` target (or focused subset) via `swift test` to ensure the new assertions compile and run.

## PRD Update Summary
- **Customer Impact:** Duplicate Share buttons degrade usability and confidence in export functionality.
- **Acceptance Criteria:** macOS build shows a single Share button providing all export options; automated tests confirm non-duplication.
- **Technical Approach:** Consolidate Share toolbar item definitions, ensuring menu content is composed in one location and reused.
- **Dependencies:** None identified beyond existing export menu builders.

## Notes / Next Steps
- After diagnostics, update this document with findings, chosen implementation changes, and test results.

## Diagnostics Update (2025-10-29)
- Confirmed the duplicate Share buttons originate from both `AppShellView` (global export menu) and `IntegritySummaryView` (integrity-tab-specific menu) defining toolbar Share menus.
- The integrity view’s menu only exposed document-level exports, explaining the truncated menu reported by the user.
- No duplicate share definitions were found in `ToolbarPattern`; the issue is scoped to ISOInspectorApp SwiftUI views.

## Implementation Plan
- Introduce a toolbar policy helper that disables the integrity view toolbar on macOS while preserving it for iOS environments.
- Refactor `IntegritySummaryView` to route toolbar construction through the policy helper so the menu is only emitted when both export handlers are provided.
- Ensure the top-level `AppShellView` retains the consolidated export menu so macOS continues to expose full export functionality through a single Share button.

## Validation Plan
- Extend `IntegritySummaryViewTests` to cover the new toolbar policy, asserting that macOS disables the secondary toolbar and that the policy requires both export actions before surfacing the menu.
- Run the affected `ISOInspectorAppTests` target (or a filtered subset) via `swift test` to verify the new unit tests and guard against regressions.

## Validation Results (2025-10-29)
- Added two new unit tests under `IntegritySummaryViewTests` that pin the toolbar policy behaviour for macOS and iOS-style platforms.
- Attempted to execute `swift test --filter IntegritySummaryViewTests`; on the Linux CI image the AppKit-gated tests are compiled but skipped, resulting in no matching cases being run.
