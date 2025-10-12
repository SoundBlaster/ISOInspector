# Apply NestedA11yIDs Identifiers to Research Log Preview Flows

## 🎯 Objective

Introduce hierarchical accessibility identifiers to the research log preview interfaces so QA automation can target the
audit components without relying on localized strings or layout heuristics.

## 🧩 Context

- Baseline adoption plan for NestedA11yIDs flags research log previews as the next migration step after the parse tree explorer. See the table in `DOCS/AI/09_NestedA11yIDs_AppTarget_PRD.md`.
- `ResearchLogAuditPreview.swift` currently exposes preview-only UI without nested identifiers, guarded by a `@todo` comment referencing this follow-up.
- QA teams plan to surface the research log audit inside production screens as part of release R13; identifiers must be

  ready when the preview is promoted.

## ✅ Success Criteria

- `ResearchLogAuditPreview` (and any production host screens) declare a stable `.a11yRoot` for the research log surface and apply `.nestedAccessibilityIdentifier(...)` to key subviews such as headers, diagnostic lists, and status badges.
- Accessibility snapshots or UI tests confirm identifiers follow the `researchLogPreview.*` naming pattern without collisions.
- Documentation and TODO references are updated to point at the implemented identifiers, closing the outstanding `@todo` marker in `ResearchLogAuditPreview.swift` and marking todo.md item #13 as complete when shipped.

## 🔧 Implementation Notes

- Validate whether the preview has been promoted into the production navigation flow; if not, coordinate rollout so

  identifiers land before QA automation depends on them.

- Reuse conventions introduced for the parse tree explorer (e.g., lowercase slug segments) to keep identifier schemes

  consistent.

- Extend `ParseTreeAccessibilityIdentifierTests` or add focused SwiftUI preview tests to assert presence of the new identifiers.
- Cross-check with QA automation owners to ensure naming matches their planned selectors and update `Docs/Guides/NestedA11yIDsIntegration.md` if additional patterns emerge.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/09_NestedA11yIDs_AppTarget_PRD.md`](../AI/09_NestedA11yIDs_AppTarget_PRD.md)
- [`Docs/Guides/NestedA11yIDsIntegration.md`](../../Docs/Guides/NestedA11yIDsIntegration.md)
