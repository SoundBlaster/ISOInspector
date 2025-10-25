# Next Tasks

- 🚧 **VoiceOver Regression Pass for Accessibility Shortcuts** _(Blocked — pending hardware)_:
  - Schedule macOS and iPadOS hardware verification to confirm focus command menus announce controls and restore focus targets. Reference `DOCS/TASK_ARCHIVE/156_G8_VoiceOver_Regression_Pass_for_Accessibility_Shortcuts/`.
- ⏳ **Real-World Assets** _(Blocked — awaiting licensing approvals)_:
  - Secure Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so regression baselines can shift from synthetic payloads once approvals land.
- 🎯 **Tolerant Parsing — Surface Issue Metrics in SwiftUI** _(Pending design sign-off)_:
  - Surface `ParseIssueStore` metrics in SwiftUI ribbons once tolerant parsing UI specs are finalized. Track via `@todo PDD:45m` in `ParseTreeStore.swift` and the open item in `todo.md`.
- ✅ **T2.2 — Emit Parse Events with Severity Metadata** _(Completed — see `./Summary_of_Work.md` for recap)_:
  - Streaming parse events now propagate `ParseIssue` severity, offsets, and reason codes to UI/CLI consumers.
