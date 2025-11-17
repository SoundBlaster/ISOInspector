# Bug Report 237: View Integrity Report Banner Action Does Not Open Report

## Objective
Document the failure of the “View Integrity Report” button on the issues banner when a file has problems so the fix can be scoped later.

## Symptoms
- When a file with issues is selected, a banner appears prompting to view the Integrity Report.
- Clicking “View Integrity Report” does nothing (no navigation, no modal).
- Users must locate the report manually through other menus.

## Environment
- macOS ISOInspector build; occurs when selecting a file containing issues.
- Likely involves the banner component within the Box Tree or Inspector view.

## Reproduction Steps
1. Open a file known to have issues.
2. Observe the banner offering to view the Integrity Report.
3. Click the “View Integrity Report” call to action.
4. Note that the Integrity Report does not open.

## Expected vs. Actual
- **Expected:** Clicking the banner CTA should navigate to the Integrity Report screen or open it in the existing panel.
- **Actual:** No action occurs; banner stays visible but unresponsive.

## Open Questions
- Is the button disabled due to missing binding or because navigation target requires additional state (e.g., selected issue)?
- Should the CTA open a new tab/panel or reuse an existing view stack?
- Are there console errors when clicking the button?

## Scope & Hypotheses
- Front of work: UI action wiring between banner and navigation stack (possibly `NavigationPath` or coordinator).
- Hypothesis: The action is not hooked up to dispatch navigation, or the data passed is nil causing guard fail.
- Need to inspect issue selection models shared between banner and report view.

## Diagnostics Plan
1. Search for the banner view definition and confirm the `Button` action is implemented.
2. Trace the navigation coordinator to ensure the route for Integrity Report is registered.
3. Add logging to confirm the action is fired and whether navigation is blocked downstream (later when coding).

## TDD Testing Plan
- Unit test for the banner view model verifying `viewIntegrityReport()` emits the correct navigation command when issues exist.
- Integration/UI test that simulates clicking the CTA and asserts the Integrity Report screen becomes visible.
- Regression test verifying the CTA remains disabled/hidden when no issues exist.

## PRD Update
- **Customer Impact:** Users cannot quickly inspect the Integrity Report from context, leading to confusion and extra clicks.
- **Acceptance Criteria:** When issues are present, the banner CTA reliably opens the Integrity Report; error handling/logging in place if navigation fails.
- **Technical Approach:** Wire banner action to navigation handler with appropriate state checks.

## Status
Bug recorded and ready for engineering execution once prioritized.
