# Next Tasks

- 🛠️ **T1.3 ParsePipeline Options for Tolerant Parsing** _(In Progress — see `DOCS/INPROGRESS/T1_3_ParsePipeline_Options.md`)_ : Define option toggles for lenient vs. strict parsing so tolerant mode can be wired through the pipeline and surfaced to app/CLI configuration layers.
- 🚧 **VoiceOver Regression Pass for Accessibility Shortcuts** _(In Progress — blocked without hardware)_: Track manual VoiceOver verification on macOS and iPadOS hardware to confirm the focus command menu announces controls and restores focus targets as expected. Reference historical notes in `DOCS/TASK_ARCHIVE/156_G8_VoiceOver_Regression_Pass_for_Accessibility_Shortcuts/`.
- ⏳ **Real-World Assets** _(Blocked — awaiting external licensing approvals)_: Secure Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so regression baselines can shift from synthetic payloads once approvals land.
- 🔄 **Snapshot & CLI Fixture Maintenance** _(Ongoing)_: Refresh snapshots and CLI fixtures whenever schema updates are intentional via `ISOINSPECTOR_REGENERATE_SNAPSHOTS=1 swift test --filter JSONExportSnapshotTests`.
