# TODO

- [ ] Integrate lazy loading and state binding into `InspectorPattern` once detail editors are introduced so scroll performance remains predictable. (FoundationUI/Sources/FoundationUI/Patterns/InspectorPattern.swift)
- [ ] Integrate snapshot-based verification for pattern integration once SwiftUI previews are available on CI runners. (FoundationUI/Tests/FoundationUITests/PatternsIntegrationTests/PatternIntegrationTests.swift)
- [x] #4 Integrate the `ResearchLogMonitor` audit with SwiftUI previews once VR-006 entries surface in the UI. (Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift) _(Completed — see `DOCS/TASK_ARCHIVE/199_T3_7_Integrity_Sorting_and_Navigation/194_ResearchLogMonitor_SwiftUIPreviews.md`.)_
- [x] #T36 Resolve Integrity navigation filters, outline shortcuts, and issue-only toggle so tolerant parsing hand-offs stay focused. (Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift) _(Completed — see `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/200_T3_7_Integrity_Navigation_Filters.md`.)_
- [x] #T5.2 Land tolerant traversal regression tests that exercise the corrupt fixture corpus and strict-mode guards. (Tests/ISOInspectorKitTests/TolerantTraversalRegressionTests.swift) _(Completed — see `DOCS/TASK_ARCHIVE/203_T5_2_Regression_Tests_for_Tolerant_Traversal/Summary_of_Work.md`.)_
