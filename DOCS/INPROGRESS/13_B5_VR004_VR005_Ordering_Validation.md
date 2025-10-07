# 13 — B5 VR-004 & VR-005 Ordering Validation

## 🎯 Objective

Implement the remaining B5 ordering rules so the streaming validator surfaces VR-004 when no `ftyp` appears before media boxes and VR-005 when `moov` trails `mdat` outside of explicit streaming scenarios.

## 🧩 Context

- Phase B task B5 requires delivering validation rules VR-001 through VR-006 once the streaming pipeline is
  stable.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L24】
- The technical specification defines VR-004 and VR-005 ordering expectations and severities, complementing the
  structural rules already implemented.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L60-L68】
- Root backlog item `todo.md #3` still tracks VR-004 and VR-005 as incomplete follow-ups after VR-001/VR-002 landed.【F:todo.md†L5-L9】
- Next-task notes call out continuing the VR rule thread and pairing it with VR-006 research logging once ordering
  checks exist to inform metadata consumers.【F:DOCS/INPROGRESS/next_tasks.md†L1-L4】

## ✅ Success Criteria

- Streaming parses raise a VR-004 error if any media-designated box (`moov`, `mdat`, `trak`, `moof`, etc.) arrives before an `ftyp`, and tests assert the issue flows through `ParsePipeline.live()` and CLI formatters.
- VR-005 warnings trigger when `mdat` precedes `moov` unless an accepted streaming signal (e.g., `mvex`/fragmented layout flag) was observed, with fixtures covering both the violation and the allowed exception.
- Validation summaries and research logs continue to include VR-006 information without regression, ensuring ordering
  signals feed the broader metadata UX plans.
- Documentation and backlog trackers update to reflect VR-004/VR-005 completion and remaining VR-006 follow-up work.

## 🔧 Implementation Notes

- Extend the validator state machine to track whether `ftyp` appeared before other top-level media boxes, leveraging existing event ordering guarantees from the streaming pipeline.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L40-L68】
- Define the set of boxes considered "media" for VR-004, referencing MP4RA catalog metadata so additions remain
  future-proof once B4 integration lands.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L24】
- For VR-005, watch for `moov` and `mdat` top-level encounters while recognizing fragmented workflows (e.g., presence of `mvex`, `sidx`, `moof`) as streaming-friendly layouts to avoid false positives.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L60-L68】
- Update unit and integration fixtures to demonstrate both ordering violations and compliant sequences, keeping tests
  deterministic and aligned with prior VR-001/VR-002 coverage patterns archived under Task
  12.【F:DOCS/TASK_ARCHIVE/12_B5_VR001_VR002_Structural_Validation/12_B5_VR001_VR002_Structural_Validation.md†L10-L36】
- Coordinate CLI/UI messaging with planned VR-006 research logging so downstream consumers capture actionable guidance
  when ordering rules fire.【F:DOCS/TASK_ARCHIVE/09_B4_Metadata_Follow_Up_Planning/Summary_of_Work.md†L25-L26】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
