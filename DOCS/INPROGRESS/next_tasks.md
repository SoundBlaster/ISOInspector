# Next Tasks

- 🚧 **E1 — Enforce Parent Containment and Non-Overlap** _(In Progress)_: Extend structural validation so child boxes cannot exceed parent ranges, flagging overlapping payloads for CLI/UI surfaces. Planning notes remain in `DOCS/TASK_ARCHIVE/141_Summary_of_Work_2025-10-21_Sample_Encryption/E1_Enforce_Parent_Containment_and_Non_Overlap.md`.
- 🚧 **G8 — Accessibility & Keyboard Shortcuts** _(In Progress)_: Finalize hardware keyboard focus commands and VoiceOver-friendly navigation for the outline, detail, notes, and hex panes across macOS and iPadOS. Task brief lives in `DOCS/INPROGRESS/G8_Accessibility_and_Keyboard_Shortcuts.md`.
- ⏳ **Real-World Assets** _(Blocked — awaiting external licensing approvals)_: Secure licensing for Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so synthetic payloads can be replaced and regression baselines refreshed once approvals land.
- 🔄 **Snapshot & CLI Fixture Maintenance** _(Ongoing)_: Refresh snapshots and CLI fixtures whenever schema updates are intentional via `ISOINSPECTOR_REGENERATE_SNAPSHOTS=1 swift test --filter JSONExportSnapshotTests`.
