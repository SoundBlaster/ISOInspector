# T1.7 — Finalize Traversal Guard Requirements

## 🎯 Objective
Document the definitive progress and depth guard rules for the tolerant parse pipeline so traversal never hangs or recurses indefinitely when encountering malformed sizes while still surfacing as much structure as possible.

## 🧩 Context
- The Corrupted Media Tolerance initiative requires lenient parsing to continue after decoder failures, but it must clamp traversal to protect against infinite loops and stack exhaustion when boxes report invalid sizes or child counts.【F:DOCS/AI/Tolerance_Parsing/CorruptedMediaTolerancePRD.md†L1-L102】【F:DOCS/AI/Tolerance_Parsing/TODO.md†L24-L42】
- T1.6 already clamps binary reads to the active parent range; T1.7 extends this by defining forward progress and recursion limits that downstream consumers (UI, CLI, exports) can rely on when handling `ParseIssue` sequences.【F:DOCS/TASK_ARCHIVE/170_T1_6_Implement_Binary_Reader_Guards/Summary_of_Work.md†L1-L12】【F:DOCS/AI/Tolerance_Parsing/TODO.md†L24-L42】
- Execution guidance calls out T1.7 as the remaining blocker before tolerant parsing issues can flow through aggregators and surface in CLI/app summaries.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L17-L29】【F:DOCS/INPROGRESS/next_tasks.md†L3-L7】

## ✅ Success Criteria
- A guard specification enumerates required progress heuristics (minimum byte advance per iteration, maximum zero-length retries, recursion depth caps) with rationale linked to fixture patterns and fuzzing goals.
- Acceptance plan lists the corrupt fixture scenarios and fuzz test coverage necessary to prove the guards prevent hangs while keeping traversal output stable for valid media.
- API notes define how guard violations materialize as `ParseIssue` metadata (reason codes, severity, offsets) so CLI/UI consumers can display actionable diagnostics.
- Follow-up tasks identified (e.g., implementation tickets for walker updates or fixture generation) are captured with owners/dependencies so engineering can execute without further clarification.

## 🔧 Implementation Notes
- Review historical infinite-loop incidents from the tolerant parsing spike and extract thresholds to codify (e.g., repeated zero-byte `mdat` children, sibling cycles caused by overlapping ranges).【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L600-L626】
- Align guard semantics with existing progress loop detection (E2) to avoid duplicated checks while ensuring tolerant mode emits structured issues instead of aborting outright.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L17-L29】【F:DOCS/AI/Tolerance_Parsing/CorruptedMediaTolerancePRD.md†L103-L158】
- Define telemetry/debug logging expectations so future benchmark runs can verify guard triggers without user intervention.
- Coordinate with CLI/export teams to ensure any new issue reason codes or metadata fields are backfilled into schema references before implementation begins.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](RULES)
- [`CorruptedMediaTolerancePRD.md`](AI/Tolerance_Parsing/CorruptedMediaTolerancePRD.md)
- [`Tolerance_Parsing/TODO.md`](AI/Tolerance_Parsing/TODO.md)
- [`DOCS/TASK_ARCHIVE`](TASK_ARCHIVE)
