# TODO

## CI/CD & Quality Gates

- [ ] Wire `swift format --in-place` into `.pre-commit-config.yaml` and add a `swift format --mode lint` gate to `.github/workflows/ci.yml` so formatting failures block pushes and pull requests. (Config: `.pre-commit-config.yaml`, `.github/workflows/ci.yml`)
- [ ] Restore SwiftLint complexity thresholds in `.swiftlint.yml` and surface analyzer artifacts from `.github/workflows/swiftlint.yml` when violations occur. (Config: `.swiftlint.yml`, `.github/workflows/swiftlint.yml`)
- [ ] Promote `coverage_analysis.py` to a shared quality gate by wiring it into `.githooks/pre-push` and `.github/workflows/ci.yml` after `swift test --enable-code-coverage`. (Scripts: `.githooks/pre-push`, `coverage_analysis.py`, `.github/workflows/ci.yml`)
- [ ] Add DocC + `missing_docs` enforcement to the lint pipeline so public APIs fail CI without documentation coverage, and capture the suppression playbook in `Documentation/ISOInspector.docc/Guides/DocumentationStyle.md`. (Config: `.swiftlint.yml`, `.github/workflows/documentation.yml`)
- [ ] Extend `.githooks/pre-push` and `.github/workflows/ci.yml` with `swift build --strict-concurrency=complete`/`swift test --strict-concurrency=complete` runs, publishing logs referenced from `DOCS/AI/PRD_SwiftStrictConcurrency_Store.md`. (Scripts: `.githooks/pre-push`, `.github/workflows/ci.yml`)

## FoundationUI Integration

- [ ] Integrate lazy loading and state binding into `InspectorPattern` once detail editors are introduced so scroll performance remains predictable. (FoundationUI/Sources/FoundationUI/Patterns/InspectorPattern.swift) _(Planning archived at `DOCS/TASK_ARCHIVE/204_T6_1_CLI_Tolerant_Flag/204_InspectorPattern_Lazy_Loading.md`.)_
- [ ] Integrate snapshot-based verification for pattern integration once SwiftUI previews are available on CI runners. (FoundationUI/Tests/FoundationUITests/PatternsIntegrationTests/PatternIntegrationTests.swift)

## FoundationUI Phase 1: Foundation Components (COMPLETE ✅)

- [x] #216 Task I1.1 — Badge & Status Indicators ✅ — Completed 2025-11-14
- [x] #218 Task I1.2 — Card Containers & Sections ✅ — Completed 2025-11-14
- [x] #219 Task I1.3 — Key-Value Rows & Metadata Display ✅ — Completed 2025-11-14
- [x] #220 Task I1.4 — Form Controls & Input Wrappers ✅ — Implementation complete 2025-11-14 (FoundationUI integration deferred to Phase 2)
- [x] #221 Task I1.5 — Advanced Layouts & Navigation ✅ — Completed 2025-11-14 (Phase 1 FINAL TASK)

### Phase 1 Follow-Up Work (Marked with @todo #220 and @todo #I1.5)

- [ ] #220 Replace BoxToggleView placeholder with DS.Toggle from FoundationUI — Import FoundationUI DS.Toggle component, apply design tokens for spacing/colors, add platform-adaptive styling, verify accessibility compliance. (Sources/ISOInspectorApp/UI/Components/BoxToggleView.swift)
- [ ] #220 Replace BoxTextInputView placeholder with DS.TextInput from FoundationUI — Import FoundationUI DS.TextInput component, apply design tokens for padding/corners/shadows, add copyable text support via DS.Copyable, implement platform-adaptive keyboard types, enhance error state styling. (Sources/ISOInspectorApp/UI/Components/BoxTextInputView.swift)
- [ ] #220 Replace BoxPickerView placeholder with DS.Picker from FoundationUI — Import FoundationUI DS.Picker component, apply platform-adaptive styling (macOS: Segmented for ≤4 options, menu for >4; iOS: Segmented for ≤3 options, menu for >3; iPadOS: Follow iOS patterns with size class adaptation), integrate design tokens for spacing and sizing, add enhanced accessibility labels, support for custom option rendering (icons, colors). (Sources/ISOInspectorApp/UI/Components/BoxPickerView.swift)
- [ ] #220 Integrate snapshot testing library for FormControlsSnapshotTests — Add swift-snapshot-testing to Package.swift, replace placeholder XCTest assertions with assertSnapshot(...), generate baseline snapshots for all component variants (light/dark modes, all states). (Tests/ISOInspectorAppTests/FoundationUI/FormControlsSnapshotTests.swift)
- [ ] #220 Integrate Accessibility Inspector APIs for FormControlsAccessibilityTests — Add XCTest accessibility API checks, implement color contrast testing (verify ≥4.5:1 for text, ≥3:1 for UI components), verify VoiceOver announcements programmatically, test Dynamic Type scaling without clipping, confirm Reduce Motion and High Contrast adaptations. (Tests/ISOInspectorAppTests/FoundationUI/FormControlsAccessibilityTests.swift)
- [ ] #220 Complete WCAG 2.1 AA compliance audit for form controls — Run comprehensive accessibility audit using Accessibility Inspector, achieve ≥98% accessibility score target, verify all WCAG 2.1 AA requirements (1.1.1 Non-text Content, 1.3.1 Info and Relationships, 1.4.1 Use of Color, 1.4.3 Contrast, 1.4.4 Resize Text, 2.1.1 Keyboard, 2.4.7 Focus Visible, 3.2.1 On Focus, 3.3.1 Error Identification, 4.1.2 Name Role Value, 4.1.3 Status Messages). (Tests/ISOInspectorAppTests/FoundationUI/FormControlsAccessibilityTests.swift)
- [ ] #I1.5 Complete ParseTreeDetailView migration — Migrate remaining section functions (encryptionSection, userNotesSection, fieldAnnotationSection, validationSection, hexSection) to use DS.Spacing and DS.Radius tokens. (Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift)
- [ ] #I1.5 Consider adding DS.Spacing.xxxs token — Evaluate whether adding `DS.Spacing.xxxs` (2pt) token is justified based on usage frequency in the codebase. (FoundationUI/Sources/FoundationUI/DesignTokens/Spacing.swift)
- [ ] #I1.5 Set up snapshot testing infrastructure — Integrate `swift-snapshot-testing` library and create baseline snapshots for all device sizes and color schemes. (Tests/ISOInspectorAppTests/FoundationUI/LayoutSnapshotTests.swift)

## Performance & Benchmarking

- [ ] Execute the macOS 1 GiB lenient-vs-strict benchmark for Task T5.4 once hardware is available, exporting `ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES=1073741824` before running `swift test --filter LargeFileBenchmarkTests/testCLIValidationLenientModePerformanceStaysWithinToleranceBudget`. (Tests/ISOInspectorPerformanceTests/LargeFileBenchmarkTests.swift) _(Step-by-step checklist lives in `DOCS/INPROGRESS/next_tasks.md`; historical notes archived at `DOCS/TASK_ARCHIVE/207_Summary_of_Work_2025-11-04_macOS_Benchmark_Block/`.)_
- [x] #4 Integrate the `ResearchLogMonitor` audit with SwiftUI previews once VR-006 entries surface in the UI. (Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift) _(Completed — see `DOCS/TASK_ARCHIVE/199_T3_7_Integrity_Sorting_and_Navigation/194_ResearchLogMonitor_SwiftUIPreviews.md`.)_
- [x] #T36 Resolve Integrity navigation filters, outline shortcuts, and issue-only toggle so tolerant parsing hand-offs stay focused. (Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift) _(Completed — see `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/200_T3_7_Integrity_Navigation_Filters.md`.)_
- [x] #T5.2 Land tolerant traversal regression tests that exercise the corrupt fixture corpus and strict-mode guards. (Tests/ISOInspectorKitTests/TolerantTraversalRegressionTests.swift) _(Completed — see `DOCS/TASK_ARCHIVE/203_T5_2_Regression_Tests_for_Tolerant_Traversal/Summary_of_Work.md`.)_
- [x] #T6.2 Surface tolerant-mode corruption summary metrics in the CLI output, including severity counts and deepest affected depth. (Sources/ISOInspectorCLI/Commands/InspectCommand.swift) _(Completed — see `DOCS/TASK_ARCHIVE/208_T6_2_CLI_Corruption_Summary_Output/Summary_of_Work.md`.)_
