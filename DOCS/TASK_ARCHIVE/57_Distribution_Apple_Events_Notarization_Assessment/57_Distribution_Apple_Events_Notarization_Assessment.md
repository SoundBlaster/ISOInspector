# Distribution: Apple Events Automation — Assessment (Outcome)

## Summary
We assessed whether ISOInspector’s notarized distribution requires Apple Events–based automation.
**Conclusion:** Apple Events are **NOT required**. The build/sign/notarization pipeline is fully CLI-driven
(`xcodebuild`, `codesign`, `xcrun notarytool`) with no AppleScript/ScriptingBridge usage.

## Evidence
- Codebase and scripts contain **no** usage of `osascript`, `.scpt`, `NSAppleScript`, `OSAScript`, `ScriptingBridge`,
  or `tell application "Finder"/"System Events"`.
- Distribution tooling (e.g., `scripts/notarize_app.sh`) exclusively shells out to CLI utilities like
  `xcrun notarytool` with no Finder/System Events automation.

## Decision
- Keep entitlements unchanged (do **not** add `com.apple.security.automation.apple-events`).
- Do **not** add `NSAppleEventsUsageDescription`.
- Continue using Hardened Runtime, proper `codesign` flags, and `notarytool` with `--wait` + `stapler`.

## CI Notes
- Ensure App Store Connect credentials (API key or Apple ID + app-specific password) are configured as CI secrets.
- Prefer `notarytool` over deprecated `altool`.
- Avoid any AppleScript-based Finder automation in packaging steps.

## Re-evaluation Trigger
If future features introduce inter-app automation (Finder layout scripting, controlling other apps), re-run this
assessment and, if needed, add:
- Entitlement: `com.apple.security.automation.apple-events = true`
- `NSAppleEventsUsageDescription` with a user-facing rationale
- QA: Verify TCC prompts under System Settings → Privacy & Security → Automation
