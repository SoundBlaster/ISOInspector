# Bug Report 238: VIR Issue Selection Does Not Scroll Box Tree to Target Box

## Objective
Document the navigation bug where selecting an issue in the View Integrity Report (VIR) screen fails to scroll the Box Tree to the corresponding box when transitioning.

## Symptoms
- In the VIR screen, clicking an issue is supposed to focus the associated box in the Box Tree.
- After navigating to the Box Tree, the tree does not scroll; users must manually search for the box.
- This slows down issue triage and makes cross-linking unreliable.

## Environment
- ISOInspector VIR UI and Box Tree view on macOS.
- Likely involves shared navigation coordinator and scroll-to-item support.

## Reproduction Steps
1. Open a file with issues and view the Integrity Report.
2. Click an issue that should point to a box.
3. Observe transition to Box Tree.
4. Notice the tree remains at its previous scroll position instead of focusing on the box referenced by the issue.

## Expected vs. Actual
- **Expected:** After selecting an issue and landing on the Box Tree, the tree scrolls to and selects/highlights the relevant box.
- **Actual:** The tree remains in its previous state; user must manually locate the box.

## Open Questions
- Does the box ID get passed correctly from VIR to the Box Tree route?
- Is there an async timing issue where the scroll command fires before the tree is rendered?
- Should we animate the scroll or simply jump to the item?

## Scope & Hypotheses
- Front of work: Navigation linking from VIR issues to Box Tree view, plus tree scroll controller.
- Hypothesis: Missing scroll-to-ID call when the Box Tree appears, or the tree virtualization lacks API to programmatically scroll.
- May need to persist pending scroll target until the tree is ready.

## Diagnostics Plan
1. Trace the code path when an issue row is tapped to ensure the box ID is stored.
2. Inspect Box Tree view for existing `scrollTo` or focus APIs; determine why they are not triggered.
3. Log lifecycle events to ensure the scroll call would happen after data loads (during future implementation).

## TDD Testing Plan
- Unit test for the navigation coordinator ensuring it enqueues a scroll target when transitioning from VIR to Box Tree.
- UI test verifying the tree scroll position changes and the expected node becomes visible after selecting an issue.
- Regression test ensuring behavior is unchanged when navigating without an issue context.

## PRD Update
- **Customer Impact:** Issue triage is inefficient; users may miss problem boxes.
- **Acceptance Criteria:** Selecting an issue highlights and scrolls to the associated box automatically with minimal delay.
- **Technical Approach:** Pass issue’s box ID through navigation, trigger scroll once Box Tree mounts, handle nil gracefully.

## Status
Prepared for engineering handoff; no code changes performed per instructions.
