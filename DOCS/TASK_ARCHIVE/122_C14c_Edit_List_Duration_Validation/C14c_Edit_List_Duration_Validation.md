# C14c — Edit List Duration Reconciliation

## 🎯 Objective

Ensure edit list payloads participate in validation so presentation durations align with movie and track headers, flagging gaps, overlaps, and unsupported rate adjustments surfaced by the `elst` parser.

## 🧩 Context

- Builds on the scoped reconciliation rules for `edts/elst` captured during Task C14a, covering duration sums, empty edits, and rate sanity requirements. 【F:DOCS/TASK_ARCHIVE/120_C14a_Finalize_Edit_List_Scope/C14a_Finalize_Edit_List_Scope.md†L1-L74】【F:DOCS/TASK_ARCHIVE/120_C14a_Finalize_Edit_List_Scope/C14a_Finalize_Edit_List_Scope.md†L89-L119】
- Leverages the streaming edit list entries emitted by Task C14b so validation can normalize segments using movie and

  media timescales without re-reading payloads.
  【F:DOCS/TASK_ARCHIVE/121_C14b_Implement_elst_Parser/C14b_Implement_elst_Parser.md†L5-L47】

- Aligns with the execution workplan priority that Phase C validation follow-ups unblock downstream fixture refreshes

  and CLI exports.

【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L68-L74】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L102-L110】

## ✅ Success Criteria

- Validation compares summed edit list movie durations against `mvhd.duration` and reports discrepancies exceeding one tick of the movie timescale.
- Track-level reconciliation maps non-empty edits into media timescale units and surfaces drift relative to `tkhd` and `mdhd` durations, tolerating disabled tracks.
- Diagnostics call out overlapping presentation windows, unsupported reverse/paused segments, and non-zero `media_rate_fraction` values with actionable messages.
- Results flow into CLI/JSON exports and existing UI diagnostic channels without regressing current tests.

## 🔧 Implementation Notes

- Extend the validation pipeline added in prior Phase C work to consume `elst` entries alongside `mvhd`, `tkhd`, and `mdhd` metadata; reuse cumulative presentation offsets computed by the parser.
- Emit structured diagnostics tagged with affected track IDs so future fixture updates (C14d) can assert expected

  messaging across empty, offset, and rate-adjusted scenarios.

- Add targeted regression coverage that exercises empty edits, multi-segment offsets, and mismatched durations using

  existing fixture corpus until refreshed baselines land.

- Coordinate with Validation Rule #15 planning to ensure sample table cross-checks can incorporate edit list timing once

  chunk alignment logic is available.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/120_C14a_Finalize_Edit_List_Scope`](../TASK_ARCHIVE/120_C14a_Finalize_Edit_List_Scope)
- [`DOCS/TASK_ARCHIVE/121_C14b_Implement_elst_Parser`](../TASK_ARCHIVE/121_C14b_Implement_elst_Parser)
