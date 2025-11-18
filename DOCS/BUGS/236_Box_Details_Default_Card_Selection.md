# Bug Report 236: Remove Default Selection in Box Details Cards

## Objective
Describe the unwanted default selection state on the first card in Box Details so work can proceed to adjust the UI state machine without code changes yet.

## Symptoms
- Opening Box Details automatically highlights/selects the first card even before the user interacts with the panel.
- The visual highlight may mislead users into thinking that card has focus or an active detail view.
- Some keyboard shortcuts might act on the preselected card unexpectedly.

## Environment
- ISOInspector Box Details view (likely SwiftUI or AppKit hybrid) on macOS.
- Occurs when navigating to Box Details from Box Tree or Integrity Report.

## Reproduction Steps
1. Open a file and navigate to Box Details.
2. Observe the cards list/grid.
3. Note that the first card is already selected.

## Expected vs. Actual
- **Expected:** No card is selected until the user clicks or navigates explicitly.
- **Actual:** First card is automatically selected/highlighted.

## Open Questions
- Is there any workflow relying on an initial selection for focus management or inspector detail binding?
- Should keyboard focus stay on the card container or fallback to a neutral element?

## Scope & Hypotheses
- Front of work: Box Details view state, likely `@State` or `SelectionManager` controlling the cards.
- Hypothesis: `selection` binding is initialized with the first element’s ID instead of `nil`.
- Need to ensure other components (details pane) handle a nil selection gracefully.

## Diagnostics Plan
1. Search for `BoxDetails` view implementations and inspect how `selection` is initialized.
2. Confirm whether the details pane is showing data for the first card even before user interaction.
3. Evaluate how selection state is persisted when navigating away and back.

## TDD Testing Plan
- View-model level tests ensuring `selectedCardID` defaults to `nil` until user interaction.
- UI test verifying no card has the selected styling upon initial render.
- Regression test ensuring selection occurs when user clicks a card and that keyboard navigation still works.

## PRD Update
- **Customer Impact:** Removes misleading highlight and prevents accidental actions on unintentional selections.
- **Acceptance Criteria:** Opening Box Details should show unselected cards; selection occurs only after explicit action; no regressions on keyboard navigation or inspector updates.
- **Technical Approach:** Initialize selection state to nil, update dependent bindings to handle empty selection.

## Status
Awaiting engineering execution; documentation satisfies BUG workflow preconditions.
