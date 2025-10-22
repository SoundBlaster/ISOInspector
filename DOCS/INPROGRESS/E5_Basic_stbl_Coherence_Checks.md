# E5 — Basic `stbl` Coherence Checks

## 🎯 Objective
Ensure sample table structures report internally consistent counts so timeline calculations and downstream tooling can trust `stbl`-derived metadata without manual inspection.

## 🧩 Context
- The PRD calls for extracting the full `stbl` hierarchy, including timing tables (`stts`, `ctts`), chunk layout (`stsc`), and size tables (`stsz`/`stz2`), to power validation and reporting surfaces.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L53-L66】
- Current validation work covers header sizing and container containment (VR-001/VR-002) plus codec invariants, but basic table coherence checks remain outstanding in the backlog.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L221-L229】
- Sample table parsers are already implemented and archived (e.g., `stsc`, `stsz/stz2`, `stco/co64`), enabling cross-table comparisons without new parsing dependencies.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L207-L217】

## ✅ Success Criteria
- Validation emits warnings/errors when declared sample counts or entry lengths disagree across `stts`, `ctts`, `stsc`, `stsz/stz2`, and chunk offset tables.
- CLI, JSON export, and UI surfaces reflect the new diagnostics with regression coverage for representative fixtures.
- Documentation and backlog entries referencing E5 are updated to indicate the checks are live and verified.

## 🔧 Implementation Notes
- Reuse existing validation infrastructure (VR-00x series) to attach new rules without disrupting streaming performance; focus on lightweight count comparisons before pursuing deeper correlation efforts.
- Leverage fragment and movie sample fixtures already tracked in the task archive to author failing/passing scenarios without waiting on blocked real-world assets.
- Coordinate with ongoing E1 containment work to avoid duplicated diagnostics when boundary violations cascade into count mismatches.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
