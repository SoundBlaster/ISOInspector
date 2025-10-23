# B2 — Define BoxNode Aggregate

## 🎯 Objective
Establish a canonical `BoxNode` domain model that captures parsed header metadata, optional payload details, validation issues, and child relationships so streaming parse events can be materialized into tree snapshots for ISOInspector's UI, CLI, and export layers.

## 🧩 Context
- The execution backlog calls for a structured node type containing the parsed header, optional payload metadata, validation warnings, and nested children to back the parse tree produced by `BoxParser.parseRoot()` and downstream consumers.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L104-L121】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L178-L183】
- Technical specifications expect the UI tree module to operate on a `BoxNode` representation that bridges the parser pipeline to view models and exporters across ISOInspector targets.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L17-L46】

## ✅ Success Criteria
- A `BoxNode` type (or equivalent renamed domain struct) exists in `ISOInspectorKit` with properties for `BoxHeader`, optional catalog metadata, optional parsed payload, validation issues, and child nodes, all marked `Sendable` for concurrency safety.
- Streaming parse events can be accumulated into a deterministic `BoxNode` tree that UI stores, CLI formatters, and JSON exporters can consume without losing validation warnings or metadata.
- Documentation and developer guides reference the new node aggregate so future tasks understand how to traverse or extend the tree representation.
- Regression checks (unit tests or snapshot exports) demonstrate that building a tree from representative fixtures preserves header offsets, payload annotations, and validation results.

## 🔧 Implementation Notes
- Build on the existing `ParsePipeline` event stream by introducing or updating a builder that accumulates events into mutable nodes before snapshotting them as `BoxNode` instances.
- Align naming and API surface with existing consumers (`ParseTreeBuilder`, UI tree stores, CLI exporters) to avoid parallel representations; migrate call sites to the canonical type where necessary.
- Ensure metadata from `BoxCatalog`, parsed payload structures, and validation issues attach to the node before it is emitted so downstream presentation layers stay synchronized.
- Confirm dependencies from Task B1 (box headers) remain satisfied and that no outstanding blockers exist in current in-progress validation tasks.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`03_Technical_Spec.md`](../AI/ISOInspector_Execution_Guide/03_Technical_Spec.md)
- [`DOCS/RULES`](../RULES)
- Relevant history in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
