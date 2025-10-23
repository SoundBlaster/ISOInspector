# Next Tasks

*No active research tasks beyond the items listed below.*
- 🚧 **E2 — Detect Zero/Negative Progress Loops** _(In Progress)_: Harden the streaming parser by detecting non-progressing iterations and capping nesting depth; see `DOCS/INPROGRESS/E2_Detect_Progress_Loops.md` for the active PRD.
- 🚧 **VoiceOver Regression Pass for Accessibility Shortcuts** _(In Progress — blocked without hardware)_: Run manual VoiceOver verification on macOS and iPadOS hardware to confirm the new focus command menu announces controls and restores focus targets as expected. Tracking details now live in `DOCS/TASK_ARCHIVE/156_G8_VoiceOver_Regression_Pass_for_Accessibility_Shortcuts/G8_VoiceOver_Regression_Pass_for_Accessibility_Shortcuts.md`.
- ⏳ **Real-World Assets** _(Blocked — awaiting external licensing approvals)_: Secure licensing for Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so synthetic payloads can be replaced and regression baselines refreshed once approvals land.
- 🔄 **Snapshot & CLI Fixture Maintenance** _(Ongoing)_: Refresh snapshots and CLI fixtures whenever schema updates are intentional via `ISOINSPECTOR_REGENERATE_SNAPSHOTS=1 swift test --filter JSONExportSnapshotTests`.
