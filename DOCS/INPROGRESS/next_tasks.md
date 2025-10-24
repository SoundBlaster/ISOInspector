# Next Tasks

- 🛠️ **Tolerant Parsing — Surface Issues in Downstream Consumers** _(In Progress — see `DOCS/INPROGRESS/T2_1_ParseIssueStore_Aggregation.md`.)_:
  - Implement Task **T2.1 ParseIssueStore** so tolerant parsing issues aggregate for CLI/app summaries. Track roadmap context in `DOCS/TASK_ARCHIVE/169_T1_5_Propagate_Decoder_Failures_Through_Tolerant_Parsing/Summary_of_Work.md` and `DOCS/AI/Tolerance_Parsing/TODO.md`.
- 🚧 **VoiceOver Regression Pass for Accessibility Shortcuts** _(Blocked — pending hardware)_:
  - Schedule macOS and iPadOS hardware verification to confirm focus command menus announce controls and restore focus targets. Reference `DOCS/TASK_ARCHIVE/156_G8_VoiceOver_Regression_Pass_for_Accessibility_Shortcuts/`.
- ⏳ **Real-World Assets** _(Blocked — awaiting licensing approvals)_:
  - Secure Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so regression baselines can shift from synthetic payloads once approvals land.
- ♻️ **Snapshot & CLI Fixture Maintenance** _(Ongoing)_:
  - Refresh snapshots and CLI fixtures whenever schema updates are intentional via `ISOINSPECTOR_REGENERATE_SNAPSHOTS=1 swift test --filter JSONExportSnapshotTests`.
