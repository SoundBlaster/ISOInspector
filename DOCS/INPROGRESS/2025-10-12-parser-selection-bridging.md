# Parser selection bridging — micro PRD

## Intent

Ensure the SwiftUI explorer automatically surfaces parser output by selecting the first available node as soon as
streaming events populate the tree.

## Scope

- Kit: No changes.
- CLI: No changes.
- App: `ParseTreeExplorerView` auto-selects the first node when the parse snapshot updates; `ParseTreeOutlineViewModel` exposes helpers for default selection and node existence checks.

## Integration contract

- Public Kit API added/changed: None.
- Call sites updated: SwiftUI tree explorer now updates its local selection when `ParseTreeStore` publishes a new snapshot.
- Backward compat: Selection defaults maintain existing behavior for already selected nodes.
- Tests: `ParseTreeOutlineViewModelTests` exercises default selection and identifier tracking.

## Next puzzles

- [ ] Add macOS UI coverage to verify default selection when automation harness for SwiftUI is available.

## Notes

Build: `swift build && swift test`
