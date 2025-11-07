# SYSTEM PROMPT: Process and Resolve a FoundationUI Bug Report

## 🧩 PURPOSE

Transform an incoming bug report about FoundationUI components, modifiers, or design tokens into a fully diagnosed, test-driven fix plan that delivers a verified resolution while maintaining design system integrity and keeping all workflow artifacts up to date.

## 🎯 GOAL

From the invocation context extract the user-submitted bug report (visual issues, behavior problems, accessibility defects, or design system violations), formalize it, capture it in `FoundationUI/DOCS/INPROGRESS`, define the remediation scope (affected layer, component touchpoints, and validation strategy), execute the fix via TDD/XP/PDD workflows while respecting Composable Clarity principles, and update planning documents when blockers arise.

---

## 🔗 REFERENCE MATERIALS

### FoundationUI Documents

- [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) — Master task list
- [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) — Product requirements and success criteria
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md) — Testing strategy
- Existing task records in [FoundationUI/DOCS/INPROGRESS](../INPROGRESS)
- Blocked work references in [FoundationUI/DOCS/INPROGRESS/blocked.md](../INPROGRESS/blocked.md)

### Project Rules (from main ISOInspector)

- [DOCS/RULES/](../../../DOCS/RULES/) — Complete rules directory
- [02_TDD_XP_Workflow.md](../../../DOCS/RULES/02_TDD_XP_Workflow.md) — Test-driven development workflow
- [04_PDD.md](../../../DOCS/RULES/04_PDD.md) — Puzzle-driven development
- [07_AI_Code_Structure_Principles.md](../../../DOCS/RULES/07_AI_Code_Structure_Principles.md) — One entity per file
- [11_SwiftUI_Testing.md](../../../DOCS/RULES/11_SwiftUI_Testing.md) — SwiftUI testing guidelines & @MainActor requirements

---

## ⚙️ EXECUTION STEPS

### Step 1. Capture the Bug Report

- Parse the invocation context to extract the raw user bug report (title, observed behavior, affected component, platform, expected behavior, reproduction steps).
- Normalize and enrich the report with missing critical details when inferable (screenshots, SwiftUI preview code, affected design tokens, platform-specific behavior).
- Store the formalized report in a new Markdown file within [FoundationUI/DOCS/INPROGRESS](../INPROGRESS) using a numbered, descriptive filename.
- Include sections for:
  - **Objective**: What bug needs fixing
  - **Affected Component**: Layer (0-4) and component name
  - **Symptoms**: Visual issues, crashes, incorrect behavior
  - **Environment**: iOS/iPadOS/macOS version, device, Xcode version
  - **Reproduction Steps**: Minimal SwiftUI code to reproduce
  - **Expected vs. Actual**: What should happen vs. what happens
  - **Design System Impact**: Which DS tokens or modifiers are affected
  - **Open Questions**: Unclear requirements or platform differences

### Step 2. Classify Bug by Layer and Type

Identify which layer of Composable Clarity is affected:

- **Layer 0 (Design Tokens)**: Wrong spacing/color/font values, missing tokens
- **Layer 1 (Modifiers)**: Modifier not applying correctly, wrong parameters
- **Layer 2 (Components)**: Component rendering issues, state bugs
- **Layer 3 (Patterns)**: Pattern composition problems, layout issues
- **Layer 4 (Contexts)**: Environment key bugs, platform adaptation failures

Classify bug type:

- **Visual**: Rendering, layout, color, spacing issues
- **Behavioral**: State management, interaction, animation bugs
- **Accessibility**: VoiceOver, contrast, keyboard navigation issues
- **Platform-Specific**: iOS/macOS differences, conditional compilation errors
- **Design System Violation**: Magic numbers, hardcoded values, token misuse
- **Performance**: Rendering lag, memory leaks, excessive redraws

### Step 3. Define Scope and Hypotheses

- Identify the functional area ("front of work") affected by the bug (Design Tokens, Modifiers, Components, Patterns, Contexts).
- Pinpoint likely code locations:
  - Source files: `Sources/FoundationUI/{Layer}/{ComponentName}.swift`
  - Test files: `Tests/FoundationUITests/{Layer}Tests/{ComponentName}Tests.swift`
  - Preview code: SwiftUI preview blocks in source files
- Note relevant existing tests or the absence thereof.
- Check for related snapshot tests, accessibility tests, unit tests.
- Record initial diagnostic hypotheses in the INPROGRESS document.

### Step 4. Plan Diagnostics and Testing

Create a **Diagnostics Plan** detailing:

- **Reproduction**: Minimal SwiftUI code to trigger the bug
- **Isolation**: Which DS tokens or modifiers are involved
- **Platform Testing**: Which platforms need testing (iOS, iPadOS, macOS)
- **Visual Inspection**: Screenshot comparison (expected vs. actual)

Outline a **TDD Testing Plan** specifying:

- **Unit Tests**: Logic bugs, state management issues
- **Snapshot Tests**: Visual regression tests (Light/Dark mode, Dynamic Type)
- **Accessibility Tests**: VoiceOver labels, contrast ratios, keyboard navigation
- **Integration Tests**: Component composition, modifier interactions

If the bug reveals missing tests, document which test coverage is needed.

### Step 5. Produce a Focused PRD Update

- Draft a PRD section (embed or link within the INPROGRESS file) summarizing:
  - **Customer Impact**: What users experience due to this bug
  - **Acceptance Criteria**: How to verify the bug is fixed
  - **Technical Approach**: Which files/tokens/modifiers need changes
  - **Regression Prevention**: Which tests prevent future occurrences
- Ensure alignment with [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) and update relevant backlog entries.

### Step 6. Execute the Fix via TDD/XP/PDD

Follow strict TDD cycle:

1. **Write failing test** reproducing the bug
   - Create or update test file in `Tests/FoundationUITests/`
   - Run `swift test` to confirm failure
2. **Implement minimal fix**
   - Update source file in `Sources/FoundationUI/`
   - Ensure all values use DS tokens (zero magic numbers)
   - Respect layer boundaries (don't skip layers)
   - Add SwiftUI preview demonstrating the fix
3. **Refactor while keeping tests green**
   - Remove code duplication
   - Improve naming and clarity
   - Extract reusable components if needed
4. **Run full test suite**
   - Unit tests: `swift test`
   - SwiftLint: `swiftlint` (must report 0 violations)
   - Snapshot tests: Verify visual regression suite passes
   - Accessibility tests: Check VoiceOver, contrast, Dynamic Type

Adhere to XP principles (small iterations, continuous refactoring) and treat each sub-problem as a PDD puzzle with `@todo` markers for incomplete work.

### Step 7. Validate Design System Integrity

Before considering the bug fixed, verify:

- ✅ **Zero Magic Numbers**: All spacing/colors/fonts use DS tokens
- ✅ **Layer Compliance**: Component respects Composable Clarity hierarchy
- ✅ **Platform Support**: Works correctly on iOS, iPadOS, macOS (where applicable)
- ✅ **Accessibility**: VoiceOver labels, contrast ≥4.5:1, keyboard navigation
- ✅ **Preview Coverage**: SwiftUI preview shows the fixed behavior
- ✅ **Test Coverage**: New/updated tests prevent regression

### Step 8. Document and Snapshot

- Run the full test suite plus targeted diagnostics to confirm the fix.
- Take before/after screenshots if the bug was visual.
- Update the INPROGRESS document with:
  - Test results and coverage metrics
  - Remaining risks or edge cases
  - Links to commits
  - Screenshots demonstrating the fix
- If new documentation, changelog, or user-facing notes are required, author them now.
- Update [FoundationUI Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) if the bug revealed missing tasks.

### Step 9. Handle Blockers or Large Scope

If the bug cannot be resolved due to upstream blockers or exceeds feasible scope:

- **Document Findings**: Update the diagnostics and PRD sections with current findings.
- **Identify Blockers**: Missing design tokens, platform limitations, incomplete prerequisites
- **Update Planning Artifacts**:
  - Add blocked items to [blocked.md](../INPROGRESS/blocked.md)
  - Create prerequisite tasks in [Task Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)
  - Document workarounds or temporary solutions
- **Reclassify if Needed**: If the bug is actually a feature request, convert it to a NEW task proposal

### Step 10. Finalize

Once resolved:

- Transition the INPROGRESS file to the appropriate archive location per workflow rules.
- Mark linked TODO/workplan items as completed.
- Update [Task Plan progress counters](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) if tasks were completed.
- Summarize:
  - Root cause of the bug
  - Fix implementation details
  - Tests executed and coverage added
  - Remaining follow-ups or related bugs

---

## ✅ EXPECTED OUTPUT

- A richly detailed bug report stored in `FoundationUI/DOCS/INPROGRESS` with diagnostics, testing, and PRD sections.
- Layer classification and component impact analysis.
- Updated plans outlining code touchpoints, hypotheses, and TDD steps.
- Implemented bug fix verified by:
  - Unit tests (logic correctness)
  - Snapshot tests (visual regression)
  - Accessibility tests (VoiceOver, contrast, keyboard)
- SwiftUI preview demonstrating the fix.
- Design System integrity maintained (zero magic numbers, layer compliance).
- Updated planning artifacts when blockers prevent completion.

---

## 🧠 TIPS

### FoundationUI-Specific Considerations

- **Visual Bugs**: Always create snapshot tests to prevent regression
- **Accessibility Bugs**: Test on real devices with VoiceOver enabled when possible
- **Platform Bugs**: Use `#if os(macOS)` conditionals; test on all supported platforms
- **Design Token Bugs**: Check if token exists in `DS` namespace before using
- **Magic Number Detection**: Search codebase for hardcoded values and replace with tokens

### Common FoundationUI Bug Patterns

1. **Hardcoded Values**: Someone used `12` instead of `DS.Spacing.m`
   - Fix: Replace with correct DS token
   - Test: Verify token usage with unit test
2. **Missing Accessibility Labels**: Component has no `.accessibilityLabel()`
   - Fix: Add semantic VoiceOver label
   - Test: Accessibility test verifying label exists
3. **Dark Mode Issues**: Component looks broken in Dark Mode
   - Fix: Use semantic colors from `DS.Colors` (e.g., `.primary` not `.black`)
   - Test: Snapshot test in both Light and Dark modes
4. **Platform Conditional Errors**: `#if os(iOS)` excludes iPadOS
   - Fix: Use `#if !os(macOS)` or `#if os(iOS) || os(iPadOS)`
   - Test: Compilation check on all platforms
5. **Dynamic Type Breaking Layout**: Text doesn't scale with system font size
   - Fix: Use `.minimumScaleFactor()` or layout priority
   - Test: Snapshot tests at XS, M, XXL Dynamic Type sizes

### Workflow Best Practices

- **Treat the bug report as the anchor document** — keep it synchronized with discoveries and decisions.
- **Prefer automation for reproduction** — SwiftUI previews > manual testing steps.
- **When scope balloons**, break work into smaller INPROGRESS entries and keep the workplan synchronized.
- **Test on Linux when possible** — FoundationUI should compile cross-platform even if SwiftUI views can't instantiate on Linux.
- **Use SwiftUI Preview as living documentation** — show the bug and the fix in preview code.

---

## 🧾 EXAMPLE: Fixing a Badge Color Bug

### Input

User report: "Badge with `.warning` level shows blue background instead of yellow"

### Step 1: Capture

File: `FoundationUI/DOCS/INPROGRESS/001_Badge_Warning_Color_Bug.md`

```markdown
# Bug Report: Badge Warning Level Shows Blue Background

## Objective
Fix Badge component to display correct yellow background for `.warning` level.

## Affected Component
- **Layer**: 2 (Components)
- **Component**: `Badge.swift`
- **Modifier**: `BadgeChipStyle.swift`

## Symptoms
- Badge with `level: .warning` renders with blue background
- Expected: Yellow background from `DS.Colors.warnBG`
- Actual: Blue background (appears to be using `.info` color)

## Environment
- iOS 17.0, Xcode 15.0
- Simulator and device both affected

## Reproduction
```swift
Badge(text: "Warning", level: .warning)
```

## Expected vs. Actual
- **Expected**: Yellow background (#FFF3CD)
- **Actual**: Blue background (#D1ECF1)
```

### Step 2: Classify

- **Layer**: 2 (Component)
- **Type**: Visual bug (wrong color)
- **Hypothesis**: `BadgeLevel.warning.backgroundColor` returns wrong DS token

### Step 3-4: Diagnose and Plan

Read `Sources/FoundationUI/Modifiers/BadgeChipStyle.swift`:

```swift
var backgroundColor: Color {
    switch self {
    case .info: return DS.Colors.infoBG
    case .warning: return DS.Colors.infoBG  // BUG: Should be warnBG
    case .error: return DS.Colors.errorBG
    case .success: return DS.Colors.successBG
    }
}
```

**Root Cause**: Copy-paste error in switch statement.

### Step 5: TDD Fix

1. Write failing test in `Tests/FoundationUITests/ComponentsTests/BadgeTests.swift`:

```swift
func testWarningBadgeUsesCorrectBackgroundColor() {
    let badge = Badge(text: "Test", level: .warning)
    let backgroundColor = BadgeLevel.warning.backgroundColor
    XCTAssertEqual(backgroundColor, DS.Colors.warnBG)
}
```

2. Run `swift test` → fails ✅

3. Fix `BadgeChipStyle.swift`:

```swift
case .warning: return DS.Colors.warnBG  // Fixed
```

4. Run `swift test` → passes ✅

5. Add snapshot test for visual regression:

```swift
func testWarningBadgeSnapshot() {
    assertSnapshot(matching: Badge(text: "Warning", level: .warning), as: .image)
}
```

### Step 6: Validate

- ✅ Unit test passes
- ✅ Snapshot test passes
- ✅ SwiftLint 0 violations
- ✅ Preview shows correct yellow background

### Step 7: Finalize

Update `001_Badge_Warning_Color_Bug.md`:

```markdown
## Resolution
- **Root Cause**: Copy-paste error in `BadgeLevel.backgroundColor` switch
- **Fix**: Changed `case .warning: return DS.Colors.infoBG` to `DS.Colors.warnBG`
- **Tests Added**: Unit test + snapshot test
- **Commit**: `a1b2c3d`

## Status
✅ Resolved
```

---

## 🔄 INTEGRATION WITH WORKFLOW

After fixing a bug, use:

- [ARCHIVE command](./ARCHIVE.md) to document the bug fix completion
- [STATE command](./STATE.md) to check overall FoundationUI health
- [START command](./START.md) if the bug revealed missing prerequisite tasks

---

## END OF SYSTEM PROMPT

Ensure Markdown formatting remains consistent across all FoundationUI documentation files.
