# Next Tasks

*No active research tasks beyond the items listed below.*
- ✅ **T1.1 — Define ParseIssue Model** _(Completed — Sprint 1 Kickoff)_: Implemented structured corruption event model (`ParseIssue`) to underpin tolerant parsing mode. See summary in [`Summary_of_Work.md`](./Summary_of_Work.md) and planning resources in [`DOCS/AI/Tolerance_Parsing/`](../AI/Tolerance_Parsing/README.md).
- 🚧 **VoiceOver Regression Pass for Accessibility Shortcuts** _(In Progress — blocked without hardware)_: Run manual VoiceOver verification on macOS and iPadOS hardware to confirm the new focus command menu announces controls and restores focus targets as expected. Tracking details now live in `DOCS/TASK_ARCHIVE/156_G8_VoiceOver_Regression_Pass_for_Accessibility_Shortcuts/G8_VoiceOver_Regression_Pass_for_Accessibility_Shortcuts.md`.
- ⏳ **Real-World Assets** _(Blocked — awaiting external licensing approvals)_: Secure licensing for Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so synthetic payloads can be replaced and regression baselines refreshed once approvals land.
- 🔄 **Snapshot & CLI Fixture Maintenance** _(Ongoing)_: Refresh snapshots and CLI fixtures whenever schema updates are intentional via `ISOINSPECTOR_REGENERATE_SNAPSHOTS=1 swift test --filter JSONExportSnapshotTests`.
