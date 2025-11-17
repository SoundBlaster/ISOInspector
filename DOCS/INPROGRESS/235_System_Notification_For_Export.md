# Bug Report 235: System Notification Option for Successful Export

## Objective
Capture the requirement to replace the current modal alert for successful export with a system notification (while keeping the alert as a fallback) so that engineers can scope the change before implementation.

## Symptoms
- After exporting data, ISOInspector shows a blocking alert that the export succeeded.
- Users want a less intrusive confirmation that leverages macOS notification APIs.
- There is no preference to opt into the modern notification pathway or handle denied permissions.

## Environment
- ISOInspector macOS build.
- Export workflow (likely in `ExportController` or similar) and the preferences/settings module.

## Reproduction Steps
1. Perform an export action (e.g., export Integrity Report or Box data).
2. Wait for the success confirmation.
3. Observe that only an alert dialog is presented and no notification is attempted.

## Expected vs. Actual
- **Expected:** When notifications are allowed, ISOInspector posts a system notification indicating success. If notifications are disallowed or the user toggles off notifications in app settings, the legacy alert is used instead.
- **Actual:** Only the alert dialog is available, making the workflow blocking and dated.

## Open Questions
- Should we request notification permission proactively or lazily after first export?
- Where should the preference live (global settings vs. per-export)?
- Do we need to log failures when notifications are denied so we can fallback cleanly?

## Scope & Hypotheses
- Front of work: Export success handler, preferences UI, and notification permission utilities.
- Likely touches `UserDefaults` keys for settings and `UNUserNotificationCenter` integration.
- Might require new localization strings for the preference label and fallback messaging.

## Diagnostics Plan
1. Inspect export completion flow to identify where the success alert is presented.
2. Confirm whether there is any existing notification helper in the codebase we can reuse.
3. Prototype a permission check path that will later map to tests.

## TDD Testing Plan
- Unit tests for a notification presenter that ensures fallback to alert when permissions/preferences are off.
- UI test verifying the settings toggle persists and changes the export confirmation behavior.
- Integration test stub for ensuring notification requests occur once and handle user denial gracefully.

## PRD Update
- **Customer Impact:** Streamlines export workflow by reducing interruptions and aligns with modern macOS UX while retaining compatibility for users who prefer alerts.
- **Acceptance Criteria:** App posts a system notification on successful export when allowed; preference toggle available; fallback alert remains functional when notifications are disabled or unavailable.
- **Technical Approach:** Add notification permission management, extend settings, and conditionally route completion flow to notification vs. alert.

## Status
Documentation complete; implementation pending per BUG workflow.
