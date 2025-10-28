# T3.7.1 — Integrity Tab Sorting Refinements

## 🎯 Objective

Resolve TODO markers #T36-001 and #T36-002 by implementing deterministic, multi-field sorting for offset-based and affected-node-based orderings in the Integrity summary table, ensuring CLI/export parity across large fixture sets.

## 🧩 Context

- Task T3.6 shipped the Integrity Summary tab with basic sorting implementations that left refinement work as PDD puzzles.【F:DOCS/TASK_ARCHIVE/196_T3_6_Integrity_Summary_Tab/T3_6_Summary_of_Work.md†L189-L196】
- The current sorting logic in `IntegritySummaryViewModel` uses single-field comparisons that may produce non-deterministic ordering when issues share the same primary sort key:
  - **#T36-001 (Offset sorting)**: Currently sorts by `byteRange?.lowerBound`, with no secondary tie-breaker.【F:Sources/ISOInspectorApp/Integrity/IntegritySummaryViewModel.swift†L66-L70】
  - **#T36-002 (Affected node sorting)**: Currently sorts by first `affectedNodeIDs` entry, with no handling for multiple affected nodes or depth context.【F:Sources/ISOInspectorApp/Integrity/IntegritySummaryViewModel.swift†L72-L75】
- The tolerance parsing roadmap requires that Integrity navigation filters (T3.7) ship with deterministic ordering so investigators can reliably cycle through corruption issues in document order.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L61-L78】
- The master PRD emphasizes that sorting must match CLI/export ordering for consistency across all ISOInspector surfaces.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L251-L267】

## ✅ Success Criteria

- [ ] **Offset-based sorting** uses multi-field comparison: primary sort by `byteRange.lowerBound`, secondary tie-breaker by severity rank (Error > Warning > Info), tertiary tie-breaker by issue code or stable identifier to ensure deterministic ordering even when multiple issues share the same byte offset.
- [ ] **Affected node sorting** uses multi-field comparison: primary sort by affected node depth or path, secondary sort by node ID numeric order, tertiary tie-breaker by severity rank to maintain consistent ordering when multiple issues affect the same node.
- [ ] **Test coverage** includes unit tests that assert deterministic sort order when issues have matching primary keys (e.g., three issues at the same offset with different severities produce a stable, repeatable order).
- [ ] **UI verification** confirms that switching sort modes in the Integrity tab produces consistent, repeatable orderings across app relaunch and fixture reload scenarios.
- [ ] **Documentation** updates the IntegritySummaryViewModel implementation comments to reflect the multi-field sort strategy and rationale for each tie-breaker.

## 🔧 Implementation Notes

### Current State Analysis

**File:** `Sources/ISOInspectorApp/Integrity/IntegritySummaryViewModel.swift`

```swift
// Current implementation (lines 60-76)
switch sortOrder {
case .severity:
    issues = issues.sorted { lhs, rhs in
        severityRank(lhs.severity) > severityRank(rhs.severity)
    }
case .offset:
    issues = issues.sorted { lhs, rhs in
        // @todo #T36-001 Implement offset-based sorting
        (lhs.byteRange?.lowerBound ?? 0) < (rhs.byteRange?.lowerBound ?? 0)
    }
case .affectedNode:
    issues = issues.sorted { lhs, rhs in
        // @todo #T36-002 Implement affected node sorting
        (lhs.affectedNodeIDs.first ?? 0) < (rhs.affectedNodeIDs.first ?? 0)
    }
}
```

### Proposed Multi-Field Sort Strategy

**Offset-based sorting (#T36-001):**
1. **Primary:** Sort by `byteRange?.lowerBound ?? Int.max` (issues without byte ranges sort to end)
2. **Secondary:** Tie-break by severity rank (Error=3, Warning=2, Info=1) in descending order
3. **Tertiary:** Tie-break by `code` lexicographic order for stable deterministic sort

**Affected node sorting (#T36-002):**
1. **Primary:** Sort by affected node path depth (if available via `ParseTreeNode` traversal)
2. **Secondary:** Sort by first `affectedNodeIDs` entry numerically
3. **Tertiary:** Tie-break by severity rank in descending order
4. **Quaternary:** Tie-break by `byteRange?.lowerBound` for stable order

### Testing Strategy

Following TDD methodology:
1. Write failing unit tests that assert deterministic ordering for edge cases:
   - Multiple issues at the same byte offset with different severities
   - Multiple issues affecting the same node with different codes
   - Issues with missing byte ranges or empty `affectedNodeIDs` arrays
2. Implement minimal multi-field sort logic to make tests pass
3. Refactor for clarity while keeping tests green
4. Add integration test with real fixtures (e.g., `vr006_missing_required_children_lenient.json`) to verify CLI/export parity

### Related Components

- **ParseIssue model**: Already contains all required fields (`byteRange`, `affectedNodeIDs`, `severity`, `code`).【F:Sources/ISOInspectorKit/Validators/ParseIssue.swift】
- **ParseTreeNode**: May require helper method to query node depth/path for affected node sorting if not already available.【F:Sources/ISOInspectorKit/Parse/ParseTreeNode.swift】
- **CLI export ordering**: Verify that `makeIssueSummary()` in ParseIssueStore uses matching sort logic for parity.【F:Sources/ISOInspectorKit/Stores/ParseIssueStore.swift】

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES/02_TDD_XP_Workflow.md`](../RULES/02_TDD_XP_Workflow.md)
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/TASK_ARCHIVE/196_T3_6_Integrity_Summary_Tab`](../TASK_ARCHIVE/196_T3_6_Integrity_Summary_Tab)

## 📋 Next Steps After Completion

Once sorting refinements are complete, the following T3.7 deliverables remain:
1. **#T36-003**: Improve navigation from Integrity tab to Explorer (verify selection scrolling and focus preservation)
2. **Tree view filter toggle**: Add toolbar control to show/hide corrupt nodes in ParseTreeOutlineView
3. **Keyboard shortcuts**: Implement Cmd+Shift+E to jump to next issue in document order
4. **Accessibility audit**: Ensure navigation shortcuts respect VoiceOver and keyboard focus order

## 🎯 Exit Criteria

Task T3.7.1 is complete when:
- Both TODO markers (#T36-001, #T36-002) are resolved with multi-field sort implementations
- Unit tests cover deterministic ordering edge cases and pass consistently
- IntegritySummaryView displays stable, repeatable orderings when cycling between sort modes
- Code comments document the sort strategy and rationale
- Commit follows atomic PDD principles with clear message referencing T3.7.1 and resolved puzzles
