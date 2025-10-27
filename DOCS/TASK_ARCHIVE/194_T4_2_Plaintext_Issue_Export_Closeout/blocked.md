# Blocked Tasks Log

The following efforts cannot proceed until their upstream dependencies are resolved. Update this log whenever blockers change to maintain day-to-day visibility.

## VoiceOver Regression Pass for Accessibility Shortcuts
- **Blocking issue:** Required macOS and iPadOS hardware is not yet available for VoiceOver verification.
- **Next step once unblocked:** Run the regression checklist to confirm focus command menus announce controls and restore focus targets, referencing archived context in `DOCS/TASK_ARCHIVE/156_G8_VoiceOver_Regression_Pass_for_Accessibility_Shortcuts/`.

## Real-World Assets Acquisition
- **Blocking issue:** Licensing approvals for Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures are still pending.
- **Next step once unblocked:** Import the licensed assets and refresh regression baselines so tolerant parsing and export scenarios can validate against real-world payloads.
- **Notes:** Review the permanent blockers stored under [`DOCS/TASK_ARCHIVE/BLOCKED`](../TASK_ARCHIVE/BLOCKED) to avoid duplicating retired work.
