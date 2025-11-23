# TODO

## CI/CD & Quality Gates

- [ ] Wire `swift format --in-place` into `.pre-commit-config.yaml` and add a `swift format --mode lint` gate to `.github/workflows/ci.yml` so formatting failures block pushes and pull requests. (Config: `.pre-commit-config.yaml`, `.github/workflows/ci.yml`)
- [ ] Restore SwiftLint complexity thresholds in `.swiftlint.yml` and surface analyzer artifacts from `.github/workflows/swiftlint.yml` when violations occur. (Config: `.swiftlint.yml`, `.github/workflows/swiftlint.yml`) _(Status: In Progress — see `DOCS/INPROGRESS/A7_SwiftLint_Complexity_Thresholds.md` for scope and outstanding refactors.)_

### Task A7 Follow-up: Refactor Large Files (Blocking Strict Mode)

- [ ] #A7 Refactor JSONParseTreeExporter.swift to comply with type_body_length threshold — Extract nested types (Node, Issue, Payload, etc.) into separate files in JSONPayloadTypes/ directory. Currently 2127 lines, target <1200 lines. (Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift)
- [ ] #A7 Refactor BoxValidator.swift to comply with type_body_length threshold — Extract individual validation rules into separate files (one rule per file) in ValidationRules/ directory. Currently 1738 lines, target <1200 lines. (Sources/ISOInspectorKit/Validation/BoxValidator.swift)
- [ ] #A7 Refactor DocumentSessionController to comply with type_body_length threshold — Extract bookmark management, recent files management, and parse pipeline coordination into separate services (BookmarkService, RecentsService, ParseCoordinationService). Currently 1634 lines, target <1200 lines. Remove swiftlint:disable directive. (Sources/ISOInspectorApp/State/DocumentSessionController.swift)
- [ ] #A7 Enable strict mode for main project after refactoring large files — After completing the 3 refactoring tasks above, switch CI to `swiftlint lint --strict` and remove informational mode. Update `.github/workflows/swiftlint.yml` and `.swiftlint.yml`. (`.github/workflows/swiftlint.yml`, `.swiftlint.yml`)

- [ ] Promote `coverage_analysis.py` to a shared quality gate by wiring it into `.githooks/pre-push` and `.github/workflows/ci.yml` after `swift test --enable-code-coverage`. (Scripts: `.githooks/pre-push`, `coverage_analysis.py`, `.github/workflows/ci.yml`)
- [ ] Add DocC + `missing_docs` enforcement to the lint pipeline so public APIs fail CI without documentation coverage, and capture the suppression playbook in `Documentation/ISOInspector.docc/Guides/DocumentationStyle.md`. (Config: `.swiftlint.yml`, `.github/workflows/documentation.yml`)
- [x] Extend `.githooks/pre-push` and `.github/workflows/ci.yml` with `swift build --strict-concurrency=complete`/`swift test --strict-concurrency=complete` runs, publishing logs referenced from `DOCS/AI/PRD_SwiftStrictConcurrency_Store.md`. (Scripts: `.githooks/pre-push`, `.github/workflows/ci.yml`) _(Completed 2025-11-15 — Task A9, archived at `DOCS/TASK_ARCHIVE/225_A9_Swift6_Concurrency_Cleanup/`)_
- [ ] Add `.github/workflows/swift-duplication.yml` that runs `scripts/run_swift_duplication_check.sh` (wrapper around `npx jscpd@3.5.10`) on all Swift targets, fails when duplicates exceed 1% or blocks >45 lines repeat, and uploads a console artifact. (Docs: `DOCS/AI/github-workflows/02_swift_duplication_guard/prd.md` + `TODO.md`)

## FoundationUI Integration

- [ ] Integrate lazy loading and state binding into `InspectorPattern` once detail editors are introduced so scroll performance remains predictable. (FoundationUI/Sources/FoundationUI/Patterns/InspectorPattern.swift) _(Planning archived at `DOCS/TASK_ARCHIVE/204_T6_1_CLI_Tolerant_Flag/204_InspectorPattern_Lazy_Loading.md`.)_
- [ ] Integrate snapshot-based verification for pattern integration once SwiftUI previews are available on CI runners. (FoundationUI/Tests/FoundationUITests/PatternsIntegrationTests/PatternIntegrationTests.swift)

## NavigationSplitView Inspector (Task 243)

- [x] #243 Wire the inspector toggle to a NavigationSplitView/NavigationSplitScaffold-backed three-column layout so ⌘⌥I updates inspector visibility per DOCS/INPROGRESS/243_Reorganize_Navigation_SplitView_Inspector_Panel.md. (Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift)
- [ ] #243 Split Selection Details into dedicated inspector subviews (metadata, corruption, encryption, notes, fields, validation, hex) to keep inspector scrolling predictable in the third column. (Sources/ISOInspectorApp/Inspector/InspectorDetailView.swift)
- [ ] Bug 246: Window width overflows when sidebar + detail + inspector are visible; constrain column widths or avoid simultaneous wide panes. See DOCS/INPROGRESS/246_Bug_NavigationSplit_Width_Overflow.md.

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
  - **Hardware dependency:** Requires access to macOS hardware that can host the 1 GiB benchmark fixture; currently blocked per `DOCS/TASK_ARCHIVE/207_Summary_of_Work_2025-11-04_macOS_Benchmark_Block/blocked.md` until that runner is provisioned.
- [x] #4 Integrate the `ResearchLogMonitor` audit with SwiftUI previews once VR-006 entries surface in the UI. (Sources/ISOInspectorKit/Validation/ResearchLogMonitor.swift) _(Completed — see `DOCS/TASK_ARCHIVE/199_T3_7_Integrity_Sorting_and_Navigation/194_ResearchLogMonitor_SwiftUIPreviews.md`.)_
- [x] #T36 Resolve Integrity navigation filters, outline shortcuts, and issue-only toggle so tolerant parsing hand-offs stay focused. (Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift) _(Completed — see `DOCS/TASK_ARCHIVE/200_T3_7_Integrity_Navigation_Filters/200_T3_7_Integrity_Navigation_Filters.md`.)_
- [x] #T5.2 Land tolerant traversal regression tests that exercise the corrupt fixture corpus and strict-mode guards. (Tests/ISOInspectorKitTests/TolerantTraversalRegressionTests.swift) _(Completed — see `DOCS/TASK_ARCHIVE/203_T5_2_Regression_Tests_for_Tolerant_Traversal/Summary_of_Work.md`.)_
- [x] #T6.2 Surface tolerant-mode corruption summary metrics in the CLI output, including severity counts and deepest affected depth. (Sources/ISOInspectorCLI/Commands/InspectCommand.swift) _(Completed — see `DOCS/TASK_ARCHIVE/208_T6_2_CLI_Corruption_Summary_Output/Summary_of_Work.md`.)_

## Task C22 — User Settings Panel: Persistence + Reset Wiring (Completed 2025-11-15)

**Status:** ✅ **COMPLETED** (5/7 puzzles fully implemented, 2/7 deferred with @todo markers)

### ViewModel Integration & Data Layer ✅

- [x] #222 Load actual permanent settings from UserPreferencesStore (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:31) _Completed — C22_
- [x] #222 Load actual session settings from DocumentSessionController (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:32) _Completed — C22_
- [x] #222 Call UserPreferencesStore.reset() to clear permanent settings (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:48) _Completed — C22_
- [x] #222 Reload permanent settings after reset (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:49) _Completed — C22_
- [x] #222 Add resetSessionSettings() method (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:56) _Completed — C22_
- [x] #222 Add updatePermanentSetting(key:value:) method (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:57) _Completed — C22_
- [x] #222 Add updateSessionSetting(key:value:) method (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:58) _Completed — C22_

### Data Model Extensions ✅

- [x] #222 Add validation configuration properties to PermanentSettings (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:64) _Completed — C22_
- [x] #222 Add telemetry/logging verbosity properties to PermanentSettings (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:65) _Completed — C22_
- [x] #222 Add accessibility preferences to PermanentSettings (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:66) _Completed — C22_
- [x] #222 Add workspace scope properties to SessionSettings (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:74) _Completed — C22_
- [x] #222 Add pane layout properties to SessionSettings (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:75) _Completed — C22_
- [x] #222 Add temporary validation overrides to SessionSettings (Sources/ISOInspectorApp/UI/ViewModels/SettingsPanelViewModel.swift:76) _Completed — C22_

### UI Controls & Presentation ✅

- [x] #222 Add validation preset controls to permanent settings section (Sources/ISOInspectorApp/UI/Components/SettingsPanelView.swift:93) _Completed — C22_
- [x] #222 Add telemetry/logging verbosity controls to permanent settings section (Sources/ISOInspectorApp/UI/Components/SettingsPanelView.swift:94) _Completed — C22_
- [x] #222 Add workspace scope controls to session settings section (Sources/ISOInspectorApp/UI/Components/SettingsPanelView.swift:126) _Completed — C22_
- [x] #222 Add pane layout controls to session settings section (Sources/ISOInspectorApp/UI/Components/SettingsPanelView.swift:127) _Completed — C22_
- [x] #222 Add advanced configuration controls to advanced settings section (Sources/ISOInspectorApp/UI/Components/SettingsPanelView.swift:152) _Completed — C22_

### Platform-Specific Enhancements ⏳ (Partial — Deferred)

- [ ] #222 Add detent support for iPad (.medium, .large) (Sources/ISOInspectorApp/UI/Scenes/SettingsPanelScene.swift:86) _Deferred — marked with @todo #222 for future work_
- [ ] #222 Add fullScreenCover for iPhone (Sources/ISOInspectorApp/UI/Scenes/SettingsPanelScene.swift:87) _Deferred — marked with @todo #222 for future work_

### Testing & Accessibility ⏳ (Partial — Deferred)

- [x] #222 Add validation preset control IDs to SettingsPanelAccessibilityID (Sources/ISOInspectorApp/Accessibility/SettingsPanelAccessibilityID.swift:50) _Completed — C22_
- [x] #222 Add telemetry/logging control IDs to SettingsPanelAccessibilityID (Sources/ISOInspectorApp/Accessibility/SettingsPanelAccessibilityID.swift:51) _Completed — C22_
- [x] #222 Add workspace scope control IDs to SettingsPanelAccessibilityID (Sources/ISOInspectorApp/Accessibility/SettingsPanelAccessibilityID.swift:63) _Completed — C22_
- [x] #222 Add pane layout control IDs to SettingsPanelAccessibilityID (Sources/ISOInspectorApp/Accessibility/SettingsPanelAccessibilityID.swift:64) _Completed — C22_
- [x] #222 Add advanced configuration control IDs to SettingsPanelAccessibilityID (Sources/ISOInspectorApp/Accessibility/SettingsPanelAccessibilityID.swift:75) _Completed — C22_
- [ ] #222 Migrate to proper XCUITest UI tests for full accessibility validation (Tests/ISOInspectorAppTests/UI/SettingsPanelAccessibilityTests.swift:12) _Deferred — marked with @todo #222 for future work_
- [ ] #222 Test VoiceOver focus order starts on first control (Tests/ISOInspectorAppTests/UI/SettingsPanelAccessibilityTests.swift:13) _Deferred — marked with @todo #222 for future work_
- [ ] #222 Test keyboard navigation between sections (Tests/ISOInspectorAppTests/UI/SettingsPanelAccessibilityTests.swift:14) _Deferred — marked with @todo #222 for future work_
- [ ] #222 Test Dynamic Type support (Tests/ISOInspectorAppTests/UI/SettingsPanelAccessibilityTests.swift:15) _Deferred — marked with @todo #222 for future work_
- [ ] #222 Verify platform-specific accessibility identifiers (Tests/ISOInspectorAppTests/UI/SettingsPanelAccessibilityTests.swift:26) _Deferred — marked with @todo #222 for future work_
- [ ] #222 Test keyboard shortcut (⌘,) on macOS (Tests/ISOInspectorAppTests/UI/SettingsPanelAccessibilityTests.swift:27) _Deferred — marked with @todo #222 for future work_
- [ ] #222 Test VoiceOver announcements for state changes (Tests/ISOInspectorAppTests/UI/SettingsPanelAccessibilityTests.swift:28) _Deferred — marked with @todo #222 for future work_
- [ ] #222 Add proper state change tests with XCTest expectations (Tests/ISOInspectorAppTests/UI/SettingsPanelAccessibilityTests.swift:42) _Deferred — marked with @todo #222 for future work_
- [ ] #222 Test error message announcements for screen readers (Tests/ISOInspectorAppTests/UI/SettingsPanelAccessibilityTests.swift:43) _Deferred — marked with @todo #222 for future work_

### Summary

See detailed completion report in: `DOCS/TASK_ARCHIVE/223_C22_User_Settings_Persistence_and_Reset/Summary_of_Work.md`
