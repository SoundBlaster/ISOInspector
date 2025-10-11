# PRD: NestedA11yIDs Integration for App Target UI Testability

## 1. Purpose
Introduce the [NestedA11yIDs](https://github.com/SoundBlaster/NestedA11yIDs) Swift Package into the ISOInspector App target to standardize hierarchical accessibility identifiers across SwiftUI views, enabling deterministic UI test selectors and reducing maintenance overhead for future automation.

## 2. Scope
**Included**
- Evaluate compatibility of NestedA11yIDs with the current Swift toolchain and App target build settings.
- Add the package dependency via Swift Package Manager and link it to the App target only (no command-line or library targets).
- Document integration steps, coding conventions, and usage patterns for view developers and test authors.
- Provide initial adoption guidelines for existing SwiftUI views to establish baseline accessibility identifier coverage.
- Define validation steps to guarantee UI tests can query identifiers composed by the package.

**Excluded / Future Work**
- Refactoring all existing views to use NestedA11yIDs (provide roadmap only).
- Creating or updating UI test suites beyond smoke verification of identifier availability.
- Supporting UIKit-specific accessibility wrappers (SwiftUI-only for this scope).
- Android, web, or other non-Apple platform considerations.

## 3. Constraints & Assumptions
- Swift toolchain version must match the current repository baseline (as defined in `Package.resolved`).
- Repository continues to build via Swift Package Manager; Xcode-specific project files are generated from SPM manifest.
- Accessibility identifiers must remain stable across locales and dynamic content updates.
- Package license (MIT) is acceptable for project inclusion.

## 4. Deliverables
| ID | Deliverable | Description | Acceptance Criteria |
|----|-------------|-------------|---------------------|
| D1 | SPM Dependency Update | Update `Package.swift` and `Package.resolved` to include `NestedA11yIDs` (>= 1.0.0) and link to App target. | `swift build` succeeds; dependency resolved in lockfile. |
| D2 | Integration Guide | Markdown documentation outlining configuration, usage patterns, and examples for developers/testers. | Guide stored in `Docs` hierarchy, peer-reviewed for clarity. |
| D3 | Baseline Adoption Plan | Checklist of high-priority views to migrate, with owner and timeline recommendations. | Plan published within PRD and referenced by execution teams. |
| D4 | Verification Script Updates | Extend existing UI test harness or add a lightweight SwiftUI preview/test stub verifying identifier exposure. | Automated check passes in CI or documented manual procedure. |

## 5. Implementation Plan & TODO Breakdown
| Task ID | Description | Priority | Effort | Owner | Dependencies | Acceptance Criteria |
|---------|-------------|----------|--------|-------|--------------|---------------------|
| T1 | Review NestedA11yIDs release notes and confirm Swift version compatibility. | High | 1 | iOS Platform Lead | None | Document compatibility findings in PR. |
| T2 | Add `.package(url: "https://github.com/SoundBlaster/NestedA11yIDs.git", from: "1.0.0")` to `Package.swift` dependencies and reference in App target. | High | 2 | Build Engineer | T1 | `swift build --target ISOInspectorApp` succeeds without warnings. |
| T3 | Run `swift package resolve` to update `Package.resolved` and commit new checksum entries. | High | 1 | Build Engineer | T2 | Lockfile includes NestedA11yIDs with resolved version. |
| T4 | Update App target source configuration (e.g., `Sources/ISOInspectorApp/App.swift`) to import NestedA11yIDs and demonstrate root identifier usage in at least one representative view. | Medium | 3 | UI Engineer | T2 | Selected view renders with `.a11yRoot("...")` and nested identifiers applied. |
| T5 | Draft integration guidelines (coding standards, naming conventions, migration checklist) in `DOCS/AI` or `Docs/Architecture`. | High | 2 | Documentation Owner | T4 | Document reviewed by QA and UI leads. |
| T6 | Provide sample UI test snippet (XCUI) verifying composed identifiers. | Medium | 2 | QA Engineer | T4 | Snippet executes in UI test target or documented as part of test plan. |
| T7 | Update CI documentation to mention new dependency and build step adjustments if any. | Low | 1 | DevOps | T3 | CI checklist acknowledges dependency and caching requirements. |
| T8 | Track follow-up migration tasks for remaining views (backlog creation). | Medium | 1 | Product Analyst | T5 | Backlog items logged with priority and estimates. |

_Effort unit legend: 1 = ~0.5 day, 2 = 1 day, 3 = 1.5 days, 5 = 2+ days._

## 6. Functional Requirements
1. The App target must link NestedA11yIDs without affecting other targets.
2. SwiftUI views that adopt NestedA11yIDs must expose accessibility identifiers following the pattern `<root>.<child>[.<grandchild>...]`.
3. `.a11yRoot()` modifiers must automatically enforce `.accessibilityElement(children: .contain)` on containers.
4. Integration must not introduce duplicate accessibility identifiers when combined with existing `.accessibilityIdentifier` usage (fallback required).
5. Build tooling (SPM, CI) must resolve the package without manual interventions.

## 7. Non-Functional Requirements
- **Performance:** Identifier composition should not introduce perceivable latency (<1 ms per view render) or additional allocations beyond library defaults.
- **Maintainability:** Documentation must specify naming conventions and code review checklist items to prevent regressions.
- **Testability:** UI test selectors must remain stable across runs; guidelines include strategies for dynamic lists and localization.
- **Compliance:** Accessibility identifiers must remain human-readable and respect Apple's accessibility best practices.

## 8. Developer Workflow & Usage Flow
1. Developer imports NestedA11yIDs in target SwiftUI file.
2. Assign `.a11yRoot("feature")` at the container level (e.g., screen root view).
3. Apply `.nestedAccessibilityIdentifier("component")` to child views.
4. Run `swift build` or open the project in Xcode; ensure dependency downloads automatically.
5. QA author uses identifiers like `feature.component` in `XCUIApplication()` UI tests for interaction.

## 9. Edge Cases & Failure Scenarios
- **Dynamic Lists:** Items generated with `ForEach` require stable keys to avoid identifier collisions. Document patterns for deterministic child IDs.
- **Conditional Views:** Ensure identifiers remain consistent when views are shown/hidden; propose using placeholder identifiers or default states.
- **Legacy `.accessibilityIdentifier` Usage:** Provide migration guidance to avoid double identifiers or mismatched naming.
- **Localization Impact:** Root and child strings must avoid localized text; use fixed English slugs documented in coding standards.

## 10. Testing & Validation Strategy
- **Build Verification:** `swift build --target ISOInspectorApp` and `swift test` must pass locally and in CI after integration.
- **UI Smoke Test:** Add or update a UI test to assert existence of `XCUIElement` using the new hierarchical identifier pattern.
- **Static Analysis:** Run `swiftlint` (if configured) or custom lint rules to ensure `.nestedAccessibilityIdentifier` is used where required.
- **Documentation Review:** Cross-functional review involving UI, QA, and Accessibility leads before publishing.

## 11. Rollout Plan
1. Merge dependency and documentation updates.
2. Pilot adoption on one high-traffic screen; monitor QA feedback.
3. Gradually migrate remaining screens following backlog created in T8.
4. Update automated UI tests incrementally to leverage new identifiers.

## 12. Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Package introduces binary incompatibility with minimum iOS version. | Low | High | Validate deployment target; pin version `1.0.x`; monitor upstream releases. |
| Developers forget to set `.a11yRoot` leading to flat identifiers. | Medium | Medium | Add linting tip and code review checklist to documentation. |
| UI tests rely on localized text despite new identifiers. | Medium | Medium | Provide migration guide and sample selectors; enforce through QA review. |
| Dependency download failure in CI due to network limits. | Low | Medium | Cache SPM dependencies; document manual mirror setup. |

## 13. Acceptance Criteria Summary
- App target builds successfully with NestedA11yIDs dependency on supported platforms.
- At least one representative SwiftUI screen demonstrates nested accessibility identifiers and passes QA smoke test.
- Documentation and TODO backlog are published, reviewed, and linked within repository docs.
- CI pipeline remains green with updated dependencies and tests.

## 14. Open Questions
- Should the dependency also be exposed to preview/test helper targets for snapshot testing?
- Do we need a custom lint rule to enforce `.a11yRoot` usage on every top-level screen?
- Are there analytics or logging impacts when altering accessibility identifiers that require coordination with telemetry teams?

## 15. Integration Status — 2025-10-11
- **Compatibility review:** NestedA11yIDs 1.0.0 builds cleanly with Swift 6.0 toolchain used by ISOInspector.
- **App wiring:** `ISOInspectorApp` applies `.a11yRoot(parseTree)` at the window root and propagates nested identifiers through `ParseTreeExplorerView`, outline filters, and detail panels.
- **Testing:** Added `ParseTreeAccessibilityIdentifierTests` that host the explorer view and assert composed identifiers (root + search field) resolve.
- **Documentation:** See `Docs/Guides/NestedA11yIDsIntegration.md` for usage conventions, naming, and testing tips.

### Baseline Adoption Plan
| View / Feature | Owner | Identifier Scope | Target Release |
| --- | --- | --- | --- |
| Parse tree explorer outline + detail | App Core | Complete (`parseTree` hierarchy) | R12 |
| Research log preview flows | QA Tools | Root + research log list | R13 |
| Annotation editors (notes list + editor) | App Core | Bookmark + notes actions | R13 |
| Future inspectors (timeline/payload analyzers) | Product UX | TBD | Roadmap |
