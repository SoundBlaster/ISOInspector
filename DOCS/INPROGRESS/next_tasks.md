# Next Tasks

- 🚧 **E1 — Enforce Parent Containment and Non-Overlap** _(In Progress)_: Extend structural validation so child boxes cannot exceed parent ranges, flagging overlapping payloads for CLI/UI surfaces. Planning notes remain in `DOCS/TASK_ARCHIVE/141_Summary_of_Work_2025-10-21_Sample_Encryption/E1_Enforce_Parent_Containment_and_Non_Overlap.md`.
- ✅ **G8 — Accessibility & Keyboard Shortcuts** _(Completed)_: Hardware focus shortcuts now flow through a shared catalog and Focus command menu so macOS and iPadOS expose the same key bindings and restore focus targets without pointer input. Summary recorded in `DOCS/INPROGRESS/Summary_of_Work.md`.
- ⏳ **Real-World Assets** _(Blocked — awaiting external licensing approvals)_: Secure licensing for Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so synthetic payloads can be replaced and regression baselines refreshed once approvals land.
- 🔄 **Snapshot & CLI Fixture Maintenance** _(Ongoing)_: Refresh snapshots and CLI fixtures whenever schema updates are intentional via `ISOINSPECTOR_REGENERATE_SNAPSHOTS=1 swift test --filter JSONExportSnapshotTests`.
