# Traversal Guard Implementation

## 🎯 Objective
Implement the tolerant parsing traversal guard logic so the `StreamingBoxWalker` enforces forward progress, depth limits, and corruption budgets without regressing strict-mode behaviour.

## 🧩 Context
- Aligns with the thresholds and recovery actions documented in [`Traversal_Guard_Requirements.md`](../AI/Tolerance_Parsing/Traversal_Guard_Requirements.md) and the Phase T1 roadmap in [`Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md).
- Supports the corrupted media tolerance initiative described in the master execution plan (`04_TODO_Workplan.md`) and the broader tolerant parsing PRD backlog.

## ✅ Success Criteria
- Guard implementation emits the documented `ParseIssue` codes (`guard.no_progress`, `guard.zero_size_loop`, etc.) with correct metadata when thresholds trigger.
- Lenient traversal never loops indefinitely on corrupt fixtures; strict mode continues to abort on the first structural error.
- New corrupt fixtures (e.g., zero-size flood, overlapping boxes) are added and referenced by regression tests covering guard activation paths.
- CLI/app surfaces reflect guard issues in summaries or telemetry hooks without duplicate reporting.

## 🔧 Implementation Notes
- Extend `ParsePipeline.Options` with guard configuration parameters and propagate them through tolerant parsing entry points.
- Update `StreamingBoxWalker` (and related iterators) to enforce minimum cursor advances, zero-length limits, recursion depth caps, cursor regression fences, and per-frame issue budgets.
- Ensure guard-triggered nodes adjust `ParseTreeNode.status` to `.partial` and integrate with existing logging/telemetry categories.
- Add or refresh fixtures and tests under `Tests/ISOInspectorKitTests` plus any CLI snapshot coverage demonstrating guard reporting.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`Traversal_Guard_Requirements.md`](../AI/Tolerance_Parsing/Traversal_Guard_Requirements.md)
- [`Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/RULES`](../RULES)
- Relevant archives in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
