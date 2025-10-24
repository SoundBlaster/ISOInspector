# Next Tasks

- 🚀 **T1.5 — Propagate Decoder Failures Through Tolerant Parsing** _(In Progress — see `DOCS/INPROGRESS/T1_5_Propagate_Decoder_Failures_Through_Tolerant_Parsing.md`)_: Update streaming iteration to capture `BoxHeaderDecoder` failures, attach diagnostics to the current node, and continue traversal per the acceptance criteria tracked in `DOCS/AI/Tolerance_Parsing/TODO.md`.
- 🚧 **VoiceOver Regression Pass for Accessibility Shortcuts** _(In Progress — blocked pending hardware)_: Schedule macOS and iPadOS hardware verification to confirm focus command menus announce controls and restore focus targets. Reference the context in `DOCS/TASK_ARCHIVE/156_G8_VoiceOver_Regression_Pass_for_Accessibility_Shortcuts/`.
- ⏳ **Real-World Assets** _(Blocked — awaiting licensing approvals)_: Secure Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so regression baselines can shift from synthetic payloads once approvals land.
- 🔄 **Snapshot & CLI Fixture Maintenance** _(Ongoing)_: Refresh snapshots and CLI fixtures whenever schema updates are intentional via `ISOINSPECTOR_REGENERATE_SNAPSHOTS=1 swift test --filter JSONExportSnapshotTests`.
