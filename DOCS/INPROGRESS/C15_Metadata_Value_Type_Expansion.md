# C15 Metadata Value Type Expansion

## 🎯 Objective

Extend the metadata value decoding coverage so that `udta/meta/ilst` entries for additional MP4RA-defined data types render human-readable values across the CLI and SwiftUI app exports.

## 🧩 Context

- Builds on the Phase C baseline metadata parsers and value decoding delivered in `DOCS/TASK_ARCHIVE/125_C15_Metadata_Box_Coverage/` and the follow-up decoding work documented in `DOCS/TASK_ARCHIVE/128_C15_Metadata_Value_Decoding_Expansion/`.
- Prioritized as a Phase C P0+ follow-up in `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` to keep metadata exports aligned with the official MP4RA registry.
- Dependent on new fixture samples capturing GIF/TIFF image payloads, signed fixed-point values, and other outstanding MP4RA data encodings referenced in `todo.md` and `DOCS/INPROGRESS/next_tasks.md`.

## ✅ Success Criteria

- MP4RA metadata value types called out in the backlog (e.g., GIF/TIFF image payloads, signed fixed-point formats, any

  additional binary encodings) are decoded into readable structures for both CLI and app consumers.

- Automated tests cover each newly supported value type using fixtures or synthetic payloads while preserving existing

  coverage for previously handled types.

- JSON export snapshots and app detail panes display meaningful representations for the new value types without

  regressions in existing metadata output.

- Documentation and inline code comments reference the MP4RA specification identifiers for each added type to simplify

  future maintenance.

## 🔧 Implementation Notes

- Coordinate with fixture preparation owners to land representative samples; until then, create minimal synthetic

  payloads to drive parser behavior where feasible.

- Extend the metadata decoder registry in `BoxParserRegistry+Metadata.swift` and related value adapters, ensuring the Combine/UI pipelines continue to emit normalized metadata models.
- Reuse the validation hooks established during Task C15 to confirm that unrecognized value types still fall back to

  binary representations with research log entries.

- Update CLI and SwiftUI regression baselines after expanding decoding coverage, following the snapshot refresh workflow

  recorded in the Task C15 archives.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/128_C15_Metadata_Value_Decoding_Expansion/`](../TASK_ARCHIVE/128_C15_Metadata_Value_Decoding_Expansion/)
