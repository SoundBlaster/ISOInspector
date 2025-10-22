# Next Tasks

- 🚧 **D6 — Sample Encryption Placeholder Parsing** _(In Progress)_: Recognize `senc`, `saio`, and `saiz` boxes during fragment parsing so the pipeline records their offsets/sizes and surfaces presence to CLI/UI consumers without attempting decryption.
- 🚧 **E1 — Enforce Parent Containment and Non-Overlap** _(In Progress)_: Extend structural validation so child boxes cannot exceed parent ranges, flagging overlapping payloads for CLI/UI surfaces; context captured in `DOCS/TASK_ARCHIVE/141_Summary_of_Work_2025-10-21_Sample_Encryption/E1_Enforce_Parent_Containment_and_Non_Overlap.md`.
- 🚧 **E4 — Verify avcC/hvcC Invariants** _(In Progress)_: Build validation rules that confirm codec configuration records report consistent `lengthSizeMinusOne` values, array counts, and NAL unit lengths across ISOInspectorKit, CLI warnings, and JSON exports; see `DOCS/INPROGRESS/E4_Verify_avcC_hvcC_Invariants.md` for scope.
- ✅ **E3 — Warn on Unusual Top-Level Ordering** _(Completed — see `DOCS/TASK_ARCHIVE/142_E3_Warn_on_Unusual_Top_Level_Ordering/Summary_of_Work.md`)_:
  Advisory validator now warns when `ftyp` or `moov` appear in atypical top-level sequences while keeping streaming layouts non-blocking.
- ⏳ **Real-World Assets** _(Blocked — awaiting external licensing approvals)_: Secure licensing for Dolby Vision, AV1, VP9, Dolby AC-4, and MPEG-H fixtures so synthetic payloads can be replaced and regression baselines refreshed once approvals land.
