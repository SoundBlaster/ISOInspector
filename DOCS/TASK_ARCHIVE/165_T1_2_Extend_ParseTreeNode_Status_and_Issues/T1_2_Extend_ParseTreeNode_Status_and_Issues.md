# T1.2 — Extend ParseTreeNode with Issues and Status Fields

## 🎯 Objective
Enable the corrupted media tolerance prototype by enriching `ParseTreeNode` with `issues` metadata and a status enum so lenient parsing can surface corruption without halting traversal.

## 🧩 Context
- `DOCS/AI/Tolerance_Parsing/TODO.md` defines T1.2 as part of Phase T1 for introducing resilient parsing, with expectations that nodes store `ParseIssue` arrays and export their status.
- The master PRD highlights tolerant parsing as a roadmap priority and requires corruption indicators across the tree, detail panes, exports, and downstream tooling.
- Existing JSON export and UI pipelines assume nodes are always valid; this task supplies the data needed for later UI (T3) and export (T4) deliverables.

## ✅ Success Criteria
- `ParseTreeNode` exposes an `issues: [ParseIssue]` collection and a `status` enum that captures valid, partial, corrupt, or skipped states, defaulting to valid for untouched nodes.
- JSON export (and any mirrored CLI serialization) includes the new status and issue array so tolerance diagnostics persist in saved artifacts.
- Tree stores, document view models, and other in-memory aggregates remain source-compatible while gaining accessors for corruption metadata.
- Unit and snapshot tests covering healthy and corrupt fixture scenarios validate serialization, ensure backward compatibility for strict mode, and demonstrate how tolerant mode will consume the new fields.

## 🔧 Implementation Notes
- Coordinate with the T1.1 `ParseIssue` model to reuse severity codes and byte-range metadata when populating node issues.
- Audit `BoxNode`/`ParseTreeNode` initializers and builders to accept optional issue lists without breaking streaming parse performance.
- Update export encoders and any bridging structures (e.g., Combine stores, CLI summaries) to forward status and issues, guarding strict-mode paths that expect empty collections.
- Prepare migration notes for downstream tasks (T1.3–T1.7, T3.x, T4.1) so they can rely on the enriched node model without additional refactors.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/RULES`](../RULES)
