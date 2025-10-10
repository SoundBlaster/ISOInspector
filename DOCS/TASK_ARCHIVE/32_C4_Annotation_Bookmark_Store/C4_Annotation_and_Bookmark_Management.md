# C4 — Annotation and Bookmark Management

## 🎯 Objective

Deliver persistent annotations and bookmark tooling in the SwiftUI app so investigators can flag boxes, jot notes, and
reopen sessions with their context intact.

## 🧩 Context

- Phase C workplan item **C4** targets annotation and bookmark persistence following the detail/hex integrations

  finished in C3.

- Product requirement **FR-UI-003** mandates session bookmarking and annotations stored per file across launches.
- Research gap **R6** captures the pending decision on CoreData vs. JSON persistence mechanics.

## ✅ Success Criteria

- Users can create, edit, and delete annotations tied to specific parse tree nodes.
- Bookmarks surface within the tree UI and survive app relaunches for at least one fixture.
- Persistence layer passes unit tests covering serialization, migrations, and concurrency safety.
- Detail and hex panes remain synchronized with annotation/bookmark selections without regressions in existing tests.

## 🔧 Implementation Notes

- Leverage the existing `ParseTreeDetailViewModel` and annotation provider to attach user-authored notes to parsed payload ranges.
- Define a persistence schema (likely CoreData-backed with JSON export interop) aligned with the outcome of research

  task R6.

- Expose bookmark state through SwiftUI state stores so filters/search can highlight or scope to bookmarked boxes.
- Coordinate with forthcoming E3 session persistence to ensure storage APIs compose cleanly.
- Update DocC catalogs and manuals to reference the new annotation workflows once implementation stabilizes.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/ISOInspector_Execution_Guide/05_Research_Gaps.md`](../AI/ISOInspector_Execution_Guide/05_Research_Gaps.md)
- [`DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md`](../AI/ISOInspector_Execution_Guide/02_Product_Requirements.md)
- [`DOCS/TASK_ARCHIVE/24_C3_Highlight_Field_Subranges/`](../TASK_ARCHIVE/24_C3_Highlight_Field_Subranges/)
