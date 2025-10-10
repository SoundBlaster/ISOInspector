# F1 Expand Fixture Catalog with Fragmented and Malformed Assets

## 🎯 Objective

Create an expanded automated fixture corpus covering fragmented MP4, DASH segment pairs, large `mdat` edge cases, and deliberately malformed files so validation rules and streaming parsers have representative samples with documented expectations.

## 🧩 Context

- High-priority workplan item **F1** requires building out malformed MP4 fixtures tied to validation coverage and

  depends on the completed parsing foundation from B2
  onward.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L47-L54】

- The root backlog tracks `@todo #8` to expand fixture coverage with fragmented, DASH, and malformed assets plus validation notes, and it is the only upcoming task currently queued.【F:todo.md†L1-L15】【F:DOCS/INPROGRESS/next_tasks.md†L1-L3】
- Main PRD backlog Phase H highlights the need for a corpus spanning MOV, fragmented MP4, DASH, huge `mdat`, and malformed cases to drive tests and benchmarks.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L226-L230】

## ✅ Success Criteria

- Fixture directory gains representative samples for baseline MP4/MOV, fragmented MP4 (`moof`/`traf`), DASH init + media segments, large `mdat`, and intentionally malformed headers or hierarchies.
- Each fixture is accompanied by metadata describing provenance, scenario focus, and expected validation outcomes

  (pass/fail rules, warnings).

- Automated tests reference the new fixtures to assert parser behavior and validation diagnostics without manual setup.
- Repository documentation (fixture catalog README or inline comments) is updated so future tasks can regenerate or

  extend assets consistently.

## 🔧 Implementation Notes

- Use existing fixture harness in `Tests/ISOInspectorKitTests/Fixtures` as the staging area; extend helper types in `FixtureCatalog.swift` to describe new assets and expectations.
- Generate malformed or fragmented files via Python or Swift scripts, ensuring they are deterministic and small enough

  for version control; capture generation scripts or commands alongside fixtures.

- Coordinate validation expectations with existing VR-001–VR-006 implementations, adding TODO hooks for future

  validation rules if scenarios expose gaps.

- Ensure large `mdat` coverage uses sparse data or truncated payloads to keep repository size manageable while still exercising streaming behaviors.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
