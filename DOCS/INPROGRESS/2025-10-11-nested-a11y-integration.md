# Nested accessibility IDs — micro PRD

## Intent

Wire NestedA11yIDs into the ISOInspector App target so the parse tree explorer exposes deterministic accessibility
identifiers and downstream documentation reflects the conventions.

## Scope

- Kit: _n/a_
- CLI: _n/a_
- App: `ISOInspectorApp`, `ParseTreeExplorerView`, `ParseTreeDetailView`, `ResearchLogAuditPreview` follow-up

## Integration contract

- Public Kit API added/changed: none
- Call sites updated: `ISOInspectorApp.swift`, `ParseTreeOutlineView.swift`, `ParseTreeDetailView.swift`
- Backward compat: additive identifiers only
- Tests: `Tests/ISOInspectorAppTests/ParseTreeAccessibilityIdentifierTests.swift`

## Next puzzles

- [ ] Apply NestedA11yIDs identifiers to research log preview flows (tracked as @todo in `ResearchLogAuditPreview.swift`).
- [ ] Expand identifier coverage to annotation editor actions if QA requires automation hooks.

## Notes

Build: `swift test`
