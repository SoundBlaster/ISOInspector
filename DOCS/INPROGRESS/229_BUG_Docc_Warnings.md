# 229 · DocC Warning Storm During ISOInspector Documentation Build

## Objective
Eliminate the DocC and Swift compilation warnings emitted while building ISOInspector documentation so the doc archive can be generated cleanly and the documentation site preserves credibility for downstream reviewers.

## Symptoms
- `docc convert` for `ISOInspectorKit`, `FoundationUI`, and `ISOInspectorApp-macOS` spews dozens of warnings about unresolved symbol links (`'BadgeChipStyle' doesn't exist`, `'Utilities' is ambiguous`, etc.).
- Swift compile phase for `ISOInspectorApp-macOS` warns that `@ViewBuilder` blocks in `SettingsPanelView` are disabled because of explicit `return` statements.
- Tutorials such as `AnnotationAndBookmarkWalkthrough.tutorial` emit syntax warnings (`Unknown argument 'title' in Step`).
- Downstream packages (Yams, NestedA11yIDs) also emit warnings, inflating the overall noise floor and making it difficult to spot project-owned issues.

## Environment
- Repository: ISOInspector @ `/Users/egor/Development/GitHub/ISOInspector`
- Tooling: Xcode 16 beta? (log references `XcodeDefault.xctoolchain`, macOS 14+, Swift 5.9+ target)
- Command producing log: Xcode Product ▸ Build Documentation (generates `Build Documentation ISOInspectorApp-macOS_2025-11-16T16-20-27.txt`).
- Targets impacted: `ISOInspectorKit`, `FoundationUI`, `ISOInspectorApp-macOS`, plus dependent packages.

## Reproduction Steps
1. Clean Derived Data (`rm -rf ~/Library/Developer/Xcode/DerivedData/ISOInspector-*`).
2. In repo root, run `xcodebuild -scheme ISOInspectorApp-macOS -destination 'platform=macOS' docbuild` **or** trigger Product ▸ Build Documentation inside Xcode.
3. Observe warnings identical to those captured in `DOCS/INPROGRESS/Build Documentation ISOInspectorApp-macOS_2025-11-16T16-20-27.txt`.

## Expected vs. Actual
- **Expected:** DocC build completes with zero warnings for project-owned modules; documentation articles link only to valid symbols and tutorials render cleanly.
- **Actual:** DocC build finishes but emits >100 warnings because docs reference non-existent or private symbols, `@ViewBuilder` patterns are misapplied, and tutorial directives include unsupported arguments.

## Open Questions
1. Should DocC warnings inside third-party SourcePackages (Yams, NestedA11yIDs) be suppressed separately, or is the priority limited to ISOInspector/ FoundationUI modules?
2. Is there a hard requirement to keep the existing doc taxonomy (`## Topics` near the top), or can it be relocated to satisfy DocC formatting rules?
3. Are we okay renaming/modifying exposed APIs (e.g., publishing `BadgeChipStyle` as a `ViewModifier`) to align documentation with actual types?

---

## Scope & Hypotheses
- **Front of Work:** FoundationUI documentation bundle + ISOInspectorKit doc comments + ISOInspectorApp UI components.
- **Likely Touchpoints:**
  - `FoundationUI/Sources/FoundationUI/Documentation.docc/FoundationUI.md`
  - `FoundationUI/Sources/FoundationUI/Documentation.docc/Articles/*.md`
  - `FoundationUI/Sources/FoundationUI/Modifiers/{BadgeChipStyle,CardStyle,InteractiveStyle,SurfaceStyle}.swift`
  - `FoundationUI/Sources/FoundationUI/Utilities/KeyboardShortcuts.swift`
  - `ISOInspector/Sources/ISOInspectorKit/ISO/BoxNode.swift`
  - `ISOInspector/Sources/ISOInspectorApp/UI/Components/SettingsPanelView.swift`
  - `ISOInspector/Sources/ISOInspectorApp/ISOInspectorApp.docc/Tutorials/AnnotationAndBookmarkWalkthrough.tutorial`
- **Initial Hypotheses:**
  1. Doc articles reference symbol names (`BadgeChipStyle`, `CardStyle`, `KeyboardShortcuts`) that are not public symbols; making those modifiers public or adjusting docs to reference actual APIs will eliminate the majority of DocC warnings.
  2. The `## Topics` section in `FoundationUI.md` is followed by general narrative content, causing DocC to treat regular bullet lists as task-group entries and emit “Only links are allowed” warnings; moving canonical content outside `## Topics` will fix this.
  3. `SettingsPanelView` mixes `@ViewBuilder` with explicit `return AnyView(...)`; rewriting the view builder in idiomatic SwiftUI removes the compiler warnings that bleed into the doc build output.
  4. Tutorial Steps use unsupported arguments (e.g., `Step(title:)`) introduced by older DocC drafts; removing or replacing them with supported metadata resolves the tutorial warning.

## Diagnostics Plan
- Parse the captured log and categorize warnings by source file to prioritize project-owned fixes.
- Inspect FoundationUI doc files to ensure every symbol link corresponds to an actual exported symbol; adjust doc markup or publish missing types accordingly.
- Review `SettingsPanelView`’s `@ViewBuilder` blocks and simplify them into pure view builders without explicit returns or `AnyView` wrapping.
- Audit tutorials for unsupported Step arguments.
- After fixes, rerun `xcodebuild -scheme ISOInspectorApp-macOS -destination 'platform=macOS' docbuild` (or a scoped `docc convert`) to confirm the warnings vanish.

## TDD / Testing Plan
1. **Doc Build Test:** `xcodebuild -scheme ISOInspectorApp-macOS -destination 'platform=macOS' docbuild` — ensures DocC archive generation is warning-free.
2. **Targeted Swift Build:** `xcodebuild -scheme ISOInspectorKit -destination 'generic/platform=macOS' build` — validates BoxNode doc comments compile cleanly.
3. **SwiftUI Lint:** `swift build` for FoundationUI package if a lighter sanity check is needed after modifier changes.
4. **Optional Snapshot:** Run FoundationUI previews/tests only if doc build still reports issues to isolate regressions.

## PRD / Acceptance Notes
- Customer Impact: Documentation consumers (internal + external) rely on warning-free builds for trust and CI gating; repeated warnings block adoption of FoundationUI as a polished design system.
- Acceptance Criteria:
  1. DocC build completes without warnings originating from ISOInspector repositories (FoundationUI, ISOInspectorKit, ISOInspectorApp).
  2. Tutorials validate without syntax warnings.
  3. Compiler warnings tied to `@ViewBuilder` misuse are eliminated.
  4. External package warnings are documented (if unavoidable) so CI filters know what remains.
- Technical Approach: Align documentation symbol links with actual API surface (either by exporting the documented types or updating docs), enforce idiomatic SwiftUI builder usage, and rerun doc builds as regression tests per TDD workflow.

## Work Log & Notes
- _2025-11-16_: Captured original warning log (`Build Documentation ISOInspectorApp-macOS_2025-11-16T16-20-27.txt`).
- _2025-11-17_: Formalized bug report, scoped impacted files, and drafted diagnostics/TDD plan (this document).

## Fix Execution
- Exported all FoundationUI modifiers that documentation referenced (BadgeChipStyle, CardStyle, InteractiveStyle, SurfaceStyle) and reworded cross-target doc links to avoid unresolved symbol warnings.
- Rebuilt `FoundationUI.md` topics/structure, renamed the Utilities article to `UtilitiesCatalog`, and trimmed `See Also` lists so DocC no longer flags nonexistent references.
- Modernized ISOInspectorApp documentation (tutorial steps now use DocC-supported directives, added a table-of-contents with a bundle image, and removed invalid cross-module symbol links).
- Fixed the SwiftUI result-builder warning in `SettingsPanelView`, clarified the `BoxNode` Sendable mention, and filled the missing `modelVersion` parameter docs in `CoreDataAnnotationBookmarkStore`.

## Validation
- `xcodebuild -workspace ISOInspector.xcworkspace -scheme ISOInspectorApp-macOS -destination 'platform=macOS' docbuild` (succeeds; residual DocC warnings described below).

## Remaining Risks / Follow-ups
- DocC still reports 70+ warnings that originate from existing checklist-style sections inside long-form articles (e.g., `Articles/GettingStarted.md`, `Articles/PlatformAdaptation.md`). DocC interprets those checklists as task groups and insists on pure link lists; resolving them would require rewriting each article into tutorial/task-group form.
- The new tutorial table-of-contents uses a placeholder 1×1 PNG; consider replacing it with an actual product screenshot to avoid future branding issues.
