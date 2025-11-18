# Bug Report 239: Missing Hex Preview for Selected Box

## Objective
Record the defect where selecting a box does not display its hex preview so the feature gap can be addressed later.

## Symptoms
- When a box is selected, the UI should show a hex dump/preview of its data.
- Currently, no hex preview is rendered (panel blank or placeholder text).
- Users cannot inspect raw bytes without leaving ISOInspector.

## Environment
- Box Details or Hex Preview panel within ISOInspector on macOS.
- Occurs consistently for selected boxes.

## Reproduction Steps
1. Open a file and select a box in the Box Tree.
2. Attempt to view the hex preview pane.
3. Observe that no hex data is shown.

## Expected vs. Actual
- **Expected:** Selecting a box populates the hex preview pane with bytes corresponding to that box.
- **Actual:** Pane stays empty or shows “No preview”.

## Open Questions
- Is the hex preview feature fully implemented or temporarily disabled?
- Does the selected box have available byte ranges to display?
- Are there performance considerations (lazy loading) interfering with rendering?

## Scope & Hypotheses
- Front of work: Data pipeline from Box selection to hex renderer component.
- Hypothesis: Binding to the selected box’s byte buffer is nil or not triggered; may be due to missing asynchronous fetch.
- Might require verifying that `HexViewer` receives data and handles large payloads.

## Diagnostics Plan
1. Inspect the selection view model to ensure it exposes byte range data.
2. Check whether the hex preview view subscribes to selection changes.
3. Validate that the data source loads bytes for the selected box (maybe via caching or streaming).

## TDD Testing Plan
- Unit test verifying the view model publishes hex data when a box is selected.
- UI/snapshot test ensuring the hex pane renders non-empty content for boxes with data and handles empty state gracefully.
- Performance/regression test for large boxes to ensure preview still loads.

## PRD Update
- **Customer Impact:** Users cannot inspect raw data, limiting debugging and verification workflows.
- **Acceptance Criteria:** Selecting any box with byte data displays a hex preview; empty state shown only when no bytes exist.
- **Technical Approach:** Ensure selection triggers data load and hex view renders it, possibly adding caching/buffering.

## Status
Documented for future implementation; no fixes performed now.
