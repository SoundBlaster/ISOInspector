# Distribution: Apple Events Follow-Up

## ✅ Outcome

- Notarized distribution does **not** require Apple Events automation. The pipeline relies exclusively on CLI tooling

  (`codesign`, `xcrun notarytool`) and the codebase contains no AppleScript/ScriptingBridge integrations.

- Entitlements remain unchanged; no `com.apple.security.automation.apple-events` entitlement or

  `NSAppleEventsUsageDescription` entry is necessary.

- Repository docs and TODO trackers now point to the archived outcome record so future distribution work starts from a

  verified baseline.

## 📎 Final Record

- See `DOCS/TASK_ARCHIVE/57_Distribution_Apple_Events_Notarization_Assessment/57_Distribution_Apple_Events_Notarization_Assessment.md` for the full

  decision log and re-evaluation guidance.

## 📌 Status

- Completed — ready to archive once downstream teams acknowledge the summary in their planning docs.
